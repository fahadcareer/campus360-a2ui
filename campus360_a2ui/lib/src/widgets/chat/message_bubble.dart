import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:genui/genui.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../res/colors/colors.dart';
import '../a2ui_catalog.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  /// Build historical widgets directly from stored ui_data
  Widget _buildHistoryWidgets(BuildContext context, List<dynamic> uiData) {
    final widgets = <Widget>[];
    for (final item in uiData) {
      if (item is Map<String, dynamic>) {
        final widgetType = item['type'] as String?;
        final widgetData = item['data'] as Map<String, dynamic>? ?? {};
        if (widgetType != null) {
          // Find the matching CatalogItem and build the widget
          final catalogItem = A2UICatalog.catalog.items
              .cast<CatalogItem>()
              .where((ci) => ci.name == widgetType)
              .firstOrNull;
          if (catalogItem != null) {
            try {
              final widget = catalogItem.widgetBuilder(
                CatalogItemContext(
                  id: item['id']?.toString() ?? 'hist_${widgets.length}',
                  data: widgetData,
                  buildChild: (childId, [dataContext]) =>
                      const SizedBox.shrink(),
                  dispatchEvent: (_) {},
                  buildContext: context,
                  dataContext: DataContext(DataModel(), '/'),
                  getComponent: (_) => null,
                  surfaceId: 'history',
                ),
              );
              widgets.add(widget);
            } catch (e) {
              print('DEBUG: Error building history widget $widgetType: $e');
            }
          }
        }
      }
    }
    if (widgets.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message is UserMessage;

    final userBubbleColor = isDark
        ? AppColors.chatGptSurface
        : AppColors.chatGptLightSurface;
    final textColor = isDark ? Colors.white : AppColors.chatGptLightPrimaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  child: Icon(
                    Icons.psychology,
                    size: 14,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  padding: isUser
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isUser ? userBubbleColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isUser
                      ? Text(
                          (message as UserMessage).text,
                          style: TextStyle(color: textColor, fontSize: 15),
                        )
                      : message is AiTextMessage
                      ? MarkdownBody(
                          data: (message as AiTextMessage).text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              height: 1.6,
                            ),
                            code: TextStyle(
                              backgroundColor: userBubbleColor,
                              color: textColor,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF6F6F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            h1: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            h2: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            listBullet: TextStyle(color: textColor),
                          ),
                        )
                      : (message is AiUiMessage)
                      ? Consumer<ChatProvider>(
                          builder: (context, provider, _) {
                            final surfaceId =
                                (message as AiUiMessage).surfaceId;

                            // Check if this is a historical widget
                            if (surfaceId.startsWith('history_')) {
                              final uiData = provider.historyWidgets[surfaceId];
                              if (uiData != null && uiData.isNotEmpty) {
                                return _buildHistoryWidgets(context, uiData);
                              }
                              return const SizedBox.shrink();
                            }

                            // Live widget — use GenUiSurface
                            final conversation = provider.conversation;
                            if (conversation == null)
                              return const SizedBox.shrink();
                            return KeyedSubtree(
                              key: ValueKey('surface_$surfaceId'),
                              child: GenUiSurface(
                                host: conversation.host,
                                surfaceId: surfaceId,
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: userBubbleColor,
                  child: Icon(Icons.person, size: 14, color: textColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
