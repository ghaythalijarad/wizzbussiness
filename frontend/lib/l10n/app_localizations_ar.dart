// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'WIZZ';

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get createBusinessAccount => 'إنشاء حساب تجاري';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get businessName => 'اسم النشاط التجاري';

  @override
  String get businessType => 'نوع النشاط التجاري';

  @override
  String get businessPhoto => 'صورة النشاط التجاري';

  @override
  String get country => 'البلد';

  @override
  String get city => 'المدينة';

  @override
  String get neighborhood => 'الحي';

  @override
  String get streetName => 'اسم الشارع';

  @override
  String get healthCertificate => 'شهادة صحية';

  @override
  String get additionalDocuments => 'مستندات إضافية';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get businessInformation => 'معلومات النشاط التجاري';

  @override
  String get businessAddress => 'عنوان النشاط التجاري';

  @override
  String get requiredDocuments => 'المستندات المطلوبة';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInToYourAccount => 'سجل دخولك إلى حسابك';

  @override
  String get registerYourBusiness => 'سجل نشاطك التجاري';

  @override
  String get checkYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get resendEmail => 'إعادة إرسال البريد';

  @override
  String get createBusinessAccountButton => 'إنشاء حساب تجاري';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get createAStrongPassword => 'أنشئ كلمة مرور قوية';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get enterYourFullName => 'أدخل اسمك الكامل';

  @override
  String get enterYourBusinessName => 'أدخل اسم نشاطك التجاري';

  @override
  String get selectYourBusinessType => 'اختر نوع نشاطك التجاري';

  @override
  String get uploadBusinessPhoto => 'ارفع صورة نشاطك التجاري';

  @override
  String get enterYourCity => 'أدخل مدينتك';

  @override
  String get enterYourNeighborhood => 'أدخل حيك';

  @override
  String get enterYourStreetName => 'أدخل اسم الشارع';

  @override
  String get uploadHealthCertificate => 'ارفع الشهادة الصحية';

  @override
  String get uploadAdditionalDocuments => 'ارفع أي مستندات تجارية إضافية';

  @override
  String get confirmYourAccount => 'Confirm Your Account';

  @override
  String get confirmationCodeSent =>
      'We\'ve sent a 6-digit confirmation code to:';

  @override
  String get confirmationCode => 'Confirmation Code';

  @override
  String get confirmationCodeHint => '123456';

  @override
  String get confirmAccount => 'Confirm Account';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendCodeIn(Object seconds) {
    return 'Resend Code in ${seconds}s';
  }

  @override
  String get backToSignUp => 'Back to Sign Up';

  @override
  String get confirmationCodeRequired => 'Confirmation code is required';

  @override
  String get confirmationCodeLength => 'Code must be 6 digits';

  @override
  String confirmationCodeResent(Object email) {
    return 'Confirmation code resent to $email';
  }

  @override
  String get invalidConfirmationCode =>
      'Invalid confirmation code. Please try again.';

  @override
  String get accountConfirmedSuccess => 'Account confirmed successfully!';

  @override
  String get enterRegisteredEmail => 'أدخل بريدك الإلكتروني المسجل';

  @override
  String get resetPasswordDescription =>
      'أدخل عنوان بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.';

  @override
  String get emailSentDescription =>
      'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى عنوان بريدك الإلكتروني. يرجى التحقق من صندوق الوارد واتباع التعليمات.';

  @override
  String get accountReviewNotice =>
      'ستتم مراجعة معلومات نشاطك التجاري قبل التفعيل.';

  @override
  String get termsAndConditionsNotice =>
      'بإنشاء حساب، فإنك توافق على شروط الخدمة وسياسة الخصوصية.';

  @override
  String get register => 'تسجيل';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get forgotPasswordQuestion => 'نسيت كلمة المرور؟';

  @override
  String get dontHaveAnAccount => 'ليس لديك حساب؟';

  @override
  String get joinOrderReceiver => 'انضم إلى مستلم الطلبات';

  @override
  String get signUpSubtitle => 'أنشئ حسابك للبدء';

  @override
  String get accountSecurity => 'أمان الحساب';

  @override
  String get and => 'و';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get iAgreeToThe => 'أوافق على';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get takePicture => 'التقاط صورة';

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get verificationCodeRequired => 'يرجى إدخال رمز التحقق';

  @override
  String get verifyYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get pleaseEnterYourEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get pleaseEnterYourPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get failedToFetchProfile => 'فشل في جلب الملف الشخصي';

  @override
  String get noBusinessFoundForUser =>
      'لم يتم العثور على نشاط تجاري لهذا المستخدم';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get loginFailedMessage =>
      'Login failed. Please check your credentials.';

  @override
  String get errorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة. يرجى التحقق من البيانات والمحاولة مرة أخرى.';

  @override
  String get sessionConflictTitle => 'Already Signed In';

  @override
  String get sessionConflictMessage =>
      'You are already signed in. Please choose an option below.';

  @override
  String get continueCurrentSession => 'Continue with current session';

  @override
  String get signOutAndRetry => 'Sign out and try again';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmation => 'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String get userAlreadySignedIn => 'User is already signed in';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get forceSignInOption => 'Force sign in';

  @override
  String get sessionExpiredTitle => 'Session Expired';

  @override
  String get authenticationFailedTitle => 'Authentication Failed';

  @override
  String get systemErrorTitle => 'System Error';

  @override
  String get tooManyAttemptsTitle => 'Too Many Attempts';

  @override
  String get userNotFoundTitle => 'User Not Found';

  @override
  String get emailVerificationTitle => 'Email Verification Required';

  @override
  String get orders => 'الطلبات';

  @override
  String get items => 'العناصر';

  @override
  String get analytics => 'التحليلات';

  @override
  String get discounts => 'الخصومات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get goOnline => 'الانتقال للحالة المتصلة';

  @override
  String get goOffline => 'فصل الاتصال';

  @override
  String get menu => 'القائمة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get errorPickingImage => 'خطأ في اختيار الصورة';

  @override
  String get errorPickingFile => 'خطأ في اختيار الملف';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get businessIsNowOnline => 'النشاط التجاري متصل الآن';

  @override
  String get businessIsNowOffline => 'النشاط التجاري غير متصل الآن';

  @override
  String get businessNowOnline => 'النشاط التجاري متصل الآن';

  @override
  String get businessNowOffline => 'النشاط التجاري غير متصل الآن';

  @override
  String get errorUpdatingStatus =>
      'خطأ في تحديث الحالة. يرجى المحاولة مرة أخرى.';

  @override
  String get returnOrderFeature => 'Return order feature coming soon';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsTapped => 'Notifications tapped';

  @override
  String get returnAnOrder => 'Return an Order';

  @override
  String get manageDiscounts => 'Manage Discounts';

  @override
  String get returnOrder => 'Return Order';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get posSettings => 'إعدادات نقاط البيع';

  @override
  String get languageSettings => 'إعدادات اللغة';

  @override
  String get locationSettings => 'إعدادات الموقع';

  @override
  String get workingHoursSettings => 'إعدادات ساعات العمل';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String timeoutFirstAlert(String remainingTime) {
    return 'سيتم رفض الطلب تلقائيًا في غضون $remainingTime.';
  }

  @override
  String timeoutUrgentAlert(String remainingTime) {
    return 'عاجل: سيتم الرفض التلقائي في غضون $remainingTime.';
  }

  @override
  String get timeoutAutoReject => 'تم رفض الطلب تلقائيًا بسبب انتهاء الوقت.';

  @override
  String get openingTime => 'وقت الافتتاح';

  @override
  String get closingTime => 'وقت الإغلاق';

  @override
  String get setOpeningTime => 'تحديد وقت الافتتاح';

  @override
  String get setClosingTime => 'تحديد وقت الإغلاق';

  @override
  String get notSet => 'غير محدد';

  @override
  String get workingHoursSaved => 'تم حفظ ساعات العمل بنجاح';

  @override
  String get businessManagement => 'إدارة الأعمال';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get ownerName => 'اسم المالك';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get businessAddressLabel => 'عنوان النشاط التجاري';

  @override
  String get rating => 'التقييم';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get accountStatus => 'حالة الحساب';

  @override
  String get posSettingsUpdated => 'POS settings updated successfully';

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String get connectionFailed => 'فشل اختبار الاتصال';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get close => 'Close';

  @override
  String get posSystemType => 'POS System Type';

  @override
  String get selectPosSystem => 'اختر نظام نقاط البيع';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get apiEndpoint => 'نقطة نهاية API';

  @override
  String get pleaseEnterApiEndpoint => 'Please enter API endpoint';

  @override
  String get pleaseEnterValidUrl => 'Please enter a valid URL';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get enterApiKey => 'Enter API Key';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get pleaseEnterApiKey => 'Please enter API key';

  @override
  String get accessToken => 'رمز الوصول';

  @override
  String get enterAccessToken => 'Enter Access Token';

  @override
  String get locationId => 'معرف الموقع';

  @override
  String get enterLocationId => 'Enter Location ID';

  @override
  String get posIntegrationSettings => 'POS Integration Settings';

  @override
  String get enablePosIntegration => 'Enable POS Integration';

  @override
  String get enablePosIntegrationDescription =>
      'Automatically sync orders with your POS system';

  @override
  String get autoSendOrders => 'Auto Send Orders';

  @override
  String get autoSendOrdersDescription =>
      'Automatically send new orders to POS';

  @override
  String get connectionStatus => 'حالة الاتصال';

  @override
  String get posIntegrationEnabled => 'POS Integration Enabled';

  @override
  String get posIntegrationDisabled => 'POS Integration Disabled';

  @override
  String get system => 'System';

  @override
  String get endpoint => 'Endpoint';

  @override
  String get testing => 'Testing...';

  @override
  String get saving => 'Saving...';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get posSyncLogs => 'سجلات المزامنة';

  @override
  String get noSyncLogsFound => 'لم يتم العثور على سجلات مزامنة';

  @override
  String get general => 'عام';

  @override
  String get advanced => 'متقدم';

  @override
  String get posIntegration => 'تكامل نقاط البيع';

  @override
  String get noSyncLogsAvailable => 'لا توجد سجلات مزامنة متاحة';

  @override
  String get syncSettings => 'إعدادات المزامنة';

  @override
  String get syncInterval => 'فترة المزامنة';

  @override
  String get minutes => 'دقائق';

  @override
  String get status => 'الحالة';

  @override
  String get successful => 'ناجح';

  @override
  String get failed => 'فاشل';

  @override
  String get syncLogDetails => 'تفاصيل سجل المزامنة';

  @override
  String get syncTime => 'وقت المزامنة';

  @override
  String get posOrderId => 'معرف طلب نقاط البيع';

  @override
  String get errorMessage => 'رسالة الخطأ';

  @override
  String get retrySync => 'إعادة المزامنة';

  @override
  String get orderSyncRetryInitiated => 'تم بدء إعادة محاولة مزامنة الطلب';

  @override
  String get webhookSetupTitle => 'دليل إعداد الويب هوك';

  @override
  String get webhookSetupDescription => 'اتبع هذه الخطوات لتكوين الويب هوك';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get contactSupportDescription =>
      'تحتاج مساعدة في تكامل نقاط البيع؟ تواصل مع فريق الدعم';

  @override
  String get webhookConfigTitle => 'تكوين الويب هوك';

  @override
  String get webhookConfigDescription =>
      'تكوين نقاط نهاية الويب هوك للمزامنة الفورية';

  @override
  String get webhookStep1 => 'الخطوة 1: إنشاء نقطة نهاية الويب هوك';

  @override
  String get webhookStep2 => 'الخطوة 2: تكوين المصادقة';

  @override
  String get webhookStep3 => 'الخطوة 3: اختبار الاتصال';

  @override
  String get advancedConfiguration => 'التكوين المتقدم';

  @override
  String get timeoutSeconds => 'ثواني المهلة الزمنية';

  @override
  String get retryAttempts => 'محاولات الإعادة';

  @override
  String get testMode => 'وضع الاختبار';

  @override
  String get testModeDescription => 'تفعيل وضع الاختبار للتطوير والاختبار';

  @override
  String get webhooksIntegration => 'تكامل Webhooks';

  @override
  String get webhooksDescription =>
      'تكوين webhooks للحصول على تحديثات الطلبات الفورية';

  @override
  String get configureWebhooks => 'تكوين Webhooks';

  @override
  String get securitySettings => 'إعدادات الأمان';

  @override
  String get encryptionStatus => 'حالة التشفير';

  @override
  String get encryptionEnabled => 'جميع اتصالات API مشفرة';

  @override
  String get apiKeyRotation => 'تدوير مفتاح API';

  @override
  String get lastRotated => 'آخر تدوير منذ 30 يوماً';

  @override
  String get rotate => 'تدوير';

  @override
  String get systemSetupGuides => 'أدلة إعداد النظام';

  @override
  String get setupGuide => 'دليل الإعداد';

  @override
  String get troubleshooting => 'استكشاف الأخطاء وإصلاحها';

  @override
  String get connectionIssues => 'مشاكل الاتصال';

  @override
  String get syncFailures => 'فشل المزامنة';

  @override
  String get apiErrors => 'أخطاء API';

  @override
  String get supportContact => 'الدعم والاتصال';

  @override
  String get liveChat => 'المحادثة المباشرة';

  @override
  String get availableWeekdays => 'متاح أيام الأسبوع من 9 صباحاً - 6 مساءً';

  @override
  String get emailSupport => 'دعم البريد الإلكتروني';

  @override
  String get liveChatComingSoon => 'ميزة المحادثة المباشرة قريباً';

  @override
  String get emailSupportOpened => 'تم فتح دعم البريد الإلكتروني';

  @override
  String get generalSettings => 'عام';

  @override
  String get syncLogs => 'سجلات المزامنة';

  @override
  String get advancedSettings => 'متقدم';

  @override
  String get help => 'مساعدة';

  @override
  String get allDiscounts => 'جميع الخصومات';

  @override
  String get activeDiscounts => 'الخصومات النشطة';

  @override
  String get scheduledDiscounts => 'الخصومات المجدولة';

  @override
  String get expiredDiscounts => 'الخصومات المنتهية الصلاحية';

  @override
  String get createDiscount => 'Create Discount';

  @override
  String get noDiscountsCreated => 'No discounts created yet';

  @override
  String get createYourFirstDiscount =>
      'Create your first discount to start attracting customers';

  @override
  String get deleteDiscount => 'Delete Discount';

  @override
  String get areYouSureYouWantToDeleteThisDiscount =>
      'Are you sure you want to delete this discount?';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'Delete';

  @override
  String get editDiscount => 'Edit Discount';

  @override
  String get title => 'Title';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get description => 'الوصف';

  @override
  String get discountType => 'نوع الخصم';

  @override
  String get percentage => 'النسبة المئوية';

  @override
  String get fixedAmount => 'مبلغ ثابت';

  @override
  String get conditional => 'مشروط';

  @override
  String get buyXGetY => 'اشتري X واحصل على Y';

  @override
  String get freeDelivery => 'توصيل مجاني';

  @override
  String freeDeliveryTitle(String title) {
    return 'Free Delivery: $title';
  }

  @override
  String freeDeliveryIncludedWith(String title) {
    return 'Free delivery included with $title';
  }

  @override
  String categoryAndPrice(String category, String currency, String price) {
    return '$category • $currency $price';
  }

  @override
  String get others => 'أخرى';

  @override
  String get value => 'Value';

  @override
  String get pleaseEnterValue => 'Please enter a value';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String minimumOrderAmount(String amount) {
    return 'Minimum order amount: $amount';
  }

  @override
  String get minimumOrder => 'الحد الأدنى للطلب';

  @override
  String get startDate => 'تاريخ البداية';

  @override
  String get endDate => 'تاريخ النهاية';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get create => 'Create';

  @override
  String get off => 'off';

  @override
  String get discount => 'discount';

  @override
  String get active => 'نشط';

  @override
  String get scheduled => 'مجدول';

  @override
  String get expired => 'منتهي الصلاحية';

  @override
  String get validityPeriod => 'فترة الصلاحية';

  @override
  String get unknownStatus => 'حالة غير معروفة';

  @override
  String get sampleItem => 'Sample Item';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get averageOrderValue => 'متوسط قيمة الطلب';

  @override
  String get topSellingItems => 'العناصر الأكثر مبيعاً';

  @override
  String itemSoldQuantity(int quantity) {
    return 'Sold: $quantity';
  }

  @override
  String itemRevenue(String revenue) {
    return 'Revenue: \$$revenue';
  }

  @override
  String get ordersByStatus => 'Orders by Status';

  @override
  String get orderStatusPending => 'قيد الانتظار';

  @override
  String get orderStatusConfirmed => 'مؤكد';

  @override
  String get orderStatusPreparing => 'قيد التحضير';

  @override
  String get orderStatusReady => 'جاهز';

  @override
  String get orderStatusOnTheWay => 'في الطريق';

  @override
  String get orderStatusDelivered => 'تم التوصيل';

  @override
  String get orderStatusPickedUp => 'تم الاستلام';

  @override
  String get orderStatusCancelled => 'ملغي';

  @override
  String get orderStatusReturned => 'مُرجع';

  @override
  String get orderStatusExpired => 'منتهي الصلاحية';

  @override
  String get itemAddedSuccessfully => 'Item added successfully';

  @override
  String get itemUpdatedSuccessfully => 'Item updated successfully';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get currency => 'Currency';

  @override
  String get currencyPrefix => 'د.ع ';

  @override
  String get edit => 'Edit';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deleteItemConfirmation =>
      'Are you sure you want to delete this item?';

  @override
  String get itemDeletedSuccessfully => 'Item deleted successfully';

  @override
  String get addNewItem => 'إضافة عنصر جديد';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get selectCategory => 'اختر فئة';

  @override
  String get pleaseSelectCategory => 'يرجى اختيار فئة';

  @override
  String get newCategoryName => 'اسم الفئة الجديدة';

  @override
  String get pleaseEnterCategoryName => 'يرجى إدخال اسم الفئة';

  @override
  String get selectExistingCategory => 'اختر فئة موجودة';

  @override
  String get addNewCategory => 'إضافة فئة جديدة';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get pleaseEnterItemName => 'يرجى إدخال اسم العنصر';

  @override
  String get price => 'السعر';

  @override
  String get pleaseEnterPrice => 'Please enter price';

  @override
  String get pleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get imageUrl => 'رابط الصورة';

  @override
  String get optional => 'اختياري';

  @override
  String get available => 'متاح';

  @override
  String get add => 'Add';

  @override
  String get editItem => 'Edit Item';

  @override
  String get update => 'Update';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get preparing => 'Preparing';

  @override
  String get orderReady => 'الطلب جاهز';

  @override
  String get onTheWay => 'في الطريق';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get pickedUp => 'تم الاستلام';

  @override
  String get cancelled => 'ملغي';

  @override
  String get orderReturned => 'مُرجع';

  @override
  String noOrdersFoundFor(String filter) {
    return 'No orders found for $filter';
  }

  @override
  String get notes => 'الملاحظات';

  @override
  String get total => 'المجموع';

  @override
  String get reject => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get required => 'Required';

  @override
  String get changeFile => 'Change File';

  @override
  String get selectFile => 'Select File';

  @override
  String get restaurant => 'مطعم';

  @override
  String get store => 'متجر';

  @override
  String get pharmacy => 'صيدلية';

  @override
  String get cloudKitchen => 'مطبخ سحابي';

  @override
  String get cafe => 'مقهى';

  @override
  String get bakery => 'مخبزة';

  @override
  String get herbalspices => 'الأعشاب والتوابل';

  @override
  String get cosmetics => 'مستحضرات التجميل';

  @override
  String get betshop => 'بيت الرهان';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get registrationSubmitted => 'Registration Submitted';

  @override
  String get registrationSubmittedMessage =>
      'Your registration has been submitted for review';

  @override
  String get nameLabel => 'Name';

  @override
  String get typeLabel => 'Type';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get addressLabel => 'Address';

  @override
  String get countryLabel => 'Country';

  @override
  String get cityLabel => 'City';

  @override
  String get districtLabel => 'District';

  @override
  String get neighbourhoodLabel => 'Neighbourhood';

  @override
  String get streetLabel => 'Street';

  @override
  String get buildingHomeLabel => 'Building/Home';

  @override
  String get zipCodeLabel => 'Zip Code';

  @override
  String get businessOwnerInformation => 'معلومات مالك النشاط';

  @override
  String get nationalIdLabel => 'National ID';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get registrationSuccessLogin =>
      'Registration successful! You can now log in with your credentials.';

  @override
  String get gettingYourLocation => 'Getting your location...';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission denied permanently';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get couldNotDeterminePlacemark => 'Could not determine placemark';

  @override
  String get businessRegistration => 'تسجيل النشاط التجاري';

  @override
  String get welcomeToHadhir => 'مرحباً بك في حاضر';

  @override
  String get fillInTheFormBelowToGetStarted => 'املأ النموذج أدناه للبدء';

  @override
  String get createYourBusinessAccount => 'أنشئ حساب نشاطك التجاري';

  @override
  String get tapToUpload => 'اضغط للرفع';

  @override
  String get uploaded => 'تم الرفع';

  @override
  String get businessAndOwnerInformation => 'معلومات النشاط والمالك';

  @override
  String get selectBusinessType => 'يرجى اختيار نوع النشاط التجاري';

  @override
  String get pleaseEnterBusinessName => 'يرجى إدخال اسم النشاط التجاري';

  @override
  String get pleaseEnterOwnerName => 'يرجى إدخال اسم المالك';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get invalidEmailFormat => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get businessNameRequired => 'Business name is required';

  @override
  String get pleaseEnterYourBusinessName => 'يرجى إدخال اسم نشاطك التجاري';

  @override
  String get streetAddress => 'عنوان الشارع';

  @override
  String get state => 'State/Province';

  @override
  String get zipCode => 'الرمز البريدي';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get weakPassword => 'كلمة المرور ضعيفة جداً';

  @override
  String get confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccess => 'Registration successful';

  @override
  String get emailAlreadyInUse => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get passwordResetLinkSent => 'Password reset link sent to your email';

  @override
  String get welcomeToOrderReceiver => 'Welcome to Order Receiver';

  @override
  String get welcomeDescription =>
      'Manage your business orders efficiently with our powerful order management system.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get testRegistrationForm => 'Test Registration Form';

  @override
  String get networkError => 'Network Error';

  @override
  String get returnOrderTitle => 'Return Order';

  @override
  String get enterOrderNumber => 'Enter Order Number';

  @override
  String get orderNotFound => 'Order Not Found';

  @override
  String get orderReturnedSuccessfully => 'Order Returned Successfully';

  @override
  String get locationSaved => 'Location Saved';

  @override
  String get businessLocation => 'موقع النشاط التجاري';

  @override
  String get locationSet => 'Location Set';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get updateLocation => 'Update Location';

  @override
  String get noLocationSet => 'No Location Set';

  @override
  String get chooseLocationOnMap => 'Choose Location on Map';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get enableLocationServices => 'Enable Location Services';

  @override
  String get locationNotSelected => 'Location Not Selected';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get tapToSelectLocation => 'انقر لتحديد الموقع';

  @override
  String get registrationDate => 'تاريخ التسجيل';

  @override
  String get failedToSaveLocation => 'فشل في حفظ الموقع';

  @override
  String get businessLocationDescription =>
      'حدد موقع نشاطك التجاري لمساعدة العملاء في العثور عليك وتحسين دقة التوصيل.';

  @override
  String get locationInformation => 'معلومات الموقع';

  @override
  String get customerVisibility => 'رؤية العملاء';

  @override
  String get customerVisibilityDescription =>
      'سيتم عرض موقعك للعملاء عند تقديم الطلبات';

  @override
  String get deliveryOptimization => 'تحسين التوصيل';

  @override
  String get deliveryOptimizationDescription =>
      'الموقع الدقيق يساعد على تحسين مسارات التوصيل والتوقيت';

  @override
  String get privacyAndSecurity => 'الخصوصية والأمان';

  @override
  String get privacyAndSecurityDescription =>
      'يتم تشفير بيانات موقعك وتخزينها بأمان';

  @override
  String get pleaseSignInToAccessLocationSettings =>
      'يرجى تسجيل الدخول للوصول إلى إعدادات الموقع';

  @override
  String get smartBusinessControls => 'عناصر التحكم الذكية في الأعمال';

  @override
  String get readyToReceiveOrders => 'مستعد لاستقبال الطلبات';

  @override
  String get ordersArePaused => 'الطلبات متوقفة';

  @override
  String get menuItemsAndCategories => 'Menu items & categories';

  @override
  String get businessInsights => 'Business Insights';

  @override
  String get offersAndPromotions => 'Offers & promotions';

  @override
  String get appConfiguration => 'App configuration';

  @override
  String get changeAppLanguage => 'Change app language';

  @override
  String get cancelRecentOrder => 'Cancel recent order';

  @override
  String get tapOutsideOrPressEscToClose => 'Tap outside or press ESC to close';

  @override
  String get languageChangedToArabic => 'تم تغيير اللغة إلى العربية';

  @override
  String get languageChangedToEnglish => 'Language changed to English';

  @override
  String get managePromotionalOffers => 'إدارة العروض الترويجية';

  @override
  String get viewBusinessInsights => 'عرض رؤى الأعمال';

  @override
  String get manageItemsAndCategories => 'إدارة العناصر والفئات';

  @override
  String get platformIntegration => 'تكامل المنصة';

  @override
  String get centralizedDeliveryPlatform => 'منصة توصيل مركزية';

  @override
  String get appAndAccountPreferences => 'تفضيلات التطبيق والحساب';

  @override
  String get keyboardShortcutsTip =>
      'نصيحة: استخدم اختصارات لوحة المفاتيح للإجراءات الأسرع';

  @override
  String get conditionalDiscountConfiguration => 'إعداد الخصم المشروط';

  @override
  String get buyXGetYConfiguration => 'إعداد اشتري X واحصل على Y';

  @override
  String get buyConfiguration => 'إعداد الشراء';

  @override
  String get getConfiguration => 'إعداد الحصول';

  @override
  String get quantity => 'الكمية';

  @override
  String get selectItem => 'اختر عنصراً';

  @override
  String get itemSelected => 'تم اختيار العنصر';

  @override
  String get enterValidQuantity => 'أدخل كمية صحيحة';

  @override
  String get missingItems => 'عناصر مفقودة';

  @override
  String pleasSelectBothBuyAndGetItems(String discountType) {
    return 'يرجى اختيار عناصر الشراء والحصول للخصم $discountType.';
  }

  @override
  String get ok => 'موافق';

  @override
  String get addFreeDeliveryToDiscount => 'إضافة توصيل مجاني لهذا الخصم';

  @override
  String get conflictingDiscountsTitle => 'خصومات متعارضة';

  @override
  String get someSelectedItemsAlreadyHaveDiscounts =>
      'بعض العناصر أو الفئات المختارة لديها خصومات نشطة بالفعل. كل عنصر يمكن أن يحتوي على خصم واحد فقط في المرة الواحدة.';

  @override
  String get applicabilityNotConfigurable =>
      'لا يمكن تكوين القابلية للتطبيق لهذا النوع من الخصم حيث أن العناصر محددة مسبقاً في الإعداد أعلاه.';

  @override
  String get noItemSelected => 'لم يتم اختيار عنصر';

  @override
  String get appliesToAllItems => 'يطبق على جميع العناصر';

  @override
  String appliesToSpecificItems(int count) {
    return 'يطبق على $count عناصر محددة';
  }

  @override
  String appliesToCategories(int count) {
    return 'يطبق على $count فئات';
  }

  @override
  String get appliesToOrdersAboveMinimum => 'يطبق على الطلبات فوق الحد الأدنى';

  @override
  String validFromTo(int startDay, int startMonth, int startYear, int endDay,
      int endMonth, int endYear) {
    return 'صالح من: $startDay/$startMonth/$startYear - $endDay/$endMonth/$endYear';
  }

  @override
  String minAmount(String amount) {
    return 'الحد الأدنى: \$$amount';
  }

  @override
  String categoriesSelected(int count) {
    return '$count فئات مختارة';
  }

  @override
  String itemsSelected(int count) {
    return '$count عناصر مختارة';
  }

  @override
  String missingItemsMessage(String discountType) {
    return 'يرجى اختيار عناصر الشراء والحصول لخصم $discountType.';
  }

  @override
  String get selectBuyItem => 'اختر عنصر الشراء';

  @override
  String get selectGetItem => 'اختر عنصر الحصول';

  @override
  String get noCategoriesFound =>
      'لم يتم العثور على فئات. يرجى إضافة فئات أولاً.';

  @override
  String get appliesToMinimumOrder =>
      'ينطبق على الطلبات التي تزيد عن الحد الأدنى للمبلغ';

  @override
  String get startSimulation => 'Start Simulation';

  @override
  String get stopSimulation => 'Stop Simulation';

  @override
  String get simulateNewOrder => 'Simulate New Order';

  @override
  String get newOrder => 'طلب جديد';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get live => 'Live';

  @override
  String get sendTestNotification => 'إرسال إشعار تجريبي';

  @override
  String get showLocalNotifications => 'إظهار الإشعارات المحلية';

  @override
  String get showLocalNotificationsDescription =>
      'عرض الإشعارات في منطقة إشعارات النظام';

  @override
  String get playNotificationSounds => 'تشغيل أصوات الإشعارات';

  @override
  String get playNotificationSoundsDescription =>
      'تشغيل الصوت عند استلام الإشعارات';

  @override
  String get testNotifications => 'اختبار الإشعارات';

  @override
  String get testNotificationDescription =>
      'سيرسل هذا إشعار اختبار للتحقق من أن إعداداتك تعمل بشكل صحيح.';

  @override
  String get notConnectedToNotifications =>
      'Not connected to real-time notifications';

  @override
  String get unread => 'Unread';

  @override
  String get highPriority => 'High Priority';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get newOrderNotificationsAppearHere =>
      'New order notifications will appear here';

  @override
  String get clearAllNotifications => 'Clear All Notifications';

  @override
  String get testNotificationSentSuccessfully =>
      'Test notification sent successfully';

  @override
  String failedToSendTestNotification(String error) {
    return 'Failed to send test notification: $error';
  }

  @override
  String failedToConnectToNotifications(String error) {
    return 'Failed to connect to notifications: $error';
  }

  @override
  String get view => 'View';

  @override
  String get urgent => 'urgent';

  @override
  String get high => 'high';

  @override
  String get normal => 'normal';

  @override
  String get low => 'low';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get today => 'اليوم';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get overview => 'Overview';

  @override
  String get performance => 'Performance';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get reviewsAndInsights => 'Reviews & Insights';

  @override
  String get customerReviews => 'Customer Reviews';

  @override
  String get leastOrderedItems => 'Least Ordered Items';

  @override
  String get leastOrderedItemsDescription =>
      'Items that need more attention or promotion';

  @override
  String get growingPopularity => 'Growing Popularity';

  @override
  String get customerSatisfaction => 'Customer Satisfaction';

  @override
  String get efficientService => 'Efficient Service';

  @override
  String get customerBase => 'Customer Base';

  @override
  String get bestPerformer => 'Best Performer';

  @override
  String get needsAttention => 'Needs Attention';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String growingPopularityDescription(double growthRate) {
    return 'Your business has a $growthRate% growth rate this month';
  }

  @override
  String customerSatisfactionDescription(
      String averageRating, int totalReviews) {
    return 'Average rating of $averageRating/5.0 from $totalReviews reviews';
  }

  @override
  String efficientServiceDescription(String averagePreparationTime) {
    return 'Average preparation time: $averagePreparationTime minutes';
  }

  @override
  String customerBaseDescription(int customersServed, double cancellationRate) {
    return 'Served $customersServed customers with $cancellationRate% cancellation rate';
  }

  @override
  String quickInsightSoldCount(int quantity) {
    return '$quantity sold';
  }

  @override
  String onlySoldCount(int quantity) {
    return 'Only $quantity sold';
  }

  @override
  String get revenueTrend => 'Revenue Trend';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get customersServed => 'Customers Served';

  @override
  String get cancellationRate => 'Cancellation Rate';

  @override
  String get revenueBreakdown => 'Revenue Breakdown';

  @override
  String get dailyRevenue => 'Daily Revenue';

  @override
  String get weeklyRevenue => 'Weekly Revenue';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String get performanceMetrics => 'مقاييس الأداء';

  @override
  String get avgPrepTime => 'Avg. Prep Time';

  @override
  String get successRate => 'Success Rate';

  @override
  String get specialDish => 'Special Dish';

  @override
  String get popularItem => 'Popular Item';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get todaysRevenue => 'Today\'s Revenue';

  @override
  String get avgOrderValue => 'Avg. Order Value';

  @override
  String get upload => 'Upload';

  @override
  String get tapToSelectFile => 'Tap to select file';

  @override
  String get requiredPleaseAddAPhoto => 'Required. Please add a photo.';

  @override
  String get change => 'Change';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get pleaseFillInAllRequiredFields =>
      'Please fill in all required fields.';

  @override
  String get businessPhotoIsRequired => 'Business photo is required.';

  @override
  String get businessLicenseRequired => 'Business license is required.';

  @override
  String get ownerIdentityRequired => 'Owner identity is required.';

  @override
  String get healthCertificateRequired => 'Health certificate is required.';

  @override
  String get ownerPhotoRequired => 'Owner photo is required.';

  @override
  String get loginInstead => 'تسجيل الدخول بدلاً من ذلك';

  @override
  String get failedToUploadBusinessPhoto => 'Failed to upload business photo';

  @override
  String get errorUploadingBusinessPhoto => 'Error uploading business photo';

  @override
  String get failedToUploadBusinessLicense =>
      'Failed to upload business license';

  @override
  String get failedToUploadOwnerIdentity => 'Failed to upload owner identity';

  @override
  String get failedToUploadHealthCertificate =>
      'Failed to upload health certificate';

  @override
  String get failedToUploadOwnerPhoto => 'Failed to upload owner photo';

  @override
  String get errorUploadingDocuments => 'Error uploading documents';

  @override
  String get registrationInitiated => 'Registration initiated';

  @override
  String get registrationCompletedSuccessfully =>
      'Registration completed successfully';

  @override
  String get verificationFailed => 'فشل التحقق';

  @override
  String get error => 'خطأ';

  @override
  String get selectImageSource => 'اختر مصدر الصورة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String verificationCodeSentTo(String email) {
    return 'تم إرسال رمز التحقق إلى $email';
  }

  @override
  String get applicationPending => 'Application Pending';

  @override
  String get applicationPendingDescription =>
      'Your application is pending approval.';

  @override
  String get applicationApproved => 'Application Approved';

  @override
  String get applicationApprovedDescription =>
      'Your application has been approved.';

  @override
  String get applicationRejected => 'Application Rejected';

  @override
  String get applicationRejectedDescription =>
      'Your application has been rejected.';

  @override
  String get underReview => 'Under Review';

  @override
  String get underReviewDescription => 'Your application is under review.';

  @override
  String get statusUnknown => 'Status Unknown';

  @override
  String get statusUnknownDescription =>
      'The status of your application is unknown.';

  @override
  String get applicationStatus => 'Application Status';

  @override
  String get discountApplicability => 'Discount Applicability';

  @override
  String get allItems => 'All Items';

  @override
  String get specificItems => 'Specific Items';

  @override
  String get specificCategories => 'Specific Categories';

  @override
  String get selectItems => 'Select Items';

  @override
  String get noItemsSelected => 'No items selected';

  @override
  String get selectCategories => 'Select Categories';

  @override
  String get noCategoriesSelected => 'No categories selected';

  @override
  String get conflictingDiscounts => 'Conflicting Discounts';

  @override
  String get kwd => 'د.ك';

  @override
  String get categories => 'categories';

  @override
  String get notSpecified => 'Not Specified';

  @override
  String get verified => 'موثق';

  @override
  String get viewAndManageOrders => 'View and manage orders';

  @override
  String get businessDashboardVersion => 'Business Dashboard Version';

  @override
  String get modernMaterialDesign => 'Modern Material Design';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get businessLicense => 'رخصة النشاط التجاري';

  @override
  String get ownerIdentity => 'Owner Identity';

  @override
  String get ownerPhoto => 'صورة المالك';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get kitchen => 'مطبخ';

  @override
  String get chooseFromFiles => 'Choose from Files';

  @override
  String get accountInformation => 'معلومات الحساب';

  @override
  String get pleaseEnterAValidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get passwordMustBeAtLeast8Chars =>
      'كلمة المرور يجب أن تكون 8 أحرف على الأقل';

  @override
  String get reEnterYourPassword => 'أعد إدخال كلمة المرور';

  @override
  String get enterOwnerName => 'Enter owner name';

  @override
  String get ownerFirstName => 'الاسم الأول للمالك';

  @override
  String get enterOwnerFirstName => 'أدخل الاسم الأول للمالك';

  @override
  String get pleaseEnterOwnerFirstName => 'يرجى إدخال الاسم الأول للمالك';

  @override
  String get ownerLastName => 'اسم العائلة للمالك';

  @override
  String get enterOwnerLastName => 'أدخل اسم العائلة للمالك';

  @override
  String get pleaseEnterOwnerLastName => 'يرجى إدخال اسم العائلة للمالك';

  @override
  String get enterYourBusinessPhone => 'أدخل هاتف نشاطك التجاري';

  @override
  String get pleaseEnterYourPhoneNumber => 'يرجى إدخال رقم هاتفك';

  @override
  String get addAPhotoToShowcaseYourBusiness => 'أضف صورة لعرض نشاطك التجاري';

  @override
  String get pleaseEnterYourCity => 'يرجى إدخال مدينتك';

  @override
  String get district => 'المنطقة';

  @override
  String get enterYourDistrict => 'أدخل منطقتك';

  @override
  String get pleaseEnterYourDistrict => 'يرجى إدخال منطقتك';

  @override
  String get enterYourStreetAddress => 'أدخل عنوان الشارع';

  @override
  String get pleaseEnterYourStreetAddress => 'يرجى إدخال عنوان الشارع';

  @override
  String get documentsRequired => 'الوثائق المطلوبة';

  @override
  String get pleaseUploadAllRequiredDocuments =>
      'يرجى رفع جميع الوثائق المطلوبة';

  @override
  String get emailVerification => 'التحقق من البريد الإلكتروني';

  @override
  String get enterTheCodeSentToYourEmail =>
      'أدخل الرمز المرسل إلى بريدك الإلكتروني';

  @override
  String get changeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get enter6DigitCode => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String get enterVerificationCode => 'Enter verification code';

  @override
  String get pleaseEnterVerificationCode => 'Please enter verification code';

  @override
  String get pleaseEnterTheVerificationCode => 'يرجى إدخال رمز التحقق';

  @override
  String get verificationCodeSent => 'Verification code sent to your email';

  @override
  String get resendVerificationCode => 'إعادة إرسال رمز التحقق';

  @override
  String get failedToResendCode => 'فشل في إعادة إرسال رمز التحقق';

  @override
  String get troubleshootingSection => 'استكشاف الأخطاء وإصلاحها';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get completeRegistration => 'إكمال التسجيل';

  @override
  String get none => 'لا شيء';

  @override
  String get account => 'الحساب';

  @override
  String get business => 'النشاط التجاري';

  @override
  String get location => 'الموقع';

  @override
  String get documents => 'الوثائق';

  @override
  String get createYourAccount => 'إنشاء حسابك';

  @override
  String get enterAccountDetails => 'أدخل تفاصيل حسابك للبدء';

  @override
  String get tellUsAboutYourBusiness => 'أخبرنا عن نشاطك التجاري';

  @override
  String get whereIsYourBusiness => 'أين يقع نشاطك التجاري؟';

  @override
  String get uploadDocumentsOptional =>
      'ارفع الوثائق للتحقق من نشاطك التجاري (اختياري)';

  @override
  String get selectSubcategory => 'اختر الفئة الفرعية (اختياري)';

  @override
  String get businessSubcategory => 'الفئة الفرعية للنشاط التجاري (اختياري)';

  @override
  String get uploadBusinessLicense => 'ارفع رخصة نشاطك التجاري';

  @override
  String get identityDocument => 'وثيقة الهوية';

  @override
  String get uploadIdentityDocument => 'ارفع وثيقة هويتك';

  @override
  String get uploadOwnerPhoto => 'ارفع صورة المالك';

  @override
  String get enterCountry => 'أدخل بلدك';

  @override
  String get pleaseEnterCountry => 'يرجى إدخال البلد';

  @override
  String get enterCity => 'أدخل مدينتك';

  @override
  String get pleaseEnterCity => 'يرجى إدخال المدينة';

  @override
  String get enterDistrict => 'أدخل منطقتك';

  @override
  String get pleaseEnterDistrict => 'يرجى إدخال المنطقة';

  @override
  String get enterStreetAddress => 'أدخل عنوان الشارع';

  @override
  String get pleaseEnterStreetAddress => 'يرجى إدخال عنوان الشارع';

  @override
  String get registrationSuccessful =>
      'تم التسجيل بنجاح! مرحباً بك في حاضر للأعمال.';

  @override
  String get registrationVerifiedSuccessfully => 'تم التحقق من التسجيل بنجاح!';

  @override
  String verificationFailedWithReason(String reason) {
    return 'فشل التحقق: $reason';
  }

  @override
  String get verificationCodeSentToEmail =>
      'تم إرسال رمز التحقق إلى بريدك الإلكتروني';

  @override
  String registrationFailedWithReason(String reason) {
    return 'فشل التسجيل: $reason';
  }

  @override
  String get confirm => 'تأكيد';

  @override
  String get didntReceiveCode => 'لم تستلم الرمز؟';

  @override
  String get wrongEmailChangeIt => 'هل البريد الإلكتروني خاطئ؟ غيّره';

  @override
  String get verificationCodeMustBe6Digits =>
      'يجب أن يتكون رمز التحقق من 6 أرقام';

  @override
  String get accountAlreadyVerifiedPleaseSignIn =>
      'تم التحقق من الحساب مسبقاً. يرجى تسجيل الدخول.';

  @override
  String get tooManyAttemptsPleaseWait =>
      'محاولات كثيرة. يرجى الانتظار ثم المحاولة مرة أخرى.';

  @override
  String get noAccountFoundForThisEmail =>
      'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';

  @override
  String get mustAgreeToTerms => 'يجب الموافقة على الشروط والأحكام';

  @override
  String get passwordRequirementsTitle => 'متطلبات كلمة المرور';

  @override
  String get passwordRequirementsBullets =>
      '• 8 أحرف على الأقل\n• تشمل أحرفاً كبيرة وصغيرة وأرقاماً ورمزاً خاصاً';

  @override
  String get changeEmailAddressTitle => 'تغيير عنوان البريد الإلكتروني';

  @override
  String get changeEmailAddressMessage =>
      'هل أنت متأكد من رغبتك في تغيير بريدك الإلكتروني؟ سيؤدي ذلك إلى إعادتك إلى شاشة التسجيل.';

  @override
  String get invalidIraqiPhoneNumber =>
      'يرجى إدخال رقم عراقي صالح (77X/78X/79X للهاتف المحمول)';

  @override
  String get centralizedPlatform => 'المنصة المركزية';

  @override
  String get platformConnection => 'اتصال المنصة';

  @override
  String get connected => 'متصل';

  @override
  String get disconnected => 'غير متصل';

  @override
  String get syncStatus => 'حالة المزامنة';

  @override
  String get platformApps => 'تطبيقات المنصة';

  @override
  String get localBusinesses => 'الأعمال المحلية';

  @override
  String get syncRecommended => 'المزامنة مُوصى بها';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get unknown => 'Unknown';

  @override
  String get actions => 'Actions';

  @override
  String get setupPlatform => 'إعداد المنصة';

  @override
  String get syncAllBusinesses => 'مزامنة جميع الأعمال';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get failedToLoadPlatformStatus => 'فشل في تحميل حالة المنصة';

  @override
  String get platformSetupCompletedSuccessfully =>
      'تم إكمال إعداد المنصة بنجاح';

  @override
  String get platformSetupFailed => 'فشل في إعداد المنصة';

  @override
  String get errorSettingUpPlatform => 'خطأ في إعداد المنصة';

  @override
  String get allBusinessesSyncedSuccessfully => 'تم مزامنة جميع الأعمال بنجاح';

  @override
  String get failedToSyncAllBusinessesToPlatform =>
      'فشل في مزامنة جميع الأعمال مع المنصة';

  @override
  String get errorSyncingBusinesses => 'خطأ في مزامنة الأعمال';

  @override
  String get noAppsFound => 'لم يتم العثور على تطبيقات';

  @override
  String get businessDetails => 'تفاصيل النشاط التجاري';

  @override
  String get manageYourBusinessProfileAndInformation =>
      'إدارة ملف نشاطك التجاري ومعلوماتك';

  @override
  String get manageYourPersonalInformation => 'إدارة معلوماتك الشخصية';

  @override
  String get updateYourPasswordAndSecurity => 'تحديث كلمة المرور والأمان';

  @override
  String get configurePointOfSaleIntegration => 'تكوين تكامل نقاط البيع';

  @override
  String get soundNotifications => 'الإشعارات الصوتية';

  @override
  String get configureSoundAlertsForNewOrdersAndUpdates =>
      'تكوين التنبيهات الصوتية للطلبات الجديدة والتحديثات';

  @override
  String get manageNotificationPreferencesAndDeliveryMethods =>
      'إدارة تفضيلات الإشعارات وطرق التوصيل';

  @override
  String get manageBusinessLocationAndGpsCoordinates =>
      'إدارة موقع النشاط التجاري وإحداثيات GPS';

  @override
  String get setUpOpeningAndClosingHoursForYourBusiness =>
      'تحديد أوقات الفتح والإغلاق لنشاطك التجاري';

  @override
  String get discountManagement => 'إدارة الخصومات';

  @override
  String get createAndManageYourDiscounts => 'إنشاء وإدارة خصوماتك';

  @override
  String get reviews => 'المراجعات';

  @override
  String get joinThousandsOfBusinessOwners =>
      'انضم إلى آلاف أصحاب الأعمال الذين يثقون في منصتنا لإدارة طلباتهم وتنمية أعمالهم.';

  @override
  String get startBusinessRegistration => 'بدء تسجيل النشاط التجاري';

  @override
  String get completeBusinessRegistration => 'تسجيل النشاط التجاري بالكامل';

  @override
  String get setUpYourBusinessProfileWithAllNecessaryInformationAndDocuments =>
      'قم بإعداد ملف نشاطك التجاري بجميع المعلومات والوثائق اللازمة';

  @override
  String get secureAndVerified => 'آمن وموثق';

  @override
  String get yourBusinessWillBeVerifiedBeforeActivationForSecurityAndTrust =>
      'سيتم التحقق من نشاطك التجاري قبل التفعيل للأمان والثقة';

  @override
  String get fullDashboardAccess => 'الوصول الكامل للوحة التحكم';

  @override
  String get manageOrdersProductsAnalyticsAndBusinessSettingsInOnePlace =>
      'إدارة الطلبات والمنتجات والتحليلات وإعدادات النشاط التجاري في مكان واحد';

  @override
  String get byCreatingAnAccountYouAgreeToOurTermsOfServiceAndPrivacyPolicy =>
      'من خلال إنشاء حساب، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا. سيتم مراجعة معلومات نشاطك التجاري قبل التفعيل.';

  @override
  String get businessDocuments => 'مستندات النشاط التجاري';

  @override
  String get uploadOptionalDocumentsToVerifyBusiness =>
      'ارفع المستندات الاختيارية للتحقق من نشاطك التجاري';

  @override
  String get uploadBusinessLicenseDocument => 'ارفع مستند رخصة نشاطك التجاري';

  @override
  String get uploadOwnerIdentificationDocument => 'ارفع مستند هوية المالك';

  @override
  String get uploadHealthCertificateIfApplicable =>
      'ارفع الشهادة الصحية إذا كانت مطلوبة';

  @override
  String get uploadPhotoOfBusinessOwner => 'ارفع صورة مالك النشاط التجاري';

  @override
  String get previous => 'السابق';

  @override
  String get merchantStatusApplicationApproved => 'تم قبول الطلب!';

  @override
  String get merchantStatusApplicationUnderReview => 'الطلب قيد المراجعة';

  @override
  String get merchantStatusApplicationRejected => 'تم رفض الطلب';

  @override
  String get merchantStatusAccountSuspended => 'تم تعليق الحساب';

  @override
  String get merchantStatusApplicationStatus => 'حالة الطلب';

  @override
  String get merchantStatusApprovedMessage =>
      'تهانينا! تم قبول طلب التاجر الخاص بك. يمكنك الآن البدء في استقبال الطلبات.';

  @override
  String get merchantStatusPendingMessage =>
      'شكراً لك على تقديم طلبك. نحن نراجع معلوماتك حالياً وسنخبرك بمجرد اكتمال العملية.';

  @override
  String get merchantStatusRejectedMessage =>
      'للأسف، تم رفض طلبك. يرجى مراجعة المتطلبات والنظر في إعادة التقديم.';

  @override
  String get merchantStatusSuspendedMessage =>
      'تم تعليق حساب التاجر الخاص بك. يرجى الاتصال بفريق الدعم للحصول على مزيد من المعلومات.';

  @override
  String get merchantStatusDefaultMessage =>
      'يرجى الاتصال بالدعم للحصول على مزيد من المعلومات حول حالة طلبك.';

  @override
  String get merchantStatusWhatHappensNext => 'ما الذي سيحدث بعد ذلك؟';

  @override
  String get merchantStatusWhatHappensNextDescription =>
      'سيقوم فريقنا بمراجعة طلبك خلال 1-2 يوم عمل. قد نتصل بك إذا كانت هناك حاجة لمعلومات إضافية.';

  @override
  String get merchantStatusWhyRejected => 'لماذا تم رفض طلبي؟';

  @override
  String get merchantStatusWhyRejectedDescription =>
      'الأسباب الشائعة تشمل الوثائق غير المكتملة، أو مشاكل في التحقق من النشاط التجاري، أو انتهاكات السياسة. اتصل بالدعم للحصول على التفاصيل.';

  @override
  String get merchantStatusAccountSuspendedInfo => 'تم تعليق الحساب';

  @override
  String get merchantStatusAccountSuspendedDescription =>
      'تم تعليق حسابك مؤقتاً. قد يكون هذا بسبب انتهاكات السياسة أو مخاوف أمنية. اتصل بالدعم للحصول على المساعدة.';

  @override
  String get merchantStatusReapply => 'إعادة التقديم';

  @override
  String get merchantStatusContactSupport => 'اتصل بالدعم';

  @override
  String get merchantStatusBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get merchantStatusSupportFeatureComingSoon =>
      'ميزة الاتصال بالدعم قريباً!';
}
