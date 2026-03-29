import 'dart:convert';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/services/api_client.dart';
import 'package:leapcarrier/core/services/exceptions.dart';
import 'package:leapcarrier/core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AuthService — LEAP Carrier
//
// Owns the login / logout contract:
//   1. Uppercase userId (OTM requires DOMAIN.USERNAME format)
//   2. Build Basic Auth header via SessionService
//   3. Validate credentials via lightweight GET to /items/DEFAULT
//   4. Fetch associated service provider GID via GET_SERVPROV query
//   5. Save session via SessionService on success
// ═══════════════════════════════════════════════════════════════════════════════

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Validates credentials, fetches servprovGid, saves session.
  /// Throws AuthException on failure.
  Future<void> login({
    required String instanceUrl,
    required String userId,
    required String password,
    bool rememberMe = false,
  }) async {
    final cleanUrl = instanceUrl.trim().replaceAll(RegExp(r'/$'), '');
    final upperId = userId.trim().toUpperCase();
    final authHeader = SessionService.buildBasicAuth(upperId, password.trim());

    // Step 1 — Validate credentials
    final response = await ApiClient.instance.getRaw(
      '$cleanUrl${AppConstants.pathValidateLogin}',
      authHeader: authHeader,
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException(
        'Invalid credentials. Please check your username and password.',
      );
    } else if (response.statusCode != 200) {
      throw AuthException(
        'Server error (${response.statusCode}). Please try again or contact your admin.',
      );
    }

    // Step 2 — Save session first (needed for subsequent API calls)
    await SessionService.instance.saveSession(
      instanceUrl: cleanUrl,
      authHeader: authHeader,
      userId: upperId,
      password: rememberMe ? password.trim() : null,
    );

    // Step 3 — Fetch the service provider GID associated with this user
    // Uses the GET_SERVPROV saved query — same as the OTM web app
    try {
      final spResponse = await ApiClient.instance.postRaw(
        '$cleanUrl${AppConstants.pathServprovQuery}',
        authHeader: authHeader,
        body: {
          'copiedFrom': 'GET_SERVPROV',
          'parameterValues': {
            'serv_gid': upperId,
          },
        },
      );

      if (spResponse.statusCode == 200) {
        final data = jsonDecode(spResponse.body);
        final rawItems = data['items'];
        final items = rawItems is List
            ? rawItems
            : (rawItems is Map ? [rawItems] : []);
        if (items.isNotEmpty) {
          final servprovGid = items[0]['servprovGid'] as String? ?? '';
          final servprovName =
              items[0]['servprovName'] as String? ?? servprovGid;
          if (servprovGid.isNotEmpty) {
            await SessionService.instance
                .saveServprov(servprovGid, servprovName);
          }
        }
      }
    } catch (_) {
      // Non-fatal — app still works, spot bid submission will fail gracefully
    }
  }

  Future<void> logout() => SessionService.instance.clear();
}