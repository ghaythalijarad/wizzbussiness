// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Business Manager';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get register => 'Register';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get forgotPasswordQuestion => 'Forgot Password?';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account?';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get failedToFetchProfile => 'Failed to fetch profile';

  @override
  String get noBusinessFoundForUser => 'No business found for this user';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get demoStore => 'Demo Store';

  @override
  String get demoPharmacy => 'Demo Pharmacy';

  @override
  String get demoRestaurant => 'Demo Restaurant';

  @override
  String get demoKitchen => 'Demo Kitchen';

  @override
  String get orders => 'Orders';

  @override
  String get items => 'Items';

  @override
  String get analytics => 'Analytics';

  @override
  String get discounts => 'Discounts';

  @override
  String get settings => 'Settings';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get goOnline => 'Go Online';

  @override
  String get goOffline => 'Go Offline';

  @override
  String get businessIsNowOnline => 'Business is now online';

  @override
  String get businessIsNowOffline => 'Business is now offline';

  @override
  String get returnOrderFeature => 'Return order feature coming soon';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsTapped => 'Notifications tapped';

  @override
  String get returnAnOrder => 'Return an Order';

  @override
  String get manageDiscounts => 'Manage Discounts';

  @override
  String get returnOrder => 'Return Order';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get posSettings => 'POS Settings';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get logout => 'Logout';

  @override
  String get businessName => 'Business Name';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get businessAddressLabel => 'Business Address';

  @override
  String get rating => 'Rating';

  @override
  String get changePassword => 'Change Password';

  @override
  String get posSettingsUpdated => 'POS settings updated successfully';

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get close => 'Close';

  @override
  String get posSystemType => 'POS System Type';

  @override
  String get selectPosSystem => 'Select POS System';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get apiEndpoint => 'API Endpoint';

  @override
  String get pleaseEnterApiEndpoint => 'Please enter API endpoint';

  @override
  String get pleaseEnterValidUrl => 'Please enter a valid URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get enterApiKey => 'Enter API Key';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get pleaseEnterApiKey => 'Please enter API key';

  @override
  String get accessToken => 'Access Token';

  @override
  String get enterAccessToken => 'Enter Access Token';

  @override
  String get locationId => 'Location ID';

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
  String get connectionStatus => 'Connection Status';

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
  String get saveSettings => 'Save Settings';

  @override
  String get posSyncLogs => 'POS Sync Logs';

  @override
  String get noSyncLogsFound => 'No sync logs found';

  @override
  String get status => 'Status';

  @override
  String get successful => 'Successful';

  @override
  String get failed => 'Failed';

  @override
  String get syncLogDetails => 'Sync Log Details';

  @override
  String get syncTime => 'Sync Time';

  @override
  String get posOrderId => 'POS Order ID';

  @override
  String get errorMessage => 'Error Message';

  @override
  String get retrySync => 'Retry Sync';

  @override
  String get orderSyncRetryInitiated => 'Order sync retry initiated';

  @override
  String get advancedConfiguration => 'Advanced Configuration';

  @override
  String get timeoutSeconds => 'Timeout (seconds)';

  @override
  String get retryAttempts => 'Retry Attempts';

  @override
  String get testMode => 'Test Mode';

  @override
  String get testModeDescription => 'Enable test mode for development';

  @override
  String get webhooksIntegration => 'Webhooks Integration';

  @override
  String get webhooksDescription =>
      'Configure webhooks for real-time notifications';

  @override
  String get configureWebhooks => 'Configure Webhooks';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get encryptionStatus => 'Encryption Status';

  @override
  String get encryptionEnabled => 'Encryption Enabled';

  @override
  String get apiKeyRotation => 'API Key Rotation';

  @override
  String get lastRotated => 'Last Rotated';

  @override
  String get rotate => 'Rotate';

  @override
  String get systemSetupGuides => 'System Setup Guides';

  @override
  String get setupGuide => 'Setup Guide';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get connectionIssues => 'Connection Issues';

  @override
  String get syncFailures => 'Sync Failures';

  @override
  String get apiErrors => 'API Errors';

  @override
  String get supportContact => 'Support Contact';

  @override
  String get liveChat => 'Live Chat';

  @override
  String get availableWeekdays => 'Available weekdays 9 AM - 5 PM';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get liveChatComingSoon => 'Live chat coming soon';

  @override
  String get emailSupportOpened => 'Email support opened';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get syncLogs => 'Sync Logs';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get help => 'Help';

  @override
  String get allDiscounts => 'All Discounts';

  @override
  String get activeDiscounts => 'Active Discounts';

  @override
  String get scheduledDiscounts => 'Scheduled Discounts';

  @override
  String get expiredDiscounts => 'Expired Discounts';

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
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get editDiscount => 'Edit Discount';

  @override
  String get title => 'Title';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get description => 'Description';

  @override
  String get discountType => 'Discount Type';

  @override
  String get percentage => 'Percentage';

  @override
  String get fixedAmount => 'Fixed Amount';

  @override
  String get conditional => 'Conditional';

  @override
  String get buyXGetY => 'Buy X Get Y';

  @override
  String get freeDelivery => 'Free Delivery';

  @override
  String get others => 'Others';

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
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get create => 'Create';

  @override
  String get off => 'off';

  @override
  String get discount => 'discount';

  @override
  String get active => 'Active';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get expired => 'Expired';

  @override
  String get sampleItem => 'Sample Item';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get averageOrderValue => 'Average Order Value';

  @override
  String get topSellingItems => 'Top Selling Items';

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
  String get currencyPrefix => 'IQD ';

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
  String get addNewItem => 'Add New Item';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get newCategoryName => 'New Category Name';

  @override
  String get pleaseEnterCategoryName => 'Please enter category name';

  @override
  String get selectExistingCategory => 'Select Existing Category';

  @override
  String get addNewCategory => 'Add New Category';

  @override
  String get itemName => 'Item Name';

  @override
  String get pleaseEnterItemName => 'Please enter item name';

  @override
  String get price => 'Price';

  @override
  String get pleaseEnterPrice => 'Please enter price';

  @override
  String get pleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get optional => 'Optional';

  @override
  String get available => 'Available';

  @override
  String get add => 'Add';

  @override
  String get editItem => 'Edit Item';

  @override
  String get update => 'Update';

  @override
  String get pending => 'Pending';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get orderReady => 'Ready';

  @override
  String get pickedUp => 'Picked Up';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get orderReturned => 'Returned';

  @override
  String noOrdersFoundFor(String filter) {
    return 'No orders found for $filter';
  }

  @override
  String get notes => 'Notes';

  @override
  String get total => 'Total';

  @override
  String get reject => 'Reject';

  @override
  String get accept => 'Accept';

  @override
  String get required => 'Required';

  @override
  String get changeFile => 'Change File';

  @override
  String get selectFile => 'Select File';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get store => 'Store';

  @override
  String get pharmacy => 'Pharmacy';

  @override
  String get cloudKitchen => 'Cloud Kitchen';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get registrationSubmitted => 'Registration Submitted';

  @override
  String get registrationSubmittedMessage =>
      'Your registration has been submitted for review';

  @override
  String get businessInformation => 'Business Information';

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
  String get businessOwnerInformation => 'Business Owner Information';

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
  String get businessRegistration => 'Business Registration';

  @override
  String get businessAndOwnerInformation => 'Business and Owner Information';

  @override
  String get businessType => 'Business Type';

  @override
  String get selectBusinessType => 'Please select a business type';

  @override
  String get pleaseEnterBusinessName => 'Please enter business name';

  @override
  String get pleaseEnterOwnerName => 'Please enter owner name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get country => 'Country';

  @override
  String get pleaseEnterCountry => 'Please enter country';

  @override
  String get city => 'City';

  @override
  String get pleaseEnterCity => 'Please enter city';

  @override
  String get district => 'District';

  @override
  String get pleaseEnterDistrict => 'Please enter district';

  @override
  String get zipCode => 'Zip Code';

  @override
  String get pleaseEnterZipCode => 'Please enter zip code';

  @override
  String get neighbourhood => 'Neighbourhood';

  @override
  String get pleaseEnterNeighbourhood => 'Please enter neighbourhood';

  @override
  String get street => 'Street';

  @override
  String get pleaseEnterStreet => 'Please enter street';

  @override
  String get buildingNumber => 'Building Number';

  @override
  String get nationalId => 'National ID';

  @override
  String get pleaseEnterNationalId => 'Please enter national ID';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get pleaseEnterDateOfBirth => 'Please enter date of birth';

  @override
  String get ownerNationalId => 'Owner National ID';

  @override
  String get ownerNationalIdSubtitle =>
      'Upload a clear photo of the national ID';

  @override
  String get ownerPhoto => 'Owner Photo';

  @override
  String get ownerPhotoSubtitle => 'Upload a clear photo of the owner';

  @override
  String get requiredDocuments => 'Required Documents';

  @override
  String get commercialLicense => 'Commercial License';

  @override
  String get commercialLicenseSubtitle =>
      'Upload your business commercial license';

  @override
  String get healthCertificate => 'Health Certificate';

  @override
  String get healthCertificateSubtitle =>
      'Required for food-related businesses';

  @override
  String get submitRegistration => 'Submit Registration';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get emailSent => 'Email Sent';

  @override
  String get passwordResetLinkSent =>
      'A password reset link has been sent to your email';

  @override
  String get ok => 'OK';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get pleaseEnterOtp => 'Please enter OTP';

  @override
  String get resetYourPassword => 'Reset Your Password';

  @override
  String get emailOrPhone => 'Email or Phone';

  @override
  String get pleaseEnterEmailAddress => 'Please enter your email address';

  @override
  String get newPassword => 'New Password';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get pleaseConfirmPassword => 'Please confirm password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String newOrderReceived(String customerName) {
    return 'New order received from $customerName';
  }

  @override
  String get passwordResetSuccessful => 'Password Reset Successful';

  @override
  String get passwordResetSuccessMessage =>
      'Your password has been reset successfully.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get passwordLengthRequirement =>
      'Password must be at least 8 characters.';

  @override
  String get passwordComplexityRequirement =>
      'Password must include uppercase, lowercase, and numbers.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get enterNewPasswordBelow => 'Enter your new password below.';

  @override
  String get passwordRequirements => 'Password Requirements';

  @override
  String get passwordRequirementsDetails =>
      'Must be at least 8 characters, include uppercase, lowercase, and a number.';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get autoFillAddress => 'Auto-fill Address';

  @override
  String get validityPeriod => 'Validity Period';

  @override
  String get unknownStatus => 'Unknown Status';

  @override
  String get discountCombinationWarning =>
      'This discount type cannot be combined with existing active discounts';

  @override
  String get freeDeliveryCombinable =>
      'Free Delivery can be combined with other discounts';

  @override
  String get discountCreatedSuccessfully => 'Discount created successfully';

  @override
  String get discountUpdatedSuccessfully => 'Discount updated successfully';

  @override
  String get combinableDiscount => 'Combinable';

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
  String get selectCategories => 'Select Categories';

  @override
  String get noItemsSelected => 'No items selected';

  @override
  String get noCategoriesSelected => 'No categories selected';

  @override
  String get categories => 'Categories';

  @override
  String get conflictingDiscounts =>
      'Some selected items or categories already have active discounts. Each item can only have one discount at a time.';

  @override
  String get wizzBusiness => 'Wizz Business';

  @override
  String get businessManagement => 'Business Management';

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
  String get networkError => 'Network error';

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
  String get businessLocation => 'Business Location';

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
  String get confirmLocation => 'Confirm Location';

  @override
  String get tapToSelectLocation => 'Tap to Select Location';

  @override
  String get registrationDate => 'Registration Date';

  @override
  String get smartBusinessControls => 'Smart business controls';

  @override
  String get readyToReceiveOrders => 'Ready to receive orders';

  @override
  String get ordersArePaused => 'Orders are paused';

  @override
  String get menuItemsAndCategories => 'Menu items & categories';

  @override
  String get businessInsights => 'Business insights';

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
  String get managePromotionalOffers => 'Manage promotional offers';

  @override
  String get viewBusinessInsights => 'View business insights';

  @override
  String get manageItemsAndCategories => 'Manage items & categories';

  @override
  String get platformIntegration => 'Platform Integration';

  @override
  String get centralizedDeliveryPlatform => 'Centralized delivery platform';

  @override
  String get appAndAccountPreferences => 'App & account preferences';

  @override
  String get keyboardShortcutsTip =>
      'Tip: Use keyboard shortcuts for faster actions';

  @override
  String get conditionalDiscountConfiguration =>
      'Conditional Discount Configuration';

  @override
  String get buyXGetYConfiguration => 'Buy X Get Y Configuration';

  @override
  String get buyConfiguration => 'Buy Configuration';

  @override
  String get getConfiguration => 'Get Configuration';

  @override
  String get quantity => 'Quantity';

  @override
  String get selectItem => 'Select Item';

  @override
  String get itemSelected => 'Item Selected';

  @override
  String get enterValidQuantity => 'Enter valid quantity';

  @override
  String get missingItems => 'Missing Items';

  @override
  String pleasSelectBothBuyAndGetItems(String discountType) {
    return 'Please select both buy and get items for $discountType discount.';
  }

  @override
  String get addFreeDeliveryToDiscount => 'Add free delivery to this discount';

  @override
  String get conflictingDiscountsTitle => 'Conflicting Discounts';

  @override
  String get someSelectedItemsAlreadyHaveDiscounts =>
      'Some selected items or categories already have active discounts. Each item can only have one discount at a time.';

  @override
  String get applicabilityNotConfigurable =>
      'Applicability is not configurable for this discount type as items are already specified in the configuration above.';

  @override
  String get noItemSelected => 'No item selected';

  @override
  String get appliesToAllItems => 'Applies to all items';

  @override
  String appliesToSpecificItems(int count) {
    return 'Applies to $count specific items';
  }

  @override
  String appliesToCategories(int count) {
    return 'Applies to $count categories';
  }

  @override
  String get appliesToOrdersAboveMinimum =>
      'Applies to orders above minimum amount';

  @override
  String validFromTo(int startDay, int startMonth, int startYear, int endDay,
      int endMonth, int endYear) {
    return 'Valid: $startDay/$startMonth/$startYear - $endDay/$endMonth/$endYear';
  }

  @override
  String minAmount(String amount) {
    return 'Min: \$$amount';
  }

  @override
  String categoriesSelected(int count) {
    return '$count categories selected';
  }

  @override
  String itemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String missingItemsMessage(String discountType) {
    return 'Please select both buy and get items for $discountType discount.';
  }

  @override
  String get selectBuyItem => 'Select Buy Item';

  @override
  String get selectGetItem => 'Select Get Item';

  @override
  String get noCategoriesFound =>
      'No categories found. Please add categories first.';

  @override
  String get appliesToMinimumOrder => 'Applies to orders above minimum amount';

  @override
  String get startSimulation => 'Start Simulation';

  @override
  String get stopSimulation => 'Stop Simulation';

  @override
  String get simulateNewOrder => 'Simulate New Order';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get live => 'Live';

  @override
  String get sendTestNotification => 'Send Test Notification';

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
    return 'Failed to send test notification';
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
  String get today => 'Today';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get overview => 'Overview';

  @override
  String get revenue => 'Revenue';

  @override
  String get performance => 'Performance';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get todaysRevenue => 'Today\'s Revenue';

  @override
  String get avgOrderValue => 'Avg Order Value';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get customersServed => 'Customers Served';

  @override
  String get cancellationRate => 'Cancellation Rate';

  @override
  String get revenueTrend => 'Revenue Trend';

  @override
  String get revenueBreakdown => 'Revenue Breakdown';

  @override
  String get dailyRevenue => 'Daily Revenue';

  @override
  String get weeklyRevenue => 'Weekly Revenue';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String get performanceMetrics => 'Performance Metrics';

  @override
  String get avgPrepTime => 'Avg Prep Time';

  @override
  String get successRate => 'Success Rate';

  @override
  String get specialDish => 'Special Dish';

  @override
  String get popularItem => 'Popular Item';

  @override
  String get revenueLabel => 'Revenue';

  @override
  String get errorLoadingUserData => 'Error loading user data';

  @override
  String get retry => 'Retry';

  @override
  String get userInformation => 'User Information';

  @override
  String get security => 'Security';

  @override
  String get passwordChangeAvailableInSettings =>
      'Password change is available in the main Settings page.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get kitchen => 'Kitchen';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get verified => 'Verified';

  @override
  String get centralizedPlatform => 'Centralized Platform';

  @override
  String get platformConnection => 'Platform Connection';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get account => 'Account';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get platformApps => 'Platform Apps';

  @override
  String get localBusinesses => 'Local Businesses';

  @override
  String get syncRecommended => 'Sync Recommended';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get noAppsFound => 'No apps found';

  @override
  String get unknown => 'Unknown';

  @override
  String get actions => 'Actions';

  @override
  String get setupPlatform => 'Setup Platform';

  @override
  String get syncAllBusinesses => 'Sync All Businesses';

  @override
  String get refreshStatus => 'Refresh Status';

  @override
  String get failedToLoadPlatformStatus => 'Failed to load platform status';

  @override
  String get platformSetupCompletedSuccessfully =>
      'Platform setup completed successfully!';

  @override
  String get platformSetupFailed => 'Platform setup failed';

  @override
  String get errorSettingUpPlatform => 'Error setting up platform';

  @override
  String get allBusinessesSyncedSuccessfully =>
      'All businesses synced successfully!';

  @override
  String get errorSyncingBusinesses => 'Error syncing businesses';

  @override
  String get noBusinessFoundForThisUser => 'No business found for this user';

  @override
  String get loginFailedMessage => 'Login failed';

  @override
  String get notAvailable => 'N/A';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get pleaseEnterOldPassword => 'Please enter your old password';

  @override
  String get pleaseEnterNewPassword => 'Please enter your new password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match';

  @override
  String get generateTestOrders =>
      'Generate test orders to help with development and testing.';

  @override
  String get createRealisticOrders =>
      'This will create realistic orders with random customer data, items, and pricing.';

  @override
  String get createOneOrder => 'Create 1 Order';

  @override
  String get createThreeOrders => 'Create 3 Orders';

  @override
  String get failedToCreateOrders => 'Failed to create orders';

  @override
  String get categoriesLoaded => 'Categories loaded';

  @override
  String get createFirstCategory => 'Create First Category';

  @override
  String get noCategoriesFoundMessage =>
      'No categories found. Create your first category to organize your items.';

  @override
  String get failedToDeleteItem => 'Failed to delete item';

  @override
  String get failedToLoadCategories => 'Failed to load categories';

  @override
  String get failedToAddItem => 'Failed to add item';

  @override
  String get failedToUpdateItem => 'Failed to update item';

  @override
  String get pleaseSelectCategoryOrCreate =>
      'Please select a category or create a new one';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get pleaseCompleteAllRequiredFields =>
      'Please complete all required fields';

  @override
  String get documentSelectedSuccessfully => 'Document selected successfully';

  @override
  String get errorGettingLocation => 'Error getting location';

  @override
  String get pleaseEnterValidEmailAddress =>
      'Please enter a valid email address';

  @override
  String get phoneNumberIsRequired => 'Phone number is required';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get passwordMustBeAtLeast8Characters =>
      'Password must be at least 8 characters long';

  @override
  String get passwordMustContainLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordMustContainUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordMustContainNumber =>
      'Password must contain at least one number';

  @override
  String get passwordMustContainSpecialCharacter =>
      'Password must contain at least one special character';

  @override
  String get pleaseConfirmYourPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatchRegistration => 'Passwords do not match';

  @override
  String get pleaseEnterExactly10Digits => 'Please enter exactly 10 digits';

  @override
  String get pleaseEnterOnlyNumbers => 'Please enter only numbers';

  @override
  String get pleaseEnterValidIraqiNumber =>
      'Please enter a valid Iraqi number (77X/78X/79X for mobile)';

  @override
  String get userWithEmailAlreadyExists =>
      'A user with this email already exists';

  @override
  String get passwordResetEmailSentSuccessfully =>
      'Password reset email sent successfully';

  @override
  String get failedToSendPasswordResetEmail =>
      'Failed to send password reset email';

  @override
  String get registrationFailedStatus => 'Registration failed';

  @override
  String get validationError => 'Validation error';

  @override
  String get failedToFetchTestUserProfile =>
      'Failed to fetch test user profile';

  @override
  String get unknownErrorOccurred => 'An unknown error occurred';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String get noAccessTokenFound => 'No access token found';

  @override
  String get sessionExpiredPleaseLoginAgain =>
      'Session expired. Please login again.';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get errorDuringLogout => 'Error during logout';

  @override
  String get registrationSuccessful => 'Registration successful';

  @override
  String get passwordResetSuccessfully => 'Password reset successfully';

  @override
  String get failedToResetPassword => 'Failed to reset password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get otpSentSuccessfully => 'OTP sent successfully';

  @override
  String get viewAndManageOrders => 'View and manage orders';

  @override
  String get businessDashboardVersion => 'Business Dashboard v2.0';

  @override
  String get modernMaterialDesign => 'Modern Material Design';

  @override
  String get menu => 'Menu';

  @override
  String get aUserWithThisEmailAlreadyExists =>
      'A user with this email already exists';

  @override
  String get anUnknownErrorOccurred => 'An unknown error occurred';

  @override
  String get failedToCreateCategory => 'Failed to create category';

  @override
  String get failedToLoadItems => 'Failed to load items';

  @override
  String get failedToCreateItem => 'Failed to create item';

  @override
  String get failedToLoadNotificationHistory =>
      'Failed to load notification history';

  @override
  String get failedToMarkNotificationAsRead =>
      'Failed to mark notification as read';

  @override
  String get failedToCreateOrder => 'Failed to create order';

  @override
  String get failedToLoadOrders => 'Failed to load orders';

  @override
  String get failedToUpdateOrderStatus => 'Failed to update order status';

  @override
  String get failedToLoadSupportedPosSystems =>
      'Failed to load supported POS systems';

  @override
  String get failedToLoadPosSettings => 'Failed to load POS settings';

  @override
  String get failedToCreatePosSettings => 'Failed to create POS settings';

  @override
  String get failedToUpdatePosSettings => 'Failed to update POS settings';

  @override
  String get failedToDeletePosSettings => 'Failed to delete POS settings';

  @override
  String get failedToTestPosConnection => 'Failed to test POS connection';

  @override
  String get failedToGetPosSystemHealth => 'Failed to get POS system health';

  @override
  String get failedToRetryPosSync => 'Failed to retry POS sync';

  @override
  String get failedToLoadPosIntegrationStatistics =>
      'Failed to load POS integration statistics';

  @override
  String get failedToBulkSyncOrdersToPos => 'Failed to bulk sync orders to POS';

  @override
  String get failedToUpdateWebhookConfiguration =>
      'Failed to update webhook configuration';

  @override
  String get failedToValidatePosCredentials =>
      'Failed to validate POS credentials';

  @override
  String get failedToLoadUserBusinesses => 'Failed to load user businesses';

  @override
  String get failedToLoadComparativeAnalytics =>
      'Failed to load comparative analytics';

  @override
  String get failedToTestPlatformConnection =>
      'Failed to test platform connection';

  @override
  String get errorTestingPlatformConnection =>
      'Error testing platform connection';

  @override
  String get failedToGetPlatformApps => 'Failed to get platform apps';

  @override
  String get errorGettingPlatformApps => 'Error getting platform apps';

  @override
  String get failedToDeployCentralizedApp => 'Failed to deploy centralized app';

  @override
  String get errorDeployingCentralizedApp => 'Error deploying centralized app';

  @override
  String get failedToSyncBusinessToPlatform =>
      'Failed to sync business to platform';

  @override
  String get errorSyncingBusinessToPlatform =>
      'Error syncing business to platform';

  @override
  String get failedToSyncAllBusinessesToPlatform =>
      'Failed to sync all businesses to platform';

  @override
  String get errorSyncingAllBusinessesToPlatform =>
      'Error syncing all businesses to platform';

  @override
  String get failedToGetPlatformSyncStatus =>
      'Failed to get platform sync status';

  @override
  String get errorGettingPlatformSyncStatus =>
      'Error getting platform sync status';

  @override
  String get failedToSetupCentralizedPlatform =>
      'Failed to setup centralized platform';

  @override
  String get errorSettingUpCentralizedPlatform =>
      'Error setting up centralized platform';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get userNotLoggedIn => 'User not logged in. Please log in first.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get showLocalNotifications => 'Show Local Notifications';

  @override
  String get showLocalNotificationsDescription =>
      'Display notifications in system notification area';

  @override
  String get playNotificationSounds => 'Play Notification Sounds';

  @override
  String get playNotificationSoundsDescription =>
      'Play sound when notifications are received';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get testNotificationDescription =>
      'This will send a test notification to verify your settings are working correctly.';

  @override
  String get photoLibrary => 'Photo Library';

  @override
  String get camera => 'Camera';

  @override
  String get errorSelectingDocument => 'Error selecting document';

  @override
  String get errorSelectingImage => 'Error selecting image';

  @override
  String get orderSimulation => 'Order Simulation';

  @override
  String get later => 'Later';

  @override
  String get viewOrder => 'View Order';

  @override
  String get understood => 'Understood';

  @override
  String get error => 'Error';

  @override
  String get minimumOrder => 'Minimum Order';

  @override
  String freeDeliveryIncludedWith(String title) {
    return 'Free delivery included with $title';
  }

  @override
  String freeDeliveryTitle(String title) {
    return '$title - Free Delivery';
  }

  @override
  String get kwd => 'KWD';

  @override
  String categoryAndPrice(String category, String currency, String price) {
    return '$category • $currency $price';
  }
}
