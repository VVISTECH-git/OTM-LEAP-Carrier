import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/services/session_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:intl/intl.dart';

class SpotBidsScreen extends StatefulWidget {
  final CarrierShipment? initialShipment;
  const SpotBidsScreen({super.key, this.initialShipment});
  @override
  State<SpotBidsScreen> createState() => _SpotBidsScreenState();
}

class _SpotBidsScreenState extends State<SpotBidsScreen> {
  List<CarrierShipment> _shipments = [];
  Map<String, double?> _existingBids = {};
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();
  List<CarrierShipment> _filtered = [];

  @override
  void initState() { super.initState(); _fetch(); _search.addListener(_filter); }

  @override
  void dispose() { _search.dispose(); _refreshTimer?.cancel(); super.dispose(); }

  Timer? _refreshTimer;

  Future<String> get _servprovGid async => SessionService.instance.servprovGid;

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stubs = await OtmService.fetchSpotBidShipments();
      final servprovGid = await _servprovGid;

      // Fetch all shipment details in parallel — cuts load time from
      // O(2N) serial round-trips to O(1) parallel batch.
      final validStubs = stubs.where((stub) {
        final domain = stub['domainName'] ?? '';
        final xid    = stub['shipmentXid'] ?? '';
        return domain.isNotEmpty && xid.isNotEmpty;
      }).toList();

      final detailResults = await Future.wait(
        validStubs.map((stub) async {
          final domain = stub['domainName'] as String;
          final xid    = stub['shipmentXid'] as String;
          try { return await OtmService.fetchShipmentDetail('$domain.$xid'); }
          catch (_) { return null; }
        }),
      );

      final shipments = <CarrierShipment>[];
      for (final detail in detailResults) {
        if (detail != null) {
          try { shipments.add(CarrierShipment.fromJson(detail)); } catch (_) {}
        }
      }

      // Fetch all existing bids in parallel too.
      final bidEntries = await Future.wait(
        shipments.map((s) async {
          final txnNo = s.spotBidTender?.iTransactionNo;
          if (txnNo == null) return MapEntry(s.bareXid, null);
          final bid = await OtmService.checkExistingBid(
            transactionNo: txnNo, servprovGid: servprovGid);
          return MapEntry(s.bareXid, bid);
        }),
      );

      final bids = Map<String, double?>.fromEntries(bidEntries);
      setState(() { _shipments = shipments; _filtered = shipments; _existingBids = bids; _loading = false; });
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

  void _removeAndRefresh(CarrierShipment s) {
    setState(() {
      _shipments.removeWhere((x) => x.bareXid == s.bareXid);
      _filtered.removeWhere((x) => x.bareXid == s.bareXid);
      _existingBids.remove(s.bareXid);
    });
    // Use a cancellable Timer so the callback is properly cleaned up if the
    // widget is disposed before the 15s window elapses.
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) _fetch();
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
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

  // ── Detail sheet — single entry point for all actions ────────────────────
  void _showDetailSheet(CarrierShipment s, AppThemeData t) {
    final tender      = s.spotBidTender;
    final existingBid = _existingBids[s.bareXid];
    final hasMarket   = s.marketCost != null;
    final startStr    = s.startTime != null ? DateFormat('dd MMM · HH:mm').format(s.startTime!.toLocal()) : '—';
    final endStr      = s.endTime   != null ? DateFormat('dd MMM · HH:mm').format(s.endTime!.toLocal())   : '—';
    final countdown   = tender?.respondByCountdown;

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

            // Title + timer
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text('Shipment #${s.displayId}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: t.text, fontFamily: LeapPlatform.fontFamily))),
              if (countdown != null)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: t.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, size: 11, color: t.warning),
                    const SizedBox(width: 4),
                    Text(countdown, style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700, color: t.warning,
                        fontFamily: LeapPlatform.fontFamily)),
                  ]),
                ),
            ]),

            const SizedBox(height: 2),
            Text('Spot Bid · Auction in progress',
                style: TextStyle(fontSize: 11, color: t.textMuted,
                    fontFamily: LeapPlatform.fontFamily)),

            const SizedBox(height: 14),

            // ── Detail grid ──────────────────────────────────────────────
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
                if (hasMarket)
                  _detailCell('MARKET PRICE',
                      '${_currencySymbol(s.currency)} ${_fmt(s.marketCost!)}',
                      t, valueColor: t.success),
              ],
            ),

            // ── Your existing bid panel (if any) ─────────────────────────
            if (existingBid != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOUR BID', style: TextStyle(fontSize: 9,
                        color: t.primary, fontWeight: FontWeight.w700,
                        fontFamily: LeapPlatform.fontFamily)),
                    const SizedBox(height: 2),
                    Text('${_currencySymbol(s.currency)} ${_fmt(existingBid)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: t.primary, fontFamily: LeapPlatform.fontFamily)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: t.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text('auction in progress', style: TextStyle(
                        fontSize: 9, color: t.primary, fontWeight: FontWeight.w600,
                        fontFamily: LeapPlatform.fontFamily)),
                  ),
                ]),
              ),
            ],

            // ── Fair market price panel ───────────────────────────────────
            if (hasMarket) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.success.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.success.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('FAIR MARKET PRICE', style: TextStyle(fontSize: 9,
                        color: t.success, fontWeight: FontWeight.w700,
                        fontFamily: LeapPlatform.fontFamily)),
                    const SizedBox(height: 2),
                    Text('${_currencySymbol(s.currency)} ${_fmt(s.marketCost!)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: t.success, fontFamily: LeapPlatform.fontFamily)),
                  ])),
                ]),
              ),
            ],

            const SizedBox(height: 16),

            // ── Stops ────────────────────────────────────────────────────
            Text('STOPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: t.textMuted, letterSpacing: 0.5,
                fontFamily: LeapPlatform.fontFamily)),
            const SizedBox(height: 8),

            if (s.stops.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: t.surface3, borderRadius: BorderRadius.circular(8)),
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
                final nbg = isPU ? t.success.withValues(alpha: 0.15) : isDel ? t.danger.withValues(alpha: 0.15) : t.surface3;
                final nfg = isPU ? t.success : isDel ? t.danger : t.textMuted;
                final lbl = isPU ? 'Pickup' : isDel ? 'Delivery' : 'Stop';
                final timeStr = stop.scheduledArrival != null
                    ? DateFormat('dd MMM · HH:mm').format(stop.scheduledArrival!.toLocal()) : '—';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: t.surface3, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: nbg, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${i + 1}', style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700, color: nfg,
                          fontFamily: LeapPlatform.fontFamily)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(stop.displayName, style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700, color: t.text,
                          fontFamily: LeapPlatform.fontFamily)),
                      Text(timeStr, style: TextStyle(fontSize: 10, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: nbg, borderRadius: BorderRadius.circular(100)),
                      child: Text(lbl, style: TextStyle(fontSize: 9,
                          fontWeight: FontWeight.w700, color: nfg,
                          fontFamily: LeapPlatform.fontFamily)),
                    ),
                  ]),
                );
              }),

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Column(children: [

                // Accept market price — full width, prominent
                if (hasMarket)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(context); _confirmAcceptMarketPrice(s, t); },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                        label: Text(
                          'Accept Market Price · ${_currencySymbol(s.currency)} ${_fmt(s.marketCost!)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: Colors.white, fontFamily: LeapPlatform.fontFamily),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.success, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),

                // Place bid / Update bid
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: existingBid != null
                      ? OutlinedButton.icon(
                          onPressed: () { Navigator.pop(context); _showBidSheet(s, t, isUpdate: true); },
                          icon: Icon(Icons.edit_rounded, size: 15, color: t.primary),
                          label: Text('Update Bid', style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: t.primary,
                              fontFamily: LeapPlatform.fontFamily)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: t.primary.withValues(alpha: 0.4)),
                            backgroundColor: t.primary.withValues(alpha: 0.06),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () { Navigator.pop(context); _showBidSheet(s, t); },
                          icon: const Icon(Icons.gavel_rounded, size: 15, color: Colors.white),
                          label: Text(
                            hasMarket ? 'Place Custom Bid' : 'Place Bid',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: Colors.white, fontFamily: LeapPlatform.fontFamily),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                ),
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

  // ── Confirm accept market price sheet ────────────────────────────────────
  void _confirmAcceptMarketPrice(CarrierShipment s, AppThemeData t) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(color: t.surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Icon(Icons.check_circle_outline_rounded, size: 36, color: t.success),
          const SizedBox(height: 10),
          Text('Accept Market Price', style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w800, color: t.text,
              fontFamily: LeapPlatform.fontFamily)),
          const SizedBox(height: 6),
          Text('${_currencySymbol(s.currency)} ${_fmt(s.marketCost!)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: t.success, fontFamily: LeapPlatform.fontFamily)),
          const SizedBox(height: 6),
          Text('#${s.displayId} · ${s.source.displayName} → ${s.dest.displayName}',
              style: TextStyle(fontSize: 11, color: t.textMuted,
                  fontFamily: LeapPlatform.fontFamily), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('This will award the shipment to you immediately.',
              style: TextStyle(fontSize: 12, color: t.textMuted,
                  fontFamily: LeapPlatform.fontFamily), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitBid(s, s.marketCost!, isBuyItNow: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: t.success),
              child: const Text('Confirm', style: TextStyle(
                  color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
            )),
          ]),
        ]),
      ),
    );
  }

  // ── Bid input sheet ───────────────────────────────────────────────────────
  void _showBidSheet(CarrierShipment s, AppThemeData t, {bool isUpdate = false}) {
    final existingBid = _existingBids[s.bareXid];
    final bidCtrl = TextEditingController(
        text: isUpdate && existingBid != null ? existingBid.toStringAsFixed(0) : '');
    bool submitting = false;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
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
                Icon(Icons.gavel_rounded, size: 22, color: t.primary),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isUpdate ? 'Update Bid' : 'Place Bid',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                          color: t.text, fontFamily: LeapPlatform.fontFamily)),
                  Text('#${s.displayId} · ${s.source.displayName} → ${s.dest.displayName}',
                      style: TextStyle(fontSize: 11, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily), overflow: TextOverflow.ellipsis),
                ])),
                if (s.spotBidTender?.respondByCountdown != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.timer_outlined, size: 12, color: t.warning),
                      const SizedBox(width: 4),
                      Text(s.spotBidTender!.respondByCountdown!,
                          style: TextStyle(fontSize: 10, color: t.warning,
                              fontWeight: FontWeight.w700,
                              fontFamily: LeapPlatform.fontFamily)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: t.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border, width: 1.5)),
                child: TextField(
                  controller: bidCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: t.text, fontFamily: LeapPlatform.fontFamily),
                  decoration: InputDecoration(
                    labelText: 'Your Bid Amount (${s.currency})',
                    labelStyle: TextStyle(fontSize: 13, color: t.textMuted,
                        fontFamily: LeapPlatform.fontFamily),
                    prefixText: '${_currencySymbol(s.currency)} ',
                    prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: t.success, fontFamily: LeapPlatform.fontFamily),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    final amount = double.tryParse(bidCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid bid amount')));
                      return;
                    }
                    setModal(() => submitting = true);
                    try {
                      await _submitBid(s, amount, isBuyItNow: false, fromSheet: true);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (_) { setModal(() => submitting = false); }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Text(isUpdate ? 'Update Bid' : 'Submit Bid',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _submitBid(CarrierShipment s, double amount,
      {required bool isBuyItNow, bool fromSheet = false}) async {
    final t = context.read<LeapThemeProvider>().theme;
    final tender = s.spotBidTender;
    final transactionNo = tender?.iTransactionNo;
    final servprovGid = await _servprovGid;
    if (transactionNo == null) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Cannot submit: no Spot Bid tender found.',
            style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
        backgroundColor: t.danger)); }
      return;
    }
    // Guard: servprovGid is fetched during login. If that lookup failed
    // silently, submitting with an empty GID would produce a cryptic OTM
    // error instead of a clear user message.
    if (servprovGid.isEmpty) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Cannot submit: service provider ID not found. Please log out and log in again.',
            style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
        backgroundColor: t.danger)); }
      return;
    }
    try {
      await OtmService.submitSpotBid(
        iTransactionNo: transactionNo, bidAmount: amount,
        currency: s.currency, servprovGid: servprovGid, isBuyItNow: isBuyItNow);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isBuyItNow
              ? 'Market price accepted! Shipment awarded. 🎉'
              : 'Bid submitted successfully!',
              style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
          backgroundColor: isBuyItNow ? t.success : t.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        if (isBuyItNow) {
          _removeAndRefresh(s);
        } else {
          // refresh bid amount on card
          final servprov = await _servprovGid;
          final txn = s.spotBidTender?.iTransactionNo;
          if (txn != null) {
            final updated = await OtmService.checkExistingBid(
                transactionNo: txn, servprovGid: servprov);
            setState(() => _existingBids[s.bareXid] = updated);
          }
        }
      }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
        backgroundColor: t.danger, behavior: SnackBarBehavior.floating)); }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.surface1,
      appBar: AppBar(
        backgroundColor: t.navColor, foregroundColor: Colors.white,
        title: const Text('Spot Bid Shipments', style: TextStyle(
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
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13,
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
      Icon(Icons.local_offer_outlined, size: 48, color: t.textMuted),
      const SizedBox(height: 8),
      Text('No spot bid shipments', style: TextStyle(color: t.textMuted,
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
    final startStr    = s.startTime != null ? DateFormat('dd MMM · HH:mm').format(s.startTime!.toLocal()) : '—';
    final endStr      = s.endTime   != null ? DateFormat('dd MMM · HH:mm').format(s.endTime!.toLocal())   : '—';
    final respondBy   = s.spotBidTender?.respondByCountdown;
    final existingBid = _existingBids[s.bareXid];
    final hasMarket   = s.marketCost != null;

    return GestureDetector(
      onTap: () => _showDetailSheet(s, t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: t.surface2, borderRadius: BorderRadius.circular(12),
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
              if (respondBy != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: t.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined, size: 10, color: t.warning),
                    const SizedBox(width: 3),
                    Text(respondBy, style: TextStyle(fontSize: 9, color: t.warning,
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

              // Info row — Start / End / Weight only (no truncation)
              Row(children: [
                Expanded(child: _infoCell('Start', startStr, t)),
                _divider(t),
                Expanded(child: _infoCell('End', endStr, t)),
                if (s.totalWeight != null) ...[
                  _divider(t),
                  Expanded(child: _infoCell('Weight', s.totalWeight!.display, t)),
                ],
              ]),

              const SizedBox(height: 10),

              // Bid status indicator on card
              if (existingBid != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOUR BID', style: TextStyle(fontSize: 9, color: t.primary,
                          fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily)),
                      const SizedBox(height: 2),
                      Text('${_currencySymbol(s.currency)} ${_fmt(existingBid)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                              color: t.primary, fontFamily: LeapPlatform.fontFamily)),
                    ])),
                    if (hasMarket)
                      Text('Market: ${_currencySymbol(s.currency)} ${_fmt(s.marketCost!)}',
                          style: TextStyle(fontSize: 10, color: t.success,
                              fontWeight: FontWeight.w600,
                              fontFamily: LeapPlatform.fontFamily)),
                  ]),
                ),
                const SizedBox(height: 8),
              ] else if (hasMarket) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.success.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('FAIR MARKET PRICE', style: TextStyle(fontSize: 9, color: t.success,
                          fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily)),
                      const SizedBox(height: 2),
                      Text('${_currencySymbol(s.currency)} ${_fmt(s.marketCost!)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                              color: t.success, fontFamily: LeapPlatform.fontFamily)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 8),
              ],

              // CTA — always "View & Respond"
              Container(
                width: double.infinity, height: 38,
                decoration: BoxDecoration(
                  color: t.primary, borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: t.primary.withValues(alpha: 0.25),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.gavel_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(existingBid != null ? 'View Details & Update Bid' : 'View Details & Bid',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                ])),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoCell(String label, String value, AppThemeData t) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, color: t.textMuted,
          fontWeight: FontWeight.w600, fontFamily: LeapPlatform.fontFamily)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: t.text, fontFamily: LeapPlatform.fontFamily),
          overflow: TextOverflow.ellipsis),
    ]);

  Widget _divider(AppThemeData t) => Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: t.border);
}