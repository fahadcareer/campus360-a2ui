import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../res/colors/colors.dart';
import '../../services/auth_service.dart';
import '../../pages/profile_screen.dart';
import '../../data/models/user_model.dart';

class ChatSidebar extends StatefulWidget {
  const ChatSidebar({super.key});

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final session = await AuthService.getCachedSession();
    if (session != null) {
      final userData = await AuthService.getUserProfile(session['token']!);
      if (userData != null && mounted) {
        setState(() {
          _user = UserModel.fromJson(userData);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDark
        ? AppColors.chatGptSidebar
        : AppColors.chatGptLightSidebar;

    return SafeArea(
      child: Container(
        width: 260,
        color: sidebarColor,
        child: Column(
          children: [
            // New Chat Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () => context.read<ChatProvider>().clearChat(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: isDark
                            ? Colors.white
                            : AppColors.chatGptLightPrimaryText,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'New Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : AppColors.chatGptLightPrimaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Chat History List
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final history = chatProvider.history;

                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final cid = item['id']?.toString() ?? '';
                      final title = item['title']?.toString() ?? 'New Chat';
                      final isActive = chatProvider.conversationId == cid;
                      final isPinned = item['pinned'] == true;

                      return _SidebarItem(
                        title: title,
                        isActive: isActive,
                        isPinned: isPinned,
                        onTap: () {
                          chatProvider.switchConversation(cid);
                          if (MediaQuery.of(context).size.width < 800) {
                            Navigator.pop(context); // Close drawer on mobile
                          }
                        },
                        onDelete: () {
                          chatProvider.deleteConversation(cid);
                        },
                        onRename: (newTitle) {
                          chatProvider.renameConversation(cid, newTitle);
                        },
                        onTogglePin: () {
                          chatProvider.togglePin(cid);
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Profile/Settings
            Divider(color: Theme.of(context).dividerColor, height: 1),
            ListTile(
              onTap: () async {
                final session = await AuthService.getCachedSession();
                if (session != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: session['userId']!,
                        token: session['token']!,
                      ),
                    ),
                  );
                }
              },
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: isDark
                    ? AppColors.chatGptSurface
                    : AppColors.chatGptLightSurface,
                backgroundImage: _user?.avatar != null
                    ? NetworkImage(_user!.avatar)
                    : null,
                child: _user?.avatar == null
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: isDark
                            ? Colors.white
                            : AppColors.chatGptLightPrimaryText,
                      )
                    : null,
              ),
              title: Text(
                _user?.name ?? 'User',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white
                      : AppColors.chatGptLightPrimaryText,
                ),
              ),
              trailing: Icon(
                Icons.more_horiz,
                size: 18,
                color: isDark
                    ? AppColors.chatGptSecondaryText
                    : AppColors.chatGptLightSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String title;
  final bool isActive;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;
  final VoidCallback onTogglePin;

  const _SidebarItem({
    required this.title,
    required this.isActive,
    required this.isPinned,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onTogglePin,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  void _showRenameDialog() {
    final controller = TextEditingController(text: widget.title);
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Rename Chat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Enter new title',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                widget.onRename(trimmed);
              }
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  widget.onRename(trimmed);
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.chatGptSurface
        : AppColors.chatGptLightSurface;
    final textColor = isDark ? Colors.white : AppColors.chatGptLightPrimaryText;
    final secondaryText = isDark
        ? AppColors.chatGptSecondaryText
        : AppColors.chatGptLightSecondaryText;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? surfaceColor
                : (_isHovered
                      ? surfaceColor.withOpacity(0.5)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin, size: 12, color: secondaryText),
                ),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isActive ? textColor : secondaryText,
                    fontWeight: widget.isActive
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_isHovered || widget.isActive)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: secondaryText,
                    ),
                    color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          widget.onTogglePin();
                          break;
                        case 'rename':
                          _showRenameDialog();
                          break;
                        case 'delete':
                          widget.onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              widget.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 16,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.isPinned ? 'Unpin' : 'Pin Chat',
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'rename',
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rename',
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem(
                        value: 'delete',
                        height: 40,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
