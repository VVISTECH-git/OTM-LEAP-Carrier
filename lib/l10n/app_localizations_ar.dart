import 'app_localizations.dart';

// ignore_for_file: type=lint

/// Arabic translations for LEAP Carrier.
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'مدعوم من Oracle OTM';
  @override String get signIn => 'تسجيل الدخول';
  @override String get username => 'اسم المستخدم';
  @override String get password => 'كلمة المرور';
  @override String get rememberMe => 'تذكرني';
  @override String get usernameRequired => 'اسم المستخدم مطلوب';
  @override String get passwordRequired => 'كلمة المرور مطلوبة';
  @override String get invalidCredentials => 'بيانات غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور.';
  @override String serverError(int code) => 'خطأ في الخادم ($code). حاول مرة أخرى أو تواصل مع المسؤول.';
  @override String attemptsRemaining(int count) => 'تبقى $count محاولة قبل الإغلاق';
  @override String tryAgainIn(int seconds) => 'حاول مجدداً خلال ${seconds} ثانية';

  @override String get otmInstance => 'نظام OTM';
  @override String get swipeToRemove => 'اسحب لليسار للحذف';
  @override String get scanNewInstance => 'مسح نظام جديد';
  @override String get savedInstances => 'الأنظمة المحفوظة';
  @override String get noInstancesSaved => 'لا توجد أنظمة محفوظة';
  @override String get tapToSetupInstance => 'انقر لإعداد نظام OTM';
  @override String get confirmInstance => 'تأكيد النظام';
  @override String get addOtmInstance => 'إضافة نظام OTM';
  @override String get saveAndUse => 'حفظ واستخدام هذا النظام';
  @override String get scanAgain => 'مسح مرة أخرى';
  @override String get scanQrCode => 'مسح رمز QR';
  @override String get enterManually => 'إدخال يدوي';
  @override String get pointCamera => 'وجّه الكاميرا نحو رمز QR لنظام OTM';
  @override String get urlValidating => 'سيتم التحقق من الرابط أثناء الكتابة';
  @override String get urlNotRecognised => 'الرابط غير معترف به كنظام OTM';
  @override String get otmProduction => 'OTM الإنتاج';
  @override String get otmTest => 'OTM الاختبار';
  @override String get otmDevelopment => 'OTM التطوير';
  @override String otmDevelopmentN(int n) => 'OTM التطوير $n';

  @override String get navHome => 'الرئيسية';
  @override String get navSpotBids => 'العروض الفورية';
  @override String get navTendered => 'العطاءات';
  @override String get navActive => 'النشطة';
  @override String get navInvoicing => 'الفوترة';

  @override String get accept => 'قبول';
  @override String get decline => 'رفض';
  @override String get reject => 'رفض';
  @override String get cancel => 'إلغاء';
  @override String get retry => 'إعادة المحاولة';
  @override String get refresh => 'تحديث';
  @override String get save => 'حفظ';
  @override String get submit => 'إرسال';
  @override String get done => 'تم';
  @override String get edit => 'تعديل';
  @override String get search => 'بحث';
  @override String get signOut => 'تسجيل الخروج';
  @override String get signOutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';
  @override String get yes => 'نعم';
  @override String get no => 'لا';

  @override String get shipment => 'شحنة';
  @override String get shipmentId => 'رقم الشحنة';
  @override String get weight => 'الوزن';
  @override String get pickup => 'الاستلام';
  @override String get delivery => 'التسليم';
  @override String get origin => 'المنشأ';
  @override String get destination => 'الوجهة';
  @override String get status => 'الحالة';
  @override String get language => 'اللغة';
  @override String get changeTheme => 'تغيير المظهر';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'جميع الشحنات';
  @override String get noShipments => 'لا توجد شحنات';
  @override String get pullToRefresh => 'اسحب للأسفل للتحديث';
  @override String get needsAttention => 'يحتاج انتباهاً';
  @override String activeShipments(int count) => '$count نشطة';
  @override String tenderedCount(int count) => '$count معلقة';
  @override String spotBidsCount(int count) => '$count متاحة';

  @override String get tenderedTitle => 'الشحنات المعروضة';
  @override String get tenderPending => 'بانتظار الرد';
  @override String get tenderAccepted => 'مقبولة';
  @override String get tenderRejected => 'مرفوضة';
  @override String get acceptTender => 'قبول العطاء';
  @override String get declineTender => 'رفض العطاء';
  @override String get confirmAccept => 'نعم، قبول';
  @override String get confirmDecline => 'نعم، رفض';
  @override String get actionCannotBeUndone => 'لا يمكن التراجع عن هذا الإجراء.';
  @override String get respondBy => 'الرد قبل';
  @override String get tenderApprovedSuccess => 'تم قبول العطاء بنجاح!';
  @override String get tenderRejectedSuccess => 'تم رفض العطاء بنجاح!';
  @override String get noTenderedShipments => 'لا توجد شحنات معروضة';
  @override String get noActionableTender => 'لم يتم العثور على عطاء قابل للتنفيذ.';
  @override String get driverNotAssigned => 'لم يتم تعيين سائق';
  @override String get smsNotSent => 'لم يُرسَل SMS';

  @override String get spotBidsTitle => 'الشحنات العروض الفورية';
  @override String get placeBid => 'تقديم عرض';
  @override String get submitBid => 'إرسال العرض';
  @override String get buyItNow => 'شراء الآن';
  @override String get marketRate => 'سعر السوق';
  @override String get yourBidAmount => 'مبلغ عرضك';
  @override String get bidSubmittedSuccess => 'تم إرسال العرض بنجاح!';
  @override String get noSpotBidShipments => 'لا توجد شحنات للعروض الفورية';
  @override String get existingBidLabel => 'عرضك الحالي';
  @override String get bidWon => 'فزت بالعرض';

  @override String get activeTitle => 'الشحنات النشطة';
  @override String get inTransit => 'في الطريق';
  @override String get atPickup => 'عند نقطة الاستلام';
  @override String get etaLabel => 'الوصول المتوقع';
  @override String get noActiveShipments => 'لا توجد شحنات نشطة';
  @override String get stopTimeline => 'جدول المحطات';
  @override String get addEvent => 'إضافة حدث';
  @override String get trackEvents => 'تتبع الأحداث';
  @override String get noTrackingEvents => 'لا توجد أحداث تتبع';
  @override String get noEventUpdate => 'لا تحديث للحدث منذ';

  @override String get assignDriver => 'تعيين سائق';
  @override String get assignDriverTruck => 'تعيين السائق والشاحنة';
  @override String get driverName => 'اسم السائق';
  @override String get driverPhone => 'رقم هاتف السائق';
  @override String get vehicleReg => 'رقم تسجيل المركبة';
  @override String get truckType => 'نوع الشاحنة';
  @override String get assignNow => 'تعيين الآن';
  @override String get assignLater => 'تعيين لاحقاً';
  @override String get driverAssignedSuccess => 'تم تعيين السائق بنجاح!';
  @override String get enterDriverPhone => 'يرجى إدخال رقم هاتف السائق';

  @override String get invoicingTitle => 'الفوترة';
  @override String get costs => 'التكاليف';
  @override String get invoices => 'الفواتير';
  @override String get addCost => 'إضافة تكلفة';
  @override String get generateInvoice => 'إنشاء فاتورة';
  @override String get costType => 'نوع التكلفة';
  @override String get amount => 'المبلغ';
  @override String get description => 'الوصف';
  @override String get adjustmentReason => 'سبب التعديل';
  @override String get totalAmount => 'الإجمالي';
  @override String get invoiceHistoryComingSoon => 'سجل الفواتير قريباً';
  @override String get costAddedSuccess => 'تمت إضافة التكلفة بنجاح!';
  @override String get enterValidAmount => 'يرجى إدخال مبلغ صالح';

  @override String get truckLcv => 'LCV (صغير)';
  @override String get truck24ft => '24 قدم';
  @override String get truck32ft => '32 قدم';
  @override String get truck40ft => '40 قدم';
  @override String get truckTrailer => 'مقطورة';
}
