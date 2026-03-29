import 'app_localizations.dart';

// ignore_for_file: type=lint

/// Hindi translations for LEAP Carrier.
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Oracle OTM द्वारा संचालित';
  @override String get signIn => 'साइन इन करें';
  @override String get username => 'उपयोगकर्ता नाम';
  @override String get password => 'पासवर्ड';
  @override String get rememberMe => 'मुझे याद रखें';
  @override String get usernameRequired => 'उपयोगकर्ता नाम आवश्यक है';
  @override String get passwordRequired => 'पासवर्ड आवश्यक है';
  @override String get invalidCredentials => 'अमान्य क्रेडेंशियल। कृपया उपयोगकर्ता नाम और पासवर्ड जांचें।';
  @override String serverError(int code) => 'सर्वर त्रुटि ($code)। पुनः प्रयास करें या अपने व्यवस्थापक से संपर्क करें।';
  @override String attemptsRemaining(int count) => 'लॉकआउट से पहले $count प्रयास शेष';
  @override String tryAgainIn(int seconds) => '${seconds} सेकंड में पुनः प्रयास करें';

  @override String get otmInstance => 'OTM इंस्टेंस';
  @override String get swipeToRemove => 'हटाने के लिए बाईं ओर स्वाइप करें';
  @override String get scanNewInstance => 'नया इंस्टेंस स्कैन करें';
  @override String get savedInstances => 'सहेजे गए इंस्टेंस';
  @override String get noInstancesSaved => 'कोई इंस्टेंस सहेजा नहीं गया';
  @override String get tapToSetupInstance => 'OTM इंस्टेंस सेट अप करने के लिए टैप करें';
  @override String get confirmInstance => 'इंस्टेंस की पुष्टि करें';
  @override String get addOtmInstance => 'OTM इंस्टेंस जोड़ें';
  @override String get saveAndUse => 'इस इंस्टेंस को सहेजें और उपयोग करें';
  @override String get scanAgain => 'फिर से स्कैन करें';
  @override String get scanQrCode => 'QR कोड स्कैन करें';
  @override String get enterManually => 'मैन्युअली दर्ज करें';
  @override String get pointCamera => 'OTM इंस्टेंस QR कोड पर कैमरा निर्देशित करें';
  @override String get urlValidating => 'टाइप करते समय URL मान्य किया जाएगा';
  @override String get urlNotRecognised => 'URL को OTM इंस्टेंस के रूप में नहीं पहचाना गया';
  @override String get otmProduction => 'OTM उत्पादन';
  @override String get otmTest => 'OTM परीक्षण';
  @override String get otmDevelopment => 'OTM विकास';
  @override String otmDevelopmentN(int n) => 'OTM विकास $n';

  @override String get navHome => 'होम';
  @override String get navSpotBids => 'स्पॉट बिड';
  @override String get navTendered => 'टेंडर';
  @override String get navActive => 'सक्रिय';
  @override String get navInvoicing => 'चालान';

  @override String get accept => 'स्वीकार करें';
  @override String get decline => 'अस्वीकार करें';
  @override String get reject => 'अस्वीकार करें';
  @override String get cancel => 'रद्द करें';
  @override String get retry => 'पुनः प्रयास करें';
  @override String get refresh => 'ताज़ा करें';
  @override String get save => 'सहेजें';
  @override String get submit => 'सबमिट करें';
  @override String get done => 'हो गया';
  @override String get edit => 'संपादित करें';
  @override String get search => 'खोजें';
  @override String get signOut => 'साइन आउट';
  @override String get signOutConfirm => 'क्या आप साइन आउट करना चाहते हैं?';
  @override String get yes => 'हाँ';
  @override String get no => 'नहीं';

  @override String get shipment => 'शिपमेंट';
  @override String get shipmentId => 'शिपमेंट ID';
  @override String get weight => 'वजन';
  @override String get pickup => 'पिकअप';
  @override String get delivery => 'डिलीवरी';
  @override String get origin => 'उद्गम';
  @override String get destination => 'गंतव्य';
  @override String get status => 'स्थिति';
  @override String get language => 'भाषा';
  @override String get changeTheme => 'थीम बदलें';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'सभी शिपमेंट';
  @override String get noShipments => 'कोई शिपमेंट नहीं';
  @override String get pullToRefresh => 'ताज़ा करने के लिए नीचे खींचें';
  @override String get needsAttention => 'ध्यान चाहिए';
  @override String activeShipments(int count) => '$count सक्रिय';
  @override String tenderedCount(int count) => '$count लंबित';
  @override String spotBidsCount(int count) => '$count उपलब्ध';

  @override String get tenderedTitle => 'टेंडर शिपमेंट';
  @override String get tenderPending => 'टेंडर लंबित';
  @override String get tenderAccepted => 'स्वीकृत';
  @override String get tenderRejected => 'अस्वीकृत';
  @override String get acceptTender => 'टेंडर स्वीकार करें';
  @override String get declineTender => 'टेंडर अस्वीकार करें';
  @override String get confirmAccept => 'हाँ, स्वीकार करें';
  @override String get confirmDecline => 'हाँ, अस्वीकार करें';
  @override String get actionCannotBeUndone => 'यह कार्रवाई पूर्ववत नहीं की जा सकती।';
  @override String get respondBy => 'तक जवाब दें';
  @override String get tenderApprovedSuccess => 'टेंडर सफलतापूर्वक स्वीकृत!';
  @override String get tenderRejectedSuccess => 'टेंडर सफलतापूर्वक अस्वीकृत!';
  @override String get noTenderedShipments => 'कोई टेंडर शिपमेंट नहीं';
  @override String get noActionableTender => 'इस शिपमेंट के लिए कोई कार्रवाई योग्य टेंडर नहीं मिला।';
  @override String get driverNotAssigned => 'चालक नियुक्त नहीं';
  @override String get smsNotSent => 'SMS नहीं भेजा गया';

  @override String get spotBidsTitle => 'स्पॉट बिड शिपमेंट';
  @override String get placeBid => 'बिड लगाएं';
  @override String get submitBid => 'बिड सबमिट करें';
  @override String get buyItNow => 'अभी खरीदें';
  @override String get marketRate => 'बाजार दर';
  @override String get yourBidAmount => 'आपकी बिड राशि';
  @override String get bidSubmittedSuccess => 'बिड सफलतापूर्वक सबमिट!';
  @override String get noSpotBidShipments => 'कोई स्पॉट बिड शिपमेंट नहीं';
  @override String get existingBidLabel => 'आपकी वर्तमान बिड';
  @override String get bidWon => 'बिड जीती';

  @override String get activeTitle => 'सक्रिय शिपमेंट';
  @override String get inTransit => 'परिवहन में';
  @override String get atPickup => 'पिकअप पर';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'कोई सक्रिय शिपमेंट नहीं';
  @override String get stopTimeline => 'स्टॉप टाइमलाइन';
  @override String get addEvent => 'घटना जोड़ें';
  @override String get trackEvents => 'घटनाएं ट्रैक करें';
  @override String get noTrackingEvents => 'कोई ट्रैकिंग घटना नहीं';
  @override String get noEventUpdate => 'कोई अपडेट नहीं';

  @override String get assignDriver => 'चालक नियुक्त करें';
  @override String get assignDriverTruck => 'चालक और ट्रक नियुक्त करें';
  @override String get driverName => 'चालक का नाम';
  @override String get driverPhone => 'चालक का फोन नंबर';
  @override String get vehicleReg => 'वाहन पंजीकरण संख्या';
  @override String get truckType => 'ट्रक का प्रकार';
  @override String get assignNow => 'अभी नियुक्त करें';
  @override String get assignLater => 'बाद में नियुक्त करें';
  @override String get driverAssignedSuccess => 'चालक सफलतापूर्वक नियुक्त!';
  @override String get enterDriverPhone => 'कृपया चालक का फोन नंबर दर्ज करें';

  @override String get invoicingTitle => 'चालान';
  @override String get costs => 'लागत';
  @override String get invoices => 'चालान';
  @override String get addCost => 'लागत जोड़ें';
  @override String get generateInvoice => 'चालान बनाएं';
  @override String get costType => 'लागत प्रकार';
  @override String get amount => 'राशि';
  @override String get description => 'विवरण';
  @override String get adjustmentReason => 'समायोजन का कारण';
  @override String get totalAmount => 'कुल';
  @override String get invoiceHistoryComingSoon => 'चालान इतिहास जल्द आएगा';
  @override String get costAddedSuccess => 'लागत सफलतापूर्वक जोड़ी गई!';
  @override String get enterValidAmount => 'कृपया एक वैध राशि दर्ज करें';

  @override String get truckLcv => 'LCV (छोटा)';
  @override String get truck24ft => '24 फीट';
  @override String get truck32ft => '32 फीट';
  @override String get truck40ft => '40 फीट';
  @override String get truckTrailer => 'ट्रेलर';
}
