import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LEAP Design System — Unified Theme File
// Version: 2.0.0  (9-theme switcher edition)
//
// Drop this single file into each app at:
//   lib/core/theme/leap_theme.dart
//
// Each app picks its DEFAULT theme (shown on first launch):
//   Driver   → LeapThemes.brick   (brick red  — existing default, unchanged)
//   DockMate → LeapThemes.navy    (navy blue  — professional dock ops)
//   Carrier  → LeapThemes.navy    (navy blue  — enterprise service provider)
//
// All 9 themes are available to users in all 3 apps via LeapThemePicker.
//
// Access tokens anywhere in a widget:
//   context.read<LeapThemeProvider>().theme.primary
//   context.watch<LeapThemeProvider>().theme.navColor
//
// Show the picker:
//   LeapThemePicker.show(context)
// ═══════════════════════════════════════════════════════════════════════════════


// ─── Platform-level constants (never change per app or per theme) ─────────────

class LeapPlatform {
  LeapPlatform._();

  static const Color oracleOrange = Color(0xFFF97316);  // Oracle OTM badge dot
  static const Color success      = Color(0xFF10A868);
  static const Color warning      = Color(0xFFF97316);
  static const Color danger       = Color(0xFFE01E35);
  static const Color info         = Color(0xFF0EA5E9);
  static const String fontFamily  = 'PlusJakartaSans';
}


// ─── AppThemeData — one object per theme ──────────────────────────────────────
// Semantic token naming: purpose-based, not color-based.

class AppThemeData {
  final String id;
  final String label;
  final String description;

  // Header / nav gradient stops
  final Color navColor;
  final Color navColor2;

  // Trip / progress bar gradient (Driver-specific, harmless elsewhere)
  final Color tripGrad1;
  final Color tripGrad2;

  // Brand / action
  final Color primary;
  final Color primary2;
  final Color accent;

  // CTA button — if set, button uses LinearGradient instead of flat primary
  final List<Color>? ctaGradient;

  // Semantic status (same values across all themes — overrides intentionally)
  Color get success       => LeapPlatform.success;
  Color get warning       => LeapPlatform.warning;
  Color get danger        => LeapPlatform.danger;
  Color get info          => LeapPlatform.info;

  // 3-level surface hierarchy
  final Color surface1;       // page / scaffold background
  final Color surface2;       // cards, sheets
  final Color surface3;       // hover states, input fills

  // Text
  final Color text;
  final Color textMuted;
  final Color textSecondary;

  // Borders & focus
  final Color border;
  final Color focusRing;

  // Secondary / done-button color
  final Color secondary;

  // Active node on timeline / progress
  final Color activeNode;
  final Color activeNodeGlow;

  // 4 swatches shown in the picker card
  final List<Color> swatchColors;

  const AppThemeData({
    required this.id,
    required this.label,
    required this.description,
    required this.navColor,
    required this.navColor2,
    required this.tripGrad1,
    required this.tripGrad2,
    required this.primary,
    required this.primary2,
    required this.accent,
    this.ctaGradient,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.textMuted,
    required this.textSecondary,
    required this.border,
    required this.focusRing,
    required this.secondary,
    required this.activeNode,
    required this.activeNodeGlow,
    required this.swatchColors,
  });

  ColorScheme toColorScheme() => ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    secondary: accent,
    surface: surface1,
    error: danger,
  );

  ThemeData toMaterialTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: LeapPlatform.fontFamily,
    colorScheme: toColorScheme(),
    scaffoldBackgroundColor: surface1,
    textTheme: TextTheme(
      displayLarge:  TextStyle(fontFamily: LeapPlatform.fontFamily, fontSize: 32, fontWeight: FontWeight.w800, color: text),
      titleLarge:    TextStyle(fontFamily: LeapPlatform.fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: text),
      bodyLarge:     TextStyle(fontFamily: LeapPlatform.fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: text),
      bodyMedium:    TextStyle(fontFamily: LeapPlatform.fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
      labelLarge:    TextStyle(fontFamily: LeapPlatform.fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: text),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: navColor,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: const TextStyle(
        fontFamily: LeapPlatform.fontFamily,
        fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: LeapPlatform.fontFamily, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusRing, width: 2)),
      labelStyle: TextStyle(fontFamily: LeapPlatform.fontFamily, color: textMuted, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontFamily: LeapPlatform.fontFamily, fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
    ),
  );
}


// ─── All 9 LEAP themes ────────────────────────────────────────────────────────

class LeapThemes {
  LeapThemes._();

  static const navy = AppThemeData(
    id: 'navy', label: 'Navy Blue', description: 'Enterprise · Professional',
    navColor: Color(0xFF0F1F3D), navColor2: Color(0xFF162952),
    tripGrad1: Color(0xFF162952), tripGrad2: Color(0xFF1847C2),
    primary: Color(0xFF1847C2), primary2: Color(0xFF2D5BE3), accent: Color(0xFFE8720A),
    surface1: Color(0xFFF4F6FB), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFEDF1F7),
    text: Color(0xFF0F1F3D), textMuted: Color(0xFF7A8499), textSecondary: Color(0xFF4B5675),
    border: Color(0xFFD4DCE9), focusRing: Color(0xFF2D5BE3),
    secondary: Color(0xFF0F1F3D), activeNode: Color(0xFF1847C2), activeNodeGlow: Color(0x331847C2),
    swatchColors: [Color(0xFF0F1F3D), Color(0xFF1847C2), Color(0xFFE8720A), Color(0xFF10A868)],
  );

  static const brick = AppThemeData(
    id: 'brick', label: 'Brick Red', description: 'Logistics · High energy',
    navColor: Color(0xFF7D1C0E), navColor2: Color(0xFF4E0F07),
    tripGrad1: Color(0xFF5C1308), tripGrad2: Color(0xFF7A1D12),
    primary: Color(0xFFC53B2C), primary2: Color(0xFFE24A39), accent: Color(0xFFF97316),
    ctaGradient: [Color(0xFFC92A1B), Color(0xFFE24A39)],
    surface1: Color(0xFFFAEAE7), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFF5DDD8),
    text: Color(0xFF3D0D06), textMuted: Color(0xFF7A4B43), textSecondary: Color(0xFF5C3028),
    border: Color(0xFFE2C2BC), focusRing: Color(0xFFE24A39),
    secondary: Color(0xFF7D1C0E), activeNode: Color(0xFFF97316), activeNodeGlow: Color(0x47F97316),
    swatchColors: [Color(0xFF7D1C0E), Color(0xFFC53B2C), Color(0xFFF97316), Color(0xFF10A868)],
  );

  static const forest = AppThemeData(
    id: 'forest', label: 'Forest Green', description: 'Operations · Calm',
    navColor: Color(0xFF0D4F3C), navColor2: Color(0xFF0A3D2E),
    tripGrad1: Color(0xFF0A3D2E), tripGrad2: Color(0xFF0D4F3C),
    primary: Color(0xFF0D7A4E), primary2: Color(0xFF10A868), accent: Color(0xFF2563EB),
    surface1: Color(0xFFF0FDF4), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFDCFCE7),
    text: Color(0xFF052E1A), textMuted: Color(0xFF4D8C6F), textSecondary: Color(0xFF1E5C41),
    border: Color(0xFFBBE8D4), focusRing: Color(0xFF2563EB),
    secondary: Color(0xFF0D4F3C), activeNode: Color(0xFF2563EB), activeNodeGlow: Color(0x332563EB),
    swatchColors: [Color(0xFF0D4F3C), Color(0xFF0D7A4E), Color(0xFFD97706), Color(0xFF2563EB)],
  );

  static const midnight = AppThemeData(
    id: 'midnight', label: 'Midnight Indigo', description: 'Tech · Premium',
    navColor: Color(0xFF1E1B4B), navColor2: Color(0xFF16134A),
    tripGrad1: Color(0xFF16134A), tripGrad2: Color(0xFF3730A3),
    primary: Color(0xFF4338CA), primary2: Color(0xFF6366F1), accent: Color(0xFFF59E0B),
    surface1: Color(0xFFEEF2FF), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFE0E7FF),
    text: Color(0xFF1E1B4B), textMuted: Color(0xFF6D68D8), textSecondary: Color(0xFF3730A3),
    border: Color(0xFFC7D2FE), focusRing: Color(0xFF6366F1),
    secondary: Color(0xFF1E1B4B), activeNode: Color(0xFFF59E0B), activeNodeGlow: Color(0x40F59E0B),
    swatchColors: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFFF59E0B), Color(0xFF10B981)],
  );

  static const slate = AppThemeData(
    id: 'slate', label: 'Slate & Steel', description: 'Corporate · Minimal',
    navColor: Color(0xFF1E293B), navColor2: Color(0xFF0F172A),
    tripGrad1: Color(0xFF0F172A), tripGrad2: Color(0xFF1E3A5F),
    primary: Color(0xFF2563EB), primary2: Color(0xFF3B82F6), accent: Color(0xFFF59E0B),
    surface1: Color(0xFFF8FAFC), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFF1F5F9),
    text: Color(0xFF0F172A), textMuted: Color(0xFF7A8DA3), textSecondary: Color(0xFF475569),
    border: Color(0xFFCBD5E1), focusRing: Color(0xFF3B82F6),
    secondary: Color(0xFF1E293B), activeNode: Color(0xFF2563EB), activeNodeGlow: Color(0x332563EB),
    swatchColors: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF3B82F6), Color(0xFF22C55E)],
  );

  static const teal = AppThemeData(
    id: 'teal', label: 'Teal Aqua', description: 'SaaS · Modern',
    navColor: Color(0xFF0F4C5C), navColor2: Color(0xFF093848),
    tripGrad1: Color(0xFF093848), tripGrad2: Color(0xFF0D6B7A),
    primary: Color(0xFF0D9488), primary2: Color(0xFF14B8A6), accent: Color(0xFFF59E0B),
    surface1: Color(0xFFF0FDFA), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFCCFBF1),
    text: Color(0xFF042F2E), textMuted: Color(0xFF3D9E95), textSecondary: Color(0xFF0F766E),
    border: Color(0xFF9DE0D8), focusRing: Color(0xFF14B8A6),
    secondary: Color(0xFF0F4C5C), activeNode: Color(0xFFF59E0B), activeNodeGlow: Color(0x47F59E0B),
    swatchColors: [Color(0xFF0F4C5C), Color(0xFF14B8A6), Color(0xFF0EA5E9), Color(0xFF10A868)],
  );

  static const indigo = AppThemeData(
    id: 'indigo', label: 'Indigo Purple', description: 'Product · Design',
    navColor: Color(0xFF312E81), navColor2: Color(0xFF231E6B),
    tripGrad1: Color(0xFF231E6B), tripGrad2: Color(0xFF3730A3),
    primary: Color(0xFF4F46E5), primary2: Color(0xFF6366F1), accent: Color(0xFF8B5CF6),
    surface1: Color(0xFFEEF2FF), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFE0E7FF),
    text: Color(0xFF1E1B4B), textMuted: Color(0xFF6D7AC7), textSecondary: Color(0xFF3730A3),
    border: Color(0xFFC7D2FE), focusRing: Color(0xFF6366F1),
    secondary: Color(0xFF312E81), activeNode: Color(0xFF8B5CF6), activeNodeGlow: Color(0x408B5CF6),
    swatchColors: [Color(0xFF312E81), Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF10B981)],
  );

  static const amber = AppThemeData(
    id: 'amber', label: 'Amber Gold', description: 'Outdoor · High visibility',
    navColor: Color(0xFF78350F), navColor2: Color(0xFF5C2809),
    tripGrad1: Color(0xFF5C2809), tripGrad2: Color(0xFF92400E),
    primary: Color(0xFF1D4ED8), primary2: Color(0xFF2563EB), accent: Color(0xFFF59E0B),
    surface1: Color(0xFFFFFBEB), surface2: Color(0xFFFFFFFF), surface3: Color(0xFFFEF3C7),
    text: Color(0xFF3C1A05), textMuted: Color(0xFF92540C), textSecondary: Color(0xFF78350F),
    border: Color(0xFFFCD99A), focusRing: Color(0xFF2563EB),
    secondary: Color(0xFF78350F), activeNode: Color(0xFFF59E0B), activeNodeGlow: Color(0x4CF59E0B),
    swatchColors: [Color(0xFF78350F), Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFF10A868)],
  );

  static const dark = AppThemeData(
    id: 'dark', label: 'Dark Mode', description: 'Night · Battery saver',
    navColor: Color(0xFF0F172A), navColor2: Color(0xFF020617),
    tripGrad1: Color(0xFF020617), tripGrad2: Color(0xFF1E293B),
    primary: Color(0xFF3B82F6), primary2: Color(0xFF60A5FA), accent: Color(0xFFF59E0B),
    surface1: Color(0xFF0F172A), surface2: Color(0xFF1E293B), surface3: Color(0xFF2D3748),
    text: Color(0xFFF1F5F9), textMuted: Color(0xFF9CA3AF), textSecondary: Color(0xFFCBD5E1),
    border: Color(0xFF2D3748), focusRing: Color(0xFF60A5FA),
    secondary: Color(0xFF0F172A), activeNode: Color(0xFF60A5FA), activeNodeGlow: Color(0x4C60A5FA),
    swatchColors: [Color(0xFF0F172A), Color(0xFF1F2937), Color(0xFF3B82F6), Color(0xFF10B981)],
  );

  // All themes in display order
  static const List<AppThemeData> all = [
    navy, brick, forest, midnight, slate, teal, indigo, amber, dark,
  ];

  static AppThemeData byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => navy);
}


// ─── LeapThemeProvider ────────────────────────────────────────────────────────
// Drop-in for all 3 apps. Each app passes its own defaultTheme.
//
// Setup in main.dart:
//   final themeProvider = LeapThemeProvider(defaultTheme: LeapThemes.navy);
//   unawaited(themeProvider.loadSavedTheme());
//   runApp(ChangeNotifierProvider.value(value: themeProvider, child: MyApp()));

class LeapThemeProvider extends ChangeNotifier {
  final AppThemeData defaultTheme;
  final String _prefKey;
  late AppThemeData _theme;

  LeapThemeProvider({
    required this.defaultTheme,
    String? prefsKey,
  })  : _prefKey = prefsKey ?? 'leap_selected_theme',
        _theme = defaultTheme;

  AppThemeData get theme => _theme;

  Future<void> loadSavedTheme() async {
    final prefs   = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefKey);
    if (savedId != null) {
      _theme = LeapThemes.byId(savedId);
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeData theme) async {
    if (_theme.id == theme.id) return;
    _theme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, theme.id);
  }

  ThemeData toMaterialTheme() => _theme.toMaterialTheme();
}


// ─── LeapThemePicker ─────────────────────────────────────────────────────────
// Modal bottom sheet showing all 9 themes as swatchable cards.
// Call from any screen: LeapThemePicker.show(context)
//
// Example — add palette icon button to any AppBar:
//   IconButton(
//     icon: const Icon(Icons.palette_outlined),
//     onPressed: () => LeapThemePicker.show(context),
//   )

class LeapThemePicker {
  LeapThemePicker._();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<LeapThemeProvider>(),
        child: const _LeapThemePickerSheet(),
      ),
    );
  }
}

class _LeapThemePickerSheet extends StatefulWidget {
  const _LeapThemePickerSheet();
  @override
  State<_LeapThemePickerSheet> createState() => _LeapThemePickerSheetState();
}

class _LeapThemePickerSheetState extends State<_LeapThemePickerSheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = context.read<LeapThemeProvider>().theme.id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LeapThemeProvider>();
    final isDark   = provider.theme.id == 'dark';
    final sheetBg  = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleCol = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1F3D);
    final subCol   = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF8892A4);
    final borderCol= isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16, 16, 16,
        MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: borderCol, borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Title row
        Row(children: [
          Text('Choose Theme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: titleCol, fontFamily: LeapPlatform.fontFamily)),
          const Spacer(),
          Text('${LeapThemes.all.length} themes',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: subCol, fontFamily: LeapPlatform.fontFamily)),
        ]),
        const SizedBox(height: 4),
        Text('Changes apply instantly across the app',
          style: TextStyle(fontSize: 12, color: subCol, fontWeight: FontWeight.w500,
              fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 16),

        // 2-column grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemCount: LeapThemes.all.length,
          itemBuilder: (_, i) {
            final t        = LeapThemes.all[i];
            final selected = _selectedId == t.id;
            return _SwatchCard(
              theme: t, selected: selected, isDark: isDark,
              onTap: () async {
                setState(() => _selectedId = t.id);
                await provider.setTheme(t);
              },
            );
          },
        ),
        const SizedBox(height: 16),

        // Done button
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              elevation: 0,
            ),
            child: const Text('Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  fontFamily: LeapPlatform.fontFamily)),
          ),
        ),
      ]),
    );
  }
}

class _SwatchCard extends StatelessWidget {
  final AppThemeData theme;
  final bool         selected;
  final bool         isDark;
  final VoidCallback onTap;

  const _SwatchCard({
    required this.theme,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg   = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final labelCol = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F1F3D);
    final descCol  = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF8892A4);
    final borderCol= isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.navColor.withValues(alpha: 0.08) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.primary : borderCol,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          // 4 swatches
          Row(
            mainAxisSize: MainAxisSize.min,
            children: theme.swatchColors.map((c) => Container(
              width: 13, height: 13,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(3),
              ),
            )).toList(),
          ),
          const SizedBox(width: 8),
          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(theme.label,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: selected ? theme.primary : labelCol,
                    fontFamily: LeapPlatform.fontFamily,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(theme.description,
                  style: TextStyle(
                    fontSize: 9, color: descCol, fontWeight: FontWeight.w500,
                    fontFamily: LeapPlatform.fontFamily,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Selected checkmark
          if (selected)
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                  color: theme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
        ]),
      ),
    );
  }
}


// ─── Status pill helper ───────────────────────────────────────────────────────

class LeapStatusStyle {
  final Color bg;
  final Color fg;
  final Color dot;
  const LeapStatusStyle(this.bg, this.fg, this.dot);
}

const Map<String, LeapStatusStyle> leapShipmentStatusStyles = {
  'new':       LeapStatusStyle(Color(0x336D28D9), Color(0xFF6D28D9), Color(0xFF6D28D9)),
  'review':    LeapStatusStyle(Color(0x33E8720A), Color(0xFFC45E00), Color(0xFFC45E00)),
  'approved':  LeapStatusStyle(Color(0x331847C2), Color(0xFF1847C2), Color(0xFF1847C2)),
  'tendered':  LeapStatusStyle(Color(0x331847C2), Color(0xFF1847C2), Color(0xFF1847C2)),
  'active':    LeapStatusStyle(Color(0x3310A868), Color(0xFF0D7A4E), Color(0xFF0D7A4E)),
  'completed': LeapStatusStyle(Color(0x3310A868), Color(0xFF0D7A4E), Color(0xFF0D7A4E)),
  'invoiced':  LeapStatusStyle(Color(0x330891B2), Color(0xFF0891B2), Color(0xFF0891B2)),
  'paid':      LeapStatusStyle(Color(0x4010A868), Color(0xFF0D7A4E), Color(0xFF0D7A4E)),
  'cancelled': LeapStatusStyle(Color(0x33E01E35), Color(0xFFE01E35), Color(0xFFE01E35)),
};