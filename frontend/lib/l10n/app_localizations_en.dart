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
  String get signIn => 'Sign In';

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
  String get joinOrderReceiver => 'Join Order Receiver';

  @override
  String get signUpSubtitle =>
      'Create your business account to start receiving orders';

  @override
  String get accountSecurity => 'Account Security';

  @override
  String get and => 'and';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get iAgreeToThe => 'I agree to the';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get takePicture => 'Take Picture';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get verificationCodeRequired => 'Verification code is required';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get failedToFetchProfile => 'Failed to fetch profile';

  @override
  String get noBusinessFoundForUser => 'No business found for user';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginFailedMessage =>
      'Login failed. Please check your credentials.';

  @override
  String get errorInvalidCredentials =>
      'Invalid email or password. Please check your credentials and try again.';

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
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

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
  String get menu => 'Menu';

  @override
  String get retry => 'Retry';

  @override
  String get errorPickingImage => 'Error picking image';

  @override
  String get errorPickingFile => 'Error picking file';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get businessIsNowOnline => 'Business is now online';

  @override
  String get businessIsNowOffline => 'Business is now offline';

  @override
  String get businessNowOnline => 'Business is now online';

  @override
  String get businessNowOffline => 'Business is now offline';

  @override
  String get errorUpdatingStatus => 'Error updating status. Please try again.';

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
  String get locationSettings => 'Location Settings';

  @override
  String get workingHoursSettings => 'Working Hours Settings';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String timeoutFirstAlert(String remainingTime) {
    return 'Auto-reject in $remainingTime';
  }

  @override
  String timeoutUrgentAlert(String remainingTime) {
    return 'URGENT: Reject in $remainingTime';
  }

  @override
  String get timeoutAutoReject => 'Order will be auto-rejected';

  @override
  String get openingTime => 'Opening Time';

  @override
  String get closingTime => 'Closing Time';

  @override
  String get setOpeningTime => 'Set Opening Time';

  @override
  String get setClosingTime => 'Set Closing Time';

  @override
  String get notSet => 'Not set';

  @override
  String get workingHoursSaved => 'Working hours saved successfully';

  @override
  String get businessManagement => 'Business Management';

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
  String get personalInformation => 'Personal Information';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get accountStatus => 'Account Status';

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
  String get general => 'General';

  @override
  String get advanced => 'Advanced';

  @override
  String get posIntegration => 'POS Integration';

  @override
  String get noSyncLogsAvailable => 'No sync logs available';

  @override
  String get syncSettings => 'Sync Settings';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String get minutes => 'minutes';

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
  String get webhookSetupTitle => 'Webhook Setup Guide';

  @override
  String get webhookSetupDescription =>
      'Follow these steps to configure webhooks';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get contactSupportDescription =>
      'Need help with POS integration? Contact our support team';

  @override
  String get webhookConfigTitle => 'Webhook Configuration';

  @override
  String get webhookConfigDescription =>
      'Configure webhook endpoints for real-time synchronization';

  @override
  String get webhookStep1 => 'Step 1: Create webhook endpoint';

  @override
  String get webhookStep2 => 'Step 2: Configure authentication';

  @override
  String get webhookStep3 => 'Step 3: Test connection';

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
  String get minimumOrder => 'Minimum Order';

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
  String get validityPeriod => 'Validity Period';

  @override
  String get unknownStatus => 'Unknown Status';

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
  String get orderStatusOnTheWay => 'On the Way';

  @override
  String get orderStatusDelivered => 'Delivered';

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
  String get preparing => 'Preparing';

  @override
  String get orderReady => 'Ready';

  @override
  String get onTheWay => 'On the Way';

  @override
  String get delivered => 'Delivered';

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
  String get cafe => 'Cafe';

  @override
  String get bakery => 'Bakery';

  @override
  String get herbalspices => 'Herbal & Spices';

  @override
  String get cosmetics => 'Cosmetics';

  @override
  String get betshop => 'Bet Shop';

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
  String get registerYourBusiness => 'Register Your Business';

  @override
  String get welcomeToHadhir => 'Welcome to Hadhir';

  @override
  String get fillInTheFormBelowToGetStarted =>
      'Fill in the form below to get started';

  @override
  String get createYourBusinessAccount => 'Create Your Business Account';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get uploaded => 'Uploaded';

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
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get invalidEmailFormat => 'Please enter a valid email address';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get businessNameRequired => 'Business name is required';

  @override
  String get pleaseEnterYourBusinessName => 'Please enter your business name';

  @override
  String get businessAddress => 'Business Address';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State/Province';

  @override
  String get zipCode => 'ZIP/Postal Code';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccess => 'Registration successful';

  @override
  String get emailAlreadyInUse => 'Email address is already in use';

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
  String get failedToSaveLocation => 'Failed to save location';

  @override
  String get businessLocationDescription =>
      'Set your business location to help customers find you and improve delivery accuracy.';

  @override
  String get locationInformation => 'Location Information';

  @override
  String get customerVisibility => 'Customer Visibility';

  @override
  String get customerVisibilityDescription =>
      'Your location will be shown to customers when they place orders';

  @override
  String get deliveryOptimization => 'Delivery Optimization';

  @override
  String get deliveryOptimizationDescription =>
      'Accurate location helps optimize delivery routes and timing';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get privacyAndSecurityDescription =>
      'Your location data is encrypted and securely stored';

  @override
  String get pleaseSignInToAccessLocationSettings =>
      'Please sign in to access location settings';

  @override
  String get smartBusinessControls => 'Smart business controls';

  @override
  String get readyToReceiveOrders => 'Ready to receive orders';

  @override
  String get ordersArePaused => 'Orders are paused';

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
  String get ok => 'OK';

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
  String get newOrder => 'New Order';

  @override
  String get viewDetails => 'View Details';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get live => 'Live';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get showLocalNotifications => 'Show Local Notifications';

  @override
  String get showLocalNotificationsDescription =>
      'Display notifications on this device';

  @override
  String get playNotificationSounds => 'Play Notification Sounds';

  @override
  String get playNotificationSoundsDescription =>
      'Play sounds when notifications are received';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get testNotificationDescription =>
      'Send a test notification to verify settings';

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
  String get performance => 'Performance';

  @override
  String get revenue => 'Revenue';

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
  String get performanceMetrics => 'Performance Metrics';

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
  String get businessPhoto => 'Business Photo';

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
  String get loginInstead => 'Login Instead';

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
  String get verificationFailed => 'Verification failed';

  @override
  String get error => 'Error';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String verificationCodeSentTo(String email) {
    return 'Verification code sent to $email';
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
  String get kwd => 'KWD';

  @override
  String get categories => 'categories';

  @override
  String get notSpecified => 'Not Specified';

  @override
  String get verified => 'Verified';

  @override
  String get viewAndManageOrders => 'View and manage orders';

  @override
  String get businessDashboardVersion => 'Business Dashboard Version';

  @override
  String get modernMaterialDesign => 'Modern Material Design';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get businessLicense => 'Business License';

  @override
  String get ownerIdentity => 'Owner Identity';

  @override
  String get healthCertificate => 'Health Certificate';

  @override
  String get ownerPhoto => 'Owner Photo';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get kitchen => 'Kitchen';

  @override
  String get chooseFromFiles => 'Choose from Files';

  @override
  String get accountInformation => 'Account Information';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get pleaseEnterAValidEmail => 'Please enter a valid email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get passwordMustBeAtLeast8Chars =>
      'Password must be at least 8 characters';

  @override
  String get reEnterYourPassword => 'Re-enter your password';

  @override
  String get enterYourBusinessName => 'Enter your business name';

  @override
  String get enterOwnerName => 'Enter owner name';

  @override
  String get ownerFirstName => 'Owner First Name';

  @override
  String get enterOwnerFirstName => 'Enter owner first name';

  @override
  String get pleaseEnterOwnerFirstName => 'Please enter owner first name';

  @override
  String get ownerLastName => 'Owner Last Name';

  @override
  String get enterOwnerLastName => 'Enter owner last name';

  @override
  String get pleaseEnterOwnerLastName => 'Please enter owner last name';

  @override
  String get enterYourBusinessPhone => 'Enter your business phone';

  @override
  String get pleaseEnterYourPhoneNumber => 'Please enter your phone number';

  @override
  String get addAPhotoToShowcaseYourBusiness =>
      'Add a photo to showcase your business';

  @override
  String get enterYourCity => 'Enter your city';

  @override
  String get pleaseEnterYourCity => 'Please enter your city';

  @override
  String get district => 'District';

  @override
  String get enterYourDistrict => 'Enter your district';

  @override
  String get pleaseEnterYourDistrict => 'Please enter your district';

  @override
  String get enterYourStreetAddress => 'Enter your street address';

  @override
  String get pleaseEnterYourStreetAddress => 'Please enter your street address';

  @override
  String get documentsRequired => 'Documents Required';

  @override
  String get pleaseUploadAllRequiredDocuments =>
      'Please upload all required documents';

  @override
  String get emailVerification => 'Email Verification';

  @override
  String get enterTheCodeSentToYourEmail => 'Enter the code sent to your email';

  @override
  String get changeEmail => 'Change Email';

  @override
  String get enter6DigitCode => 'Enter 6-digit code';

  @override
  String get enterVerificationCode => 'Enter verification code';

  @override
  String get pleaseEnterVerificationCode => 'Please enter verification code';

  @override
  String get pleaseEnterTheVerificationCode =>
      'Please enter the verification code';

  @override
  String get verificationCodeSent => 'Verification code sent to your email';

  @override
  String get resendVerificationCode => 'Resend Verification Code';

  @override
  String get failedToResendCode => 'Failed to resend verification code';

  @override
  String get troubleshootingSection => 'Troubleshooting';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get completeRegistration => 'Complete Registration';

  @override
  String get createAccount => 'Create Account';

  @override
  String get none => 'None';

  @override
  String get account => 'Account';

  @override
  String get business => 'Business';

  @override
  String get location => 'Location';

  @override
  String get documents => 'Documents';

  @override
  String get createYourAccount => 'Create Your Account';

  @override
  String get enterAccountDetails => 'Enter your account details to get started';

  @override
  String get tellUsAboutYourBusiness => 'Tell us about your business';

  @override
  String get whereIsYourBusiness => 'Where is your business located?';

  @override
  String get uploadDocumentsOptional =>
      'Upload documents to verify your business (optional)';

  @override
  String get selectSubcategory => 'Select Subcategory (Optional)';

  @override
  String get businessSubcategory => 'Business Subcategory (Optional)';

  @override
  String get uploadBusinessLicense => 'Upload your business license';

  @override
  String get identityDocument => 'Identity Document';

  @override
  String get uploadIdentityDocument => 'Upload your identity document';

  @override
  String get uploadHealthCertificate => 'Upload your health certificate';

  @override
  String get uploadOwnerPhoto => 'Upload a photo of the owner';

  @override
  String get uploadBusinessPhoto => 'Upload a photo of your business';

  @override
  String get country => 'Country';

  @override
  String get enterCountry => 'Enter your country';

  @override
  String get pleaseEnterCountry => 'Please enter your country';

  @override
  String get enterCity => 'Enter your city';

  @override
  String get pleaseEnterCity => 'Please enter your city';

  @override
  String get enterDistrict => 'Enter your district';

  @override
  String get pleaseEnterDistrict => 'Please enter your district';

  @override
  String get enterStreetAddress => 'Enter your street address';

  @override
  String get pleaseEnterStreetAddress => 'Please enter your street address';

  @override
  String get registrationSuccessful =>
      'Registration successful! Welcome to Hadhir Business.';

  @override
  String get registrationVerifiedSuccessfully =>
      'Registration verified successfully!';

  @override
  String verificationFailedWithReason(String reason) {
    return 'Verification failed: $reason';
  }

  @override
  String get verificationCodeSentToEmail =>
      'Verification code sent to your email';

  @override
  String registrationFailedWithReason(String reason) {
    return 'Registration failed: $reason';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get wrongEmailChangeIt => 'Wrong email? Change it';

  @override
  String get verificationCodeMustBe6Digits =>
      'Verification code must be 6 digits';

  @override
  String get accountAlreadyVerifiedPleaseSignIn =>
      'Account already verified. Please sign in.';

  @override
  String get tooManyAttemptsPleaseWait =>
      'Too many attempts. Please wait and try again.';

  @override
  String get noAccountFoundForThisEmail => 'No account found for this email.';

  @override
  String get mustAgreeToTerms => 'You must agree to the terms and conditions';

  @override
  String get passwordRequirementsTitle => 'Password Requirements';

  @override
  String get passwordRequirementsBullets =>
      '• At least 8 characters\n• Include uppercase, lowercase, numbers, and a special character';

  @override
  String get changeEmailAddressTitle => 'Change Email Address';

  @override
  String get changeEmailAddressMessage =>
      'Are you sure you want to change your email address? This will take you back to the sign-up screen.';

  @override
  String get invalidIraqiPhoneNumber =>
      'Please enter a valid Iraqi number (77X/78X/79X for mobile)';

  @override
  String get centralizedPlatform => 'Centralized Platform';

  @override
  String get platformConnection => 'Platform Connection';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

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
      'Platform setup completed successfully';

  @override
  String get platformSetupFailed => 'Platform setup failed';

  @override
  String get errorSettingUpPlatform => 'Error setting up platform';

  @override
  String get allBusinessesSyncedSuccessfully =>
      'All businesses synced successfully';

  @override
  String get failedToSyncAllBusinessesToPlatform =>
      'Failed to sync all businesses to platform';

  @override
  String get errorSyncingBusinesses => 'Error syncing businesses';

  @override
  String get noAppsFound => 'No apps found';
}
