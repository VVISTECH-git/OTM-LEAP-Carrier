import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AddEventScreen — LEAP Carrier
//
// Dispatcher tool for logging tracking events against a shipment stop.
//
// Event codes are stop-type-driven:
//   • Stop type P (Pickup)   → X3 (Arrived), AF (Departed)
//   • Stop type D (Delivery) → X1 (Arrived), CD (Delivered)
//
// Already-logged events (passed in via loggedCodes) are shown greyed out
// with a "Logged" badge — visible but not selectable.
// If all events for a stop are already logged, submit is disabled.
// ═══════════════════════════════════════════════════════════════════════════════

class _EventDef {
  final String code;
  final String label;
  final Color  color;
  final Color  bgColor;
  final IconData icon;
  const _EventDef(this.code, this.label, this.color, this.bgColor, this.icon);
}

const _pickupEvents = [
  _EventDef('X3', 'Arrived at Pick-up Location', Color(0xFF1A7A4A), Color(0xFFE8F5EE), Icons.location_on_rounded),
  _EventDef('AF', 'Actual Pickup',                Color(0xFF1A7A4A), Color(0xFFE8F5EE), Icons.arrow_forward_rounded),
];

const _deliveryEvents = [
  _EventDef('X1', 'Arrived at Delivery Location',          Color(0xFF2D5BE3), Color(0xFFE8EEF8), Icons.location_on_rounded),
  _EventDef('CD', 'Carrier Departed Delivery Location',    Color(0xFF2D5BE3), Color(0xFFE8EEF8), Icons.check_circle_outline_rounded),
];

class AddEventScreen extends StatefulWidget {
  final CarrierShipment        shipment;
  final List<TrackingEventItem> loggedEvents;

  const AddEventScreen({
    super.key,
    required this.shipment,
    this.loggedEvents = const [],
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  late ShipmentStop? _selectedStop;
  String?            _selectedCode;
  DateTime           _eventDateTime = DateTime.now();
  bool               _dtExpanded    = false;
  bool               _submitting    = false;
  final _remarksCtrl = TextEditingController();

  // Codes already logged across all stops
  Set<String> get _loggedCodes =>
      widget.loggedEvents.map((e) => e.statusCodeGid).toSet();

  // Events for the currently selected stop type
  List<_EventDef> get _eventsForStop {
    if (_selectedStop == null) return [];
    final type = _selectedStop!.stopType?.toUpperCase() ?? '';
    if (type == 'P' || type == 'PU' || type == 'PICKUP') return _pickupEvents;
    if (type == 'D' || type == 'DELIVERY')               return _deliveryEvents;
    return [];
  }

  bool get _allLogged =>
      _eventsForStop.isNotEmpty &&
      _eventsForStop.every((e) => _loggedCodes.contains(e.code));

  @override
  void initState() {
    super.initState();
    // Auto-select the first incomplete stop
    final stops = widget.shipment.stops;
    if (stops.isNotEmpty) {
      _selectedStop = stops.firstWhere(
        (s) => !s.isCompleted,
        orElse: () => stops.first,
      );
    }
    _autoSelectEvent();
  }

  void _autoSelectEvent() {
    final events = _eventsForStop;
    if (events.isEmpty) { _selectedCode = null; return; }
    // Pick first event not yet logged
    final first = events.firstWhere(
      (e) => !_loggedCodes.contains(e.code),
      orElse: () => events.first,
    );
    _selectedCode = _loggedCodes.contains(first.code) ? null : first.code;
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    if (_selectedCode == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select an event'),
        backgroundColor: context.read<LeapThemeProvider>().theme.danger,
      ));
      return;
    }
    if (_selectedStop == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select a stop'),
        backgroundColor: context.read<LeapThemeProvider>().theme.danger,
      ));
      return;
    }

    final s = widget.shipment;
    try {
      await OtmService.postTrackingEvent(
        shipmentGid:   '${s.domainName}.${s.bareXid}',
        domainName:    s.domainName,
        eventCode:     _selectedCode!,
        eventDateTime: _eventDateTime,
        stopXid:       _selectedStop!.stopXid,
        remarks:       _remarksCtrl.text.trim().isEmpty
            ? null : _remarksCtrl.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$_selectedCode logged successfully',
            style: const TextStyle(fontFamily: LeapPlatform.fontFamily)),
        backgroundColor: context.read<LeapThemeProvider>().theme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
        backgroundColor: context.read<LeapThemeProvider>().theme.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    final s = widget.shipment;

    return Scaffold(
      backgroundColor: t.surface1,
      appBar: AppBar(
        backgroundColor: t.navColor,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Event',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17,
                  fontFamily: LeapPlatform.fontFamily)),
          Text('Shipment #${s.displayId}',
              style: TextStyle(fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFamily: LeapPlatform.fontFamily)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Stop selector — horizontal scrollable pills ───────────────
          if (s.stops.isNotEmpty) ...[
            _label('STOP', t),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: s.stops.map((stop) {
                  final isSelected = _selectedStop?.stopXid == stop.stopXid;
                  final isPU = stop.stopType?.toUpperCase() == 'P' ||
                      stop.stopType?.toUpperCase() == 'PU';
                  final typeColor = isPU ? const Color(0xFF1A7A4A) : const Color(0xFF2D5BE3);
                  final typeLabel = isPU ? 'Pickup' : 'Delivery';

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStop = stop;
                        _autoSelectEvent();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.primary.withValues(alpha: 0.06)
                            : t.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? t.primary : t.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? t.primary : t.surface3,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(
                            '${stop.stopSequence}',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : t.textMuted,
                              fontFamily: LeapPlatform.fontFamily,
                            ),
                          )),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          stop.displayName,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: isSelected ? t.primary : t.text,
                            fontFamily: LeapPlatform.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(typeLabel,
                            style: TextStyle(
                              fontSize: 9, color: typeColor,
                              fontWeight: FontWeight.w500,
                              fontFamily: LeapPlatform.fontFamily,
                            )),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Event list — dynamic per stop type ────────────────────────
          _label('EVENT', t),
          const SizedBox(height: 8),
          if (_eventsForStop.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Text('No events available for this stop type.',
                  style: TextStyle(fontSize: 13, color: t.textMuted,
                      fontFamily: LeapPlatform.fontFamily)),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: _eventsForStop.asMap().entries.map((entry) {
                  final i   = entry.key;
                  final ev  = entry.value;
                  final isLogged   = _loggedCodes.contains(ev.code);
                  final isSelected = _selectedCode == ev.code;
                  final isLast     = i == _eventsForStop.length - 1;

                  return GestureDetector(
                    onTap: isLogged ? null : () {
                      setState(() => _selectedCode = ev.code);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.primary.withValues(alpha: 0.05)
                            : t.surface2,
                        border: !isLast
                            ? Border(bottom: BorderSide(color: t.border))
                            : null,
                      ),
                      child: Opacity(
                        opacity: isLogged ? 0.45 : 1.0,
                        child: Row(children: [
                          // Icon
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: ev.bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(ev.icon, size: 15, color: ev.color),
                          ),
                          const SizedBox(width: 12),
                          // Label + code
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.label,
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: t.text,
                                    fontFamily: LeapPlatform.fontFamily,
                                  )),
                              const SizedBox(height: 2),
                              Text(ev.code,
                                  style: TextStyle(
                                    fontSize: 10, color: t.textMuted,
                                    fontFamily: LeapPlatform.fontFamily,
                                  )),
                            ],
                          )),
                          // Radio or logged badge
                          if (isLogged)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: t.success),
                              const SizedBox(width: 4),
                              Text('Logged',
                                  style: TextStyle(
                                    fontSize: 10, color: t.success,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: LeapPlatform.fontFamily,
                                  )),
                            ])
                          else
                            Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? t.primary : t.border,
                                  width: 2,
                                ),
                                color: isSelected ? t.primary : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Center(child: Container(
                                      width: 7, height: 7,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ))
                                  : null,
                            ),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // ── Date & time — collapsed by default ────────────────────────
          Row(children: [
            _label('DATE & TIME', t),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _dtExpanded = !_dtExpanded),
              child: Text(
                _dtExpanded ? 'Use now' : 'Change',
                style: TextStyle(fontSize: 11, color: t.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: LeapPlatform.fontFamily),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (!_dtExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Row(children: [
                Icon(Icons.access_time_rounded, size: 15, color: t.textMuted),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy · HH:mm').format(_eventDateTime),
                  style: TextStyle(fontSize: 13, color: t.text,
                      fontFamily: LeapPlatform.fontFamily),
                ),
                const SizedBox(width: 6),
                Text('(now)', style: TextStyle(fontSize: 11,
                    color: t.textMuted,
                    fontFamily: LeapPlatform.fontFamily)),
              ]),
            )
          else
            _buildDateTimePicker(t),
          const SizedBox(height: 20),

          // ── Remarks ───────────────────────────────────────────────────
          _label('REMARKS', t, optional: true),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: TextField(
              controller: _remarksCtrl,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: t.text,
                  fontFamily: LeapPlatform.fontFamily),
              decoration: InputDecoration(
                hintText: 'Add notes about this event...',
                hintStyle: TextStyle(color: t.textMuted, fontSize: 13,
                    fontFamily: LeapPlatform.fontFamily),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: (_submitting || _allLogged) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _allLogged
                    ? t.surface3 : t.primary,
                disabledBackgroundColor: _allLogged
                    ? t.surface3 : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(
                      _allLogged
                          ? 'All events logged for this stop'
                          : 'Submit Event',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _allLogged ? t.textMuted : Colors.white,
                        fontFamily: LeapPlatform.fontFamily,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildDateTimePicker(AppThemeData t) {
    return Column(children: [
      // Date row
      GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _eventDateTime,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now(),
            builder: (ctx, child) => Theme(
              data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(primary: t.primary)),
              child: child!,
            ),
          );
          if (date != null && mounted) {
            setState(() => _eventDateTime = DateTime(
              date.year, date.month, date.day,
              _eventDateTime.hour, _eventDateTime.minute,
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, size: 15, color: t.primary),
            const SizedBox(width: 8),
            Text(DateFormat('dd MMM yyyy').format(_eventDateTime),
                style: TextStyle(fontSize: 13, color: t.text,
                    fontFamily: LeapPlatform.fontFamily)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 16, color: t.textMuted),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      // Time row
      GestureDetector(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_eventDateTime),
            builder: (ctx, child) => Theme(
              data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(primary: t.primary)),
              child: child!,
            ),
          );
          if (time != null && mounted) {
            setState(() => _eventDateTime = DateTime(
              _eventDateTime.year, _eventDateTime.month, _eventDateTime.day,
              time.hour, time.minute,
            ));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Row(children: [
            Icon(Icons.access_time_rounded, size: 15, color: t.primary),
            const SizedBox(width: 8),
            Text(DateFormat('HH:mm').format(_eventDateTime),
                style: TextStyle(fontSize: 13, color: t.text,
                    fontFamily: LeapPlatform.fontFamily)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 16, color: t.textMuted),
          ]),
        ),
      ),
    ]);
  }

  Widget _label(String text, AppThemeData t, {bool optional = false}) =>
      RichText(text: TextSpan(children: [
        TextSpan(
          text: text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: t.textMuted, letterSpacing: 0.4,
              fontFamily: LeapPlatform.fontFamily),
        ),
        if (optional)
          TextSpan(
            text: '  optional',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400,
                color: t.textMuted, fontFamily: LeapPlatform.fontFamily),
          ),
      ]));
}