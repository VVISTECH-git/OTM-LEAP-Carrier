import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:intl/intl.dart';

class TenderedScreen extends StatefulWidget {
  final CarrierShipment? initialShipment;
  const TenderedScreen({super.key, this.initialShipment});
  @override
  State<TenderedScreen> createState() => _TenderedScreenState();
}

class _TenderedScreenState extends State<TenderedScreen> {
  List<CarrierShipment> _shipments = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();
  List<CarrierShipment> _filtered = [];

  @override
  void initState() { super.initState(); _fetch(); _search.addListener(_filter); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stubs = await OtmService.fetchTenderedShipments();
      final validStubs = stubs.where((stub) {
        final domain = stub['domainName'] ?? '';
        final xid    = stub['shipmentXid'] ?? '';
        return domain.isNotEmpty && xid.isNotEmpty;
      }).toList();

      // Fetch shipment details in batches of 3 — parallel within each batch
      // to avoid both sequential blocking (ANR) and unbounded concurrency
      // (memory pressure / 26s EGL frames on slow connections).
      const batchSize = 3;
      final shipments = <CarrierShipment>[];
      for (int i = 0; i < validStubs.length; i += batchSize) {
        final batch = validStubs.skip(i).take(batchSize).toList();
        final batchResults = await Future.wait(
          batch.map((stub) async {
            final domain = stub['domainName'] as String;
            final xid    = stub['shipmentXid'] as String;
            try {
              final detail = await OtmService.fetchShipmentDetail('$domain.$xid');
              return CarrierShipment.fromJson(detail);
            } catch (_) {
              return null;
            }
          }),
        );
        shipments.addAll(batchResults.whereType<CarrierShipment>());
      }
      if (mounted) setState(() { _shipments = shipments; _filtered = shipments; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
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

  void _removeAndRefresh(CarrierShipment s) {
    setState(() {
      _shipments.removeWhere((x) => x.bareXid == s.bareXid);
      _filtered.removeWhere((x) => x.bareXid == s.bareXid);
    });
    Future.delayed(const Duration(seconds: 5), () { if (mounted) _fetch(); });
  }

  Future<bool> _respond(CarrierShipment s, bool accept,
      {String? driverPhone, String? driverName, String? vehicleReg, String? truckType}) async {
    final t = context.read<LeapThemeProvider>().theme;
    final tender = s.activeTender;
    if (tender == null || tender.iTransactionNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No actionable tender found.',
            style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
        backgroundColor: t.danger, behavior: SnackBarBehavior.floating,
      ));
      return false;
    }

    // Step 1 — Accept or reject the tender
    await OtmService.respondToTender(iTransactionNo: tender.iTransactionNo!, accept: accept);

    // Step 2 — If accepted, post non-empty driver fields as shipment remarks
    if (accept) {
      final fields = <String, String>{
        if (driverPhone != null && driverPhone.isNotEmpty)
          AppConstants.remarkDriverPhone: driverPhone,
        if (driverName != null && driverName.isNotEmpty)
          AppConstants.remarkDriverName: driverName,
        if (vehicleReg != null && vehicleReg.isNotEmpty)
          AppConstants.remarkVehicleReg: vehicleReg,
        if (truckType != null && truckType.isNotEmpty)
          AppConstants.remarkTruckType: truckType,
      };
      if (fields.isNotEmpty) {
        try {
          await OtmService.saveDriverRemarks(
            shipmentGid: '${s.domainName}.${s.bareXid}',
            fields:      fields,
            domainName:  s.domainName,
          );
        } catch (_) {
          // Tender is accepted — surface remarks failure so carrier knows
          // driver assignment needs to be done from the home screen search
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                'Tender accepted ✅  but driver details could not be saved. '
                'Use "Find Shipment" on the home screen to assign the driver.',
                style: TextStyle(fontFamily: LeapPlatform.fontFamily),
              ),
              backgroundColor: t.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        }
      }
    }
    return true;
  }

  // ── Timer urgency from theme ─────────────────────────────────────────────
  Color _timerBg(TenderItem? tender, AppThemeData t) {
    if (tender?.expectedResponse == null) return t.warning.withValues(alpha: 0.12);
    final h = tender!.expectedResponse!.difference(DateTime.now()).inHours;
    if (h < 3)  return t.danger.withValues(alpha: 0.12);
    if (h < 24) return t.warning.withValues(alpha: 0.12);
    return t.success.withValues(alpha: 0.12);
  }
  Color _timerFg(TenderItem? tender, AppThemeData t) {
    if (tender?.expectedResponse == null) return t.warning;
    final h = tender!.expectedResponse!.difference(DateTime.now()).inHours;
    if (h < 3)  return t.danger;
    if (h < 24) return t.warning;
    return t.success;
  }
  Color _timerBorder(TenderItem? tender, AppThemeData t) =>
    _timerFg(tender, t).withValues(alpha: 0.4);

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default:    return currency;
    }
  }

  String _fmt(double v) => v == v.truncateToDouble()
      ? v.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
      : v.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+\.)'), (m) => '${m[1]},');

  // ── Detail bottom sheet ──────────────────────────────────────────────────
  void _showDetailSheet(CarrierShipment s, AppThemeData t) {
    final tender   = s.activeTender;
    final timerFg  = _timerFg(tender, t);
    final timerBg  = _timerBg(tender, t);
    final timerBdr = _timerBorder(tender, t);
    final startStr = s.startTime != null ? DateFormat('dd MMM · HH:mm').format(s.startTime!.toLocal()) : '—';
    final endStr   = s.endTime   != null ? DateFormat('dd MMM · HH:mm').format(s.endTime!.toLocal())   : '—';
    final tenderTypeLabel = tender?.tenderType.isNotEmpty == true ? tender!.tenderType : 'Ordinary';
    final expiryLabel     = tender?.respondByCountdown ?? '—';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Handle
            Center(child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)),
            )),

            // Title + timer pill
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text('Shipment #${s.displayId}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: t.text, fontFamily: LeapPlatform.fontFamily))),
              if (tender?.respondByCountdown != null)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: timerBg, borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: timerBdr),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, size: 11, color: timerFg),
                    const SizedBox(width: 4),
                    Text(tender!.respondByCountdown!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: timerFg, fontFamily: LeapPlatform.fontFamily)),
                  ]),
                ),
            ]),

            const SizedBox(height: 2),
            Text('$tenderTypeLabel tender · Expires in $expiryLabel',
                style: TextStyle(fontSize: 11, color: t.textMuted,
                    fontFamily: LeapPlatform.fontFamily)),

            const SizedBox(height: 14),

            // ── Detail grid — Rate here since card only shows Start/End/Weight ──
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 2.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _detailCell('START',  startStr, t),
                _detailCell('END',    endStr,   t),
                _detailCell('WEIGHT', s.totalWeight?.display ?? '—', t),
                _detailCell('RATE',   tender?.cost != null
                    ? '${_currencySymbol(tender!.currency)} ${_fmt(tender.cost!)}'
                    : '—', t, valueColor: t.success),
              ],
            ),

            const SizedBox(height: 16),

            // ── Stops ────────────────────────────────────────────────────
            Text('STOPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: t.textMuted, letterSpacing: 0.5,
                fontFamily: LeapPlatform.fontFamily)),
            const SizedBox(height: 8),

            if (s.stops.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surface3, borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: t.textMuted),
                  const SizedBox(width: 8),
                  Text('No stop details available.',
                      style: TextStyle(fontSize: 11, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily)),
                ]),
              )
            else
              ...s.stops.asMap().entries.map((e) {
                final i = e.key; final stop = e.value;
                final isPU  = stop.stopType?.toUpperCase() == 'P' || stop.stopType?.toUpperCase() == 'PU';
                final isDel = stop.stopType?.toUpperCase() == 'D';
                final nbg   = isPU  ? t.success.withValues(alpha: 0.15)
                            : isDel ? t.danger.withValues(alpha: 0.15)
                            : t.surface3;
                final nfg   = isPU  ? t.success
                            : isDel ? t.danger
                            : t.textMuted;
                final lbl   = isPU  ? 'Pickup'
                            : isDel ? 'Delivery'
                            : 'Stop';
                final timeStr = stop.scheduledArrival != null
                    ? DateFormat('dd MMM · HH:mm').format(stop.scheduledArrival!.toLocal()) : '—';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.surface3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: nbg, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${i + 1}', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: nfg, fontFamily: LeapPlatform.fontFamily)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(stop.displayName, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: t.text, fontFamily: LeapPlatform.fontFamily)),
                      Text(timeStr, style: TextStyle(
                          fontSize: 10, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: nbg, borderRadius: BorderRadius.circular(100)),
                      child: Text(lbl, style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: nfg, fontFamily: LeapPlatform.fontFamily)),
                    ),
                  ]),
                );
              }),

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _confirmReject(s, t); },
                  icon: Icon(Icons.close_rounded, size: 15, color: t.danger),
                  label: Text('Reject', style: TextStyle(
                      color: t.danger, fontFamily: LeapPlatform.fontFamily)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: t.danger.withValues(alpha: 0.4)),
                    backgroundColor: t.danger.withValues(alpha: 0.06),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _showAcceptSheet(s, t); },
                  icon: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  label: const Text('Accept', style: TextStyle(
                      color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.success, minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailCell(String label, String value, AppThemeData t, {Color? valueColor}) =>
    Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(color: t.surface3, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(fontSize: 9, color: t.textMuted,
            letterSpacing: 0.05, fontWeight: FontWeight.w600,
            fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: valueColor ?? t.text, fontFamily: LeapPlatform.fontFamily),
            overflow: TextOverflow.ellipsis),
      ]),
    );

  void _confirmReject(CarrierShipment s, AppThemeData t) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: t.surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Reject Tender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: t.text, fontFamily: LeapPlatform.fontFamily)),
          const SizedBox(height: 8),
          Text('Shipment #${s.displayId}', style: TextStyle(fontSize: 13, color: t.textMuted,
              fontFamily: LeapPlatform.fontFamily)),
          const SizedBox(height: 4),
          Text('This action cannot be undone.', style: TextStyle(fontSize: 12,
              color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _respond(s, false);
                  HapticFeedback.mediumImpact();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Tender rejected.',
                          style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                      backgroundColor: t.danger, behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                    _removeAndRefresh(s);
                  }
                } catch (e) {
                  if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}',
                        style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
                    backgroundColor: t.danger, behavior: SnackBarBehavior.floating,
                  )); }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: t.danger),
              child: const Text('Yes, Reject',
                  style: TextStyle(color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
            )),
          ]),
        ]),
      ),
    );
  }

  void _showAcceptSheet(CarrierShipment s, AppThemeData t) {
    final phoneCtrl = TextEditingController();
    final nameCtrl  = TextEditingController();
    final vehCtrl   = TextEditingController();
    String? selTruck; bool submitting = false;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      isScrollControlled: true, isDismissible: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(color: t.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.check_circle_outline_rounded, size: 22, color: t.success),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Accept Tender', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                      color: t.text, fontFamily: LeapPlatform.fontFamily)),
                  Text('#${s.displayId} · ${s.source.displayName} → ${s.dest.displayName}',
                      style: TextStyle(fontSize: 11, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily), overflow: TextOverflow.ellipsis),
                ])),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.primary.withValues(alpha: 0.15)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.person_add_outlined, size: 14, color: t.primary),
                    const SizedBox(width: 6),
                    Text('Assign driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: t.primary, fontFamily: LeapPlatform.fontFamily)),
                    const Spacer(),
                    Text('Optional — assign later from Active',
                        style: TextStyle(fontSize: 10, color: t.textMuted,
                            fontFamily: LeapPlatform.fontFamily)),
                  ]),
                  const SizedBox(height: 10),
                  // Phone first — critical for SMS deeplink to driver app
                  _driverField(phoneCtrl, 'Driver Phone (optional)',
                      Icons.phone_rounded, t,
                      optional: true, hint: 'e.g. +91 9849012345',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 8),
                  _driverField(nameCtrl, 'Driver Name (optional)',
                      Icons.person_rounded, t, optional: true),
                  const SizedBox(height: 8),
                  _driverField(vehCtrl, 'Vehicle Registration (optional)',
                      Icons.directions_car_rounded, t,
                      optional: true, hint: 'e.g. KA 01 AB 1234'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.border, width: 1.5)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                      value: selTruck, isExpanded: true, dropdownColor: t.surface2,
                      hint: Text('Select Truck Type (optional)', style: TextStyle(
                          fontSize: 13, color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
                      style: TextStyle(fontSize: 13, color: t.text, fontFamily: LeapPlatform.fontFamily),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: t.textMuted),
                      items: AppConstants.truckTypes.map((tt) => DropdownMenuItem(value: tt,
                        child: Text(tt, style: TextStyle(fontFamily: LeapPlatform.fontFamily,
                            color: t.text)))).toList(),
                      onChanged: submitting ? null : (v) => setModal(() => selTruck = v),
                    )),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    setModal(() => submitting = true);
                    try {
                      await _respond(s, true,
                        driverPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        driverName:  nameCtrl.text.trim().isEmpty  ? null : nameCtrl.text.trim(),
                        vehicleReg:  vehCtrl.text.trim().isEmpty   ? null : vehCtrl.text.trim(),
                        truckType:   selTruck,
                      );
                      HapticFeedback.mediumImpact();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Tender accepted successfully! 🎉',
                              style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                          backgroundColor: t.success, behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                        _removeAndRefresh(s);
                      }
                    } catch (e) {
                      setModal(() => submitting = false);
                      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}',
                            style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
                        backgroundColor: t.danger, behavior: SnackBarBehavior.floating,
                      )); }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: t.success),
                  child: submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                          strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Confirm Accept', style: TextStyle(
                          color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                )),
              ]),
            ]),
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

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) { if (didPop) return; Navigator.pop(context, _shipments); },
      child: Scaffold(
        backgroundColor: t.surface1,
        appBar: AppBar(
          backgroundColor: t.navColor, foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _shipments),
          ),
          title: const Text('Tendered Shipments', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 17,
              fontFamily: LeapPlatform.fontFamily)),
        ),
        body: Column(children: [
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
      ),
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
      Icon(Icons.gavel_rounded, size: 48, color: t.textMuted),
      const SizedBox(height: 8),
      Text('No tendered shipments', style: TextStyle(color: t.textMuted,
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
    final tender   = s.activeTender;
    final timerFg  = _timerFg(tender, t);
    final timerBg  = _timerBg(tender, t);
    final timerBdr = _timerBorder(tender, t);
    final startStr = s.startTime != null ? DateFormat('dd MMM · HH:mm').format(s.startTime!.toLocal()) : '—';
    final endStr   = s.endTime   != null ? DateFormat('dd MMM · HH:mm').format(s.endTime!.toLocal())   : '—';
    final rBy      = tender?.respondByCountdown;

    return GestureDetector(
      onTap: () => _showDetailSheet(s, t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: t.surface3,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(children: [
              Text('#${s.displayId}', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w800, color: t.text,
                  fontFamily: LeapPlatform.fontFamily)),
              const Spacer(),
              if (rBy != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: timerBg, borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: timerBdr),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, size: 10, color: timerFg),
                    const SizedBox(width: 3),
                    Text(rBy, style: TextStyle(fontSize: 9, color: timerFg,
                        fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily)),
                  ]),
                ),
            ]),
          ),

          // ── Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Route
              Row(children: [
                Icon(Icons.trip_origin_rounded, size: 12, color: t.success),
                const SizedBox(width: 4),
                Expanded(child: Text(s.source.displayName, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: t.text,
                    fontFamily: LeapPlatform.fontFamily), overflow: TextOverflow.ellipsis)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 12, color: t.textMuted)),
                Icon(Icons.flag_rounded, size: 12, color: t.danger),
                const SizedBox(width: 4),
                Expanded(child: Text(s.dest.displayName, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: t.text,
                    fontFamily: LeapPlatform.fontFamily), overflow: TextOverflow.ellipsis)),
              ]),

              const SizedBox(height: 8),
              Container(height: 1, color: t.border),
              const SizedBox(height: 8),

              // Info row — Start, End, Weight only (Rate shown in detail sheet)
              Row(children: [
                Expanded(child: _infoCell('Start', startStr, t)),
                _vDivider(t),
                Expanded(child: _infoCell('End', endStr, t)),
                if (s.totalWeight != null) ...[
                  _vDivider(t),
                  Expanded(child: _infoCell('Weight', s.totalWeight!.display, t)),
                ],
              ]),

              const SizedBox(height: 10),

              // Tap-to-respond CTA — matches spot bids button style
              Container(
                width: double.infinity,
                height: 38,
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(
                      color: t.primary.withValues(alpha: 0.25),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.gavel_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text('View & Respond', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                ])),
              ),
            ]),
          ),

          // ── Driver warning strip ─────────────────────────────────────
          if (s.tenders.any((tender) => tender.isAccepted) && !s.hasDriverAssigned)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              decoration: BoxDecoration(
                color: t.warning.withValues(alpha: 0.08),
                border: Border(top: BorderSide(color: t.warning.withValues(alpha: 0.3))),
              ),
              child: Row(children: [
                Icon(Icons.person_outline_rounded, size: 12, color: t.warning),
                const SizedBox(width: 5),
                Text('Driver not yet assigned — SMS not sent', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: t.warning, fontFamily: LeapPlatform.fontFamily)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _infoCell(String label, String value, AppThemeData t, {Color? valueColor}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
          color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: valueColor ?? t.text, fontFamily: LeapPlatform.fontFamily),
          overflow: TextOverflow.ellipsis),
    ]);

  Widget _vDivider(AppThemeData t) => Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: t.border);
}