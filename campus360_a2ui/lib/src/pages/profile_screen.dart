import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/models/user_model.dart';
import '../services/auth_service.dart';
import '../providers/theme_controller.dart';
import '../providers/chat_provider.dart';
import '../widgets/toast_utils.dart';
import 'login_screen.dart';
import '../widgets/common/cus_appbar.dart';
import '../widgets/common/cus_button.dart';
import '../res/colors/colors.dart';
import '../services/microsoft_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String token;

  const ProfileScreen({super.key, required this.userId, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isMicrosoftConnected = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkMicrosoftAuth();
  }

  Future<void> _checkMicrosoftAuth() async {
    final isConnected = await MicrosoftAuthService.isSignedIn();
    if (mounted) {
      setState(() {
        _isMicrosoftConnected = isConnected;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    print(
      'DEBUG UI: Loading user profile... Token length: ${widget.token.length}',
    );
    final userData = await AuthService.getUserProfile(widget.token);
    if (userData != null) {
      print('DEBUG UI: Raw User Data: $userData');
      if (mounted) {
        setState(() {
          _user = UserModel.fromJson(userData);
          _isLoading = false;
        });
      }
    } else {
      print('DEBUG UI: Failed to load user data (null result)');
      Utility.showToast(msg: "Failed to load profile details.");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.clearSession();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: "Profile", backButton: true),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryColor,
                          backgroundImage: _user?.avatar != null
                              ? NetworkImage(_user!.avatar)
                              : null,
                          child: _user?.avatar == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user?.name ?? "User",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          _user?.role ?? "Member",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Info Card
                  _buildSection(context, "Account Information", [
                    _buildInfoTile(
                      context,
                      Icons.phone_android_outlined,
                      "Mobile",
                      _user?.phone ?? "",
                    ),
                    _buildInfoTile(
                      context,
                      Icons.location_on_outlined,
                      "Address",
                      _user?.address ?? "",
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSection(context, "App Settings", [
                    ListTile(
                      leading: Icon(
                        themeController.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: AppColors.primaryColor,
                      ),
                      title: Text(
                        "Dark Theme",
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Switch(
                        value: themeController.isDarkMode,
                        onChanged: (value) => themeController.toggleTheme(),
                        activeColor: AppColors.whiteColor,
                        activeTrackColor: AppColors.primaryColor,
                        inactiveThumbColor: AppColors.primaryColor,
                        inactiveTrackColor: AppColors.horizondalLineColor,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Integrations Section
                  _buildSection(context, "Integrations", [
                    ListTile(
                      leading: const Icon(
                        Icons.window, // Microsoft Windows-like icon
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        "Microsoft Account",
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        _isMicrosoftConnected ? "Connected" : "Not connected",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _isMicrosoftConnected
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          if (_isMicrosoftConnected) {
                            await MicrosoftAuthService.logout();
                          } else {
                            await MicrosoftAuthService.login();
                          }
                          _checkMicrosoftAuth();
                          // Reconnect WebSocket so backend gets the fresh ms_token
                          if (mounted) {
                            Provider.of<ChatProvider>(
                              context,
                              listen: false,
                            ).reinitialize();
                          }
                        },
                        child: Text(
                          _isMicrosoftConnected ? "Disconnect" : "Connect",
                          style: TextStyle(
                            color: _isMicrosoftConnected
                                ? Colors.red
                                : AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 40),

                  // Logout Button
                  CustomButton(
                    context: context,
                    onPressed: _handleLogout,
                    txt: "Logout",
                    prime: Colors.redAccent,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
