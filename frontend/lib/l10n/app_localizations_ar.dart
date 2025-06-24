// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'هاضر للأعمال';

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'التسجيل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get businessType => 'نوع النشاط التجاري';

  @override
  String get store => 'متجر';

  @override
  String get restaurant => 'مطعم';

  @override
  String get pharmacy => 'صيدلية';

  @override
  String get kitchen => 'مطبخ';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get orders => 'الطلبات';

  @override
  String get businessName => 'اسم النشاط التجاري';

  @override
  String get businessAddress => 'عنوان النشاط التجاري';

  @override
  String get autoFillAddress => 'Auto-fill Address';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get pleaseEnterEmailAddress => 'Please enter your email address';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get nationalId => 'National ID';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get country => 'البلد';

  @override
  String get city => 'المدينة';

  @override
  String get district => 'المنطقة';

  @override
  String get zipCode => 'الرمز البريدي';

  @override
  String get neighbourhood => 'الحي';

  @override
  String get street => 'الشارع';

  @override
  String get buildingNumber => 'Building Number';

  @override
  String get businessInformation => 'معلومات النشاط التجاري';

  @override
  String get businessOwnerInformation => 'معلومات صاحب النشاط التجاري';

  @override
  String get businessAndOwnerInformation => 'Business & Owner Information';

  @override
  String get businessRegistration => 'تسجيل النشاط التجاري';

  @override
  String get businessAddressLabel => 'عنوان النشاط التجاري';

  @override
  String get selectBusinessType => 'يرجى اختيار نوع النشاط التجاري';

  @override
  String get cloudKitchen => 'المطبخ السحابي';

  @override
  String get pleaseEnterBusinessName => 'Please enter business name';

  @override
  String get pleaseEnterCountry => 'Please enter country';

  @override
  String get pleaseEnterCity => 'Please enter city';

  @override
  String get pleaseEnterDistrict => 'Please enter district';

  @override
  String get pleaseEnterZipCode => 'Please enter zip code';

  @override
  String get pleaseEnterNeighbourhood => 'Please enter neighbourhood';

  @override
  String get pleaseEnterStreet => 'Please enter street';

  @override
  String get pleaseEnterOwnerName => 'يرجى إدخال اسم المالك';

  @override
  String get pleaseEnterNationalId =>
      'يرجى إدخال رقم الهوية الوطنية أو جواز السفر';

  @override
  String get pleaseEnterDateOfBirth => 'Please enter date of birth';

  @override
  String get requiredDocuments => 'المستندات المطلوبة';

  @override
  String get commercialLicense => 'Commercial License';

  @override
  String get commercialLicenseSubtitle =>
      'Upload your commercial license document';

  @override
  String get ownerNationalId => 'Owner National ID';

  @override
  String get ownerNationalIdSubtitle => 'Upload owner\'s national ID document';

  @override
  String get healthCertificate => 'الشهادة الصحية';

  @override
  String get healthCertificateSubtitle =>
      'مطلوبة للأنشطة التجارية الخاصة بالأطعمة والمشروبات';

  @override
  String get ownerPhoto => 'صورة المالك';

  @override
  String get ownerPhotoSubtitle => 'صورة حديثة لصاحب النشاط التجاري';

  @override
  String get submitRegistration => 'إرسال التسجيل';

  @override
  String get registrationSubmitted => 'تم إرسال التسجيل';

  @override
  String get registrationSubmittedMessage => 'تم إرسال تسجيلك بنجاح!';

  @override
  String get close => 'إغلاق';

  @override
  String get required => 'مطلوب';

  @override
  String get changeFile => 'تغيير الملف';

  @override
  String get selectFile => 'اختر ملف';

  @override
  String get errorSelectingImage => 'خطأ في اختيار الصورة';

  @override
  String get photoLibrary => 'مكتبة الصور';

  @override
  String get camera => 'الكاميرا';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get cancel => 'إلغاء';

  @override
  String orderExpiredNotAccepted(String orderId) {
    return 'انتهت صلاحية الطلب #$orderId - لم يتم قبوله في الوقت المحدد';
  }

  @override
  String get items => 'العناصر';

  @override
  String get analytics => 'التحليلات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get discounts => 'الخصومات';

  @override
  String get failedToSendOrderToPos => 'فشل في إرسال الطلب إلى نظام نقطة البيع';

  @override
  String get scheduled => 'مجدول';

  @override
  String get orderSentToPos => 'تم إرسال الطلب إلى نظام نقطة البيع بنجاح';

  @override
  String get off => 'خصم';

  @override
  String get expired => 'منتهي الصلاحية';

  @override
  String get enterOrderNumber => 'أدخل رقم الطلب';

  @override
  String get discount => 'خصم';

  @override
  String get delete => 'حذف';

  @override
  String get createDiscount => 'إنشاء خصم';

  @override
  String get active => 'نشط';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get preparing => 'Preparing';

  @override
  String get ready => 'Ready';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'ملغى';

  @override
  String get completed => 'Completed';

  @override
  String get confirmed => 'مؤكد';

  @override
  String get all => 'الكل';

  @override
  String get accepted => 'Accepted';

  @override
  String get accept => 'قبول';

  @override
  String get rejected => 'Rejected';

  @override
  String get reject => 'رفض';

  @override
  String get orderReady => 'جاهز';

  @override
  String get pickedUp => 'تم الاستلام';

  @override
  String get returned => 'Returned';

  @override
  String get inProgress => 'In Progress';

  @override
  String get orderReturned => 'مرتجع';

  @override
  String get filters => 'Filters';

  @override
  String get search => 'بحث';

  @override
  String get total => 'Total';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get noItemsFound => 'لم يتم العثور على عناصر';

  @override
  String get add => 'إضافة';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get update => 'Update';

  @override
  String get remove => 'Remove';

  @override
  String get settings => 'الإعدادات';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get loading => 'Loading';

  @override
  String get success => 'Success';

  @override
  String get error => 'خطأ';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'موافق';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deleteItemConfirmation => 'هل أنت متأكد من حذف هذا العنصر؟';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get itemPrice => 'Item Price';

  @override
  String get itemDescription => 'Item Description';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get updateItem => 'Update Item';

  @override
  String get itemDeletedSuccessfully => 'Item deleted successfully!';

  @override
  String get addNewItem => 'Add New Item';

  @override
  String get selectMenu => 'اختر القائمة';

  @override
  String get pleaseSelectMenu => 'يرجى اختيار قائمة';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get pleaseSelectCategory => 'يرجى اختيار فئة';

  @override
  String get pleaseEnterItemName => 'يرجى إدخال اسم العنصر';

  @override
  String get description => 'الوصف';

  @override
  String get price => 'السعر';

  @override
  String get pleaseEnterPrice => 'يرجى إدخال سعر صحيح';

  @override
  String get pleaseEnterValidPrice => 'يرجى إدخال سعر صحيح';

  @override
  String get imageUrl => 'رابط الصورة';

  @override
  String get optional => 'اختياري';

  @override
  String get available => 'متاح';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get newCategoryName => 'New Category Name';

  @override
  String get pleaseEnterCategoryName => 'Please enter a category name';

  @override
  String get selectExistingCategory => 'Select Existing Category';

  @override
  String get addNewCategory => 'Add New Category';

  @override
  String get editItem => 'تعديل العنصر';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get totalOrders => 'إجمالي الطلبات';

  @override
  String get averageOrderValue => 'متوسط قيمة الطلب';

  @override
  String get documentSelectedSuccessfully => 'Document selected successfully!';

  @override
  String get errorSelectingDocument => 'Error selecting document';

  @override
  String get topSellingItems => 'Top Selling Items';

  @override
  String get ordersByStatus => 'Orders by Status';

  @override
  String get allDiscounts => 'جميع الخصومات';

  @override
  String get activeDiscounts => 'الخصومات النشطة';

  @override
  String get scheduledDiscounts => 'الخصومات المجدولة';

  @override
  String get expiredDiscounts => 'الخصومات المنتهية';

  @override
  String get noDiscountsCreated => 'لم يتم إنشاء أي خصومات بعد';

  @override
  String get createYourFirstDiscount => 'أنشئ خصمك الأول لزيادة المبيعات';

  @override
  String get deleteDiscount => 'حذف الخصم';

  @override
  String get areYouSureYouWantToDeleteThisDiscount =>
      'Are you sure you want to delete this discount?';

  @override
  String get notes => 'Notes';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get locationSaved => 'Location Saved';

  @override
  String get locationSet => 'Location Set';

  @override
  String get noLocationSet => 'No Location Set';

  @override
  String get businessLocation => 'Business Location';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get updateLocation => 'Update Location';

  @override
  String get chooseLocationOnMap =>
      'Please choose your business location on the map.';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get notificationChannelName => 'Main Channel';

  @override
  String get notificationChannelDescription => 'Main channel notifications';

  @override
  String get newOrderReceived => 'New Order Received';

  @override
  String newOrderNotificationBody(String orderId, String customerName) {
    return 'Order #$orderId from $customerName';
  }

  @override
  String get sampleItem => 'Sample Item';

  @override
  String itemSoldQuantity(int quantity) {
    return 'Sold: $quantity';
  }

  @override
  String itemRevenue(String revenue) {
    return 'Revenue: $revenue';
  }

  @override
  String get orderStatusTitle => 'Order Status';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusPreparing => 'Preparing';

  @override
  String get orderStatusReady => 'Ready';

  @override
  String get orderStatusPickedUp => 'Picked Up';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusReturned => 'Returned';

  @override
  String get orderStatusExpired => 'Expired';

  @override
  String get freeDelivery => 'توصيل مجاني';

  @override
  String minimumOrderAmount(String amount) {
    return 'Min: \$$amount';
  }

  @override
  String validityPeriod(String startDate, String endDate) {
    return 'Valid: $startDate - $endDate';
  }

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get title => 'Title';

  @override
  String get pleaseEnterTitle => 'Please enter title';

  @override
  String get value => 'Value';

  @override
  String get pleaseEnterValue => 'Please enter value';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get startDate => 'تاريخ البداية';

  @override
  String get endDate => 'تاريخ النهاية';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get create => 'Create';

  @override
  String get percentage => 'Percentage';

  @override
  String get fixedAmount => 'Fixed Amount';

  @override
  String get conditional => 'Conditional';

  @override
  String get editDiscount => 'تعديل الخصم';

  @override
  String get discountType => 'Discount Type';

  @override
  String get emailSent => 'Email Sent';

  @override
  String get passwordResetLinkSent =>
      'If your email address is registered, you will receive a password reset link shortly. Please check your email and follow the instructions.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetYourPassword => 'Reset Your Password';

  @override
  String get enterEmailForPasswordReset =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get sendResetEmail => 'Send Reset Email';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get noMenusAvailable => 'No menus available. Please add a menu first.';

  @override
  String get itemAddedSuccessfully => 'Item added successfully!';

  @override
  String get itemUpdatedSuccessfully => 'Item updated successfully!';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get currency => 'KWD';

  @override
  String get refresh => 'Refresh';

  @override
  String get invalidCredentials => 'Invalid username or password';

  @override
  String anErrorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get demoStore => 'Demo Store';

  @override
  String get demoPharmacy => 'Demo Pharmacy';

  @override
  String get demoRestaurant => 'Demo Restaurant';

  @override
  String get demoKitchen => 'Demo Kitchen';

  @override
  String get unknownBusinessType => 'Unknown business type';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get forgotPasswordQuestion => 'Forgot Password?';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account? Register';

  @override
  String noOrdersFoundFor(String filter) {
    return 'No orders found for $filter';
  }

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get posSettings => 'POS Settings';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSureYouWantToLogout => 'Are you sure you want to logout?';

  @override
  String fieldIsRequired(String field) {
    return '$field is required';
  }

  @override
  String get emailIsRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Please enter a valid email address';

  @override
  String get phoneNumberIsRequired => 'Phone number is required';

  @override
  String get enterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters long';

  @override
  String get passwordRequiresLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordRequiresUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordRequiresNumber =>
      'Password must contain at least one number';

  @override
  String get passwordRequiresSpecialCharacter =>
      'Password must contain at least one special character';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String networkError(String error) {
    return 'Network error: $error';
  }

  @override
  String get notSelected => 'Not selected';

  @override
  String get registrationSuccessLogin =>
      'Registration successful! You can now login with your credentials.';

  @override
  String get gettingYourLocation => 'Getting your location...';

  @override
  String get locationPermissionDeniedForever =>
      'Location permissions are permanently denied. Please enable location access in your device settings.';

  @override
  String get locationPermissionDenied =>
      'Location permission denied. Please allow location access to use this feature.';

  @override
  String get couldNotGetLocation =>
      'Could not get current location. Please try again or enter manually.';

  @override
  String get locationServicesDisabled =>
      'Location services are disabled. Please enable location services.';

  @override
  String get couldNotDeterminePlacemark =>
      'Could not determine placemark. Please enter address details manually.';

  @override
  String get nameLabel => 'Name';

  @override
  String get typeLabel => 'Type';

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
  String get nationalIdLabel => 'National ID';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String registrationFailedWithMessage(String message) {
    return 'Registration failed: $message';
  }

  @override
  String get passwordResetSuccessful => 'Password Reset Successful';

  @override
  String get passwordResetSuccessMessage =>
      'Your password has been reset successfully. You can now log in with your new password.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordLengthRequirement =>
      'Password must be at least 8 characters long';

  @override
  String get passwordComplexityRequirement =>
      'Password must contain at least one uppercase letter, one lowercase letter, and one number';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get enterNewPasswordBelow => 'Please enter your new password below.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordRequirements => 'Password Requirements:';

  @override
  String get passwordRequirementsDetails =>
      '• At least 8 characters long\n• Contains uppercase and lowercase letters\n• Contains at least one number';

  @override
  String get wizzBusiness => 'WIZZ Business';

  @override
  String get businessManagement => 'Business Management';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get enableLocationServices =>
      'Please enable location services to fetch your current location.';

  @override
  String get locationNotSelected =>
      'Please select a location before confirming.';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get tapToSelectLocation => 'Tap on the map to select a location';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get notificationsTapped => 'Notifications tapped';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get returnAnOrder => 'Return an Order';

  @override
  String get manageDiscounts => 'إدارة الخصومات';

  @override
  String get returnOrder => 'إرجاع الطلب';

  @override
  String get demoCustomerName1 => 'Mohammed Al-Rashid';

  @override
  String get demoDeliveryAddress1 =>
      'Kuwait City, Block 7, Street 12, Building 8';

  @override
  String get demoDishName1 => 'Grilled Chicken';

  @override
  String get demoDishName2 => 'Caesar Salad';

  @override
  String get demoDishName3 => 'French Fries';

  @override
  String get demoNotes1 => 'Please provide extra ketchup.';

  @override
  String get simulatedCustomerName1 => 'Ahmed Ali';

  @override
  String get simulatedCustomerName2 => 'Sara Mohammed';

  @override
  String get simulatedCustomerName3 => 'Khalid Omar';

  @override
  String get simulatedCustomerName4 => 'Fatima Hassan';

  @override
  String get simulatedCustomerName5 => 'Omar Youssef';

  @override
  String get simulatedDishName1 => 'Beef Burger';

  @override
  String get simulatedDishName2 => 'Onion Rings';

  @override
  String get simulatedDishName3 => 'Cola';

  @override
  String get simulatedNotes1 => 'Extra pickles in the burger please.';

  @override
  String simulatedDeliveryAddress(int block, int street) {
    return 'Kuwait City, Block $block, Street $street';
  }

  @override
  String get returnOrderPressed => 'Return order pressed';

  @override
  String get simulatedCustomerName6 => 'Sara Al-Mutairi';

  @override
  String get simulatedCustomerName7 => 'Omar Al-Kandari';

  @override
  String get simulatedCustomerName8 => 'Noor Al-Ajmi';

  @override
  String get simulatedCustomerName9 => 'Khalid Al-Rashid';

  @override
  String get simulatedCustomerName10 => 'Maryam Al-Sabah';

  @override
  String get simulatedNotes2 => 'Customer has allergies to certain ingredients';

  @override
  String get demoRestaurantCustomerName => 'Jassim Abdullah';

  @override
  String get demoRestaurantDeliveryAddress =>
      'Salmiya, Block 10, Street 5, Building 15';

  @override
  String get demoRestaurantDishName1 => 'Margherita Pizza';

  @override
  String get demoRestaurantDishName2 => 'Pasta Alfredo';

  @override
  String get demoRestaurantDishName3 => 'Garlic Bread';

  @override
  String get demoRestaurantNotes => 'No olives on the pizza, please.';

  @override
  String get simulatedRestaurantCustomerName1 => 'Fatima Ahmed';

  @override
  String get simulatedRestaurantCustomerName2 => 'Youssef Hassan';

  @override
  String get simulatedRestaurantCustomerName3 => 'Aisha Ibrahim';

  @override
  String get simulatedRestaurantCustomerName4 => 'Mohammed Jassem';

  @override
  String get simulatedRestaurantCustomerName5 => 'Zainab Ali';

  @override
  String get simulatedRestaurantDishName1 => 'Pepperoni Pizza';

  @override
  String get simulatedRestaurantDishName2 => 'Vegetable Lasagna';

  @override
  String get simulatedRestaurantDishName3 => 'Tiramisu';

  @override
  String get simulatedRestaurantNotes => 'Extra cheese on the lasagna.';

  @override
  String get demoStoreCustomerName => 'Abdullah Al-Fahad';

  @override
  String get demoStoreDeliveryAddress =>
      'Hawally, Block 3, Street 8, Building 20';

  @override
  String get demoStoreItemName1 => 'Organic Apples';

  @override
  String get demoStoreItemName2 => 'Whole Wheat Bread';

  @override
  String get demoStoreItemName3 => 'Fresh Milk';

  @override
  String get demoStoreNotes => 'Please select ripe apples.';

  @override
  String get simulatedStoreCustomerName1 => 'Maryam Khalid';

  @override
  String get simulatedStoreCustomerName2 => 'Ali Saleh';

  @override
  String get simulatedStoreCustomerName3 => 'Noura Saad';

  @override
  String get simulatedStoreCustomerName4 => 'Fahad Nasser';

  @override
  String get simulatedStoreCustomerName5 => 'Hessa Mubarak';

  @override
  String get simulatedStoreItemName1 => 'Imported Cheese';

  @override
  String get simulatedStoreItemName2 => 'Artisanal Honey';

  @override
  String get simulatedStoreItemName3 => 'Sparkling Water';

  @override
  String get simulatedStoreNotes => 'Handle with care, fragile items.';

  @override
  String get businessIsNowOnline => 'النشاط التجاري متصل الآن';

  @override
  String get businessIsNowOffline => 'النشاط التجاري غير متصل الآن';

  @override
  String get returnOrderFeature => 'ميزة إرجاع الطلب قادمة قريباً';

  @override
  String get orderNotFound => 'لم يتم العثور على الطلب';

  @override
  String get orderReturnedSuccessfully => 'تم إرجاع الطلب بنجاح';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get iraqiPhoneRequired =>
      'Please enter a valid Iraqi phone number (+964 77X/78X/79X XXXXXXX)';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters long';

  @override
  String get passwordRequiresSpecial =>
      'Password must contain at least one special character';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get validEmailRequired => 'Please enter a valid email address';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get languageSettings => 'إعدادات اللغة';

  @override
  String get posSystemType => 'نوع نظام نقاط البيع';

  @override
  String get selectPosSystem => 'اختر نظام نقاط البيع';

  @override
  String get apiConfiguration => 'إعدادات واجهة برمجة التطبيقات';

  @override
  String get apiEndpoint => 'نقطة نهاية API';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get accessToken => 'رمز الوصول';

  @override
  String get locationId => 'معرف الموقع';

  @override
  String get pleaseEnterApiEndpoint => 'يرجى إدخال نقطة نهاية API';

  @override
  String get pleaseEnterValidUrl => 'يرجى إدخال رابط صحيح';

  @override
  String get pleaseEnterApiKey => 'يرجى إدخال مفتاح API';

  @override
  String get enterApiKey => 'أدخل مفتاح API الخاص بك';

  @override
  String get enterAccessToken => 'أدخل رمز الوصول (اختياري)';

  @override
  String get enterLocationId => 'أدخل معرف الموقع (اختياري)';

  @override
  String get posIntegrationSettings => 'إعدادات التكامل مع نقاط البيع';

  @override
  String get enablePosIntegration => 'تفعيل التكامل مع نقاط البيع';

  @override
  String get enablePosIntegrationDescription =>
      'إرسال الطلبات تلقائياً إلى نظام نقاط البيع';

  @override
  String get autoSendOrders => 'إرسال الطلبات تلقائياً';

  @override
  String get autoSendOrdersDescription =>
      'إرسال الطلبات الجديدة تلقائياً إلى نقاط البيع عند استلامها';

  @override
  String get connectionStatus => 'حالة الاتصال';

  @override
  String get posIntegrationEnabled => 'تم تفعيل التكامل مع نقاط البيع';

  @override
  String get posIntegrationDisabled => 'تم إلغاء التكامل مع نقاط البيع';

  @override
  String get system => 'النظام';

  @override
  String get endpoint => 'نقطة النهاية';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get testing => 'جاري الاختبار...';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get connectionSuccessful => 'تم الاتصال بنجاح!';

  @override
  String get connectionFailed => 'فشل الاتصال. يرجى التحقق من الإعدادات.';

  @override
  String get posSettingsUpdated => 'تم تحديث إعدادات نقاط البيع بنجاح!';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';
}
