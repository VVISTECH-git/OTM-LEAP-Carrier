import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/providers/locale_provider.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/features/shipments/screens/shipment_detail_screen.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:leapcarrier/features/shipments/screens/tendered_screen.dart';
import 'package:leapcarrier/features/shipments/screens/spot_bids_screen.dart';
import 'package:leapcarrier/features/shipments/screens/active_screen.dart';
import 'package:leapcarrier/features/invoicing/screens/invoicing_screen.dart';
import 'package:leapcarrier/features/auth/screens/login_screen.dart';
import 'package:leapcarrier/features/auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _servprovName = '';
  String _domain = '';

  bool _loading = true;
  String? _error;

  int _tenderedCount = 0;
  int _spotBidsCount = 0;
  int _activeCount   = 0;

  Timer? _refreshTimer;

  // ── Shipment search ────────────────────────────────────────────────────────
  final _searchCtrl      = TextEditingController();
  bool           _searching      = false;
  String?        _searchError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _fetchData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final creds = await OtmService.getSavedCredentials();
    setState(() {
      _servprovName = creds['servprovName'] ?? creds['servprovGid'] ?? '';
      _domain = creds['domain'] ?? '';
    });
  }

  Future<void> _fetchData({bool silent = false}) async {
    setState(() { _loading = !silent; _error = null; });
    try {
      final data = await OtmService.fetchHomeShipments();
      setState(() {
        _tenderedCount = (data['tendered'] as List).length;
        _spotBidsCount = (data['spotBids'] as List).length;
        _activeCount   = (data['active']   as List).length;
        _loading       = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Shipment search ────────────────────────────────────────────────────────
  Future<void> _searchShipment() async {
    final raw = _searchCtrl.text.trim();
    if (raw.isEmpty) return;
    FocusScope.of(context).unfocus();

    // Strip domain prefix if carrier typed it — bare XID is all we need.
    final xid = raw.contains('.') ? raw.split('.').last.toUpperCase() : raw.toUpperCase();

    setState(() { _searching = true; _searchError = null; });
    try {
      final detail    = await OtmService.searchShipmentByXid(xid);
      final shipment  = CarrierShipment.fromJson(detail);
      final shipmentGid = '${shipment.domainName}.${shipment.bareXid}';
      // Fetch remarks and tracking events in parallel
      final parallel  = await Future.wait([
        OtmService.fetchRemarks(shipmentGid),
        OtmService.fetchTrackingEvents(shipmentGid),
      ]);
      final remarks   = parallel[0];
      final rawEvents = parallel[1];
      final result    = shipment.copyWithDriverRemarks(
        driverPhone: _remarkText(remarks, AppConstants.remarkDriverPhone),
        driverName:  _remarkText(remarks, AppConstants.remarkDriverName),
        vehicleReg:  _remarkText(remarks, AppConstants.remarkVehicleReg),
        truckType:   _remarkText(remarks, AppConstants.remarkTruckType),
      );
      // Parse and dedup events
      final allEvents = rawEvents
          .map((j) => TrackingEventItem.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) {
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return b.eventDate!.compareTo(a.eventDate!);
        });
      final seen = <String>{};
      final events = allEvents
          .where((e) => seen.add(e.statusCodeGid))
          .toList()
        ..sort((a, b) {
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return b.eventDate!.compareTo(a.eventDate!);
        });
      if (!mounted) return;
      setState(() => _searching = false);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ShipmentDetailScreen(shipment: result, preloadedEvents: events)));
    } catch (e) {
      setState(() {
        _searchError = 'Shipment not found. Check the ID and try again.';
        _searching   = false;
      });
    }
  }

  String? _remarkText(List<dynamic> remarks, String qualGid) {
    for (final r in remarks) {
      if (r['remarkQualGid']?.toString() == qualGid) {
        final text = r['remarkText']?.toString() ?? '';
        return text.isNotEmpty ? text : null;
      }
    }
    return null;
  }

  void _clearSearch() {
    setState(() {
      _searchCtrl.clear();
      _searchError = null;
    });
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final t = context.read<LeapThemeProvider>().theme;
    HapticFeedback.lightImpact();
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sign Out', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w800, color: t.text)),
          const SizedBox(height: 6),
          Text('Are you sure you want to sign out?',
              style: TextStyle(fontSize: 13, color: t.textMuted)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: t.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancel', style: TextStyle(color: t.textMuted)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.danger, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
    if (confirm == true) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      }
    }
  }

  void _showSettings(BuildContext context) {
    final t = context.read<LeapThemeProvider>().theme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<LeapThemeProvider>()),
          ChangeNotifierProvider.value(value: context.read<LocaleProvider>()),
        ],
        child: _SettingsSheet(theme: t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.surface1,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(t),
          Expanded(child: _buildBody(t)),
        ]),
      ),
      bottomNavigationBar: _buildBottomNav(t),
    );
  }

  Widget _buildHeader(AppThemeData t) {
    return Container(
      color: t.navColor,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LEAP', style: TextStyle(
                  fontFamily: 'PlusJakartaSans', fontSize: 24,
                  fontWeight: FontWeight.w800, color: Colors.white,
                  letterSpacing: 8, height: 1.0)),
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 16, height: 1.5,
                    color: context.watch<LeapThemeProvider>().theme.accent),
                const SizedBox(width: 6),
                Text('CARRIER', style: TextStyle(
                    fontFamily: 'PlusJakartaSans', fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: context.watch<LeapThemeProvider>().theme.accent,
                    letterSpacing: 4)),
                const SizedBox(width: 6),
                Container(width: 16, height: 1.5,
                    color: context.watch<LeapThemeProvider>().theme.accent),
              ]),
              if (_servprovName.isNotEmpty || _domain.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(_servprovName.isNotEmpty ? _servprovName : _domain,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10, fontWeight: FontWeight.w500,
                        fontFamily: LeapPlatform.fontFamily)),
              ],
            ]),
          ),
          IconButton(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
          ),
        ]),
        const SizedBox(height: 14),
        if (!_loading)
          Row(children: [
            _statPill('Tendered', _tenderedCount, t.primary),
            const SizedBox(width: 8),
            _statPill('Spot Bids', _spotBidsCount, t.accent),
            const SizedBox(width: 8),
            _statPill('Active', _activeCount, t.success),
          ]),
      ]),
    );
  }

  Widget _statPill(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 10, color: color,
          fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily)),
      const SizedBox(width: 5),
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text('$count',
            style: const TextStyle(fontSize: 9, color: Colors.white,
                fontWeight: FontWeight.w800))),
      ),
    ]),
  );

  // ── Attention items — tenders expiring soon only ───────────────────────────
  Widget _buildBody(AppThemeData t) {
    if (_loading) return Center(child: CircularProgressIndicator(color: t.primary));
    if (_error != null) return _buildError(t);

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: t.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        children: [

          // ── Shipment search — assign driver for accepted-but-unnotified shipments
          _sectionLabel('FIND SHIPMENT', t),
          const SizedBox(height: 8),
          _buildSearchBar(t),
          if (_searching)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator(color: t.primary)),
            ),
          if (_searchError != null && !_searching)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: t.danger.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.danger.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: t.danger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_searchError!,
                      style: TextStyle(fontSize: 12, color: t.danger,
                          fontFamily: LeapPlatform.fontFamily))),
                ]),
              ),
            ),
          const SizedBox(height: 20),

          // ── Today at a glance ─────────────────────────────────────────
          _sectionLabel('TODAY AT A GLANCE', t),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCell(Icons.gavel_rounded,          'Pending Tenders', '$_tenderedCount', t.primary, t),
              _statCell(Icons.local_offer_rounded,    'Open Spot Bids',  '$_spotBidsCount', t.accent,  t),
              _statCell(Icons.local_shipping_rounded, 'In Transit',      '$_activeCount',   t.success, t),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeData t) => Container(
    decoration: BoxDecoration(
      color: t.surface2,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: t.border),
    ),
    child: Row(children: [
      const SizedBox(width: 12),
      Icon(Icons.search_rounded, size: 18, color: t.textMuted),
      const SizedBox(width: 8),
      Expanded(child: TextField(
        controller: _searchCtrl,
        style: TextStyle(fontSize: 13, color: t.text, fontFamily: LeapPlatform.fontFamily),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchShipment(),
        decoration: InputDecoration(
          hintText: 'Enter shipment ID (e.g. 80003)',
          hintStyle: TextStyle(fontSize: 13, color: t.textMuted,
              fontFamily: LeapPlatform.fontFamily),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      )),
      if (_searchCtrl.text.isNotEmpty)
        GestureDetector(
          onTap: _clearSearch,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.close_rounded, size: 16, color: t.textMuted),
          ),
        ),
      GestureDetector(
        onTap: _searchShipment,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: t.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Find', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(String text, AppThemeData t) => Text(text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: t.textMuted, letterSpacing: 0.5,
          fontFamily: LeapPlatform.fontFamily));

  Widget _statCell(IconData icon, String label, String value, Color color, AppThemeData t) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface2, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: color, fontFamily: LeapPlatform.fontFamily, height: 1.1)),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );

  Widget _buildError(AppThemeData t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.warning_amber_rounded, size: 48, color: t.warning),
        const SizedBox(height: 12),
        Text('Unable to load', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800, color: t.text,
            fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.textMuted,
                fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
      ]),
    ),
  );

  Widget _buildBottomNav(AppThemeData t) {
    const items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.gavel_rounded, 'Tendered'),
      _NavItem(Icons.local_offer_rounded, 'Spot Bids'),
      _NavItem(Icons.local_shipping_rounded, 'Active'),
      _NavItem(Icons.receipt_long_rounded, 'Invoicing'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: t.surface2,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == _tab;
            return Expanded(child: GestureDetector(
              onTap: () => _onTabTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.transparent,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(items[i].icon, size: 22,
                      color: active ? t.primary : t.textMuted),
                  const SizedBox(height: 3),
                  Text(items[i].label, style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: active ? t.primary : t.textMuted,
                      fontFamily: LeapPlatform.fontFamily)),
                ]),
              ),
            ));
          }),
        ),
      ),
    );
  }

  void _onTabTap(int i) {
    setState(() => _tab = i);
    if (i == 0) return;
    final screens = [
      null,
      const TenderedScreen(),
      const SpotBidsScreen(),
      const ActiveScreen(),
      const InvoicingScreen(),
    ];
    if (screens[i] != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screens[i]!))
          .then((_) => setState(() => _tab = 0));
    }
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─── Settings sheet ───────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  final AppThemeData theme;
  const _SettingsSheet({required this.theme});
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider  = context.watch<LeapThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final t = themeProvider.theme;

    return Container(
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: t.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _tab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _tab == 0 ? t.primary : t.surface1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _tab == 0 ? t.primary : t.border),
              ),
              child: Text('Theme', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: LeapPlatform.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: _tab == 0 ? Colors.white : t.textMuted)),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _tab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _tab == 1 ? t.primary : t.surface1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _tab == 1 ? t.primary : t.border),
              ),
              child: Text('Language', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: LeapPlatform.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: _tab == 1 ? Colors.white : t.textMuted)),
            ),
          )),
        ]),
        const SizedBox(height: 16),
        if (_tab == 0)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10,
              mainAxisSpacing: 10, childAspectRatio: 2.6,
            ),
            itemCount: LeapThemes.all.length,
            itemBuilder: (_, i) {
              final theme    = LeapThemes.all[i];
              final selected = themeProvider.theme.id == theme.id;
              return GestureDetector(
                onTap: () => themeProvider.setTheme(theme),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? theme.navColor.withValues(alpha: 0.08) : t.surface1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? theme.primary : t.border,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Row(mainAxisSize: MainAxisSize.min,
                        children: theme.swatchColors.map((c) => Container(
                          width: 13, height: 13,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(color: c,
                              borderRadius: BorderRadius.circular(3)),
                        )).toList()),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(theme.label, style: TextStyle(
                            fontFamily: LeapPlatform.fontFamily, fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? theme.primary : t.text),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(theme.description, style: TextStyle(
                            fontFamily: LeapPlatform.fontFamily, fontSize: 9,
                            color: t.textMuted, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    )),
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
            },
          ),
        if (_tab == 1)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10,
              mainAxisSpacing: 10, childAspectRatio: 3.2,
            ),
            itemCount: LocaleProvider.languages.length,
            itemBuilder: (_, i) {
              final lang     = LocaleProvider.languages[i];
              final code     = lang['code']!;
              final selected = localeProvider.locale.languageCode == code;
              return GestureDetector(
                onTap: () => localeProvider.setLocale(Locale(code)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? t.primary.withValues(alpha: 0.08) : t.surface1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected ? t.primary : t.border,
                        width: selected ? 2 : 1.5),
                  ),
                  child: Row(children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(lang['name']!, style: TextStyle(
                        fontFamily: LeapPlatform.fontFamily, fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? t.primary : t.text),
                        overflow: TextOverflow.ellipsis)),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: t.primary, size: 16),
                  ]),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            child: const Text('Done', style: TextStyle(
                fontFamily: LeapPlatform.fontFamily,
                fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
