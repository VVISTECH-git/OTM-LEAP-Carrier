import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:leapcarrier/features/shipments/screens/add_event_screen.dart';
import 'package:leapcarrier/features/shipments/screens/pod_upload_screen.dart';
import 'package:intl/intl.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final CarrierShipment shipment;
  final List<TrackingEventItem>? preloadedEvents;
  const ShipmentDetailScreen({super.key, required this.shipment, this.preloadedEvents});
  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  late CarrierShipment        _shipment;
  List<TrackingEventItem>     _events       = [];
  List<dynamic>               _costs        = [];
  bool _loadingEvents = true;
  bool _loadingCosts  = false;
  bool _costsLoaded   = false;

  // Section expanded state
  bool _stopsExpanded = true;

  // Sheet-open guards — second tap dismisses (driver + docs only)
  bool _driverSheetOpen = false;
  bool _docsSheetOpen   = false;

  // Tracks which document keys have been uploaded this session.
  // Seeded from the API on load via 'uploadedDocKeys' field (if present).
  final Set<String> _uploadedDocs = {};

  AppThemeData get _t => context.read<LeapThemeProvider>().theme;

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
    if (widget.preloadedEvents != null) {
      // Events were pre-fetched by the caller — use them directly
      _events        = widget.preloadedEvents!;
      _loadingEvents = false;
      for (final e in _events) {
        if (e.statusCodeGid == 'CD') _uploadedDocs.add('pod');
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEvents());
    }
  }

  // ── Fetch tracking events only on load ───────────────────────────────────
  Future<void> _fetchEvents() async {
    try {
      final items = await OtmService.fetchTrackingEvents(
          '${_shipment.domainName}.${_shipment.bareXid}');
      if (mounted) {
        setState(() {
          // Parse all events then dedup by statusCodeGid — keep latest per code
          final allEvents = items.map((j) => TrackingEventItem.fromJson(j)).toList()
            ..sort((a, b) {
              if (a.eventDate == null) return 1;
              if (b.eventDate == null) return -1;
              return b.eventDate!.compareTo(a.eventDate!);
            });
          final seen = <String>{};
          _events = allEvents.where((e) => seen.add(e.statusCodeGid)).toList()
            ..sort((a, b) {
              if (a.eventDate == null) return 1;
              if (b.eventDate == null) return -1;
              return b.eventDate!.compareTo(a.eventDate!);
            });
          _loadingEvents = false;
          // Seed uploaded docs from tracking events — 'CD' (POD submitted) means
          // at least the base 'pod' key was uploaded.
          for (final e in _events) {
            if (e.statusCodeGid == 'CD') _uploadedDocs.add('pod');
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }



  Future<void> _fetchCostsIfNeeded() async {
    if (_costsLoaded || _loadingCosts) return;
    setState(() => _loadingCosts = true);
    try {
      final items = await OtmService.fetchCosts(
          '${_shipment.domainName}.${_shipment.bareXid}');
      if (mounted) setState(() { _costs = items; _loadingCosts = false; _costsLoaded = true; });
    } catch (e) {
      if (mounted) setState(() { _loadingCosts = false; _costsLoaded = true; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _costsLoaded = false; });
    try {
      final shipmentGid = '${_shipment.domainName}.${_shipment.bareXid}';
      final results = await Future.wait([
        OtmService.fetchShipmentDetail(shipmentGid),
        OtmService.fetchRemarks(shipmentGid),
      ]);
      final detail  = results[0] as Map<String, dynamic>;
      final remarks = results[1] as List<dynamic>;
      String? remarkText(String qual) {
        for (final r in remarks) {
          if (r['remarkQualGid']?.toString() == qual) {
            final t = r['remarkText']?.toString() ?? '';
            return t.isNotEmpty ? t : null;
          }
        }
        return null;
      }
      if (mounted) {
        setState(() => _shipment = CarrierShipment.fromJson(detail).copyWithDriverRemarks(
          driverPhone: remarkText(AppConstants.remarkDriverPhone),
          driverName:  remarkText(AppConstants.remarkDriverName),
          vehicleReg:  remarkText(AppConstants.remarkVehicleReg),
          truckType:   remarkText(AppConstants.remarkTruckType),
        ));
      }
    } catch (_) {}
    await _fetchEvents();
  }

  // ── Driver sheet ──────────────────────────────────────────────────────────
  // Fetch remarks first, then open sheet pre-filled. Uses saveDriverRemarks
  // with existingRemarks passed to skip double GET and avoid duplicate POSTs.
  Future<void> _showDriverSheet() async {
    if (_driverSheetOpen) { Navigator.of(context).pop(); return; }
    setState(() => _driverSheetOpen = true);
    final t = _t;
    final shipmentGid = '${_shipment.domainName}.${_shipment.bareXid}';

    // Fetch fresh remarks before opening
    List<dynamic> fetchedRemarks = [];
    try {
      fetchedRemarks = await OtmService.fetchRemarks(shipmentGid);
    } catch (_) {}
    if (!mounted) { return; }

    // Pre-fill controllers from fetched remarks
    final phoneCtrl   = TextEditingController();
    final nameCtrl    = TextEditingController();
    final vehicleCtrl = TextEditingController();
    String? selTruck;
    final originalValues = <String, String>{};

    for (final r in fetchedRemarks) {
      final qual = r['remarkQualGid']?.toString() ?? '';
      final text = r['remarkText']?.toString()    ?? '';
      if (text.isEmpty) continue;
      if (qual == AppConstants.remarkDriverPhone) { phoneCtrl.text = text; originalValues[qual] = text; }
      if (qual == AppConstants.remarkDriverName)  { nameCtrl.text  = text; originalValues[qual] = text; }
      if (qual == AppConstants.remarkVehicleReg)  { vehicleCtrl.text = text; originalValues[qual] = text; }
      if (qual == AppConstants.remarkTruckType && AppConstants.truckTypes.contains(text)) {
        selTruck = text; originalValues[qual] = text;
      }
    }

    final hasAnyDriver = originalValues.containsKey(AppConstants.remarkDriverPhone);
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(color: t.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.local_shipping_rounded, size: 22, color: t.primary),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hasAnyDriver ? 'Update Driver & Truck' : 'Assign Driver & Truck',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                          color: t.text, fontFamily: LeapPlatform.fontFamily)),
                  Text('Shipment #${_shipment.displayId}',
                      style: TextStyle(fontSize: 11, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily)),
                ])),
              ]),
              const SizedBox(height: 16),
              // Phone first — critical SMS gate
              _driverField(phoneCtrl, 'Driver Phone (with country code)',
                  Icons.phone_rounded, t,
                  hint: 'e.g. +91 9849012345', keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _driverField(nameCtrl, 'Driver Name (optional)', Icons.person_rounded, t, optional: true),
              const SizedBox(height: 10),
              _driverField(vehicleCtrl, 'Vehicle Registration (optional)',
                  Icons.directions_car_rounded, t, optional: true, hint: 'e.g. KA 01 AB 1234'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border, width: 1.5)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: selTruck, isExpanded: true, dropdownColor: t.surface2,
                  hint: Text('Select Truck Type (optional)',
                      style: TextStyle(fontSize: 13, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily)),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: t.text, fontFamily: LeapPlatform.fontFamily),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: t.textMuted),
                  items: [
                    if (originalValues.containsKey(AppConstants.remarkTruckType))
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text('— Clear truck type —', style: TextStyle(
                            fontSize: 13, color: t.textMuted,
                            fontStyle: FontStyle.italic,
                            fontFamily: LeapPlatform.fontFamily)),
                      ),
                    ...AppConstants.truckTypes.map((tt) => DropdownMenuItem(value: tt,
                      child: Text(tt, style: TextStyle(fontFamily: LeapPlatform.fontFamily,
                          color: t.text)))),
                  ],
                  onChanged: submitting ? null : (v) => setModal(() => selTruck = v == '' ? null : v),
                )),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: t.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.primary.withValues(alpha: 0.15))),
                child: Row(children: [
                  Icon(Icons.sms_outlined, size: 13, color: t.primary),
                  const SizedBox(width: 7),
                  Expanded(child: Text('Driver will receive an SMS with shipment details',
                      style: TextStyle(fontSize: 11, color: t.primary,
                          fontWeight: FontWeight.w500, fontFamily: LeapPlatform.fontFamily))),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    final fields = <String, String>{
                      if (phoneCtrl.text.trim().isNotEmpty)
                        AppConstants.remarkDriverPhone: phoneCtrl.text.trim(),
                      if (nameCtrl.text.trim().isNotEmpty)
                        AppConstants.remarkDriverName:  nameCtrl.text.trim(),
                      if (vehicleCtrl.text.trim().isNotEmpty)
                        AppConstants.remarkVehicleReg:  vehicleCtrl.text.trim(),
                      if (selTruck != null && selTruck!.isNotEmpty)
                        AppConstants.remarkTruckType:   selTruck!,
                    };
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
                        domainName:      _shipment.domainName,
                        toClear:         toClear,
                        existingRemarks: fetchedRemarks,
                      );
                      HapticFeedback.mediumImpact();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        final nowAssigned = fields.containsKey(AppConstants.remarkDriverPhone);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            hasAnyDriver
                                ? 'Driver details updated! ✅'
                                : nowAssigned
                                    ? 'Driver assigned — SMS will be sent 🎉'
                                    : 'Details saved.',
                            style: const TextStyle(fontFamily: LeapPlatform.fontFamily),
                          ),
                          backgroundColor: t.success, behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                        _refresh();
                      }
                    } catch (e) {
                      setModal(() => submitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed: ${e.toString().replaceAll("Exception: ", "")}',
                              style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
                          backgroundColor: t.danger, behavior: SnackBarBehavior.floating));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: t.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(
                          strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Text(hasAnyDriver ? 'Update Assignment' : 'Save Assignment',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white, fontFamily: LeapPlatform.fontFamily)),
                ),
              ),
            ]),
          ),
        ),
        ),
      ),
    ).then((_) { if (mounted) setState(() => _driverSheetOpen = false); });
  }

  // ── Add cost sheet ────────────────────────────────────────────────────────
  void _showAddCostSheet() {
    final t = _t;
    final amountCtrl = TextEditingController();
    final searchCtrl = TextEditingController();

    Map<String, String>? selectedCostType;        // {xid, domainName, description}
    Map<String, String>? selectedAccessorial;     // {xid, desc, domainName}
    Map<String, String>? selectedAdjustmentReason;// {xid, description}
    List<Map<String, String>> costTypes          = [];
    List<Map<String, String>> accessorials       = [];
    List<Map<String, String>> filteredAccs       = [];
    List<Map<String, String>> adjustmentReasons  = [];
    bool loadingMeta   = true;
    bool submitting    = false;
    bool showAccSearch = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {

          // Load cost types + accessorial codes + adjustment reasons once
          if (loadingMeta && costTypes.isEmpty) {
            Future.wait([
              OtmService.fetchCostTypes(),
              OtmService.fetchAccessorialCodes(),
              OtmService.fetchAdjustmentReasons(),
            ]).then((results) {
              final cts = (results[0]).map<Map<String, String>>((e) => {
                'xid'        : e['costTypeXid']?.toString() ?? '',
                'description': e['description']?.toString() ?? '',
              }).toList();
              final acs = (results[1]).map<Map<String, String>>((e) => {
                'xid'       : e['accessorialCodeXid']?.toString() ?? '',
                'desc'      : e['accessorialDesc']?.toString() ?? '',
                'domainName': e['domainName']?.toString() ?? '',
              }).toList();
              final ars = (results[2]).map<Map<String, String>>((e) => {
                'xid'        : e['adjustmentReasonGid']?.toString() ?? '',
                'description': e['description']?.toString() ?? '',
              }).toList();
              setModal(() {
                costTypes         = cts;
                accessorials      = acs;
                filteredAccs      = acs;
                adjustmentReasons = ars;
                loadingMeta       = false;
              });
            }).catchError((_) { setModal(() => loadingMeta = false); return null; });
          }

          void filterAccs(String q) {
            setModal(() {
              filteredAccs = q.isEmpty
                  ? accessorials
                  : accessorials.where((a) =>
                      a['desc']!.toLowerCase().contains(q.toLowerCase()) ||
                      a['xid']!.toLowerCase().contains(q.toLowerCase())).toList();
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: loadingMeta
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  : SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [

                        // Handle
                        Center(child: Container(width: 36, height: 4,
                            decoration: BoxDecoration(color: t.border,
                                borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 16),

                        // Title
                        Row(children: [
                          Icon(Icons.receipt_long_rounded, size: 22, color: t.primary),
                          const SizedBox(width: 10),
                          Text('Add Cost', style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w800, color: t.text,
                              fontFamily: LeapPlatform.fontFamily)),
                        ]),
                        const SizedBox(height: 16),

                        // ── Cost Type dropdown ────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: t.surface3,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border, width: 1.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, String>>(
                              value: selectedCostType,
                              isExpanded: true,
                              hint: Row(children: [
                                Icon(Icons.category_rounded, size: 16, color: t.textMuted),
                                const SizedBox(width: 8),
                                Text('Select Cost Type', style: TextStyle(
                                    fontSize: 13, color: t.textMuted,
                                    fontFamily: LeapPlatform.fontFamily)),
                              ]),
                              dropdownColor: t.surface2,
                              style: TextStyle(fontSize: 13, color: t.text,
                                  fontFamily: LeapPlatform.fontFamily,
                                  fontWeight: FontWeight.w600),
                              items: costTypes.map((ct) => DropdownMenuItem(
                                value: ct,
                                child: Text('${ct['xid']} — ${ct['description']}',
                                    style: TextStyle(fontSize: 13, color: t.text,
                                        fontFamily: LeapPlatform.fontFamily)),
                              )).toList(),
                              onChanged: (val) => setModal(() {
                                selectedCostType    = val;
                                selectedAccessorial = null;
                                showAccSearch       = false;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Accessorial Code picker ───────────────────────
                        GestureDetector(
                          onTap: () => setModal(() => showAccSearch = !showAccSearch),
                          child: Container(
                            decoration: BoxDecoration(
                              color: t.surface3,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedAccessorial != null
                                    ? t.primary.withValues(alpha: 0.4) : t.border,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            child: Row(children: [
                              Icon(Icons.label_rounded, size: 16,
                                  color: selectedAccessorial != null ? t.primary : t.textMuted),
                              const SizedBox(width: 8),
                              Expanded(child: Text(
                                selectedAccessorial != null
                                    ? selectedAccessorial!['desc']!
                                    : 'Select Accessorial Code (optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedAccessorial != null ? t.text : t.textMuted,
                                  fontWeight: selectedAccessorial != null
                                      ? FontWeight.w600 : FontWeight.normal,
                                  fontFamily: LeapPlatform.fontFamily,
                                ),
                              )),
                              Icon(showAccSearch
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                                  size: 18, color: t.textMuted),
                            ]),
                          ),
                        ),

                        // ── Accessorial search + list ─────────────────────
                        if (showAccSearch) ...[
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: t.surface3,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: t.border),
                            ),
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              style: TextStyle(fontSize: 13, color: t.text,
                                  fontFamily: LeapPlatform.fontFamily),
                              decoration: InputDecoration(
                                hintText: 'Search accessorial codes...',
                                hintStyle: TextStyle(fontSize: 12, color: t.textMuted,
                                    fontFamily: LeapPlatform.fontFamily),
                                prefixIcon: Icon(Icons.search_rounded, size: 16, color: t.textMuted),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: filterAccs,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredAccs.length,
                              itemBuilder: (_, i) {
                                final a = filteredAccs[i];
                                final isSelected = selectedAccessorial?['xid'] == a['xid'] &&
                                    selectedAccessorial?['domainName'] == a['domainName'];
                                return InkWell(
                                  onTap: () {
                                    setModal(() {
                                      selectedAccessorial = a;
                                      showAccSearch       = false;
                                      searchCtrl.clear();
                                      filteredAccs        = accessorials;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? t.primary.withValues(alpha: 0.08) : Colors.transparent,
                                      border: Border(bottom: BorderSide(color: t.border)),
                                    ),
                                    child: Row(children: [
                                      Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(a['desc']!, style: TextStyle(fontSize: 12,
                                            fontWeight: FontWeight.w600, color: t.text,
                                            fontFamily: LeapPlatform.fontFamily)),
                                        Text(a['domainName']!, style: TextStyle(fontSize: 10,
                                            color: t.textMuted,
                                            fontFamily: LeapPlatform.fontFamily)),
                                      ])),
                                      if (isSelected)
                                        Icon(Icons.check_rounded, size: 16, color: t.primary),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // ── Adjustment Reason dropdown ────────────────────
                        if (adjustmentReasons.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: t.surface3,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: t.border, width: 1.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, String>>(
                                value: selectedAdjustmentReason,
                                isExpanded: true,
                                hint: Row(children: [
                                  Icon(Icons.edit_note_rounded, size: 16, color: t.textMuted),
                                  const SizedBox(width: 8),
                                  Text('Adjustment Reason (optional)', style: TextStyle(
                                      fontSize: 13, color: t.textMuted,
                                      fontFamily: LeapPlatform.fontFamily)),
                                ]),
                                dropdownColor: t.surface2,
                                style: TextStyle(fontSize: 13, color: t.text,
                                    fontFamily: LeapPlatform.fontFamily,
                                    fontWeight: FontWeight.w600),
                                items: [
                                  DropdownMenuItem<Map<String, String>>(
                                    value: null,
                                    child: Text('None', style: TextStyle(
                                        fontSize: 13, color: t.textMuted,
                                        fontFamily: LeapPlatform.fontFamily)),
                                  ),
                                  ...adjustmentReasons.map((ar) => DropdownMenuItem(
                                    value: ar,
                                    child: Text(ar['description']!.isNotEmpty
                                        ? ar['description']! : ar['xid']!,
                                        style: TextStyle(fontSize: 13, color: t.text,
                                            fontFamily: LeapPlatform.fontFamily)),
                                  )),
                                ],
                                onChanged: (val) => setModal(() => selectedAdjustmentReason = val),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // ── Amount ────────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: t.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border, width: 1.5),
                          ),
                          child: TextField(
                            controller: amountCtrl,
                            autofocus: false,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                color: t.text, fontFamily: LeapPlatform.fontFamily),
                            decoration: InputDecoration(
                              labelText: 'Amount (${_shipment.currency})',
                              labelStyle: TextStyle(fontSize: 13, color: t.textMuted,
                                  fontFamily: LeapPlatform.fontFamily),
                              prefixText: '${_currencySymbol(_shipment.currency)} ',
                              prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                  color: t.success, fontFamily: LeapPlatform.fontFamily),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Submit ────────────────────────────────────────
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: submitting ? null : () async {
                              final amount = double.tryParse(amountCtrl.text.trim());

                              // ── Debug: log what the user has filled in ──
                              if (kDebugMode) {
                                dev.log(
                                '[AddCost] Save tapped:\n'
                                '  selectedCostType   : $selectedCostType\n'
                                '  selectedAccessorial: $selectedAccessorial\n'
                                '  adjustmentReason   : $selectedAdjustmentReason\n'
                                '  amountRaw          : "${amountCtrl.text.trim()}"\n'
                                '  amountParsed       : $amount\n'
                                '  currency           : ${_shipment.currency}\n'
                                '  shipmentGid        : ${_shipment.domainName}.${_shipment.bareXid}',
                                name: 'ShipmentDetailScreen',
                                );
                              }

                              if (selectedCostType == null || amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Please select a cost type and enter a valid amount')));
                                return;
                              }
                              setModal(() => submitting = true);
                              try {
                                final accDomain = selectedAccessorial?['domainName'] ?? '';
                                final accXid    = selectedAccessorial?['xid'] ?? '';
                                final accGid = selectedAccessorial != null
                                    ? (accDomain.toUpperCase() == 'PUBLIC' || accDomain.isEmpty
                                        ? accXid
                                        : '$accDomain.$accXid')
                                    : null;
                                final costType = selectedCostType!['xid']!;
                                if (kDebugMode) {
                                  dev.log(
                                  '[AddCost] Posting payload to OTM:\n'
                                  '  shipmentGid        : ${_shipment.domainName}.${_shipment.bareXid}\n'
                                  '  costType           : $costType\n'
                                  '  accessorialCodeGid : $accGid\n'
                                  '  adjustmentReasonGid: ${selectedAdjustmentReason?['xid']}\n'
                                  '  amount             : $amount\n'
                                  '  currency           : ${_shipment.currency}',
                                  name: 'ShipmentDetailScreen',
                                  );
                                }
                                await OtmService.addCost(
                                  shipmentGid      : '${_shipment.domainName}.${_shipment.bareXid}',
                                  costType         : costType,
                                  accessorialCodeGid: accGid,
                                  adjustmentReasonGid: selectedAdjustmentReason?['xid'],
                                  amount           : amount,
                                  currency         : _shipment.currency,
                                );
                                HapticFeedback.mediumImpact();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('✅ Cost added successfully',
                                        style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                                    backgroundColor: t.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ));
                                  setState(() { _costsLoaded = false; _costs = []; });
                                  _fetchCostsIfNeeded();
                                }
                              } catch (e) {
                                if (kDebugMode) {
                                  dev.log(
                                  '[AddCost] ❌ Failed: $e',
                                  name: 'ShipmentDetailScreen',
                                  error: e,
                                  );
                                }
                                setModal(() => submitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
                                      backgroundColor: t.danger));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: submitting
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : const Text('Add Cost', style: TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w700, color: Colors.white,
                                    fontFamily: LeapPlatform.fontFamily)),
                          ),
                        ),
                      ]),
                    ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
      : v.toStringAsFixed(2);

  String _costTypeLabel(String? code) {
    switch (code) {
      case 'B': return 'Base';
      case 'A': return 'Accessorial';
      case 'O': return 'Other';
      case 'D': return 'Discount';
      case 'S': return 'Stop-off';
      case 'C': return 'Circuity';
      case 'L': return 'Delta';
      default:  return code ?? 'Cost';
    }
  }

  Widget _driverField(TextEditingController ctrl, String label, IconData icon,
      AppThemeData t, {bool optional = false, String? hint, TextInputType? keyboardType}) =>
    Container(
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border, width: 1.5)),
      child: TextField(controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: t.text, fontFamily: LeapPlatform.fontFamily),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: TextStyle(fontSize: 13, color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
          hintStyle:  TextStyle(fontSize: 12, color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
          prefixIcon: Icon(icon, color: optional ? t.textMuted : t.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        ),
      ),
    );

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    final s = _shipment;

    return Scaffold(
      backgroundColor: t.surface1,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: t.primary,
        child: CustomScrollView(
          slivers: [

            // ── Collapsing header ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: t.navColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Builder(
                  builder: (ctx) {
                    // kToolbarHeight = back button row, padding.top = status bar
                    final topPad = MediaQuery.of(ctx).padding.top + kToolbarHeight;
                    return Container(
                      color: t.navColor,
                      padding: EdgeInsets.fromLTRB(16, topPad, 16, 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('SHIPMENT', style: TextStyle(fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w700, letterSpacing: 1.5,
                              fontFamily: LeapPlatform.fontFamily)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: t.success.withValues(alpha: 0.4)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 6, height: 6,
                                  decoration: BoxDecoration(color: t.success, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text('IN PROGRESS', style: TextStyle(fontSize: 9,
                                  color: t.success, fontWeight: FontWeight.w700,
                                  fontFamily: LeapPlatform.fontFamily)),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text('#${s.displayId}', style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -0.5,
                            fontFamily: LeapPlatform.fontFamily)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.trip_origin_rounded, size: 11,
                              color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 5),
                          Expanded(child: Text(
                            '${s.source.displayName}  →  ${s.dest.displayName}',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600, fontFamily: LeapPlatform.fontFamily),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
            ),

            // ── Four action pills: Driver / Documents / Tracking / Costs ──
            SliverToBoxAdapter(child: _buildActionPillsBar(s, t)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // ── Load information — always visible compact strip ─────
                _buildLoadInfoStrip(s, t),
                const SizedBox(height: 10),

                // ── Stop timeline ──────────────────────────────────────
                _buildStopTimelineCollapsible(s, t),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  // ── Load info strip — always visible, compact chip layout ────────────────
  Widget _buildLoadInfoStrip(CarrierShipment s, AppThemeData t) {
    final sym      = _currencySymbol(s.currency);
    final startStr = s.startTime != null ? DateFormat('dd MMM · HH:mm').format(s.startTime!.toLocal()) : '—';
    final endStr   = s.endTime   != null ? DateFormat('dd MMM · HH:mm').format(s.endTime!.toLocal())   : '—';
    final stopCount = s.numStops > 0 ? s.numStops : s.stops.length;

    return Container(
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Section header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Text('LOAD INFORMATION', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: t.textMuted, letterSpacing: 0.5,
              fontFamily: LeapPlatform.fontFamily)),
        ),

        // ── RATE — full-width highlight if available ────────────────────
        if (s.marketCost != null)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.success.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(Icons.payments_rounded, size: 16, color: t.success),
              const SizedBox(width: 8),
              Text('AGREED RATE', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: t.success, letterSpacing: 0.3,
                  fontFamily: LeapPlatform.fontFamily)),
              const Spacer(),
              Text('$sym ${_fmt(s.marketCost!)}', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: t.success, fontFamily: LeapPlatform.fontFamily)),
            ]),
          ),

        // ── 2-column grid ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(children: [
            // Row 1: Start / End
            Row(children: [
              Expanded(child: _infoCell('START', startStr, t)),
              const SizedBox(width: 8),
              Expanded(child: _infoCell('END', endStr, t)),
            ]),
            const SizedBox(height: 8),
            // Row 2: Weight / Stops
            Row(children: [
              Expanded(child: _infoCell(
                'WEIGHT',
                s.totalWeight != null ? s.totalWeight!.display : '—',
                t,
              )),
              const SizedBox(width: 8),
              Expanded(child: _infoCell('STOPS', '$stopCount', t)),
            ]),
            // Row 3: Actual cost (only if present)
            if (s.totalActualCost != null) ...[
              const SizedBox(height: 8),
              _infoCell(
                'ACTUAL COST',
                '$sym ${_fmt(s.totalActualCost!)}',
                t,
                valueColor: t.primary,
                fullWidth: true,
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _infoCell(String label, String value, AppThemeData t,
      {Color? valueColor, bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface3,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
            fontSize: 9, color: t.textMuted,
            fontWeight: FontWeight.w600, letterSpacing: 0.3,
            fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: valueColor ?? t.text,
            fontFamily: LeapPlatform.fontFamily)),
      ]),
    );
  }

  // ── Stop timeline collapsible wrapper ────────────────────────────────────
  Widget _buildStopTimelineCollapsible(CarrierShipment s, AppThemeData t) {
    final doneCount = s.stops.where((st) => st.isCompleted).length;
    final summary   = s.stops.isEmpty
        ? 'No stops'
        : '$doneCount / ${s.stops.length} stops completed';
    return _collapsibleCard('STOP TIMELINE', t,
      expanded: _stopsExpanded,
      onToggle: () => setState(() => _stopsExpanded = !_stopsExpanded),
      summary: summary,
      action: _loadingEvents
        ? SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: t.primary))
        : Text('${_events.length} event${_events.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 10, color: t.textMuted,
                fontWeight: FontWeight.w600, fontFamily: LeapPlatform.fontFamily)),
      child: _buildStopTimeline(s, t),
    );
  }


  // ── Four action pills bar ─────────────────────────────────────────────────
  Widget _buildActionPillsBar(CarrierShipment s, AppThemeData t) {
    final pills = [
      _PillData(
        icon: Icons.person_rounded,
        label: 'Driver',
        sublabel: s.hasDriverAssigned
            ? (s.driverName ?? s.driverPhone ?? 'Assigned')
            : 'Unassigned',
        color: t.primary,
        hasAlert: !s.hasDriverAssigned,
        onTap: _showDriverSheet,
      ),
      _PillData(
        icon: Icons.insert_drive_file_rounded,
        label: 'Documents',
        sublabel: _uploadedDocs.isEmpty ? 'None uploaded' : '${_uploadedDocs.length} uploaded',
        color: const Color(0xFF7C3AED),
        hasAlert: _uploadedDocs.isEmpty,
        onTap: _showDocsSheet,
      ),
      _PillData(
        icon: Icons.route_rounded,
        label: 'Tracking',
        sublabel: _loadingEvents ? 'Loading…' : '${_events.length} event${_events.length == 1 ? '' : 's'}',
        color: t.success,
        hasAlert: false,
        onTap: _showTrackingSheet,
      ),
      _PillData(
        icon: Icons.receipt_long_rounded,
        label: 'Costs',
        sublabel: _costsLoaded ? '${_costs.length} recorded' : 'Tap to view',
        color: const Color(0xFFF59E0B),
        hasAlert: false,
        onTap: _showCostsSheet,
      ),
    ];

    return Container(
      color: t.surface2,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: pills.map((p) {
          final isLast = p == pills.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: GestureDetector(
                onTap: p.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: p.hasAlert
                          ? t.warning.withValues(alpha: 0.5)
                          : p.color.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: p.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(p.icon, size: 16, color: p.color),
                      ),
                      if (p.hasAlert)
                        Positioned(
                          top: -2, right: -2,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: t.warning,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.surface2, width: 1.5),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    Text(p.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: t.text, fontFamily: LeapPlatform.fontFamily),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(p.sublabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w500,
                            color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tracking bottom sheet ─────────────────────────────────────────────────
  void _showTrackingSheet() {
    final t = _t;
    final s = _shipment;

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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle + header
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: t.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route_rounded, size: 18, color: t.success),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tracking Events', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: t.text,
                  fontFamily: LeapPlatform.fontFamily)),
              Text('Shipment #${s.displayId}', style: TextStyle(fontSize: 11,
                  color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
            ])),
            if (_loadingEvents)
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: t.success))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('${_events.length} event${_events.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 10, color: t.success,
                        fontWeight: FontWeight.w700, fontFamily: LeapPlatform.fontFamily)),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEventScreen(shipment: _shipment, loggedEvents: _events),
                  ),
                );
                // Refresh events after returning
                if (mounted) { _fetchEvents(); }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: t.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: t.success.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 14, color: t.success),
                  const SizedBox(width: 4),
                  Text('Add Event', style: TextStyle(fontSize: 11, color: t.success,
                      fontWeight: FontWeight.w700,
                      fontFamily: LeapPlatform.fontFamily)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: t.border),
          // Scrollable content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: _loadingEvents
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : _events.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.location_off_rounded, size: 40,
                              color: t.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No tracking events yet',
                              style: TextStyle(fontSize: 14, color: t.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: LeapPlatform.fontFamily)),
                        ])),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final e = _events[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: t.surface3,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: t.border),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_eventIcon(e.statusCodeGid),
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: t.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(e.statusCodeGid,
                                        style: TextStyle(fontSize: 9, color: t.success,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace')),
                                  ),
                                  if (e.eventDate != null) ...[
                                    const Spacer(),
                                    Text(DateFormat('dd MMM · HH:mm').format(e.eventDate!.toLocal()),
                                        style: TextStyle(fontSize: 10, color: t.textMuted,
                                            fontFamily: LeapPlatform.fontFamily)),
                                  ],
                                ]),
                                const SizedBox(height: 4),
                                Text(_eventLabel(e.statusCodeGid),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                        color: t.text, fontFamily: LeapPlatform.fontFamily)),
                              ])),
                            ]),
                          );
                        },
                      ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ]),
      ),
    );
  }

  // ── Costs bottom sheet ────────────────────────────────────────────────────
  void _showCostsSheet() {
    final t = _t;
    final s = _shipment;

    // ValueNotifier lets the sheet rebuild when parent setState fires
    final notifier = ValueNotifier<int>(0);
    if (!_costsLoaded && !_loadingCosts) {
      _fetchCostsIfNeeded().then((_) { if (mounted) notifier.value++; });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (ctx, __, ___) => Container(
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle + header
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 18,
                    color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Costs', style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: t.text,
                    fontFamily: LeapPlatform.fontFamily)),
                Text('Shipment #${s.displayId}', style: TextStyle(fontSize: 11,
                    color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
              ])),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); _showAddCostSheet(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: t.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: t.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 14, color: t.success),
                    const SizedBox(width: 4),
                    Text('Add Cost', style: TextStyle(fontSize: 11, color: t.success,
                        fontWeight: FontWeight.w700,
                        fontFamily: LeapPlatform.fontFamily)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: t.border),
            // Content
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: _loadingCosts
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  : _costs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.receipt_outlined, size: 40,
                                color: t.textMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('No costs recorded yet',
                                style: TextStyle(fontSize: 14, color: t.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: LeapPlatform.fontFamily)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () { Navigator.pop(ctx); _showAddCostSheet(); },
                              child: Text('+ Add a cost',
                                  style: TextStyle(fontSize: 13, color: t.success,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: LeapPlatform.fontFamily)),
                            ),
                          ])))
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                      itemCount: _costs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final c       = _costs[i] as Map<String, dynamic>;
                        final codeGid = c['accessorialCodeGid']?.toString();
                        final typeName = codeGid != null
                            ? (codeGid.contains('.') ? codeGid.split('.').last : codeGid)
                            : _costTypeLabel(c['costType']?.toString());
                        final val    = c['cost']?['value'];
                        final curr   = (c['cost']?['currency'] ?? s.currency) as String;
                        final desc   = c['description']?.toString();
                        final status = c['costStatus']?.toString() ?? '';
                        final costXid = c['costXid']?.toString() ?? '';
                        return _CostItemTile(
                          key: ValueKey('cost_${i}_$costXid'),
                          typeName: typeName,
                          description: desc,
                          status: status,
                          initialAmount: val != null ? (val as num).toDouble() : null,
                          currency: curr,
                          costXid: costXid,
                          shipmentGid: '${s.domainName}.${s.bareXid}',
                          theme: t,
                          currencySymbol: _currencySymbol(curr),
                          fmt: _fmt,
                          onUpdated: (newAmt) {
                            setState(() {
                              c['cost'] = {'value': newAmt, 'currency': curr};
                            });
                            notifier.value++;
                          },
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ]),
        ),
      ),
    ).then((_) => notifier.dispose());
  }

  // ── Docs bottom sheet ─────────────────────────────────────────────────────
  void _showDocsSheet() {
    if (_docsSheetOpen) { Navigator.of(context).pop(); return; }
    setState(() => _docsSheetOpen = true);
    final s = _shipment;
    final t = _t;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setModal) {
        final deliveryStops = s.stops
            .where((st) => st.stopType?.toUpperCase() == 'D')
            .toList();

        final podDocs = deliveryStops.isEmpty || deliveryStops.length == 1
            ? [{'key': 'pod', 'icon': '✍️', 'name': 'POD (Signed)', 'req': true}]
            : deliveryStops.map((st) => {
                'key':  'pod_stop_${st.stopSequence}',
                'icon': '✍️',
                'name': 'POD — Stop ${st.stopSequence}',
                'req':  true,
              }).toList();

        final otherDocs = <Map<String, Object>>[
          {'key': 'eway',    'icon': '📄', 'name': 'e-Way Bill',   'req': false},
          {'key': 'invoice', 'icon': '🧾', 'name': 'Invoice Copy', 'req': false},
          {'key': 'damage',  'icon': '📸', 'name': 'Damage Photo', 'req': false},
        ];

        final allDocs = [...podDocs, ...otherDocs];

        return Container(
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.insert_drive_file_rounded, size: 20,
                  color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text('Documents', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: t.text,
                  fontFamily: LeapPlatform.fontFamily)),
              const Spacer(),
              Text('${_uploadedDocs.length} / ${allDocs.length} uploaded',
                  style: TextStyle(fontSize: 11, color: t.textMuted,
                      fontWeight: FontWeight.w600,
                      fontFamily: LeapPlatform.fontFamily)),
            ]),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: t.border),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(children: allDocs.map((doc) {
                final key    = doc['key'] as String;
                final isDone = _uploadedDocs.contains(key);
                final isReq  = doc['req'] as bool;
                final isLast = doc == allDocs.last;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    border: !isLast ? Border(bottom: BorderSide(color: t.border)) : null,
                  ),
                  child: Row(children: [
                    Text(doc['icon'] as String, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(doc['name'] as String,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: t.text, fontFamily: LeapPlatform.fontFamily)),
                      Text(isDone ? 'Uploaded ✓' : isReq ? 'Required' : 'Optional',
                          style: TextStyle(fontSize: 10,
                              color: isDone ? t.success : isReq ? t.danger : t.textMuted,
                              fontWeight: FontWeight.w500,
                              fontFamily: LeapPlatform.fontFamily)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDone ? t.success.withValues(alpha: 0.1)
                            : isReq ? t.danger.withValues(alpha: 0.08) : t.surface3,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDone ? t.success.withValues(alpha: 0.4)
                              : isReq ? t.danger.withValues(alpha: 0.3) : t.border),
                      ),
                      child: Text(isDone ? '✓ Done' : isReq ? 'Required' : 'Optional',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                              color: isDone ? t.success : isReq ? t.danger : t.textMuted,
                              fontFamily: LeapPlatform.fontFamily)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isDone ? null : () async {
                        Navigator.pop(context);
                        await _openPodUpload(key, doc['name'] as String);
                        setModal(() {}); // rebuild sheet if reopened
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: isDone ? t.success : const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : const Icon(Icons.add_rounded,   color: Colors.white, size: 18)),
                      ),
                    ),
                  ]),
                );
              }).toList()),
            ),
          ]),
        );
      }),
    ).then((_) { if (mounted) setState(() => _docsSheetOpen = false); });
  }

  // Navigate to PodUploadScreen and record the result
  Future<void> _openPodUpload(String docKey, String docLabel) async {
    final shipmentGid = '${_shipment.domainName}.${_shipment.bareXid}';
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PodUploadScreen(
          shipmentGid: shipmentGid,
          docKey:      docKey,
          docLabel:    docLabel,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _uploadedDocs.add(docKey));
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ $docLabel uploaded successfully',
            style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
        backgroundColor: _t.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Collapsible section card ──────────────────────────────────────────────
  Widget _collapsibleCard(String title, AppThemeData t, {
    required Widget child,
    required bool expanded,
    required VoidCallback onToggle,
    String? summary,
    Widget? action,
  }) =>
    Container(
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: onToggle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: t.textMuted, letterSpacing: 0.5,
                    fontFamily: LeapPlatform.fontFamily)),
                if (!expanded && summary != null) ...[
                  const SizedBox(height: 2),
                  Text(summary, style: TextStyle(fontSize: 11, color: t.textSecondary,
                      fontWeight: FontWeight.w600, fontFamily: LeapPlatform.fontFamily),
                      overflow: TextOverflow.ellipsis),
                ],
              ])),
              if (action != null) ...[action, const SizedBox(width: 8)],
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: t.textMuted, size: 20),
              ),
            ]),
          ),
        ),
        if (expanded) ...[
          Divider(height: 1, color: t.border),
          child,
        ],
      ]),
    );


  // ── Stop timeline ─────────────────────────────────────────────────────────
  Widget _buildStopTimeline(CarrierShipment s, AppThemeData t) {
    if (_loadingEvents) {
      return const Padding(padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (s.stops.isEmpty) {
      return Padding(padding: const EdgeInsets.all(16),
          child: Text('No stop data available.',
              style: TextStyle(fontSize: 12, color: t.textMuted,
                  fontFamily: LeapPlatform.fontFamily)));
    }
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...List.generate(s.stops.length, (i) {
          final stop     = s.stops[i];
          final isLast   = i == s.stops.length - 1;
          final isDone   = stop.isCompleted;
          final isActive = !isDone && (i == 0 || s.stops[i - 1].isCompleted);
          final isPU     = stop.stopType?.toUpperCase() == 'P' || stop.stopType?.toUpperCase() == 'PU';
          final isDel    = stop.stopType?.toUpperCase() == 'D';
          final nodeColor = isDone ? t.primary : isActive ? t.success : t.border;
          final nodeFg    = isDone ? t.primary : isActive ? t.success : t.textMuted;
          final typeBg    = isPU ? t.success.withValues(alpha: 0.12) : isDel ? t.danger.withValues(alpha: 0.12) : t.surface3;
          final typeFg    = isPU ? t.success : isDel ? t.danger : t.textMuted;
          final typeLabel = isPU ? 'Pickup' : isDel ? 'Delivery' : 'Stop';
          final schedStr  = stop.scheduledArrival != null
              ? DateFormat('dd MMM · HH:mm').format(stop.scheduledArrival!.toLocal()) : '—';

                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Node + connector
                  SizedBox(width: 32, child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? t.primary.withValues(alpha: 0.12)
                            : isActive ? t.success.withValues(alpha: 0.1) : t.border.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: nodeColor, width: isActive ? 2 : 1),
                      ),
                      child: Center(child: isDone
                          ? Icon(Icons.check_rounded, size: 14, color: t.primary)
                          : Text('${i + 1}', style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w800, color: nodeFg,
                              fontFamily: LeapPlatform.fontFamily))),
                    ),
                    if (!isLast)
                      Container(width: 2,
                        height: 32,
                        color: isDone ? t.primary.withValues(alpha: 0.3) : t.border,
                        margin: const EdgeInsets.symmetric(vertical: 3)),
                  ])),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(100)),
                          child: Text(typeLabel, style: TextStyle(fontSize: 8,
                              fontWeight: FontWeight.w700, color: typeFg,
                              fontFamily: LeapPlatform.fontFamily)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDone ? t.primary.withValues(alpha: 0.1)
                                : isActive ? t.success.withValues(alpha: 0.08) : t.border.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(isDone ? '✓ Done' : isActive ? '⏳ Active' : 'Pending',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                  color: isDone ? t.primary : isActive ? t.success : t.textMuted,
                                  fontFamily: LeapPlatform.fontFamily)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(stop.displayName, style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: t.text,
                          fontFamily: LeapPlatform.fontFamily)),
                      const SizedBox(height: 2),
                      // Scheduled time
                      Row(children: [
                        Icon(Icons.schedule_rounded, size: 10, color: t.textMuted),
                        const SizedBox(width: 4),
                        Text('Scheduled: $schedStr', style: TextStyle(fontSize: 10,
                            color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
                      ]),
                    ]),
                  )),
                ]);
        }),
      ]),
    );
  }

  String _eventIcon(String code) {
    switch (code) {
      case 'X3': return '📦';
      case 'AF': return '🚀';
      case 'X1': return '📍';
      case 'CD': return '✅';
      case 'X6': return '📡';
      default:   return '•';
    }
  }

  String _eventLabel(String code) {
    switch (code) {
      case 'X3': return 'Arrived at Pick-up Location';
      case 'AF': return 'Actual Pickup';
      case 'X1': return 'Arrived at Delivery Location';
      case 'CD': return 'Carrier Departed Delivery Location';
      default:   return code;
    }
  }
}

// ── Pill data model ──────────────────────────────────────────────────────────
class _PillData {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool hasAlert;
  final VoidCallback onTap;

  const _PillData({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.hasAlert,
    required this.onTap,
  });
}
// ── Cost item tile with inline edit ──────────────────────────────────────────
class _CostItemTile extends StatefulWidget {
  final String typeName;
  final String? description;
  final String status;
  final double? initialAmount;
  final String currency;
  final String currencySymbol;
  final String costXid;
  final String shipmentGid;
  final dynamic theme;           // AppThemeData
  final String Function(double) fmt;
  final void Function(double newAmount) onUpdated;

  const _CostItemTile({
    super.key,
    required this.typeName,
    this.description,
    required this.status,
    required this.initialAmount,
    required this.currency,
    required this.currencySymbol,
    required this.costXid,
    required this.shipmentGid,
    required this.theme,
    required this.fmt,
    required this.onUpdated,
  });

  @override
  State<_CostItemTile> createState() => _CostItemTileState();
}

class _CostItemTileState extends State<_CostItemTile> {
  bool _editing    = false;
  bool _submitting = false;
  late double? _amount;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
    _ctrl = TextEditingController(
      text: _amount != null ? _amount!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final newAmt = double.tryParse(_ctrl.text.trim());
    if (newAmt == null || newAmt <= 0) return;
    if (widget.costXid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot update: cost ID not available')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await OtmService.updateCost(
        shipmentGid: widget.shipmentGid,
        costXid    : widget.costXid,
        amount     : newAmt,
        currency   : widget.currency,
      );
      setState(() { _amount = newAmt; _editing = false; _submitting = false; });
      widget.onUpdated(newAmt);
      if (!mounted) return;
      final t = widget.theme;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Cost updated',
            style: TextStyle(fontFamily: 'PlusJakartaSans')),
        backgroundColor: t.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
          backgroundColor: widget.theme.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t   = widget.theme;
    final amt = _amount != null
        ? '${widget.currencySymbol} ${widget.fmt(_amount!)}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _editing ? t.primary.withValues(alpha: 0.4) : t.border,
          width: _editing ? 1.5 : 1.0,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Left: type + description
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.typeName, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: t.text,
                fontFamily: 'PlusJakartaSans')),
            if (widget.description != null && widget.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(widget.description!, style: TextStyle(fontSize: 11,
                  color: t.textMuted, fontFamily: 'PlusJakartaSans')),
            ],
          ])),

          // Right: amount + status OR edit button
          if (!_editing) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(amt, style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w800, color: t.success,
                  fontFamily: 'PlusJakartaSans')),
              if (widget.status.isNotEmpty)
                Text(widget.status, style: TextStyle(fontSize: 9,
                    color: t.textMuted, fontFamily: 'PlusJakartaSans')),
            ]),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, size: 12, color: t.primary),
                  const SizedBox(width: 4),
                  Text('Edit', style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: t.primary,
                      fontFamily: 'PlusJakartaSans')),
                ]),
              ),
            ),
          ],
        ]),

        // Inline edit row (shown only when editing)
        if (_editing) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: t.text, fontFamily: 'PlusJakartaSans'),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixText: '${widget.currencySymbol} ',
                  prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: t.success, fontFamily: 'PlusJakartaSans'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: t.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: t.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: t.surface2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Cancel
            GestureDetector(
              onTap: () {
                _ctrl.text = _amount != null ? _amount!.toStringAsFixed(0) : '';
                setState(() => _editing = false);
              },
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: t.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded, size: 16, color: t.textMuted),
              ),
            ),
            const SizedBox(width: 6),
            // Save
            GestureDetector(
              onTap: _submitting ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _submitting
                      ? t.success.withValues(alpha: 0.5)
                      : t.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _submitting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text('Save', style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: Colors.white,
                        fontFamily: 'PlusJakartaSans')),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}