// ═══════════════════════════════════════════════════════════════════════════════
// exceptions.dart — LEAP Carrier
//
// Single source of truth for all typed exceptions.
// Import this file wherever ApiException or AuthException is needed.
// ═══════════════════════════════════════════════════════════════════════════════

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
