import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// OtmInstanceService — LEAP Carrier
//
// Manages OTM instance URLs:
//   • Parsing a raw URL into a human-friendly OtmInstance
//   • Persisting up to 5 saved instances in SharedPreferences
//   • Tracking the active instance
//
// Previously inlined inside login_screen.dart as CarrierInstanceService.
// Extracted here to match DockMate's architecture.
//
// Parsing rules (Oracle OTM URL pattern):
//   https://otmgtm-{env-slug}-{domain}.otmgtm.{region}.ocs.oraclecloud.com/
//
//   Environment detection:
//     contains "test"     → OTM Test
//     contains "dev" + N  → OTM Development N
//     no keyword match    → OTM Production
// ═══════════════════════════════════════════════════════════════════════════════

enum OtmEnv { production, test, development }

class OtmInstance {
  final String url;
  final String displayName;
  final String domain;
  final OtmEnv env;
  final int?   devNumber;

  const OtmInstance({
    required this.url,
    required this.displayName,
    required this.domain,
    required this.env,
    this.devNumber,
  });

  String get envLabel {
    switch (env) {
      case OtmEnv.production:  return 'Production';
      case OtmEnv.test:        return 'Test';
      case OtmEnv.development: return devNumber != null ? 'Dev $devNumber' : 'Dev';
    }
  }

  Map<String, dynamic> toJson() => {
    'url':         url,
    'displayName': displayName,
    'domain':      domain,
    'env':         env.name,
    'devNumber':   devNumber,
  };

  factory OtmInstance.fromJson(Map<String, dynamic> j) => OtmInstance(
    url:         j['url']         as String,
    displayName: j['displayName'] as String,
    domain:      j['domain']      as String,
    env: OtmEnv.values.firstWhere(
      (e) => e.name == j['env'],
      orElse: () => OtmEnv.production,
    ),
    devNumber: j['devNumber'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is OtmInstance &&
      other.url.toLowerCase() == url.toLowerCase();

  @override
  int get hashCode => url.toLowerCase().hashCode;
}


class OtmInstanceService {
  OtmInstanceService._();
  static final OtmInstanceService instance = OtmInstanceService._();

  // Separate keys from DockMate so the two apps don't share instance lists
  static const _keyInstances = 'carrier_otm_instances';
  static const _keyActive    = 'carrier_otm_active_url';
  static const maxSaved      = AppConstants.maxSavedInstances;

  // ── Parse a raw OTM URL into an OtmInstance ──────────────────────────────
  // Returns null if the URL doesn't match Oracle OTM cloud pattern.

  static OtmInstance? parse(String rawUrl) {
    try {
      final trimmed = rawUrl.trim();

      // Security: reject plain-HTTP URLs — Basic Auth credentials must never
      // travel unencrypted. Only oracle OTM cloud HTTPS URLs are accepted.
      if (!trimmed.startsWith('https://')) return null;

      final url = trimmed.endsWith('/') ? trimmed : '$trimmed/';

      final host = url
          .replaceFirst(RegExp(r'^https?://'), '')
          .split('/')[0]
          .split('?')[0];

      if (!host.startsWith('otmgtm-') || !host.contains('.otmgtm.')) {
        return null;
      }

      final slug     = host.split('.')[0].replaceFirst('otmgtm-', '');
      final segments = slug.split('-');

      OtmEnv env    = OtmEnv.production;
      int?   devNum;
      String domain = segments.last;

      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i].toLowerCase();

        if (seg == 'test') {
          env    = OtmEnv.test;
          domain = segments.sublist(i + 1).join('-');
          break;
        }

        final devMatch = RegExp(r'^dev(\d*)$').firstMatch(seg);
        if (devMatch != null) {
          env    = OtmEnv.development;
          devNum = int.tryParse(devMatch.group(1) ?? '');
          domain = segments.sublist(i + 1).join('-');
          break;
        }
      }

      if (domain.isEmpty) domain = slug;

      String displayName;
      switch (env) {
        case OtmEnv.production:
          displayName = 'OTM Production';
          break;
        case OtmEnv.test:
          displayName = 'OTM Test';
          break;
        case OtmEnv.development:
          displayName = devNum != null ? 'OTM Development $devNum' : 'OTM Development';
          break;
      }

      return OtmInstance(
        url:         url,
        displayName: displayName,
        domain:      domain,
        env:         env,
        devNumber:   devNum,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Load all saved instances ─────────────────────────────────────────────

  Future<List<OtmInstance>> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyInstances);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((j) => OtmInstance.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Load the active instance ─────────────────────────────────────────────

  Future<OtmInstance?> loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    final url   = prefs.getString(_keyActive);
    if (url == null) return null;
    final saved = await loadSaved();
    try {
      return saved.firstWhere(
        (i) => i.url.toLowerCase() == url.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Save a new instance (or promote existing to top) ─────────────────────
  // Deduplicates by URL and trims to maxSaved.

  Future<void> saveInstance(OtmInstance inst) async {
    // Defence-in-depth: reject any non-HTTPS URL even if it somehow slipped
    // past parse(). Basic Auth credentials must never travel unencrypted.
    assert(inst.url.startsWith('https://'),
        'saveInstance: refusing to store a non-HTTPS URL: ${inst.url}');
    if (!inst.url.startsWith('https://')) {
      throw ArgumentError('Only HTTPS instance URLs may be saved: ${inst.url}');
    }

    final prefs   = await SharedPreferences.getInstance();
    final current = await loadSaved();
    current.removeWhere((i) => i == inst);
    current.insert(0, inst);
    await prefs.setString(
      _keyInstances,
      jsonEncode(current.take(maxSaved).map((i) => i.toJson()).toList()),
    );
  }

  // ── Set the active instance ──────────────────────────────────────────────

  Future<void> setActive(OtmInstance inst) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActive,                  inst.url);
    await prefs.setString(AppConstants.prefInstanceUrl, inst.url);
  }

  // ── Save + activate in one call ──────────────────────────────────────────

  Future<void> saveAndActivate(OtmInstance inst) async {
    await saveInstance(inst);
    await setActive(inst);
  }

  // ── Delete a saved instance ──────────────────────────────────────────────

  Future<void> delete(OtmInstance inst) async {
    final prefs   = await SharedPreferences.getInstance();
    final current = await loadSaved();
    current.removeWhere((i) => i == inst);
    await prefs.setString(
      _keyInstances,
      jsonEncode(current.map((i) => i.toJson()).toList()),
    );
  }
}
