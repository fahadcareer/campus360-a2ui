import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart';
import 'package:genui_a2ui/genui_a2ui.dart';
// ignore: implementation_imports
import 'package:genui_a2ui/src/a2a/a2a.dart' hide TextPart, DataPart;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../services/websocket_transport.dart';
import '../services/microsoft_auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/a2ui_catalog.dart';

class ChatProvider extends ChangeNotifier {
  A2uiMessageProcessor? _processor;
  A2uiAgentConnector? _connector;
  GenUiConversation? _conversation;
  WebSocketTransport? _transport;
  String? _userId;
  String? _token;
  String? _conversationId;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  List<Map<String, dynamic>> _history = [];
  final ScrollController _scrollController = ScrollController();

  /// Stores raw ui_data for historical widget surfaces, keyed by surfaceId.
  /// Used to render historical widgets directly without GenUiSurface.
  final Map<String, List<dynamic>> historyWidgets = {};

  GenUiConversation? get conversation => _conversation;
  String? get conversationId => _conversationId;
  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  List<Map<String, dynamic>> get history => _history;
  List<ChatMessage> get messages {
    final all = _conversation?.conversation.value ?? [];
    return all.where((msg) {
      if (msg is UserMessage) {
        final parts = msg.parts;
        if (parts.isNotEmpty && parts.first is DataPart) {
          final data = (parts.first as DataPart).data;
          if (data != null &&
              (data['action'] == 'action_set_ms_token' ||
                  data['action'] == 'action_set_fcm_token')) {
            return false;
          }
        }
      }
      if (msg is AiTextMessage) {
        final text = msg.parts.whereType<TextPart>().map((p) => p.text).join();
        return !text.startsWith('NOTIFICATION:');
      }
      return true;
    }).toList();
  }
  ScrollController get scrollController => _scrollController;

  Future<void> initialize(
    String userId,
    String token, {
    String? conversationId,
  }) async {
    if (_initialized &&
        _userId == userId &&
        _token == token &&
        _conversationId == conversationId)
      return;
    _userId = userId;
    _token = token;
    _conversationId = conversationId;
    await _setupConversation(userId, token, conversationId: conversationId);
    await fetchHistory();
  }

  /// Call this after Microsoft login/logout or conversation switch to reconnect WebSocket.
  Future<void> reinitialize({String? conversationId}) async {
    if (_userId != null && _token != null) {
      if (conversationId != null) _conversationId = conversationId;
      _initialized = false;
      _isLoading = false;
      await _setupConversation(
        _userId!,
        _token!,
        conversationId: _conversationId,
      );
    }
  }

  Future<void> switchConversation(String conversationId) async {
    if (_conversationId == conversationId) return;
    _conversationId = conversationId;
    await reinitialize(conversationId: conversationId);
  }

  Future<void> _setupConversation(
    String userId,
    String token, {
    String? conversationId,
  }) async {
    // Dispose old listener and conversation if exists
    _conversation?.conversation.removeListener(_onConversationUpdated);
    _conversation?.dispose();

    // Initialize GenUI + A2UI integration
    _processor = A2uiMessageProcessor(catalogs: [A2UICatalog.catalog]);

    // Fetch Microsoft token if available
    final msToken = await MicrosoftAuthService.getAccessToken();

    // Custom WebSocket setup to support FastAPI backend
    String urlString =
        '${ApiConfig.websocketChat}/$userId?token=${Uri.encodeComponent(token)}';

    if (msToken != null) {
      urlString += '&ms_token=${Uri.encodeComponent(msToken)}';
    }

    if (conversationId != null) {
      urlString += '&conversation_id=${Uri.encodeComponent(conversationId)}';
    }

    final url = Uri.parse(urlString);
    _transport = WebSocketTransport(url: url);
    final a2aClient = A2AClient(url: url.toString(), transport: _transport!);

    _connector = A2uiAgentConnector(url: url, client: a2aClient);
    final generator = A2uiContentGenerator(
      connector: _connector!,
      serverUrl: Uri.parse(ApiConfig.httpUrl),
    );

    _conversation = GenUiConversation(
      contentGenerator: generator,
      a2uiMessageProcessor: _processor!,
      onTextResponse: (text) {
        print('DEBUG PROVIDER: Received text response: $text');
        if (text.startsWith('NOTIFICATION:')) {
          final content = text.replaceFirst('NOTIFICATION:', '').trim();
          
          // Split title and body if possible (expected format: "Title: Body")
          String title = "Notification";
          String body = content;
          if (content.contains(': ')) {
            final parts = content.split(': ');
            title = parts[0];
            body = parts.sublist(1).join(': ');
          }
          
          LocalNotificationService.showNotification(
            title: title,
            body: body,
          );
        }
      },
      onSurfaceAdded: (update) =>
          print('DEBUG PROVIDER: Surface added: ${update.surfaceId}'),
    );

    // Add listener to discover types
    _conversation?.conversation.addListener(() {
      final msgs = _conversation?.conversation.value;
      if (msgs != null && msgs.isNotEmpty) {
        print('DEBUG TYPES: Last message type: ${msgs.last.runtimeType}');
      }
    });

    _conversationId = conversationId;
    _initialized = true;
    notifyListeners();

    // Send FCM token to backend immediately after setup
    Future.microtask(() async {
      final fcmToken = await LocalNotificationService.getFCMToken();
      if (fcmToken != null) {
        print('DEBUG PROVIDER: Sending FCM token to backend: ${fcmToken.substring(0, 10)}...');
        _conversation?.sendRequest(
          UserMessage([
            DataPart({'action': 'action_set_fcm_token', 'value': fcmToken}),
          ]),
        );
      }
    });

    // If we have a conversationId, fetch and load history
    if (conversationId != null) {
      _isHistoryLoading = true;
      notifyListeners();
      try {
        final histResponse = await http.get(
          Uri.parse('${ApiConfig.httpUrl}/history/$userId/$conversationId'),
        );
        if (histResponse.statusCode == 200) {
          final List msgData = json.decode(histResponse.body);
          final List<ChatMessage> mappedMessages = [];

          for (var m in msgData) {
            final role = m['role'];
            final content = m['content']?.toString() ?? '';
            final uiData = m['ui_data'] as List?;

            if (role == 'user') {
              mappedMessages.add(UserMessage([TextPart(content)]));
            } else if (role == 'ai') {
              if (uiData != null && uiData.isNotEmpty) {
                // Store raw ui_data for direct rendering in message_bubble
                final surfaceId = 'history_${m['id'] ?? m['timestamp']}';
                historyWidgets[surfaceId] = uiData;

                // Create AiUiMessage with minimal definition as a marker
                mappedMessages.add(
                  AiUiMessage(
                    surfaceId: surfaceId,
                    definition: UiDefinition(surfaceId: surfaceId),
                  ),
                );
              } else {
                // Plain AI text message
                mappedMessages.add(AiTextMessage([TextPart(content)]));
              }
            }
          }

          if (mappedMessages.isNotEmpty) {
            final notifier =
                _conversation?.conversation
                    as ValueNotifier<List<ChatMessage>>?;
            if (notifier != null) {
              notifier.value = mappedMessages;
              _scrollToBottom();
            }
          }
        }
      } catch (e) {
        print('DEBUG PROVIDER: Error loading message history: $e');
      } finally {
        _isHistoryLoading = false;
        notifyListeners();
      }
    }

    // Set up button click handler
    A2UICatalog.onButtonClick = (label, action, {value}) async {
      print(
        'DEBUG PROVIDER: Button clicked. Label: $label, Action: $action, Value: $value',
      );
      _isLoading = true;
      notifyListeners();

      // Handle location sharing for attendance
      if (action == 'action_send_location') {
        final locationData = await _getLocation();
        _conversation?.sendRequest(
          UserMessage([
            TextPart(label),
            DataPart({
              'action': action,
              if (locationData != null) 'value': locationData,
            }),
          ]),
        );
      } else if (action == 'action_microsoft_login') {
        // Trigger MS login flow directly from chat
        await MicrosoftAuthService.login();
        reinitialize();
      } else {
        _conversation?.sendRequest(
          UserMessage([
            TextPart(label),
            DataPart({'action': action, if (value != null) 'value': value}),
          ]),
        );
      }
    };

    _conversation?.conversation.addListener(_onConversationUpdated);
  }

  Future<void> fetchHistory() async {
    if (_userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.httpUrl}/history/$_userId'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _history = data.map((e) => e as Map<String, dynamic>).toList();
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG PROVIDER: Error fetching history: $e');
    }
  }

  Future<void> deleteConversation(String cid) async {
    if (_userId == null) return;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.httpUrl}/history/$_userId/$cid'),
      );
      if (response.statusCode == 200) {
        if (_conversationId == cid) {
          clearChat();
        } else {
          fetchHistory();
        }
      }
    } catch (e) {
      print('DEBUG PROVIDER: Error deleting conversation: $e');
    }
  }

  Future<void> renameConversation(String cid, String newTitle) async {
    if (_userId == null) return;
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.httpUrl}/history/$_userId/$cid/rename'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': newTitle}),
      );
      if (response.statusCode == 200) {
        fetchHistory();
      }
    } catch (e) {
      print('DEBUG PROVIDER: Error renaming conversation: $e');
    }
  }

  Future<void> togglePin(String cid) async {
    if (_userId == null) return;
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.httpUrl}/history/$_userId/$cid/pin'),
      );
      if (response.statusCode == 200) {
        fetchHistory();
      }
    } catch (e) {
      print('DEBUG PROVIDER: Error toggling pin: $e');
    }
  }

  void _onConversationUpdated() {
    final messages = _conversation?.conversation.value;
    if (messages != null && messages.isNotEmpty) {
      final last = messages.last;
      // If the last message is from AI, stop loading
      if (last is AiTextMessage || last is AiUiMessage) {
        _isLoading = false;
      }
    }
    notifyListeners();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<Map<String, double>?> _getLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('DEBUG PROVIDER: Location services are disabled');
        return null;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('DEBUG PROVIDER: Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('DEBUG PROVIDER: Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
        'DEBUG PROVIDER: Got location - Lat: ${position.latitude}, Lon: ${position.longitude}',
      );

      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      print('DEBUG PROVIDER: Error getting location: $e');
      return null;
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    print('DEBUG PROVIDER: Sending message: $text');
    _isLoading = true;
    notifyListeners();
    // Send timezone offset in DataPart
    final offset = DateTime.now().timeZoneOffset.inMinutes; // e.g. 330 for IST
    _conversation?.sendRequest(
      UserMessage([
        TextPart(text),
        DataPart({
          'timezoneOffset': offset,
          'message': text, // Ensure message field is present for backend
        }),
      ]),
    );
    _scrollToBottom();
  }

  void clearChat() {
    if (_userId != null && _token != null) {
      _conversationId = null; // Backend will create a new one
      _isLoading = false;
      _setupConversation(_userId!, _token!);
      fetchHistory();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _conversation?.conversation.removeListener(_onConversationUpdated);
    _conversation?.dispose();
    super.dispose();
  }
}
