import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:leapcarrier/features/shipments/screens/shipment_detail_screen.dart';
import 'package:intl/intl.dart';

class ActiveScreen extends StatefulWidget {
  final CarrierShipment? initialShipment;
  const ActiveScreen({super.key, this.initialShipment});
  @override
  State<ActiveScreen> createState() => _ActiveScreenState();
}

class _ActiveScreenState extends State<ActiveScreen> {
  List<CarrierShipment> _shipments = [];
  List<CarrierShipment> _filtered  = [];
  bool    _loading = true;
  String? _error;
  String? _loadingPill;   // bareXid of shipment whose pill is fetching
  String? _loadingDetail; // bareXid of shipment whose detail is fetching
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _search.addListener(_filter);
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final shipments = await OtmService.fetchActiveShipments();
      setState(() { _shipments = shipments; _filtered = shipments; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _shipments : _shipments.where((s) =>
        s.displayId.toLowerCase().contains(q) ||
        s.source.displayName.toLowerCase().contains(q) ||
        s.dest.displayName.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.surface1,
      appBar: AppBar(
        backgroundColor: t.navColor,
        foregroundColor: Colors.white,
        title: const Text('Active Shipments', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 17,
            fontFamily: LeapPlatform.fontFamily)),
      ),
      body: Column(children: [
        // Search bar — same as tendered/spot bids
        Container(
          color: t.navColor,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _search,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontFamily: LeapPlatform.fontFamily),
              decoration: InputDecoration(
                hintText: 'Search shipments...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13,
                    fontFamily: LeapPlatform.fontFamily),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 18),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.12),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody(t)),
      ]),
    );
  }

  Widget _buildBody(AppThemeData t) {
    if (_loading) { return Center(child: CircularProgressIndicator(color: t.primary)); }
    if (_error != null) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('⚠️ $_error', textAlign: TextAlign.center,
          style: TextStyle(color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
    ])); }
    if (_filtered.isEmpty) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.local_shipping_outlined, size: 48, color: t.textMuted),
      const SizedBox(height: 8),
      Text('No active shipments', style: TextStyle(color: t.textMuted,
          fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily)),
    ])); }
    return RefreshIndicator(
      onRefresh: _fetch, color: t.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(10), itemCount: _filtered.length,
        itemBuilder: (_, i) => _card(_filtered[i], t),
      ),
    );
  }

  Widget _card(CarrierShipment s, AppThemeData t) {
    final endStr = s.endTime != null
        ? DateFormat('dd MMM').format(s.endTime!.toLocal()) : null;
    final doneStops = s.stops.where((st) => st.isCompleted).length;
    final totalStops = s.stops.isNotEmpty ? s.stops.length : s.numStops;

    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: t.navColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(children: [
              // Shipment ID + route summary
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('#${s.displayId}', style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w800, color: t.primary,
                        fontFamily: LeapPlatform.fontFamily)),
                  ),
                  if (endStr != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.event_rounded, size: 10, color: t.textMuted),
                    const SizedBox(width: 3),
                    Text('Due $endStr', style: TextStyle(fontSize: 10,
                        color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
                  ],
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.radio_button_checked, size: 9, color: t.success),
                  const SizedBox(width: 4),
                  Flexible(child: Text(s.source.displayName, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: t.text,
                      fontFamily: LeapPlatform.fontFamily), overflow: TextOverflow.ellipsis)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(Icons.east_rounded, size: 11, color: t.textMuted),
                  ),
                  Icon(Icons.location_on_rounded, size: 9, color: t.danger),
                  const SizedBox(width: 4),
                  Flexible(child: Text(s.dest.displayName, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: t.text,
                      fontFamily: LeapPlatform.fontFamily), overflow: TextOverflow.ellipsis)),
                ]),
              ])),
              // IN PROGRESS badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: t.success.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 5, height: 5,
                      decoration: BoxDecoration(color: t.success, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('ACTIVE', style: TextStyle(fontSize: 8,
                      color: t.success, fontWeight: FontWeight.w800,
                      letterSpacing: 0.3, fontFamily: LeapPlatform.fontFamily)),
                ]),
              ),
            ]),
          ),

          // ── Four status pills ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(children: [

              // Driver pill — tappable to assign or update driver
              GestureDetector(
                onTap: _loadingPill == s.bareXid
                    ? null
                    : () => _showAssignDriverSheet(s, t),
                child: _loadingPill == s.bareXid
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: t.surface3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.border),
                        ),
                        child: SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: t.primary),
                        ),
                      )
                    : _statusPill(
                        icon: s.hasDriverAssigned ? Icons.person_rounded : Icons.person_add_rounded,
                        label: s.hasDriverAssigned
                            ? (s.driverName ?? s.driverPhone ?? 'Assigned')
                            : 'No Driver',
                        color: s.hasDriverAssigned ? t.primary : t.warning,
                        filled: s.hasDriverAssigned,
                        t: t,
                      ),
              ),
              const SizedBox(width: 6),

              // Stops pill
              _statusPill(
                icon: Icons.route_rounded,
                label: totalStops > 0
                    ? '$doneStops/$totalStops Stops'
                    : '${s.numStops} Stops',
                color: doneStops > 0 && doneStops == totalStops
                    ? t.success : t.primary,
                filled: false,
                t: t,
              ),
              const SizedBox(width: 6),

              // Weight pill (if available)
              if (s.totalWeight != null) ...[
                _statusPill(
                  icon: Icons.scale_rounded,
                  label: s.totalWeight!.display,
                  color: t.textMuted,
                  filled: false,
                  t: t,
                ),
                const SizedBox(width: 6),
              ],

            ]),
          ),

          // ── View Details CTA ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GestureDetector(
              onTap: _loadingDetail == s.bareXid ? null : () async {
                final shipmentGid = '${s.domainName}.${s.bareXid}';
                setState(() => _loadingDetail = s.bareXid);
                try {
                  // Fetch detail + tracking events in parallel — navigate
                  // only when everything is ready so the screen opens fully loaded
                  final results = await Future.wait([
                    OtmService.fetchShipmentDetail(shipmentGid),
                    OtmService.fetchTrackingEvents(shipmentGid),
                  ]);
                  final detail = results[0] as Map<String, dynamic>;
                  final rawEvents = results[1] as List<dynamic>;
                  final full = CarrierShipment.fromJson(detail).copyWithDriverRemarks(
                    driverPhone: s.driverPhone,
                    driverName:  s.driverName,
                    vehicleReg:  s.vehicleReg,
                    truckType:   s.truckType,
                  );
                  // Parse and dedup events by statusCodeGid — keep latest per code
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
                  setState(() => _loadingDetail = null);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ShipmentDetailScreen(
                      shipment: full,
                      preloadedEvents: events,
                    ),
                  ));
                } catch (_) {
                  if (!mounted) return;
                  setState(() => _loadingDetail = null);
                  // Fallback — navigate with what we have
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ShipmentDetailScreen(shipment: s),
                  ));
                }
              },
              child: Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(
                      color: t.primary.withValues(alpha: 0.25),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Center(child: _loadingDetail == s.bareXid
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_shipping_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text('View Details', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                    ]),
                ),
              ),
            ),
          ),
        ]),
    );
  }

  // ── Assign / Update Driver sheet ─────────────────────────────────────────
  // Flow: fetch remarks first → open sheet with data ready → save with
  // pre-fetched remarks (skip double GET) and toClear list for blanked fields.
  Future<void> _showAssignDriverSheet(CarrierShipment s, AppThemeData t) async {
    final shipmentGid = '${s.domainName}.${s.bareXid}';

    // ── Step 1: show loading on pill, fetch remarks fresh from OTM ──────────
    setState(() => _loadingPill = s.bareXid);
    List<dynamic> fetchedRemarks = [];
    try {
      fetchedRemarks = await OtmService.fetchRemarks(shipmentGid);
    } catch (_) {
      // Non-fatal — sheet opens with empty fields
    }
    if (!mounted) return;
    setState(() => _loadingPill = null);

    // ── Step 2: pre-fill controllers from fetched remarks ───────────────────
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    final vehCtrl   = TextEditingController();
    String? selTruck;

    // originalValues tracks what was pre-filled so we can detect cleared fields
    final originalValues = <String, String>{};

    for (final r in fetchedRemarks) {
      final qual = r['remarkQualGid']?.toString() ?? '';
      final text = r['remarkText']?.toString()    ?? '';
      if (text.isEmpty) continue;
      if (qual == AppConstants.remarkDriverName)  { nameCtrl.text  = text; originalValues[qual] = text; }
      if (qual == AppConstants.remarkDriverPhone) { phoneCtrl.text = text; originalValues[qual] = text; }
      if (qual == AppConstants.remarkVehicleReg)  { vehCtrl.text   = text; originalValues[qual] = text; }
      if (qual == AppConstants.remarkTruckType && AppConstants.truckTypes.contains(text)) {
        selTruck = text;
        originalValues[qual] = text;
      }
    }

    final hasAnyDriver = originalValues.containsKey(AppConstants.remarkDriverPhone);
    bool submitting = false;

    // ── Step 3: open sheet — data already ready, no spinner needed ──────────
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Handle
                Center(child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)),
                )),

                // Title
                Row(children: [
                  Icon(Icons.person_rounded, size: 18, color: t.success),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(hasAnyDriver ? 'Update Driver' : 'Assign Driver',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                            color: t.text, fontFamily: LeapPlatform.fontFamily)),
                    Text('#${s.displayId} · ${s.source.displayName} → ${s.dest.displayName}',
                        style: TextStyle(fontSize: 11, color: t.textMuted,
                            fontFamily: LeapPlatform.fontFamily)),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Phone — critical field, full number with label
                _driverField(phoneCtrl, 'Driver Phone (with country code)',
                    Icons.phone_rounded, t,
                    hint: 'e.g. +91 9849012345', keyboardType: TextInputType.phone),
                const SizedBox(height: 8),

                // Driver Name
                _driverField(nameCtrl, 'Driver Name (optional)',
                    Icons.person_outline_rounded, t,
                    optional: true, hint: 'e.g. Rajesh Kumar'),
                const SizedBox(height: 8),

                // Vehicle Registration
                _driverField(vehCtrl, 'Vehicle Registration (optional)',
                    Icons.directions_car_rounded, t,
                    optional: true, hint: 'e.g. KA 01 AB 1234'),
                const SizedBox(height: 8),

                // Truck Type dropdown — includes a "Clear" option when already set
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: t.surface2, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.border, width: 1.5)),
                  child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                    value: selTruck, isExpanded: true, dropdownColor: t.surface2,
                    hint: Text('Select Truck Type (optional)', style: TextStyle(
                        fontSize: 13, color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
                    style: TextStyle(fontSize: 13, color: t.text,
                        fontFamily: LeapPlatform.fontFamily),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: t.textMuted),
                    items: [
                      // Clear option — only shown when a truck type was previously saved
                      if (originalValues.containsKey(AppConstants.remarkTruckType))
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text('— Clear truck type —', style: TextStyle(
                              fontSize: 13, color: t.textMuted,
                              fontStyle: FontStyle.italic,
                              fontFamily: LeapPlatform.fontFamily)),
                        ),
                      ...AppConstants.truckTypes.map((tt) => DropdownMenuItem(value: tt,
                        child: Text(tt, style: TextStyle(
                            fontFamily: LeapPlatform.fontFamily, color: t.text)))),
                    ],
                    onChanged: submitting ? null : (v) => setModal(() => selTruck = v == '' ? null : v),
                  )),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: submitting ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: submitting ? null : () async {
                      // Non-empty fields to save
                      final fields = <String, String>{
                        if (phoneCtrl.text.trim().isNotEmpty)
                          AppConstants.remarkDriverPhone: phoneCtrl.text.trim(),
                        if (nameCtrl.text.trim().isNotEmpty)
                          AppConstants.remarkDriverName:  nameCtrl.text.trim(),
                        if (vehCtrl.text.trim().isNotEmpty)
                          AppConstants.remarkVehicleReg:  vehCtrl.text.trim(),
                        if (selTruck != null && selTruck!.isNotEmpty)
                          AppConstants.remarkTruckType:   selTruck!,
                      };

                      // Qualifiers that were pre-filled but are now blank → clear in OTM
                      final toClear = <String>[
                        for (final qual in originalValues.keys)
                          if (!fields.containsKey(qual)) qual,
                      ];

                      if (fields.isEmpty && toClear.isEmpty) {
                        Navigator.pop(ctx);
                        return;
                      }

                      setModal(() => submitting = true);
                      try {
                        await OtmService.saveDriverRemarks(
                          shipmentGid:     shipmentGid,
                          fields:          fields,
                          domainName:      s.domainName,
                          toClear:         toClear,
                          existingRemarks: fetchedRemarks,
                        );
                        HapticFeedback.mediumImpact();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          final wasAssigned = hasAnyDriver;
                          final nowAssigned = fields.containsKey(AppConstants.remarkDriverPhone);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              wasAssigned
                                  ? 'Driver details updated! ✅'
                                  : nowAssigned
                                      ? 'Driver assigned — SMS will be sent 🎉'
                                      : 'Details saved.',
                              style: const TextStyle(fontFamily: LeapPlatform.fontFamily),
                            ),
                            backgroundColor: t.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                          // Update the specific shipment in the list in place
                          // so the driver pill reflects the new data immediately
                          // without requiring a full list reload
                          final updated = s.copyWithDriverRemarks(
                            driverPhone: fields[AppConstants.remarkDriverPhone]
                                ?? (toClear.contains(AppConstants.remarkDriverPhone) ? null : s.driverPhone),
                            driverName:  fields[AppConstants.remarkDriverName]
                                ?? (toClear.contains(AppConstants.remarkDriverName)  ? null : s.driverName),
                            vehicleReg:  fields[AppConstants.remarkVehicleReg]
                                ?? (toClear.contains(AppConstants.remarkVehicleReg)  ? null : s.vehicleReg),
                            truckType:   fields[AppConstants.remarkTruckType]
                                ?? (toClear.contains(AppConstants.remarkTruckType)   ? null : s.truckType),
                          );
                          setState(() {
                            final idx = _shipments.indexWhere((x) => x.bareXid == s.bareXid);
                            if (idx != -1) {
                              _shipments[idx] = updated;
                              _filtered = _shipments
                                  .where((x) => _filtered.any((f) => f.bareXid == x.bareXid))
                                  .toList();
                            }
                          });
                        }
                      } catch (e) {
                        setModal(() => submitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Failed: ${e.toString().replaceAll('Exception: ', '')}',
                              style: const TextStyle(fontFamily: LeapPlatform.fontFamily),
                            ),
                            backgroundColor: t.danger,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: t.success),
                    child: submitting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : Text(
                            hasAnyDriver ? 'Update Driver' : 'Confirm Assign',
                            style: const TextStyle(
                                color: Colors.white, fontFamily: LeapPlatform.fontFamily),
                          ),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _driverField(TextEditingController ctrl, String label, IconData icon,
      AppThemeData t, {bool optional = false, String? hint, TextInputType? keyboardType}) =>
    Container(
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.border, width: 1.5)),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13, color: t.text, fontFamily: LeapPlatform.fontFamily),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: TextStyle(fontSize: 12, color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
          hintStyle:  TextStyle(fontSize: 11, color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
          prefixIcon: Icon(icon, size: 18, color: optional ? t.textMuted : t.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
      ),
    );

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required AppThemeData t,
  }) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : t.surface3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? color.withValues(alpha: 0.3) : t.border,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: filled ? color : t.textSecondary,
                fontFamily: LeapPlatform.fontFamily),
            overflow: TextOverflow.ellipsis),
      ]),
    );

}