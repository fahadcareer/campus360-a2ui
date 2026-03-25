import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat/sidebar.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/input_bar.dart';
import '../widgets/chat/typing_indicator.dart';
import '../res/colors/colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: MediaQuery.of(context).size.width < 800
          ? const ChatSidebar()
          : null,
      body: Row(
        children: [
          // Sidebar for Desktop
          if (MediaQuery.of(context).size.width >= 800 && _isSidebarVisible)
            const ChatSidebar(),

          // Main Chat Area
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  _buildHeader(context),

                  // Message List
                  Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, provider, child) {
                        final messages = provider.messages;

                        if (messages.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          controller: provider.scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          itemCount:
                              messages.length + (provider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildTypingIndicator();
                            }
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: MessageBubble(message: messages[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Input Area
                  const InputBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isDesktop)
            IconButton(
              icon: Icon(
                _isSidebarVisible ? Icons.menu_open : Icons.menu,
                color: AppColors.chatGptSecondaryText,
              ),
              onPressed: () =>
                  setState(() => _isSidebarVisible = !_isSidebarVisible),
            )
          else
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.chatGptSecondaryText,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Text(
            'Campus360 Chatbot',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_note,
              color: AppColors.chatGptSecondaryText,
            ),
            onPressed: () => context.read<ChatProvider>().clearChat(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.chatGptLightPrimaryText;
    final surfaceColor = isDark
        ? AppColors.chatGptSurface
        : AppColors.chatGptLightSurface;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: surfaceColor,
            child: Icon(Icons.psychology, size: 40, color: textColor),
          ),
          const SizedBox(height: 24),
          Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionCard('Check my schedule'),
              _buildSuggestionCard('Apply for leave'),
              _buildSuggestionCard('Show my tasks'),
              _buildSuggestionCard('Show today\'s meetings'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.chatGptSecondaryText
        : AppColors.chatGptLightSecondaryText;

    return InkWell(
      onTap: () => context.read<ChatProvider>().sendMessage(text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: secondaryText, fontSize: 13)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.chatGptSurface
        : AppColors.chatGptLightSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TypingIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
