import 'app_localizations.dart';

// ignore_for_file: type=lint

/// English translations for LEAP Carrier.
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Powered by Oracle OTM';
  @override String get signIn => 'Sign In';
  @override String get username => 'Username';
  @override String get password => 'Password';
  @override String get rememberMe => 'Remember me';
  @override String get usernameRequired => 'Username is required';
  @override String get passwordRequired => 'Password is required';
  @override String get invalidCredentials => 'Invalid credentials. Please check your username and password.';
  @override String serverError(int code) => 'Server error ($code). Please try again or contact your admin.';
  @override String attemptsRemaining(int count) => '$count attempt${count == 1 ? '' : 's'} remaining before lockout';
  @override String tryAgainIn(int seconds) => 'Try again in ${seconds}s';

  @override String get otmInstance => 'OTM Instance';
  @override String get swipeToRemove => 'Swipe left to remove';
  @override String get scanNewInstance => 'Scan new instance';
  @override String get savedInstances => 'Saved instances';
  @override String get noInstancesSaved => 'No instances saved yet';
  @override String get tapToSetupInstance => 'Tap to set up OTM instance';
  @override String get confirmInstance => 'Confirm instance';
  @override String get addOtmInstance => 'Add OTM instance';
  @override String get saveAndUse => 'Save & use this instance';
  @override String get scanAgain => 'Scan again';
  @override String get scanQrCode => 'Scan QR code';
  @override String get enterManually => 'Enter manually';
  @override String get pointCamera => 'Point camera at the OTM instance QR code';
  @override String get urlValidating => 'URL will be validated as you type';
  @override String get urlNotRecognised => 'URL not recognised as an OTM instance';
  @override String get otmProduction => 'OTM Production';
  @override String get otmTest => 'OTM Test';
  @override String get otmDevelopment => 'OTM Development';
  @override String otmDevelopmentN(int n) => 'OTM Development $n';

  @override String get navHome => 'Home';
  @override String get navSpotBids => 'Spot Bids';
  @override String get navTendered => 'Tendered';
  @override String get navActive => 'Active';
  @override String get navInvoicing => 'Invoicing';

  @override String get accept => 'Accept';
  @override String get decline => 'Decline';
  @override String get reject => 'Reject';
  @override String get cancel => 'Cancel';
  @override String get retry => 'Retry';
  @override String get refresh => 'Refresh';
  @override String get save => 'Save';
  @override String get submit => 'Submit';
  @override String get done => 'Done';
  @override String get edit => 'Edit';
  @override String get search => 'Search';
  @override String get signOut => 'Sign Out';
  @override String get signOutConfirm => 'Are you sure you want to sign out?';
  @override String get yes => 'Yes';
  @override String get no => 'No';

  @override String get shipment => 'Shipment';
  @override String get shipmentId => 'Shipment ID';
  @override String get weight => 'Weight';
  @override String get pickup => 'Pickup';
  @override String get delivery => 'Delivery';
  @override String get origin => 'Origin';
  @override String get destination => 'Destination';
  @override String get status => 'Status';
  @override String get language => 'Language';
  @override String get changeTheme => 'Change theme';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'All Shipments';
  @override String get noShipments => 'No shipments';
  @override String get pullToRefresh => 'Pull down to refresh';
  @override String get needsAttention => 'Needs Attention';
  @override String activeShipments(int count) => '$count active';
  @override String tenderedCount(int count) => '$count pending';
  @override String spotBidsCount(int count) => '$count available';

  @override String get tenderedTitle => 'Tendered Shipments';
  @override String get tenderPending => 'Tender Pending';
  @override String get tenderAccepted => 'Accepted';
  @override String get tenderRejected => 'Rejected';
  @override String get acceptTender => 'Accept Tender';
  @override String get declineTender => 'Decline Tender';
  @override String get confirmAccept => 'Yes, Accept';
  @override String get confirmDecline => 'Yes, Reject';
  @override String get actionCannotBeUndone => 'This action cannot be undone.';
  @override String get respondBy => 'Respond By';
  @override String get tenderApprovedSuccess => 'Tender approved successfully!';
  @override String get tenderRejectedSuccess => 'Tender rejected successfully!';
  @override String get noTenderedShipments => 'No tendered shipments';
  @override String get noActionableTender => 'No actionable tender found for this shipment.';
  @override String get driverNotAssigned => 'Driver not assigned';
  @override String get smsNotSent => 'SMS not sent';

  @override String get spotBidsTitle => 'Spot Bid Shipments';
  @override String get placeBid => 'Place Bid';
  @override String get submitBid => 'Submit Bid';
  @override String get buyItNow => 'Buy It Now';
  @override String get marketRate => 'Market Rate';
  @override String get yourBidAmount => 'Your Bid Amount';
  @override String get bidSubmittedSuccess => 'Bid submitted successfully!';
  @override String get noSpotBidShipments => 'No spot bid shipments';
  @override String get existingBidLabel => 'Your current bid';
  @override String get bidWon => 'Bid Won';

  @override String get activeTitle => 'Active Shipments';
  @override String get inTransit => 'In Transit';
  @override String get atPickup => 'At Pickup';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'No active shipments';
  @override String get stopTimeline => 'Stop Timeline';
  @override String get addEvent => 'Add Event';
  @override String get trackEvents => 'Track Events';
  @override String get noTrackingEvents => 'No tracking events yet';
  @override String get noEventUpdate => 'No event update in';

  @override String get assignDriver => 'Assign Driver';
  @override String get assignDriverTruck => 'Assign Driver & Truck';
  @override String get driverName => 'Driver Name';
  @override String get driverPhone => 'Driver Phone Number';
  @override String get vehicleReg => 'Vehicle Registration Number';
  @override String get truckType => 'Truck Type';
  @override String get assignNow => 'Assign Now';
  @override String get assignLater => 'Assign Later';
  @override String get driverAssignedSuccess => 'Driver assigned successfully!';
  @override String get enterDriverPhone => 'Please enter driver phone number';

  @override String get invoicingTitle => 'Invoicing';
  @override String get costs => 'Costs';
  @override String get invoices => 'Invoices';
  @override String get addCost => 'Add Cost';
  @override String get generateInvoice => 'Generate Invoice';
  @override String get costType => 'Cost Type';
  @override String get amount => 'Amount';
  @override String get description => 'Description';
  @override String get adjustmentReason => 'Adjustment Reason';
  @override String get totalAmount => 'Total';
  @override String get invoiceHistoryComingSoon => 'Invoice history coming soon';
  @override String get costAddedSuccess => 'Cost added successfully!';
  @override String get enterValidAmount => 'Please enter a valid amount';

  @override String get truckLcv => 'LCV (Small)';
  @override String get truck24ft => '24FT';
  @override String get truck32ft => '32FT';
  @override String get truck40ft => '40FT';
  @override String get truckTrailer => 'Trailer';
}
