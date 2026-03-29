// ═══════════════════════════════════════════════════════════════════════════════
// AppConstants — LEAP Carrier
//
// Single source of truth for:
//   • SharedPreferences keys
//   • Secure storage keys
//   • OTM REST API path fragments
//   • App-wide defaults and limits
//
// Nothing outside this file should contain raw key strings or path literals.
// ═══════════════════════════════════════════════════════════════════════════════

class AppConstants {
  AppConstants._();

  // ── SharedPreferences keys (non-sensitive) ─────────────────────────────────
  static const String prefInstanceUrl  = 'instance_url';
  static const String prefUserId       = 'user_id';
  static const String prefDomain       = 'domain';
  static const String prefUser         = 'user';
  static const String prefUserType     = 'user_type';
  static const String prefServprovGid  = 'servprovGid';
  static const String prefServprovName = 'servprov_name';

  // ── Secure storage keys (sensitive — Android Keystore) ────────────────────
  static const String secureAuthHeader = 'auth_header';
  static const String securePassword   = 'remembered_password';

  // ── OTM API base path ──────────────────────────────────────────────────────
  static const String _base = '/logisticsRestApi/resources-int/v2';

  // ── Login / credential validation ─────────────────────────────────────────
  static const String pathValidateLogin = '$_base/items/DEFAULT?fields=itemXid';

  // ── Saved-query shipment lists (Carrier-specific) ──────────────────────────
  static const String pathTenderedList =
      '$_base/custom-actions/savedQueries/shipmentNoSSUs/SERVPROVS%20TENDERED%20SHIPMENTS?fields=shipmentXid,domainName';

  static const String pathSpotBidList =
      '$_base/custom-actions/savedQueries/shipmentNoSSUs/SERVPROVS%20OPENSPOTBID%20SHIPMENTS?fields=shipmentXid,domainName';

  // ── Shipment detail ────────────────────────────────────────────────────────
  static const String shipmentDetailFields =
      'shipmentXid,attributeNumber18,startTime,endTime,totalWeight,'
      'marketCost,totalActualCost,domainName,sourceLocation,destLocation,tenders,stops,numStops';
  static const String shipmentDetailExpand =
      'sourceLocation,destLocation,tenders,stops';

  static const String shipmentActiveFields =
      'shipmentXid,startTime,endTime,totalWeight,domainName,'
      'sourceLocation,destLocation,statuses,stops,numStops,remarks';
  static const String shipmentActiveExpand =
      'sourceLocation,destLocation,statuses,stops,remarks';
  // ── Tender accept / decline ────────────────────────────────────────────────
  // Append iTransactionNo: e.g. pathAcceptDecline + '/$iTransactionNo'
  static const String pathAcceptDecline =
      '$_base/custom-actions/acceptDecline/tenders';

  // ── Spot bid submission (legacy XML WMServlet) ─────────────────────────────
  static const String pathWmServlet = '/GC3/glog.integration.servlet.WMServlet';

  // ── Service provider lookup (used during login) ───────────────────────────
  static const String pathServprovQuery =
      '$_base/custom-actions/queries/serviceProviders?showPks=true&fields=servprovGid';

  // ── Existing bid check ─────────────────────────────────────────────────────
  // Pattern: pathTenderBids(transactionNo, servprovGid)
  // servprovGid is URL-encoded so values like "DEMO.MHL" or any value
  // containing '/', '?', '#', or spaces don't corrupt the path segment.
  static String pathTenderBids(int transactionNo, String servprovGid) =>
      '$_base/tenders/$transactionNo/serviceProviders/${Uri.encodeComponent(servprovGid)}/bids?fields=bidAmount';

  // ── Tracking events ────────────────────────────────────────────────────────
  // bareXid is encoded so OTM GIDs containing '&', '"', or other special
  // characters don't corrupt the query string.
  static String pathTrackingEvents(String bareXid) =>
      '$_base/trackingEvents?q=shipmentGid co "${Uri.encodeComponent(bareXid)}"&limit=100';

  static const String pathTrackingEventsPost = '$_base/trackingEvents';

  // ── Shipment sub-resources ────────────────────────────────────────────────
  static String pathShipment(String shipmentGid) =>
      '$_base/shipments/$shipmentGid';

  // Search shipment by XID — no domain prefix needed, OTM resolves it
  static String pathSearchShipmentByXid(String xid, String fields, String expand) =>
      '$_base/shipments?q=${Uri.encodeQueryComponent('shipmentXid co "$xid"')}'
      '&fields=$fields&expand=$expand&limit=1';

  static String pathActiveShipments(String query, String fields, String expand, int limit) =>
      '$_base/shipments?q=$query&fields=$fields&expand=$expand&limit=$limit';

  // ── Costs ──────────────────────────────────────────────────────────────────
  static String pathShipmentCosts(String shipmentGid) =>
      '$_base/shipments/$shipmentGid/costs';

  static String pathAddCost(String shipmentGid) =>
      '$_base/shipments/$shipmentGid/costs';

  static String pathUpdateCost(String shipmentGid, String costXid) =>
      '$_base/shipments/$shipmentGid/costs/$costXid';

  static const String pathCostTypes =
      '$_base/costTypes?fields=costTypeXid,description&limit=25';

  static const String pathAccessorialCodes =
      '$_base/accessorialCodes?fields=accessorialCodeXid,accessorialDesc,domainName&limit=100';

  static const String pathAdjustmentReasons =
      '$_base/adjustmentReasons?fields=adjustmentReasonGid,description&limit=50';

  // ── Invoices ───────────────────────────────────────────────────────────────
  static String pathShipmentInvoices(String shipmentGid) =>
      '$_base/shipments/$shipmentGid/invoices'
      '?fields=invoiceXid,invoiceStatus,totalAmount,createDate&limit=100';

  static const String pathInvoicesQuery =
      '$_base/invoices?fields=invoiceXid,invoiceStatus,totalAmount,createDate,'
      'shipmentXid,domainName&limit=100';

  static const String pathInvoicesPost = '$_base/invoices';

  static String pathSubmitInvoice(String invoiceGid) =>
      '$_base/invoices/$invoiceGid';

  // ── Documents (POD / e-Way Bill / Invoice / Damage Photo) ─────────────────
  static String pathShipmentDocuments(String shipmentGid) =>
      '$_base/shipments/$shipmentGid/documents';

  // ── Remarks ────────────────────────────────────────────────────────────────
  static String pathShipmentRemarks(String shipmentGid) =>
      '$_base/shipments/$shipmentGid/remarks';

  static String pathShipmentRemark(String shipmentGid, int remarkSequence) =>
      '$_base/shipments/$shipmentGid/remarks/$remarkSequence';

  // ── Remark qualifier GIDs (PUBLIC domain — no prefix needed) ──────────────
  static const String remarkDriverName  = 'DRIVER_NAME';
  static const String remarkDriverPhone = 'DRIVER_PHONE';
  static const String remarkVehicleReg  = 'VEHICLE_REG';
  static const String remarkTruckType   = 'TRUCK_TYPE';

  // ── Truck types — single source of truth used by tendered + active screens ─
  static const List<String> truckTypes = [
    'LCV (Small)',
    '24FT',
    '32FT',
    '40FT',
    'Trailer',
    'Flatbed',
    'Container',
    'Refrigerated',
    'Tanker',
    'Tipper',
    'Other',
  ];

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration timeoutShort  = Duration(seconds: 15);
  static const Duration timeoutMedium = Duration(seconds: 20);
  static const Duration timeoutLong   = Duration(seconds: 30);
  static const Duration timeoutUpload = Duration(seconds: 90); // for base64 image uploads

  // ── Limits ────────────────────────────────────────────────────────────────
  static const int maxLoginAttempts  = 5;
  static const int lockoutSeconds    = 30;
  static const int maxSavedInstances = 5;
  static const int shipmentPageLimit = 100;

  // ── Login lockout persistence (survives app restarts) ─────────────────────
  // Stored in flutter_secure_storage (not SharedPreferences) so a rooted device
  // or ADB backup cannot trivially clear the lockout by deleting prefs XML.
  static const String secureFailedAttempts = 'login_failed_attempts';
  static const String secureLockoutUntil   = 'login_lockout_until'; // epoch ms

  // Keep old SharedPreferences keys for one-time migration on first launch
  static const String prefFailedAttempts = 'login_failed_attempts';
  static const String prefLockoutUntil   = 'login_lockout_until'; // epoch ms

  // ── Session idle timeout ───────────────────────────────────────────────────
  static const String prefSessionSavedAt = 'session_saved_at';   // epoch ms
  static const int    sessionTtlHours    = 24;                    // re-login after 24 h idle
}