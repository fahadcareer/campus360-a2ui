import 'package:flutter/material.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  ChatMessage({required this.content, required this.role, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class ChatController extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  ScrollController get scrollController => _scrollController;

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(content: text, role: MessageRole.user));
    notifyListeners();
    _scrollToBottom();

    // Simulate AI response/streaming
    _isStreaming = true;
    notifyListeners();

    // Mock streaming delay
    await Future.delayed(const Duration(seconds: 1));

    String fullResponse =
        "I'm Mandoobee, your AI assistant. I can help you with HR tasks, meeting schedules, and leave requests. How can I assist you further today?";

    // Add assistant message placeholder
    _messages.add(ChatMessage(content: "", role: MessageRole.assistant));
    _isStreaming = false;

    // Simulate streaming text appending
    String currentText = "";
    for (int i = 0; i < fullResponse.length; i++) {
      currentText += fullResponse[i];
      _messages[_messages.length - 1] = ChatMessage(
        content: currentText,
        role: MessageRole.assistant,
      );
      notifyListeners();
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 10));
    }
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

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
