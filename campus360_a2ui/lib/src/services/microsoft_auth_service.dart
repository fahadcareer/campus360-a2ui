import 'package:flutter/material.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart'; // To get the global navigatorKey

class MicrosoftAuthService {
  static const String _tokenKey = 'ms_access_token';
  static AadOAuth? _oauth;

  // NOTE: This must be replaced with the actual Client ID from the Azure Portal
  static const String tenantId = 'common';
  static const String clientId = 'e5f232ad-b9ca-4cfe-bd8b-4ea418928c47';

  static const String scopes =
      'openid profile offline_access Calendars.ReadWrite OnlineMeetings.ReadWrite User.ReadBasic.All User.Read People.Read';

  static void initialize() {
    if (_oauth != null) return;

    final Config config = Config(
      tenant: tenantId,
      clientId: clientId,
      scope: scopes,
      // For testing, this default often works with "Mobile and desktop applications" redirect URI in Azure
      redirectUri: 'https://login.live.com/oauth20_desktop.srf',
      navigatorKey: navigatorKey,
    );
    _oauth = AadOAuth(config);
  }

  static Future<bool> login() async {
    initialize();
    try {
      await _oauth!.login();
      final accessToken = await _oauth!.getAccessToken();
      if (accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, accessToken);
        return true;
      }
    } catch (e) {
      debugPrint('Error logging in to Microsoft: $e');
    }
    return false;
  }

  static Future<void> logout() async {
    initialize();
    try {
      await _oauth!.logout();
    } catch (e) {
      debugPrint('Error logging out of Microsoft: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isSignedIn() async {
    initialize();
    final hasCachedAccount = await _oauth!.hasCachedAccountInformation;
    if (hasCachedAccount) {
      return true;
    }
    final token = await getAccessToken();
    return token != null;
  }
}
