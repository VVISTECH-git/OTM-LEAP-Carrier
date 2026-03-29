import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SessionService — LEAP Carrier
//
// Single source of truth for the current user session.
//
// Storage split:
//   • auth_header (Basic Auth token) → flutter_secure_storage (Android Keystore)
//   • remembered_password            → flutter_secure_storage (Android Keystore)
//   • Everything else (instanceUrl, userId, domain, etc.) → SharedPreferences
//
// The password is stored in secure storage rather than SharedPreferences so it
// is never written to a plain-text XML file on the device.
// ═══════════════════════════════════════════════════════════════════════════════

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  SharedPreferences? _prefs;

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // iOS: disable iCloud Keychain sync so the auth token cannot appear on
    // other devices owned by the same Apple ID. first_unlock keeps it
    // accessible after the first unlock post-boot (needed for background work).
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Called after successful login. Splits userId into domain + user parts
  /// and persists everything in the correct storage tier.
  Future<void> saveSession({
    required String instanceUrl,
    required String authHeader,
    required String userId,
    String? password,         // only written when Remember Me is checked
    String? servprovGid,
    String? servprovName,
    String? userType,
  }) async {
    final p      = await _p;
    final parts  = userId.split('.');
    final domain = parts.isNotEmpty ? parts[0] : userId;
    final user   = parts.length > 1 ? parts.sublist(1).join('.') : userId;

    // Auth token + password (if Remember Me) → encrypted storage
    await _secure.write(
      key:   AppConstants.secureAuthHeader,
      value: authHeader,
    );
    if (password != null) {
      await _secure.write(
        key:   AppConstants.securePassword,
        value: password,
      );
    }

    // Non-sensitive values → SharedPreferences
    await Future.wait([
      p.setString(AppConstants.prefInstanceUrl, instanceUrl),
      p.setString(AppConstants.prefUserId,      userId),
      p.setString(AppConstants.prefDomain,      domain),
      p.setString(AppConstants.prefUser,        user),
      // Record login timestamp for idle-session expiry check
      p.setInt(AppConstants.prefSessionSavedAt,
          DateTime.now().millisecondsSinceEpoch),
      if (servprovGid != null)
        p.setString(AppConstants.prefServprovGid, servprovGid),
      if (servprovName != null)
        p.setString(AppConstants.prefServprovName, servprovName),
      if (userType != null)
        p.setString(AppConstants.prefUserType, userType),
    ]);
  }

  Future<void> saveServprov(String gid, String name) async {
    final p = await _p;
    await Future.wait([
      p.setString(AppConstants.prefServprovGid,  gid),
      p.setString(AppConstants.prefServprovName, name),
    ]);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<String> get instanceUrl async =>
      (await _p).getString(AppConstants.prefInstanceUrl) ?? '';

  /// Auth token read from encrypted storage.
  Future<String> get authHeader async =>
      await _secure.read(key: AppConstants.secureAuthHeader) ?? '';

  Future<String> get domain async =>
      (await _p).getString(AppConstants.prefDomain) ?? '';

  Future<String> get user async =>
      (await _p).getString(AppConstants.prefUser) ?? '';

  Future<String> get userId async =>
      (await _p).getString(AppConstants.prefUserId) ?? '';

  Future<String> get userType async =>
      (await _p).getString(AppConstants.prefUserType) ?? '';

  Future<String> get servprovGid async =>
      (await _p).getString(AppConstants.prefServprovGid) ?? '';

  Future<String> get servprovName async =>
      (await _p).getString(AppConstants.prefServprovName) ?? '';

  /// Password read from encrypted storage (only present if Remember Me was on).
  Future<String?> get savedPassword async =>
      await _secure.read(key: AppConstants.securePassword);

  Future<bool> get isLoggedIn async =>
      (await authHeader).isNotEmpty;

  /// True when the session token is present but older than [AppConstants.sessionTtlHours].
  /// A missing timestamp is treated as expired so stale installs re-authenticate.
  Future<bool> get isSessionExpired async {
    final p       = await _p;
    final savedAt = p.getInt(AppConstants.prefSessionSavedAt) ?? 0;
    if (savedAt == 0) return true;
    final ageMs = DateTime.now().millisecondsSinceEpoch - savedAt;
    const ttlMs = AppConstants.sessionTtlHours * 3600 * 1000;
    return ageMs > ttlMs;
  }

  /// Returns all credentials needed for API calls in one shot.
  Future<Map<String, String>> get credentials async {
    final results = await Future.wait([
      instanceUrl,
      authHeader,
      domain,
      servprovGid,
    ]);
    return {
      'baseUrl':     results[0],
      'auth':        results[1],
      'domain':      results[2],
      'servprovGid': results[3],
    };
  }

  /// Returns the full credential map for the login screen pre-fill.
  Future<Map<String, String?>> get savedCredentials async {
    final p = await _p;
    return {
      'instanceUrl':  p.getString(AppConstants.prefInstanceUrl),
      'userId':       p.getString(AppConstants.prefUserId),
      'password':     await savedPassword,
      'servprovGid':  p.getString(AppConstants.prefServprovGid),
      'servprovName': p.getString(AppConstants.prefServprovName),
      'domain':       p.getString(AppConstants.prefDomain),
    };
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  /// Soft logout — deletes the auth token but keeps instanceUrl + userId so
  /// the login screen can pre-fill them. Called automatically on 401/403.
  Future<void> softLogout() async {
    await _secure.delete(key: AppConstants.secureAuthHeader);
    final p = await _p;
    await p.remove(AppConstants.prefSessionSavedAt);
  }

  Future<void> clear() async {
    final p = await _p;

    // Delete sensitive keys from secure storage
    await Future.wait([
      _secure.delete(key: AppConstants.secureAuthHeader),
      _secure.delete(key: AppConstants.securePassword),
    ]);

    // Clear all SharedPreferences keys
    await Future.wait([
      p.remove(AppConstants.prefInstanceUrl),
      p.remove(AppConstants.prefUserId),
      p.remove(AppConstants.prefDomain),
      p.remove(AppConstants.prefUser),
      p.remove(AppConstants.prefUserType),
      p.remove(AppConstants.prefServprovGid),
      p.remove(AppConstants.prefServprovName),
      p.remove(AppConstants.prefSessionSavedAt),
    ]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds a Basic Auth header from userId and password.
  static String buildBasicAuth(String userId, String password) {
    final encoded = base64Encode(utf8.encode('$userId:$password'));
    return 'Basic $encoded';
  }
}