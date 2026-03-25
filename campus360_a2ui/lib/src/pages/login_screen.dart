import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_controller.dart';
import '../widgets/toast_utils.dart';
import 'chat_screen.dart';
import '../widgets/common/custom_text_form.dart';
import '../widgets/common/cus_button.dart';
import '../res/colors/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null && result['token'] != null) {
      if (mounted) {
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).initialize(result['userId'] ?? "unknown", result['token']);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      );
    } else {
      Utility.showToast(msg: "Login failed. Please check your credentials.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ThemeController handles theme mode, so Theme.of(context) reflects that.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeController>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: isDark ? Colors.white70 : AppColors.primaryColor,
            ),
            onPressed: () => Provider.of<ThemeController>(
              context,
              listen: false,
            ).toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Campus360 Chatbot",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to your workplace",
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : AppColors.textColor,
                ),
              ),
              const SizedBox(height: 48),
              CustomTextForm(
                controller: _emailController,
                lablelText: "Email Address",
                label: "Enter your email",
                onChanged: (val) {},
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: isDark ? Colors.white70 : AppColors.textColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextForm(
                controller: _passwordController,
                lablelText: "Password",
                label: "Enter your password",
                obscureText: _obscurePassword,
                onChanged: (val) {},
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: isDark ? Colors.white70 : AppColors.textColor,
                ),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.white70 : AppColors.textColor,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : CustomButton(
                      context: context,
                      onPressed: _login,
                      txt: "Sign In",
                      prime: AppColors.primaryColor,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
