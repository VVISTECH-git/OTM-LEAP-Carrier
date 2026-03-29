import 'package:intl/intl.dart';
import 'package:leapcarrier/core/constants/app_constants.dart';
import 'package:leapcarrier/features/shipments/models/shipment_models.dart';
import 'package:leapcarrier/core/services/api_client.dart';
import 'package:leapcarrier/core/services/exceptions.dart';
import 'package:leapcarrier/core/services/session_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// OtmService — LEAP Carrier
//
// All OTM REST API calls for the Carrier app.
//
// Depends on:
//   • ApiClient      — HTTP layer, injects auth headers, handles errors
//   • SessionService — reads credentials + manages session state
//   • AppConstants   — all path fragments and key names
//
// No raw http calls. No SharedPreferences access. No hardcoded strings.
// ═══════════════════════════════════════════════════════════════════════════════

class OtmService {
  /// OTM REST API returns a single Map (not a List) when there is only one
  /// item in a collection. This helper always normalises to a List.
  static List<dynamic> _asList(dynamic items) {
    if (items == null) return [];
    if (items is List) return items;
    if (items is Map) return [items];
    return [];
  }

  // ── Home — shipment counts ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchHomeShipments() async {
    final results = await Future.wait([
      ApiClient.instance.get(AppConstants.pathTenderedList),
      ApiClient.instance.get(AppConstants.pathSpotBidList),
      _fetchActiveCount(),
    ]);

    return {
      'tendered': _asList((results[0] as Map?)?['items']),
      'spotBids': _asList((results[1] as Map?)?['items']),
      'active':   results[2] as List,
    };
  }

  // Lightweight active count — only shipmentXid, no remarks expansion
  static Future<List<dynamic>> _fetchActiveCount() async {
    try {
      final activeQ = Uri.encodeQueryComponent(
          'statuses.statusValueGid co "IN_PROGRESS"');
      final path = AppConstants.pathActiveShipments(
        activeQ, 'shipmentXid', 'statuses', AppConstants.shipmentPageLimit);
      final res = await ApiClient.instance.get(path);
      return _asList(res?['items']);
    } catch (_) {
      return [];
    }
  }

  // ── Tendered Shipments list ────────────────────────────────────────────────
  static Future<List<dynamic>> fetchTenderedShipments() async {
    final res = await ApiClient.instance.get(AppConstants.pathTenderedList);
    return _asList(res?['items']);
  }

  // ── Search shipment by XID (no domain needed) ─────────────────────────────
  static Future<Map<String, dynamic>> searchShipmentByXid(String xid) async {
    final path = AppConstants.pathSearchShipmentByXid(
      xid,
      AppConstants.shipmentDetailFields,
      AppConstants.shipmentDetailExpand,
    );
    final res   = await ApiClient.instance.get(path);
    final items = _asList(res?['items']);
    if (items.isEmpty) throw ApiException('Shipment not found.', 404);
    return items.first as Map<String, dynamic>;
  }

  // ── Shipment full detail ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchShipmentDetail(
      String shipmentGid) async {
    final path = '${AppConstants.pathShipment(shipmentGid)}'
        '?fields=${AppConstants.shipmentDetailFields}'
        '&expand=${AppConstants.shipmentDetailExpand}';
    final res = await ApiClient.instance.get(path);
    return res as Map<String, dynamic>;
  }

  // ── Active Shipments ───────────────────────────────────────────────────────
  // Single API call — remarks are expanded inline so driver fields are
  // available directly from fromJson(). No N+1 remarks fetching needed.
  static Future<List<CarrierShipment>> fetchActiveShipments() async {
    final activeQ = Uri.encodeQueryComponent(
      'statuses.statusValueGid co "IN_PROGRESS"',
    );
    final path = AppConstants.pathActiveShipments(
      activeQ,
      AppConstants.shipmentActiveFields,
      AppConstants.shipmentActiveExpand,
      AppConstants.shipmentPageLimit,
    );
    final res   = await ApiClient.instance.get(path);
    final items = _asList(res?['items']);
    return items
        .map((j) => CarrierShipment.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Accept / Decline tender ────────────────────────────────────────────────
  static Future<void> respondToTender({
    required int iTransactionNo,
    required bool accept,
  }) async {
    await ApiClient.instance.post(
      '${AppConstants.pathAcceptDecline}/$iTransactionNo',
      body: {'acceptanceCode': accept ? 'A' : 'D'},
    );
  }

  // ── Spot Bid Shipments list ────────────────────────────────────────────────
  static Future<List<dynamic>> fetchSpotBidShipments() async {
    final res = await ApiClient.instance.get(AppConstants.pathSpotBidList);
    return _asList(res?['items']);
  }

  // ── Check existing bid ─────────────────────────────────────────────────────
  static Future<double?> checkExistingBid({
    required int transactionNo,
    required String servprovGid,
  }) async {
    try {
      final res = await ApiClient.instance.getUrl(
        '${await SessionService.instance.instanceUrl}'
        '${AppConstants.pathTenderBids(transactionNo, servprovGid)}',
      );
      final items = _asList(res?['items']);
      if (items.isEmpty) return null;
      return (items.first['bidAmount']?['value'] as num?)?.toDouble();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Submit spot bid via XML WMServlet ──────────────────────────────────────
  static Future<void> submitSpotBid({
    required int iTransactionNo,
    required double bidAmount,
    required String currency,
    required String servprovGid,
    required bool isBuyItNow,
  }) async {
    final amountStr = bidAmount.toStringAsFixed(2);
    final tag1 = isBuyItNow ? 'BIN' : '';

    // XML-escape server-sourced strings before interpolation to prevent
    // malformed or injected XML if OTM ever returns values containing < > & ' "
    String xmlEscape(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final safeServprovGid = xmlEscape(servprovGid);
    final safeCurrency    = xmlEscape(currency);

    final xmlBody = '''<?xml version="1.0" encoding="UTF-8"?>
<otm:Transmission xmlns:otm="http://xmlns.oracle.com/apps/otm/transmission/v6.4">
  <otm:TransmissionBody>
    <otm:GLogXMLElement>
      <otm:TenderResponse>
        <otm:ITransactionNo>$iTransactionNo</otm:ITransactionNo>
        <otm:ServiceProviderAlias>
          <otm:ServiceProviderAliasQualifierGid>
            <otm:Gid><otm:Xid>GLOG</otm:Xid></otm:Gid>
          </otm:ServiceProviderAliasQualifierGid>
          <otm:ServiceProviderAliasValue>$safeServprovGid</otm:ServiceProviderAliasValue>
        </otm:ServiceProviderAlias>
        <otm:BidAmount>
          <otm:FinancialAmount>
            <otm:GlobalCurrencyCode>$safeCurrency</otm:GlobalCurrencyCode>
            <otm:MonetaryAmount>$amountStr</otm:MonetaryAmount>
          </otm:FinancialAmount>
        </otm:BidAmount>
        <otm:ConditionalSpotBid>
          <otm:BidAmount>
            <otm:FinancialAmount>
              <otm:GlobalCurrencyCode>$safeCurrency</otm:GlobalCurrencyCode>
              <otm:MonetaryAmount>$amountStr</otm:MonetaryAmount>
            </otm:FinancialAmount>
          </otm:BidAmount>
          <otm:Tag1>$tag1</otm:Tag1>
        </otm:ConditionalSpotBid>
      </otm:TenderResponse>
    </otm:GLogXMLElement>
  </otm:TransmissionBody>
</otm:Transmission>''';

    await ApiClient.instance.postXml(
      AppConstants.pathWmServlet,
      body: xmlBody,
    );
  }

  // ── Tracking Events ────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchTrackingEvents(String bareXid) async {
    final res = await ApiClient.instance.get(
      AppConstants.pathTrackingEvents(bareXid),
    );
    return _asList(res?['items']);
  }

  static Future<void> postTrackingEvent({
    required String shipmentGid,
    required String domainName,
    required String eventCode,
    required DateTime eventDateTime,
    required String stopXid,  // stopNum stored as string e.g. "1"
    String? remarks,
  }) async {
    final stopSeq = int.tryParse(stopXid) ?? 1;

    // Format datetime with timezone offset (OTM expects ISO8601 with offset)
    final offset  = eventDateTime.timeZoneOffset;
    final sign    = offset.isNegative ? '-' : '+';
    final hours   = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final dtStr   = '${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(eventDateTime)}$sign$hours:$minutes';

    await ApiClient.instance.post(
      AppConstants.pathTrackingEventsPost,
      body: {
        'shipmentGid':         shipmentGid,
        'domainName':          domainName,
        'statusCodeGid':       eventCode,
        'eventdate': {
          'value': dtStr,
        },
        'responsiblePartyGid': 'CARRIER',
        'stops': {
          'items': [
            {
              'stopSequence': stopSeq,
              if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
            }
          ],
        },
      },
    );
  }

  // ── Remarks ────────────────────────────────────────────────────────────────

  /// POST one or more remarks on a shipment.
  /// Only call when [items] is non-empty.
  static Future<void> postRemarks({
    required String shipmentGid,
    required List<Map<String, dynamic>> items,
  }) async {
    await ApiClient.instance.post(
      AppConstants.pathShipmentRemarks(shipmentGid),
      body: {'items': items},
    );
  }

  /// GET all existing remarks for a shipment.
  static Future<List<dynamic>> fetchRemarks(String shipmentGid) async {
    final res = await ApiClient.instance.get(
      AppConstants.pathShipmentRemarks(shipmentGid),
    );
    return _asList(res?['items']);
  }

  /// PATCH a single remark by its sequence number.
  static Future<void> updateRemark({
    required String shipmentGid,
    required int remarkSequence,
    required String remarkText,
  }) async {
    await ApiClient.instance.patch(
      AppConstants.pathShipmentRemark(shipmentGid, remarkSequence),
      body: {'remarkText': remarkText},
    );
  }

  /// Smart upsert — POST remarks that don't exist yet, PATCH ones that do,
  /// and PATCH to empty string for any qualifier in [toClear] that exists in OTM.
  ///
  /// [fields]          — remarkQualGid → new text (non-empty values to save)
  /// [toClear]         — qualifiers that were pre-filled but are now blank
  /// [domainName]      — shipment domain (e.g. "DEMO")
  /// [existingRemarks] — pass the pre-fetched remarks list to skip the internal
  ///                     GET; if omitted a fresh GET is made
  static Future<void> saveDriverRemarks({
    required String shipmentGid,
    required Map<String, String> fields,
    required String domainName,
    List<String> toClear = const [],
    List<dynamic>? existingRemarks,
  }) async {
    if (fields.isEmpty && toClear.isEmpty) return;

    // Use caller-supplied remarks if available, otherwise fetch fresh
    List<dynamic> existing = existingRemarks ?? [];
    if (existingRemarks == null) {
      try {
        existing = await fetchRemarks(shipmentGid);
      } catch (_) {
        // If GET fails proceed — worst case we POST duplicates
      }
    }

    // Build qual → sequence map from existing remarks
    final existingMap = <String, int>{};
    for (final r in existing) {
      final qual = r['remarkQualGid']?.toString() ?? '';
      final seq  = (r['remarkSequence'] as num?)?.toInt();
      if (qual.isNotEmpty && seq != null) existingMap[qual] = seq;
    }

    final toPost  = <Map<String, dynamic>>[];
    final toPatch = <MapEntry<int, String>>[];

    // Non-empty fields — POST if new, PATCH if existing
    fields.forEach((qual, text) {
      if (existingMap.containsKey(qual)) {
        toPatch.add(MapEntry(existingMap[qual]!, text));
      } else {
        toPost.add({
          'remarkQualGid': qual,
          'remarkText':    text,
          'domainName':    domainName,
        });
      }
    });

    // Cleared fields — PATCH to empty if remark exists in OTM
    // (OTM REST API has no DELETE for remarks, so we blank the text)
    for (final qual in toClear) {
      if (existingMap.containsKey(qual)) {
        toPatch.add(MapEntry(existingMap[qual]!, ''));
      }
    }

    if (toPost.isNotEmpty) {
      await postRemarks(shipmentGid: shipmentGid, items: toPost);
    }
    for (final entry in toPatch) {
      await updateRemark(
        shipmentGid:    shipmentGid,
        remarkSequence: entry.key,
        remarkText:     entry.value,
      );
    }
  }

  // ── Assign Driver (kept for any legacy callers — now a no-op wrapper) ──────
  static Future<void> assignDriver({
    required String shipmentGid,
    required String driverPhone,
    String? driverName,
    String? vehicleReg,
    String? truckType,
  }) async {
    // Driver details are now stored exclusively as shipment remarks.
    // Build the fields map with only non-empty values.
    final fields = <String, String>{
      if (driverPhone.isNotEmpty) AppConstants.remarkDriverPhone: driverPhone,
      if (driverName  != null && driverName.isNotEmpty)  AppConstants.remarkDriverName:  driverName,
      if (vehicleReg  != null && vehicleReg.isNotEmpty)  AppConstants.remarkVehicleReg:  vehicleReg,
      if (truckType   != null && truckType.isNotEmpty)   AppConstants.remarkTruckType:   truckType,
    };
    final domain = shipmentGid.contains('.')
        ? shipmentGid.split('.').first
        : shipmentGid;
    await saveDriverRemarks(
      shipmentGid: shipmentGid,
      fields:      fields,
      domainName:  domain,
    );
  }

  // ── Costs ──────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchCosts(String shipmentGid) async {
    final res = await ApiClient.instance.get(
      AppConstants.pathShipmentCosts(shipmentGid),
    );
    return _asList(res?['items']);
  }

  static Future<List<dynamic>> fetchCostTypes() async {
    final res = await ApiClient.instance.get(AppConstants.pathCostTypes);
    return _asList(res?['items']);
  }

  static Future<List<dynamic>> fetchAccessorialCodes() async {
    final res = await ApiClient.instance.get(AppConstants.pathAccessorialCodes);
    return _asList(res?['items']);
  }

  static Future<List<dynamic>> fetchAdjustmentReasons() async {
    final res = await ApiClient.instance.get(AppConstants.pathAdjustmentReasons);
    return _asList(res?['items']);
  }

  static Future<void> addCost({
    required String shipmentGid,
    required String costType,
    required double amount,
    required String currency,
    String? accessorialCodeGid,
    String? adjustmentReasonGid,
  }) async {
    await ApiClient.instance.post(
      AppConstants.pathAddCost(shipmentGid),
      body: {
        'costType': costType,
        'cost': {'value': amount, 'currency': currency},
        if (accessorialCodeGid != null) 'accessorialCodeGid': accessorialCodeGid,
        if (adjustmentReasonGid != null) 'adjustmentReasonGid': adjustmentReasonGid,
      },
    );
  }

  static Future<void> updateCost({
    required String shipmentGid,
    required String costXid,
    required double amount,
    required String currency,
  }) async {
    await ApiClient.instance.patch(
      AppConstants.pathUpdateCost(shipmentGid, costXid),
      body: {
        'cost': {'value': amount, 'currency': currency},
      },
    );
  }

  // ── Invoices ───────────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchInvoices() async {
    try {
      final res = await ApiClient.instance.get(AppConstants.pathInvoicesQuery);
      return _asList(res?['items']);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> generateInvoice({
    required String shipmentGid,          // e.g. "DEMO.36001"
    required List<Map<String, dynamic>> costs, // from fetchCosts()
    required String currency,
  }) async {
    final session     = SessionService.instance;
    final servprovGid = await session.servprovGid;   // e.g. "DEMO.MHL"
    final domain      = await session.domain;         // e.g. "DEMO"

    // Invoice number: INV-{bareShipmentId}-{epoch seconds}
    final bareShipment = shipmentGid.contains('.')
        ? shipmentGid.split('.').last
        : shipmentGid;
    final invoiceNumber =
        'INV-$bareShipment-${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    final nowIso = DateTime.now().toUtc().toIso8601String();

    // Build line items from the cost list — same structure as reference app
    final lineItems = <Map<String, dynamic>>[];
    int seq = 1;
    for (final cost in costs) {
      final costType = cost['costType']?.toString() ?? 'A';
      final value    = (cost['cost']?['value'] as num?)?.toDouble() ?? 0.0;
      final curr     = cost['cost']?['currency']?.toString() ?? currency;
      final item = <String, dynamic>{
        'lineitemSeqNo'  : seq,
        'description'    : costType,
        'freightCharge'  : {'value': value, 'currency': curr},
        'costTypeGid'    : costType,
        'domainName'     : domain,
      };
      final accGid = cost['accessorialCodeGid']?.toString();
      if (accGid != null && accGid.isNotEmpty) {
        item['accessorialCodeGid'] = accGid;
      }
      lineItems.add(item);
      seq++;
    }

    final body = <String, dynamic>{
      'invoiceType'           : 'I',
      'invoiceNumber'         : invoiceNumber,
      'servprovAliasQualGid'  : 'GLOG',
      'servprovAliasValue'    : servprovGid,
      'invoiceDate'           : {'value': nowIso},
      'dateReceived'          : {'value': nowIso},
      'consolidationType'     : 'STANDARD',
      'domainName'            : domain,
      'shipments': {
        'items': [
          {
            'sequenceNo' : 1,
            'shipmentGid': shipmentGid,
            'domainName' : domain,
          }
        ],
      },
      'lineItems': {
        'items': lineItems,
      },
    };

    final res = await ApiClient.instance.post(
      AppConstants.pathInvoicesPost,
      body: body,
    );
    return (res as Map<String, dynamic>?) ?? {};
  }

  static Future<void> submitInvoice({
    required String invoiceGid, // e.g. "DEMO.20251114-0002"
  }) async {
    await ApiClient.instance.patch(
      AppConstants.pathSubmitInvoice(invoiceGid),
      body: {'invoiceStatus': 'SUBMITTED'},
    );
  }

  // ── Upload Document (POD / e-Way Bill / Invoice / Damage Photo) ───────────
  //
  // OTM REST API: POST shipments/{gid}/documents
  //
  // Correct payload structure (confirmed from OTM API):
  // {
  //   "documentXid": "<timestamp>",
  //   "documentType": "BLOB",
  //   "documentMimeType": "image/jpeg",
  //   "documentFilename": "<fileName>",
  //   "ownerDataQueryTypeGid": "SHIPMENT",
  //   "ownerObjectGid": "<domainName>.<bareShipmentXid>",
  //   "domainName": "<domainName>",
  //   "contentManagementSystemGid": "DATABASE",
  //   "usedAs": "I",
  //   "contents": {
  //     "items": [
  //       {
  //         "documentContentGid": "<domainName>.<timestamp>",
  //         "blobContent": "<base64>"
  //       }
  //     ]
  //   }
  // }
  static Future<void> uploadDocument({
    required String shipmentGid,   // full GID e.g. "DEMO.36001"
    required String docKey,        // 'pod', 'pod_stop_2', 'eway', 'invoice', 'damage'
    required String fileName,      // e.g. "pod_20250324120000.jpg"
    required String mimeType,      // e.g. "image/jpeg"
    required String base64Content,
  }) async {
    // Split "DOMAIN.SHIPMENTXID" into parts
    final parts      = shipmentGid.split('.');
    final domainName = parts.length > 1 ? parts.first : shipmentGid;

    // documentXid — unique ID for this document record
    final docXid = '${docKey.toUpperCase()}${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    await ApiClient.instance.postLarge(
      AppConstants.pathShipmentDocuments(shipmentGid),
      body: {
        'documentXid':                  docXid,
        'documentType':                 'BLOB',
        'documentMimeType':             mimeType,
        'documentFilename':             fileName,
        'ownerDataQueryTypeGid':        'SHIPMENT',
        'ownerObjectGid':               shipmentGid,
        'domainName':                   domainName,
        'contentManagementSystemGid':   'DATABASE',
        'usedAs':                       'I',
        'contents': {
          'items': [
            {
              'documentContentGid': '$domainName.$docXid',
              'blobContent':        base64Content,
            }
          ]
        },
      },
    );
  }

  // ── Saved credentials ──────────────────────────────────────────────────────
  static Future<Map<String, String?>> getSavedCredentials() =>
      SessionService.instance.savedCredentials;
}