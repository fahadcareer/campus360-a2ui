import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore: implementation_imports
import 'package:genui_a2ui/src/a2a/a2a.dart';
import 'package:http/http.dart' as http;

/// A custom A2A [Transport] that uses WebSockets instead of SSE.
/// This allows genui_a2ui to work with the Python FastAPI WebSocket backend.
class WebSocketTransport implements Transport {
  final Uri url;
  @override
  final Map<String, String> authHeaders;

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, Object?>>.broadcast();

  WebSocketTransport({required this.url, this.authHeaders = const {}});

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    // A2A Agent Card is usually fetched via HTTP GET
    final httpUrl = url.replace(
      scheme: url.scheme == 'wss' ? 'https' : 'http',
      path: path,
    );
    final response = await http.get(
      httpUrl,
      headers: {...authHeaders, ...headers},
    );
    return jsonDecode(response.body) as Map<String, Object?>;
  }

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> request, {
    String path = '',
    Map<String, String> headers = const {},
  }) async {
    // Fallback to HTTP for simple send if needed, but for our backend we want WS
    await _ensureConnected();
    _channel!.sink.add(jsonEncode(request));
    // For a simple 'send', we should probably wait for the next message, but
    // Chatbot usually uses sendStream.
    return {};
  }

  Stream? _broadcastStream;

  @override
  Stream<Map<String, Object?>> sendStream(
    Map<String, Object?> request, {
    Map<String, String> headers = const {},
  }) {
    print('DEBUG: WebSocketTransport.sendStream called');
    final streamController = StreamController<Map<String, Object?>>();

    _ensureConnected()
        .then((_) {
          print('DEBUG: WebSocket connected to $url');
          // Extract the real message from A2A JSON-RPC request
          String? userMessage;
          String? extractedAction;
          dynamic extractedValue;
          int? extractedTimezoneOffset; // New variable

          try {
            final params = request['params'] as Map<String, dynamic>?;
            final messageObj = params?['message'] as Map<String, dynamic>?;
            final List<dynamic>? parts = messageObj?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              // Try to find a data part with an action (internal payload)
              for (final part in parts) {
                if (part['kind'] == 'data') {
                  final data = part['data'] as Map<String, dynamic>?;
                  if (data != null) {
                    // Check for action
                    if (data.containsKey('action')) {
                      extractedAction = data['action'].toString();
                      extractedValue = data['value'];
                      userMessage = extractedAction;
                      print(
                        'DEBUG: Extracted action from DataPart: $extractedAction, Value: $extractedValue',
                      );
                      // Do not break yet, might have timezoneOffset in same or other part
                    }

                    // Check for timezoneOffset
                    if (data.containsKey('timezoneOffset')) {
                      extractedTimezoneOffset = data['timezoneOffset'] as int?;
                      print(
                        'DEBUG: Extracted timezoneOffset: $extractedTimezoneOffset',
                      );
                    }
                  }
                }
              }
              // Fallback to the first text part if no action found
              if (userMessage == null) {
                for (final part in parts) {
                  if (part is Map<String, dynamic> && part['kind'] == 'text') {
                    userMessage = part['text']?.toString();
                    print('DEBUG: Falling back to TextPart: $userMessage');
                    break;
                  }
                }
                // Last resort: just use the first part's text if still null
                if (userMessage == null && parts.isNotEmpty) {
                  final firstPart = parts.first;
                  if (firstPart is Map<String, dynamic>) {
                    userMessage = firstPart['text']?.toString();
                    print(
                      'DEBUG: Absolute fallback to first part: $userMessage',
                    );
                  }
                }
              }
            }
          } catch (e) {
            print('DEBUG: Error extracting user message: $e');
          }

          print(
            'DEBUG: Sending user payload. Message: $userMessage, Action: $extractedAction',
          );
          // Send the raw message
          try {
            final payload = {
              'message': userMessage ?? '',
              if (extractedAction != null) 'action': extractedAction,
              if (extractedValue != null) 'value': extractedValue,
              if (extractedTimezoneOffset != null)
                'timezoneOffset': extractedTimezoneOffset,
            };
            _channel!.sink.add(jsonEncode(payload));
          } catch (e) {
            print('DEBUG: Error sending to socket: $e');
            streamController.addError(e);
            return;
          }

          // Listen to the broadcast stream and adapt backend A2UIResponse to A2A Event
          late StreamSubscription subscription;
          subscription = _broadcastStream!.listen(
            (data) {
              try {
                final decoded =
                    jsonDecode(data as String) as Map<String, dynamic>;

                final sessionId = (decoded['session_id'] ?? 'default-context')
                    .toString();
                final uiList = decoded['ui'] as List?;
                final List<Map<String, dynamic>> components = [];
                String? rootId;

                // Use a guaranteed unique ID for this specific message turn
                final uniqueId = DateTime.now().millisecondsSinceEpoch
                    .toString();
                final messageId = 'msg-$uniqueId';
                final surfaceId = 'surface-$uniqueId';

                if (uiList != null && uiList.isNotEmpty) {
                  if (uiList.length > 1) {
                    // Multiple widgets: wrap in a column
                    rootId = 'root-column-$uniqueId';
                    final childIds = <String>[];
                    
                    for (var i = 0; i < uiList.length; i++) {
                      final w = uiList[i] as Map<String, dynamic>;
                      final id = w['id']?.toString() ?? 'comp-$i-$uniqueId';
                      childIds.add(id);
                      components.add(<String, dynamic>{
                        'id': id,
                        'component': <String, dynamic>{
                          w['type'].toString(): w['data'],
                        },
                      });
                    }
                    
                    // Add the column root
                    components.add(<String, dynamic>{
                      'id': rootId,
                      'component': <String, dynamic>{
                        'column': {
                          'children': childIds,
                        },
                      },
                    });
                  } else {
                    // Single widget: use it directly as root
                    final w = uiList[0] as Map<String, dynamic>;
                    rootId = w['id']?.toString() ?? 'comp-0-$uniqueId';
                    components.add(<String, dynamic>{
                      'id': rootId,
                      'component': <String, dynamic>{
                        w['type'].toString(): w['data'],
                      },
                    });
                  }
                }

                // 1. Send BeginRendering if we have a root
                if (rootId != null) {
                  streamController.add(<String, dynamic>{
                    'kind': 'status-update',
                    'taskId': 'chat-task',
                    'contextId': sessionId,
                    'status': <String, dynamic>{
                      'state': 'working',
                      'message': <String, dynamic>{
                        'role': 'agent',
                        'messageId': 'begin-$rootId',
                        'parts': [
                          <String, dynamic>{
                            'kind': 'data',
                            'data': <String, dynamic>{
                              'beginRendering': <String, dynamic>{
                                'surfaceId': surfaceId,
                                'root': rootId,
                              },
                            },
                          },
                        ],
                      },
                    },
                  });
                }

                // 2. Send the actual surface update with components
                final event = <String, dynamic>{
                  'kind': 'status-update',
                  'taskId': 'chat-task',
                  'contextId': sessionId,
                  'status': <String, dynamic>{
                    'state': 'completed',
                    'message': <String, dynamic>{
                      'role': 'agent',
                      'messageId': messageId,
                      'parts': [
                        if (decoded['message'] != null)
                          <String, dynamic>{
                            'kind': 'text',
                            'text': decoded['message'].toString(),
                          },
                        if (components.isNotEmpty)
                          <String, dynamic>{
                            'kind': 'data',
                            'data': <String, dynamic>{
                              'surfaceUpdate': <String, dynamic>{
                                'surfaceId': surfaceId,
                                'components': components,
                              },
                            },
                          },
                      ],
                    },
                  },
                  'final': true, // Mark as final
                };

                try {
                  streamController.add(event);
                } catch (addError) {
                  print('DEBUG WS: Error adding event to stream: $addError');
                }

                // Small delay to ensure A2A processing completes before closing
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (!streamController.isClosed) {
                    streamController.close();
                    subscription.cancel();
                  }
                });
              } catch (e) {
                // Ignored error in WS processing
              }
            },
            onError: (e) {
              streamController.addError(e);
            },
            onDone: () {
              streamController.close();
            },
            cancelOnError: false,
          );

          streamController.onCancel = () => subscription.cancel();
        })
        .catchError((e) {
          streamController.addError(e);
          streamController.close();
        });

    return streamController.stream;
  }

  Future<void> _ensureConnected() async {
    if (_channel == null || _channel!.closeCode != null) {
      _channel = WebSocketChannel.connect(url);
      _broadcastStream = _channel!.stream.asBroadcastStream();
    }
  }

  @override
  void close() {
    _channel?.sink.close();
    _controller.close();
  }
}
