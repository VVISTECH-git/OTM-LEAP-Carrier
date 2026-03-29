import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/services/exceptions.dart';
import 'package:leapcarrier/core/services/session_service.dart';
import 'package:leapcarrier/features/auth/screens/login_screen.dart';
import 'package:leapcarrier/main.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ApiClient — LEAP Carrier
//
// Thin HTTP wrapper that:
//   • Injects Authorization + Content-Type headers from SessionService
//   • Differentiates 401/403 (bad credentials) from 5xx (server errors)
//   • Throws typed ApiException / AuthException on failure
//   • Provides a raw mode for login (before session is saved)
//   • Provides XML POST for the legacy WMServlet spot-bid endpoint
// ═══════════════════════════════════════════════════════════════════════════════

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Header factories ───────────────────────────────────────────────────────

  Future<Map<String, String>> get _jsonHeaders async => {
        'Content-Type': 'application/json',
        'Authorization': await SessionService.instance.authHeader,
      };

  Future<Map<String, String>> get _xmlHeaders async => {
        'Content-Type': 'application/xml',
        'Authorization': await SessionService.instance.authHeader,
      };

  Future<String> get _baseUrl => SessionService.instance.instanceUrl;

  // ── GET ────────────────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, String>? extraHeaders,
  }) => _guarded(() async {
    final url = Uri.parse('${await _baseUrl}$path');
    final headers = {...await _jsonHeaders, ...?extraHeaders};
    final response = await http
        .get(url, headers: headers)
        .timeout(AppConstants.timeoutMedium);
    return _handleResponse(response);
  });

  /// GET with a full absolute URL (e.g. for bid-check where URL is built externally).
  Future<dynamic> getUrl(String fullUrl) => _guarded(() async {
    final response = await http
        .get(Uri.parse(fullUrl), headers: await _jsonHeaders)
        .timeout(AppConstants.timeoutMedium);
    return _handleResponse(response);
  });

  // ── POST ───────────────────────────────────────────────────────────────────

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
  }) => _guarded(() async {
    final url = Uri.parse('${await _baseUrl}$path');
    final response = await http
        .post(
          url,
          headers: await _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(AppConstants.timeoutMedium);
    return _handleResponse(response);
  });

  // ── POST (large body — image uploads, uses timeoutUpload) ─────────────────

  Future<dynamic> postLarge(
    String path, {
    required Map<String, dynamic> body,
  }) => _guarded(() async {
    final url = Uri.parse('${await _baseUrl}$path');
    final response = await http
        .post(
          url,
          headers: await _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(AppConstants.timeoutUpload);
    return _handleResponse(response);
  });

  // ── PATCH ──────────────────────────────────────────────────────────────────

  Future<dynamic> patch(
    String path, {
    required Map<String, dynamic> body,
  }) => _guarded(() async {
    final url = Uri.parse('${await _baseUrl}$path');
    final response = await http
        .patch(
          url,
          headers: await _jsonHeaders,
          body: jsonEncode(body),
        )
        .timeout(AppConstants.timeoutShort);
    return _handleResponse(response);
  });

  // ── XML POST (legacy WMServlet — spot bid submission) ──────────────────────

  Future<void> postXml(String path, {required String body}) => _guarded(() async {
    final url = Uri.parse('${await _baseUrl}$path');
    final response = await http
        .post(
          url,
          headers: await _xmlHeaders,
          body: body,
        )
        .timeout(AppConstants.timeoutMedium);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Authentication error. Please log in again.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        'Request failed (${response.statusCode}). Please try again.',
        response.statusCode,
      );
    }
  });

  // ── Raw GET (used during login — before session is saved) ──────────────────

  Future<http.Response> getRaw(
    String fullUrl, {
    required String authHeader,
  }) => _guarded(() => http.get(
    Uri.parse(fullUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': authHeader,
    },
  ).timeout(AppConstants.timeoutShort));

  // ── Raw POST (used for service provider lookup during login) ───────────────

  Future<http.Response> postRaw(
    String fullUrl, {
    required String authHeader,
    required Map<String, dynamic> body,
  }) => _guarded(() => http
      .post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        },
        body: jsonEncode(body),
      )
      .timeout(AppConstants.timeoutShort));

  // ── Network exception wrapper ──────────────────────────────────────────────
  // Converts low-level Dart/OS exceptions (SocketException, TimeoutException,
  // TlsException) into typed ApiExceptions with clean user-facing messages.
  // Without this, raw messages like "SocketException: OS Error: Connection
  // refused, errno = 111" leak directly into UI snackbars and error states.
  Future<T> _guarded<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Request timed out. Check your connection and try again.',
      );
    } on SocketException {
      throw const ApiException(
        'No network connection. Check your connection and try again.',
      );
    } on HandshakeException {
      throw const ApiException(
        'Secure connection failed. The server certificate may be invalid.',
      );
    } on TlsException {
      throw const ApiException(
        'Secure connection failed. The server certificate may be invalid.',
      );
    } catch (e) {
      // Catch-all: surface as a generic ApiException so raw Dart internals
      // (e.g. "Bad state: No element") never reach the UI.
      throw ApiException('An unexpected error occurred. Please try again. ($e)');
    }
  }

  // ── Response handler ───────────────────────────────────────────────────────

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const ApiException(
          'Server returned an unexpected response format. Please try again.',
        );
      }
    }

    // Only log raw HTTP errors in debug builds — response bodies can contain
    // internal paths, user GIDs, or stack traces that must not reach device logs
    // in production (readable via adb logcat).
    if (kDebugMode) {
      dev.log(
        '[ApiClient] ❌ HTTP ${response.statusCode}\n'
        '  URL : ${response.request?.url}\n'
        '  Body: ${response.body}',
        name: 'ApiClient',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      // Clear the stale session token, then bounce the user to login.
      // Fire-and-forget the async clear — the navigation happens immediately.
      SessionService.instance.softLogout().then((_) {
        LeapCarrierApp.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
      throw const AuthException(
        'Your session has expired. Please log in again.',
      );
    }

    if (response.statusCode == 404) {
      throw ApiException('Resource not found.', response.statusCode);
    }

    throw ApiException(
      'Server error (${response.statusCode}). Please try again or contact your admin.',
      response.statusCode,
    );
  }
}