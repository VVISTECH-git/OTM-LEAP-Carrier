import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:leapcarrier/core/services/otm_service.dart';
import 'package:leapcarrier/core/theme/leap_theme.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// InvoicingScreen — LEAP Carrier
//
// Tab 1 (Costs/Shipments): active shipments + Add Cost + Generate Invoice
// Tab 2 (Invoices): real invoice history list from OTM
// ═══════════════════════════════════════════════════════════════════════════════

class InvoicingScreen extends StatefulWidget {
  final CarrierShipment? shipment;
  const InvoicingScreen({super.key, this.shipment});
  @override
  State<InvoicingScreen> createState() => _InvoicingScreenState();
}

class _InvoicingScreenState extends State<InvoicingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Tab 1 — shipments
  List<CarrierShipment> _shipments = [];
  bool    _loadingShipments = true;
  String? _shipmentError;
  final TextEditingController _shipmentSearchCtrl = TextEditingController();
  String _shipmentQuery = '';

  // Tab 2 — invoices
  List<dynamic> _invoices        = [];
  bool          _loadingInvoices = true;
  String?       _invoiceError;
  final TextEditingController _invoiceSearchCtrl = TextEditingController();
  String  _invoiceQuery        = '';
  String? _invoiceStatusFilter; // null = All, 'DRAFT', 'SUBMITTED', 'APPROVED'

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabCtrl.index == 1 && _invoices.isEmpty && !_loadingInvoices) {
          _fetchInvoices();
        }
      });
    _fetchShipments();
    _fetchInvoices();
  }

  @override
  void dispose() { _tabCtrl.dispose(); _shipmentSearchCtrl.dispose(); _invoiceSearchCtrl.dispose(); super.dispose(); }

  Future<void> _fetchShipments() async {
    setState(() { _loadingShipments = true; _shipmentError = null; });
    try {
      final items = await OtmService.fetchActiveShipments();
      setState(() {
        _shipments        = items;
        _loadingShipments = false;
      });
    } catch (e) {
      setState(() {
        _shipmentError    = e.toString().replaceAll('Exception: ', '');
        _loadingShipments = false;
      });
    }
  }

  Future<void> _fetchInvoices() async {
    setState(() { _loadingInvoices = true; _invoiceError = null; });
    try {
      final items = await OtmService.fetchInvoices();
      setState(() { _invoices = items; _loadingInvoices = false; });
    } catch (e) {
      setState(() {
        _invoiceError    = e.toString().replaceAll('Exception: ', '');
        _loadingInvoices = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = context.watch<LeapThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.surface1,
      appBar: AppBar(
        backgroundColor: t.navColor,
        foregroundColor: Colors.white,
        title: const Text('Invoicing',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17,
                fontFamily: LeapPlatform.fontFamily)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
              fontFamily: LeapPlatform.fontFamily),
          tabs: const [
            Tab(icon: Icon(Icons.monetization_on_outlined, size: 16), text: 'COSTS'),
            Tab(icon: Icon(Icons.receipt_long_outlined,    size: 16), text: 'INVOICES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCostsTab(t),
          _buildInvoicesTab(t),
        ],
      ),
    );
  }

  // ── Tab 1: Costs / Shipments ───────────────────────────────────────────────
  Widget _buildCostsTab(AppThemeData t) {
    if (_loadingShipments) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }
    if (_shipmentError != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('⚠️ $_shipmentError', textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _fetchShipments, child: const Text('Retry')),
      ]));
    }
    if (_shipments.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: t.textMuted),
        const SizedBox(height: 8),
        Text('No shipments for invoicing', style: TextStyle(
            color: t.textMuted, fontWeight: FontWeight.w700,
            fontFamily: LeapPlatform.fontFamily)),
      ]));
    }

    // ── Filter logic ──────────────────────────────────────────────────────────
    final q = _shipmentQuery.toLowerCase();
    final filtered = _shipments.where((s) {
      if (q.isEmpty) return true;
      return s.displayId.toLowerCase().contains(q) ||
          s.source.displayName.toLowerCase().contains(q) ||
          s.dest.displayName.toLowerCase().contains(q);
    }).toList();

    return Column(children: [

      // ── Search bar ────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: TextField(
            controller: _shipmentSearchCtrl,
            style: TextStyle(fontSize: 13, color: t.text,
                fontFamily: LeapPlatform.fontFamily),
            decoration: InputDecoration(
              hintText: 'Search by shipment ID or route…',
              hintStyle: TextStyle(fontSize: 13, color: t.textMuted,
                  fontFamily: LeapPlatform.fontFamily),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: t.textMuted),
              suffixIcon: _shipmentQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _shipmentSearchCtrl.clear();
                        setState(() => _shipmentQuery = '');
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: t.textMuted),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
            onChanged: (v) => setState(() => _shipmentQuery = v),
          ),
        ),
      ),

      // ── Results ───────────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off_rounded, size: 40, color: t.textMuted),
                const SizedBox(height: 8),
                Text('No shipments match your search',
                    style: TextStyle(color: t.textMuted, fontSize: 13,
                        fontFamily: LeapPlatform.fontFamily)),
              ]))
            : RefreshIndicator(
                onRefresh: _fetchShipments,
                color: t.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _shipmentCard(filtered[i], t),
                ),
              ),
      ),
    ]);
  }

  Widget _shipmentCard(CarrierShipment s, AppThemeData t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#${s.displayId}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: t.text, fontFamily: LeapPlatform.fontFamily)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('READY TO INVOICE',
                    style: TextStyle(fontSize: 9, color: t.info,
                        fontWeight: FontWeight.w700,
                        fontFamily: LeapPlatform.fontFamily)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('${s.source.displayName}  →  ${s.dest.displayName}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: t.text, fontFamily: LeapPlatform.fontFamily),
                overflow: TextOverflow.ellipsis),
            if (s.startTime != null) ...[
              const SizedBox(height: 4),
              Text(DateFormat('dd MMM yyyy').format(s.startTime!.toLocal()),
                  style: TextStyle(fontSize: 11, color: t.textMuted,
                      fontWeight: FontWeight.w500,
                      fontFamily: LeapPlatform.fontFamily)),
            ],
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: t.surface3,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border(top: BorderSide(color: t.border)),
          ),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _showViewCostsSheet(s, t),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.list_alt_rounded, size: 15, color: t.textMuted),
                  const SizedBox(width: 5),
                  Text('View Costs', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: t.textMuted,
                      fontFamily: LeapPlatform.fontFamily)),
                ])),
              ),
            )),
            Container(width: 1, height: 32, color: t.border),
            Expanded(child: GestureDetector(
              onTap: () => _showCostsSheet(s, t),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_circle_outline_rounded, size: 15, color: t.primary),
                  const SizedBox(width: 5),
                  Text('Add Cost', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: t.primary,
                      fontFamily: LeapPlatform.fontFamily)),
                ])),
              ),
            )),
            Container(width: 1, height: 32, color: t.border),
            Expanded(child: GestureDetector(
              onTap: () => _showGenerateInvoiceSheet(s, t),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_rounded, size: 15, color: t.success),
                  const SizedBox(width: 5),
                  Text('Generate', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: t.success,
                      fontFamily: LeapPlatform.fontFamily)),
                ])),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  // ── Tab 2: Invoice history ─────────────────────────────────────────────────
  Widget _buildInvoicesTab(AppThemeData t) {
    if (_loadingInvoices) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }
    if (_invoiceError != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('⚠️ $_invoiceError', textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _fetchInvoices, child: const Text('Retry')),
      ]));
    }
    if (_invoices.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: t.textMuted),
        const SizedBox(height: 8),
        Text('No invoices yet', style: TextStyle(
            color: t.textMuted, fontWeight: FontWeight.w700,
            fontFamily: LeapPlatform.fontFamily)),
        const SizedBox(height: 4),
        Text('Generated invoices will appear here', style: TextStyle(
            color: t.textMuted, fontSize: 12,
            fontFamily: LeapPlatform.fontFamily)),
      ]));
    }

    // ── Filter logic ──────────────────────────────────────────────────────────
    final filtered = _invoices.where((inv) {
      final invoiceXid  = (inv['invoiceXid']  ?? '').toString().toLowerCase();
      final shipmentXid = (inv['shipmentXid'] ?? '').toString().toLowerCase();
      final status      = (inv['invoiceStatus'] ?? 'DRAFT').toString().toUpperCase();
      final q           = _invoiceQuery.toLowerCase();

      final matchesQuery = q.isEmpty ||
          invoiceXid.contains(q) || shipmentXid.contains(q);
      final matchesStatus = _invoiceStatusFilter == null ||
          status == _invoiceStatusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    return Column(children: [

      // ── Search bar ────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Container(
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: TextField(
            controller: _invoiceSearchCtrl,
            style: TextStyle(fontSize: 13, color: t.text,
                fontFamily: LeapPlatform.fontFamily),
            decoration: InputDecoration(
              hintText: 'Search by invoice ID or shipment…',
              hintStyle: TextStyle(fontSize: 13, color: t.textMuted,
                  fontFamily: LeapPlatform.fontFamily),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: t.textMuted),
              suffixIcon: _invoiceQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _invoiceSearchCtrl.clear();
                        setState(() => _invoiceQuery = '');
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: t.textMuted),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
            onChanged: (v) => setState(() => _invoiceQuery = v),
          ),
        ),
      ),

      // ── Status filter chips ───────────────────────────────────────────────
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _filterChip('All',       null,         t),
            _filterChip('Draft',     'DRAFT',      t),
            _filterChip('Submitted', 'SUBMITTED',  t),
            _filterChip('Approved',  'APPROVED',   t),
          ],
        ),
      ),
      const SizedBox(height: 4),

      // ── Results ───────────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_off_rounded, size: 40, color: t.textMuted),
                const SizedBox(height: 8),
                Text('No invoices match your search',
                    style: TextStyle(color: t.textMuted, fontSize: 13,
                        fontFamily: LeapPlatform.fontFamily)),
              ]))
            : RefreshIndicator(
                onRefresh: _fetchInvoices,
                color: t.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _invoiceCard(filtered[i], t),
                ),
              ),
      ),
    ]);
  }

  Widget _filterChip(String label, String? value, AppThemeData t) {
    final selected = _invoiceStatusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _invoiceStatusFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? t.primary : t.surface2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? t.primary : t.border,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : t.textMuted,
              fontFamily: LeapPlatform.fontFamily,
            )),
      ),
    );
  }

  Widget _invoiceCard(Map<String, dynamic> inv, AppThemeData t) {
    final invoiceXid  = inv['invoiceXid']?.toString() ?? '—';
    final domainName  = inv['domainName']?.toString() ?? '';
    final invoiceGid  = domainName.isNotEmpty ? '$domainName.$invoiceXid' : invoiceXid;
    final shipmentXid = inv['shipmentXid']?.toString() ?? '';
    final status      = inv['invoiceStatus']?.toString() ?? 'DRAFT';
    final amount      = (inv['totalAmount']?['value'] as num?)?.toDouble();
    final currency    = inv['totalAmount']?['currency']?.toString() ?? '';

    DateTime? createDate;
    try {
      if (inv['createDate']?['value'] != null) {
        createDate = DateTime.parse(inv['createDate']['value']);
      }
    } catch (_) {}

    // Status config
    Color statusBg, statusFg;
    String statusLabel;
    final statusUp = status.toUpperCase();
    switch (statusUp) {
      case 'PAID':
      case 'APPROVED':
        statusBg  = t.success.withValues(alpha: 0.12);
        statusFg  = t.success;
        statusLabel = 'Paid';
        break;
      case 'SUBMITTED':
      case 'PENDING':
        statusBg  = t.info.withValues(alpha: 0.12);
        statusFg  = t.info;
        statusLabel = 'Submitted';
        break;
      default:
        statusBg  = t.textMuted.withValues(alpha: 0.10);
        statusFg  = t.textMuted;
        statusLabel = 'Draft';
    }

    final isDraft = statusUp == 'DRAFT' || statusUp == '';

    return StatefulBuilder(
      builder: (ctx, setCard) {
        bool submitting = false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Column(children: [

            // ── Info row ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Icon(Icons.receipt_rounded,
                      size: 20, color: t.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(invoiceXid,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          color: t.text, fontFamily: LeapPlatform.fontFamily)),
                  if (shipmentXid.isNotEmpty)
                    Text('Shipment #$shipmentXid',
                        style: TextStyle(fontSize: 11, color: t.textMuted,
                            fontFamily: LeapPlatform.fontFamily)),
                  if (createDate != null)
                    Text(DateFormat('dd MMM yyyy').format(createDate.toLocal()),
                        style: TextStyle(fontSize: 10, color: t.textMuted,
                            fontFamily: LeapPlatform.fontFamily)),
                ])),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (amount != null)
                    Text('$currency ${amount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                            color: t.text, fontFamily: LeapPlatform.fontFamily)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: statusFg, fontFamily: LeapPlatform.fontFamily)),
                  ),
                ]),
              ]),
            ),

            // ── Submit button — only for Draft invoices ──
            if (isDraft)
              StatefulBuilder(
                builder: (ctx2, setBtn) => Container(
                  decoration: BoxDecoration(
                    color: t.surface3,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14)),
                    border: Border(top: BorderSide(color: t.border)),
                  ),
                  child: GestureDetector(
                    onTap: submitting ? null : () async {
                      setBtn(() => submitting = true);
                      try {
                        await OtmService.submitInvoice(invoiceGid: invoiceGid);
                        // Update local status so UI reflects immediately
                        inv['invoiceStatus'] = 'SUBMITTED';
                        setCard(() {});
                        if (!ctx2.mounted) return;
                        ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(
                          content: const Text('✅ Invoice submitted for approval',
                              style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                          backgroundColor: t.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                      } catch (e) {
                        setBtn(() => submitting = false);
                        if (!ctx2.mounted) return;
                        ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(
                            content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
                            backgroundColor: t.danger));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Center(child: submitting
                          ? SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: t.info))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.send_rounded, size: 15, color: t.info),
                              const SizedBox(width: 5),
                              Text('Submit to Shipper',
                                  style: TextStyle(fontSize: 12,
                                      fontWeight: FontWeight.w700, color: t.info,
                                      fontFamily: LeapPlatform.fontFamily)),
                            ])),
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  // ── View Costs sheet ───────────────────────────────────────────────────────
  void _showViewCostsSheet(CarrierShipment s, AppThemeData t) {
    List<Map<String, dynamic>> costs = [];
    bool loading = true;
    bool fetched = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          if (!fetched) {
            fetched = true;
            OtmService.fetchCosts('${s.domainName}.${s.bareXid}').then((items) {
              setModal(() {
                costs   = items.whereType<Map<String, dynamic>>().toList();
                loading = false;
              });
            }).catchError((_) {
              setModal(() => loading = false);
              return null;
            });
          }

          final total = costs.fold<double>(
              0.0, (sum, c) => sum + ((c['cost']?['value'] as num?)?.toDouble() ?? 0));

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: t.border,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),

                Row(children: [
                  Icon(Icons.list_alt_rounded, size: 22, color: t.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Costs', style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w800, color: t.text,
                        fontFamily: LeapPlatform.fontFamily)),
                    Text('Shipment #${s.displayId} · ${s.source.displayName} → ${s.dest.displayName}',
                        style: TextStyle(fontSize: 11, color: t.textMuted,
                            fontFamily: LeapPlatform.fontFamily),
                        overflow: TextOverflow.ellipsis),
                  ])),
                ]),
                const SizedBox(height: 14),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (costs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_outlined, size: 40, color: t.textMuted),
                      const SizedBox(height: 8),
                      Text('No costs added yet', style: TextStyle(
                          color: t.textMuted, fontWeight: FontWeight.w700,
                          fontFamily: LeapPlatform.fontFamily)),
                      const SizedBox(height: 4),
                      Text('Tap "Add Cost" to add the first entry.',
                          style: TextStyle(color: t.textMuted, fontSize: 12,
                              fontFamily: LeapPlatform.fontFamily)),
                    ]),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 4),
                      itemCount: costs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _costRow(costs[i], s, t, setModal),
                    ),
                  ),

                if (!loading && costs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(children: [
                      Text('Total', style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800, color: t.text,
                          fontFamily: LeapPlatform.fontFamily)),
                      const Spacer(),
                      Text('${s.currency.isNotEmpty ? s.currency : 'USD'} ${total.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: t.primary, fontFamily: LeapPlatform.fontFamily)),
                    ]),
                  ),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _costRow(
    Map<String, dynamic> cost,
    CarrierShipment s,
    AppThemeData t,
    StateSetter setModal,
  ) {
    final rawType   = cost['costType']?.toString() ?? '—';
    final codeGid   = cost['accessorialCodeGid']?.toString();
    final bareType  = rawType.contains('.') ? rawType.split('.').last : rawType;
    final typeLabel = codeGid != null
        ? (codeGid.contains('.') ? codeGid.split('.').last : codeGid)
        : _costTypeLabel(bareType);
    final currency  = (cost['cost']?['currency'] as String?)
        ?? (s.currency.isNotEmpty ? s.currency : 'USD');
    final costXid   = cost['costXid']?.toString() ?? '';
    final sym       = _currencySymbol(currency);

    bool   editing    = false;
    bool   submitting = false;
    double currentAmt = (cost['cost']?['value'] as num?)?.toDouble() ?? 0.0;
    final  ctrl       = TextEditingController(
        text: currentAmt == currentAmt.truncateToDouble()
            ? currentAmt.toStringAsFixed(0)
            : currentAmt.toStringAsFixed(2));

    return StatefulBuilder(
      builder: (ctx, setRow) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: editing ? t.primary.withValues(alpha: 0.4) : t.border,
            width: editing ? 1.5 : 1.0,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Display row: type | amount + Edit ──
          Row(children: [
            Expanded(
              child: Text(typeLabel, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: t.text,
                  fontFamily: LeapPlatform.fontFamily)),
            ),
            if (!editing) ...[ 
              Text(
                '$sym ${currentAmt == currentAmt.truncateToDouble() ? currentAmt.toStringAsFixed(0) : currentAmt.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: t.success, fontFamily: LeapPlatform.fontFamily),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setRow(() => editing = true),
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
                        fontFamily: LeapPlatform.fontFamily)),
                  ]),
                ),
              ),
            ],
          ]),

          // ── Edit row: text field + Cancel + Save ──
          if (editing) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: t.text, fontFamily: LeapPlatform.fontFamily),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixText: '$sym ',
                    prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: t.success, fontFamily: LeapPlatform.fontFamily),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: t.primary, width: 1.5)),
                    filled: true,
                    fillColor: t.surface2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ctrl.text = currentAmt == currentAmt.truncateToDouble()
                      ? currentAmt.toStringAsFixed(0)
                      : currentAmt.toStringAsFixed(2);
                  setRow(() => editing = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: t.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: t.textMuted),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: submitting ? null : () async {
                  final newAmt = double.tryParse(ctrl.text.trim());
                  if (newAmt == null || newAmt <= 0) return;
                  if (costXid.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: const Text('Cannot update: cost ID missing'),
                        backgroundColor: t.danger));
                    return;
                  }
                  setRow(() => submitting = true);
                  try {
                    await OtmService.updateCost(
                      shipmentGid: '${s.domainName}.${s.bareXid}',
                      costXid    : costXid,
                      amount     : newAmt,
                      currency   : currency,
                    );
                    cost['cost'] = {'value': newAmt, 'currency': currency};
                    currentAmt   = newAmt;
                    setRow(() { editing = false; submitting = false; });
                    setModal(() {});
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: const Text('✅ Cost updated',
                          style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                      backgroundColor: t.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  } catch (e) {
                    setRow(() => submitting = false);
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
                        backgroundColor: t.danger));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: submitting
                        ? t.success.withValues(alpha: 0.5) : t.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: submitting
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Text('Save', style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700, color: Colors.white,
                          fontFamily: LeapPlatform.fontFamily)),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  // ── Add Cost sheet — full implementation ───────────────────────────────────
  void _showCostsSheet(CarrierShipment s, AppThemeData t) {
    final amountCtrl = TextEditingController();
    final searchCtrl = TextEditingController();

    Map<String, String>? selectedCostType;
    Map<String, String>? selectedAccessorial;
    Map<String, String>? selectedAdjustmentReason;
    List<Map<String, String>> costTypes         = [];
    List<Map<String, String>> accessorials      = [];
    List<Map<String, String>> filteredAccs      = [];
    List<Map<String, String>> adjustmentReasons = [];
    bool loadingMeta   = true;
    bool submitting    = false;
    bool showAccSearch = false;
    bool metaFetched   = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          if (!metaFetched) {
            metaFetched = true;
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
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Add Cost', style: TextStyle(fontSize: 17,
                                fontWeight: FontWeight.w800, color: t.text,
                                fontFamily: LeapPlatform.fontFamily)),
                            Text('Shipment #${s.displayId} · ${s.source.displayName} → ${s.dest.displayName}',
                                style: TextStyle(fontSize: 11, color: t.textMuted,
                                    fontFamily: LeapPlatform.fontFamily),
                                overflow: TextOverflow.ellipsis),
                          ])),
                        ]),
                        const SizedBox(height: 14),

                        // ── Cost Type dropdown ─────────────────────────
                        Container(
                          decoration: BoxDecoration(color: t.surface3,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: t.border, width: 1.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, String>>(
                              value: selectedCostType,
                              isExpanded: true,
                              hint: Row(children: [
                                Icon(Icons.category_rounded, size: 16, color: t.textMuted),
                                const SizedBox(width: 8),
                                Text('Select Cost Type *', style: TextStyle(
                                    fontSize: 13, color: t.textMuted,
                                    fontFamily: LeapPlatform.fontFamily)),
                              ]),
                              dropdownColor: t.surface2,
                              style: TextStyle(fontSize: 13, color: t.text,
                                  fontFamily: LeapPlatform.fontFamily, fontWeight: FontWeight.w600),
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

                        // ── Accessorial Code picker ────────────────────
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

                        // ── Accessorial search + list ──────────────────
                        if (showAccSearch) ...[
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(color: t.surface3,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: t.border)),
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
                                  onTap: () => setModal(() {
                                    selectedAccessorial = a;
                                    showAccSearch       = false;
                                    searchCtrl.clear();
                                    filteredAccs        = accessorials;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? t.primary.withValues(alpha: 0.08) : Colors.transparent,
                                      border: Border(bottom: BorderSide(color: t.border)),
                                    ),
                                    child: Row(children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(a['desc']!, style: TextStyle(fontSize: 12,
                                            fontWeight: FontWeight.w600, color: t.text,
                                            fontFamily: LeapPlatform.fontFamily)),
                                        Text(a['domainName']!, style: TextStyle(fontSize: 10,
                                            color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
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

                        // ── Adjustment Reason dropdown ─────────────────
                        if (adjustmentReasons.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(color: t.surface3,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: t.border, width: 1.5)),
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
                                    fontFamily: LeapPlatform.fontFamily, fontWeight: FontWeight.w600),
                                items: [
                                  DropdownMenuItem<Map<String, String>>(
                                    value: null,
                                    child: Text('None', style: TextStyle(fontSize: 13,
                                        color: t.textMuted, fontFamily: LeapPlatform.fontFamily)),
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

                        // ── Amount ─────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(color: t.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: t.border, width: 1.5)),
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                color: t.text, fontFamily: LeapPlatform.fontFamily),
                            decoration: InputDecoration(
                              labelText: 'Amount (${s.currency.isNotEmpty ? s.currency : 'USD'})',
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

                        // ── Submit ─────────────────────────────────────
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: submitting ? null : () async {
                              final amount = double.tryParse(amountCtrl.text.trim());
                              if (selectedCostType == null || amount == null || amount <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                    content: Text('Please select a cost type and enter a valid amount')));
                                return;
                              }
                              setModal(() => submitting = true);
                              try {
                                final accDomain = selectedAccessorial?['domainName'] ?? '';
                                final accXid    = selectedAccessorial?['xid'] ?? '';
                                final accGid = selectedAccessorial != null
                                    ? (accDomain.toUpperCase() == 'PUBLIC' || accDomain.isEmpty
                                        ? accXid : '$accDomain.$accXid')
                                    : null;
                                await OtmService.addCost(
                                  shipmentGid        : '${s.domainName}.${s.bareXid}',
                                  costType           : selectedCostType!['xid']!,
                                  accessorialCodeGid : accGid,
                                  adjustmentReasonGid: selectedAdjustmentReason?['xid'],
                                  amount             : amount,
                                  currency           : s.currency.isNotEmpty ? s.currency : 'USD',
                                );
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: const Text('✅ Cost added successfully',
                                      style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                                  backgroundColor: t.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ));
                              } catch (e) {
                                setModal(() => submitting = false);
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
                                    backgroundColor: t.danger));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: t.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: submitting
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : const Text('Submit Cost',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                        color: Colors.white,
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

  // ── Generate Invoice sheet ─────────────────────────────────────────────────
  void _showGenerateInvoiceSheet(CarrierShipment s, AppThemeData t) {
    bool   submitting    = false;
    bool   loadingCosts  = true;
    bool   costsFetched  = false;
    double total         = 0;
    List<Map<String, dynamic>> fetchedCosts = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          // Load costs once on first open
          if (loadingCosts && !costsFetched) {
            costsFetched = true;
            OtmService.fetchCosts('${s.domainName}.${s.bareXid}').then((c) {
              final list = c.whereType<Map<String, dynamic>>().toList();
              double sum = 0;
              for (final cost in list) {
                sum += (cost['cost']?['value'] as num?)?.toDouble() ?? 0;
              }
              setModal(() {
                fetchedCosts = list;
                total        = sum;
                loadingCosts = false;
              });
            }).catchError((_) { setModal(() => loadingCosts = false); return null; });
          }

          return Container(
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20,
                MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: t.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.receipt_long_rounded, size: 22, color: t.success),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Generate Invoice',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                          fontFamily: LeapPlatform.fontFamily)),
                  Text('Shipment #${s.displayId}',
                      style: TextStyle(fontSize: 11, color: t.textMuted,
                          fontFamily: LeapPlatform.fontFamily)),
                ])),
              ]),
              const SizedBox(height: 16),

              // ── Invoice summary card ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: loadingCosts
                    ? Center(child: CircularProgressIndicator(
                        color: t.primary, strokeWidth: 2))
                    : Column(children: [
                        _invoiceRow('Shipment',  '#${s.displayId}', t),
                        _invoiceRow('Route',
                            '${s.source.displayName} → ${s.dest.displayName}', t),
                        if (s.equipment != null)
                          _invoiceRow('Mode', s.equipment!, t),
                        if (s.startTime != null)
                          _invoiceRow('Date',
                              DateFormat('dd MMM yyyy').format(s.startTime!.toLocal()), t),
                        const Divider(height: 16),
                        // Individual cost line items
                        ...fetchedCosts.map((cost) {
                          final raw   = cost['costType']?.toString() ?? '—';
                          final code  = raw.contains('.') ? raw.split('.').last : raw;
                          final label = _costTypeLabel(code);
                          final val   = (cost['cost']?['value'] as num?)?.toDouble() ?? 0.0;
                          final curr  = cost['cost']?['currency']?.toString()
                              ?? (s.currency.isNotEmpty ? s.currency : 'USD');
                          return _invoiceRow(label,
                              '$curr ${val == val.truncateToDouble() ? val.toStringAsFixed(0) : val.toStringAsFixed(2)}', t);
                        }),
                        const Divider(height: 16),
                        Row(children: [
                          Text('Total Amount',
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w800, color: t.text,
                                  fontFamily: LeapPlatform.fontFamily)),
                          const Spacer(),
                          Text('${s.currency.isNotEmpty ? s.currency : 'USD'} ${total.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w800, color: t.primary,
                                  fontFamily: LeapPlatform.fontFamily)),
                        ]),
                      ]),
              ),
              const SizedBox(height: 12),

              // ── Info banner ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: t.info.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.info.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: t.info),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Invoice will be submitted to the shipper for approval in OTM.',
                    style: TextStyle(fontSize: 11, color: t.info,
                        fontWeight: FontWeight.w500,
                        fontFamily: LeapPlatform.fontFamily),
                  )),
                ]),
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: (submitting || loadingCosts) ? null : () async {
                    setModal(() => submitting = true);
                    try {
                      await OtmService.generateInvoice(
                          shipmentGid: '${s.domainName}.${s.bareXid}',
                          costs      : fetchedCosts,
                          currency   : s.currency.isNotEmpty ? s.currency : 'USD');
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: const Text('✅ Invoice submitted for approval',
                            style: TextStyle(fontFamily: LeapPlatform.fontFamily)),
                        backgroundColor: t.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                      _fetchInvoices(); // refresh invoice tab
                    } catch (e) {
                      setModal(() => submitting = false);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'An unexpected error occurred. Please try again.'),
                          backgroundColor: t.danger));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: t.success),
                  child: submitting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Submit',
                          style: TextStyle(fontSize: 13, color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: LeapPlatform.fontFamily)),
                )),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _costTypeLabel(String? code) {
    switch (code?.toUpperCase()) {
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

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default:    return currency;
    }
  }

  Widget _invoiceRow(String label, String value, AppThemeData t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label,
          style: TextStyle(fontSize: 11, color: t.textMuted,
              fontWeight: FontWeight.w600,
              fontFamily: LeapPlatform.fontFamily))),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: t.text, fontFamily: LeapPlatform.fontFamily),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}