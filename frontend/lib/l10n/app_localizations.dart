import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Manager'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToYourAccount;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @failedToFetchProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch profile'**
  String get failedToFetchProfile;

  /// No description provided for @noBusinessFoundForUser.
  ///
  /// In en, this message translates to:
  /// **'No business found for this user'**
  String get noBusinessFoundForUser;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @demoStore.
  ///
  /// In en, this message translates to:
  /// **'Demo Store'**
  String get demoStore;

  /// No description provided for @demoPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Demo Pharmacy'**
  String get demoPharmacy;

  /// No description provided for @demoRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Demo Restaurant'**
  String get demoRestaurant;

  /// No description provided for @demoKitchen.
  ///
  /// In en, this message translates to:
  /// **'Demo Kitchen'**
  String get demoKitchen;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @discounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get discounts;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go Offline'**
  String get goOffline;

  /// No description provided for @businessIsNowOnline.
  ///
  /// In en, this message translates to:
  /// **'Business is now online'**
  String get businessIsNowOnline;

  /// No description provided for @businessIsNowOffline.
  ///
  /// In en, this message translates to:
  /// **'Business is now offline'**
  String get businessIsNowOffline;

  /// No description provided for @returnOrderFeature.
  ///
  /// In en, this message translates to:
  /// **'Return order feature coming soon'**
  String get returnOrderFeature;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsTapped.
  ///
  /// In en, this message translates to:
  /// **'Notifications tapped'**
  String get notificationsTapped;

  /// No description provided for @returnAnOrder.
  ///
  /// In en, this message translates to:
  /// **'Return an Order'**
  String get returnAnOrder;

  /// No description provided for @manageDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Discounts'**
  String get manageDiscounts;

  /// No description provided for @returnOrder.
  ///
  /// In en, this message translates to:
  /// **'Return Order'**
  String get returnOrder;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @posSettings.
  ///
  /// In en, this message translates to:
  /// **'POS Settings'**
  String get posSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @businessAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddressLabel;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @posSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'POS settings updated successfully'**
  String get posSettingsUpdated;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @posSystemType.
  ///
  /// In en, this message translates to:
  /// **'POS System Type'**
  String get posSystemType;

  /// No description provided for @selectPosSystem.
  ///
  /// In en, this message translates to:
  /// **'Select POS System'**
  String get selectPosSystem;

  /// No description provided for @apiConfiguration.
  ///
  /// In en, this message translates to:
  /// **'API Configuration'**
  String get apiConfiguration;

  /// No description provided for @apiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'API Endpoint'**
  String get apiEndpoint;

  /// No description provided for @pleaseEnterApiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Please enter API endpoint'**
  String get pleaseEnterApiEndpoint;

  /// No description provided for @pleaseEnterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get pleaseEnterValidUrl;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter API Key'**
  String get enterApiKey;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @pleaseEnterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter API key'**
  String get pleaseEnterApiKey;

  /// No description provided for @accessToken.
  ///
  /// In en, this message translates to:
  /// **'Access Token'**
  String get accessToken;

  /// No description provided for @enterAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Enter Access Token'**
  String get enterAccessToken;

  /// No description provided for @locationId.
  ///
  /// In en, this message translates to:
  /// **'Location ID'**
  String get locationId;

  /// No description provided for @enterLocationId.
  ///
  /// In en, this message translates to:
  /// **'Enter Location ID'**
  String get enterLocationId;

  /// No description provided for @posIntegrationSettings.
  ///
  /// In en, this message translates to:
  /// **'POS Integration Settings'**
  String get posIntegrationSettings;

  /// No description provided for @enablePosIntegration.
  ///
  /// In en, this message translates to:
  /// **'Enable POS Integration'**
  String get enablePosIntegration;

  /// No description provided for @enablePosIntegrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync orders with your POS system'**
  String get enablePosIntegrationDescription;

  /// No description provided for @autoSendOrders.
  ///
  /// In en, this message translates to:
  /// **'Auto Send Orders'**
  String get autoSendOrders;

  /// No description provided for @autoSendOrdersDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically send new orders to POS'**
  String get autoSendOrdersDescription;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// No description provided for @posIntegrationEnabled.
  ///
  /// In en, this message translates to:
  /// **'POS Integration Enabled'**
  String get posIntegrationEnabled;

  /// No description provided for @posIntegrationDisabled.
  ///
  /// In en, this message translates to:
  /// **'POS Integration Disabled'**
  String get posIntegrationDisabled;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @endpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get endpoint;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @posSyncLogs.
  ///
  /// In en, this message translates to:
  /// **'POS Sync Logs'**
  String get posSyncLogs;

  /// No description provided for @noSyncLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No sync logs found'**
  String get noSyncLogsFound;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @syncLogDetails.
  ///
  /// In en, this message translates to:
  /// **'Sync Log Details'**
  String get syncLogDetails;

  /// No description provided for @syncTime.
  ///
  /// In en, this message translates to:
  /// **'Sync Time'**
  String get syncTime;

  /// No description provided for @posOrderId.
  ///
  /// In en, this message translates to:
  /// **'POS Order ID'**
  String get posOrderId;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error Message'**
  String get errorMessage;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry Sync'**
  String get retrySync;

  /// No description provided for @orderSyncRetryInitiated.
  ///
  /// In en, this message translates to:
  /// **'Order sync retry initiated'**
  String get orderSyncRetryInitiated;

  /// No description provided for @advancedConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Advanced Configuration'**
  String get advancedConfiguration;

  /// No description provided for @timeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'Timeout (seconds)'**
  String get timeoutSeconds;

  /// No description provided for @retryAttempts.
  ///
  /// In en, this message translates to:
  /// **'Retry Attempts'**
  String get retryAttempts;

  /// No description provided for @testMode.
  ///
  /// In en, this message translates to:
  /// **'Test Mode'**
  String get testMode;

  /// No description provided for @testModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable test mode for development'**
  String get testModeDescription;

  /// No description provided for @webhooksIntegration.
  ///
  /// In en, this message translates to:
  /// **'Webhooks Integration'**
  String get webhooksIntegration;

  /// No description provided for @webhooksDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure webhooks for real-time notifications'**
  String get webhooksDescription;

  /// No description provided for @configureWebhooks.
  ///
  /// In en, this message translates to:
  /// **'Configure Webhooks'**
  String get configureWebhooks;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @encryptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Encryption Status'**
  String get encryptionStatus;

  /// No description provided for @encryptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Encryption Enabled'**
  String get encryptionEnabled;

  /// No description provided for @apiKeyRotation.
  ///
  /// In en, this message translates to:
  /// **'API Key Rotation'**
  String get apiKeyRotation;

  /// No description provided for @lastRotated.
  ///
  /// In en, this message translates to:
  /// **'Last Rotated'**
  String get lastRotated;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @systemSetupGuides.
  ///
  /// In en, this message translates to:
  /// **'System Setup Guides'**
  String get systemSetupGuides;

  /// No description provided for @setupGuide.
  ///
  /// In en, this message translates to:
  /// **'Setup Guide'**
  String get setupGuide;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @connectionIssues.
  ///
  /// In en, this message translates to:
  /// **'Connection Issues'**
  String get connectionIssues;

  /// No description provided for @syncFailures.
  ///
  /// In en, this message translates to:
  /// **'Sync Failures'**
  String get syncFailures;

  /// No description provided for @apiErrors.
  ///
  /// In en, this message translates to:
  /// **'API Errors'**
  String get apiErrors;

  /// No description provided for @supportContact.
  ///
  /// In en, this message translates to:
  /// **'Support Contact'**
  String get supportContact;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @availableWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Available weekdays 9 AM - 5 PM'**
  String get availableWeekdays;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @liveChatComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Live chat coming soon'**
  String get liveChatComingSoon;

  /// No description provided for @emailSupportOpened.
  ///
  /// In en, this message translates to:
  /// **'Email support opened'**
  String get emailSupportOpened;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @syncLogs.
  ///
  /// In en, this message translates to:
  /// **'Sync Logs'**
  String get syncLogs;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @allDiscounts.
  ///
  /// In en, this message translates to:
  /// **'All Discounts'**
  String get allDiscounts;

  /// No description provided for @activeDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Active Discounts'**
  String get activeDiscounts;

  /// No description provided for @scheduledDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Discounts'**
  String get scheduledDiscounts;

  /// No description provided for @expiredDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Expired Discounts'**
  String get expiredDiscounts;

  /// No description provided for @createDiscount.
  ///
  /// In en, this message translates to:
  /// **'Create Discount'**
  String get createDiscount;

  /// No description provided for @noDiscountsCreated.
  ///
  /// In en, this message translates to:
  /// **'No discounts created yet'**
  String get noDiscountsCreated;

  /// No description provided for @createYourFirstDiscount.
  ///
  /// In en, this message translates to:
  /// **'Create your first discount to start attracting customers'**
  String get createYourFirstDiscount;

  /// No description provided for @deleteDiscount.
  ///
  /// In en, this message translates to:
  /// **'Delete Discount'**
  String get deleteDiscount;

  /// No description provided for @areYouSureYouWantToDeleteThisDiscount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this discount?'**
  String get areYouSureYouWantToDeleteThisDiscount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editDiscount.
  ///
  /// In en, this message translates to:
  /// **'Edit Discount'**
  String get editDiscount;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @discountType.
  ///
  /// In en, this message translates to:
  /// **'Discount Type'**
  String get discountType;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @fixedAmount.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get fixedAmount;

  /// No description provided for @conditional.
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get conditional;

  /// No description provided for @buyXGetY.
  ///
  /// In en, this message translates to:
  /// **'Buy X Get Y'**
  String get buyXGetY;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get freeDelivery;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @pleaseEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get pleaseEnterValue;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @minimumOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum order amount: {amount}'**
  String minimumOrderAmount(String amount);

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'discount'**
  String get discount;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @sampleItem.
  ///
  /// In en, this message translates to:
  /// **'Sample Item'**
  String get sampleItem;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @averageOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Average Order Value'**
  String get averageOrderValue;

  /// No description provided for @topSellingItems.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Items'**
  String get topSellingItems;

  /// No description provided for @itemSoldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Sold: {quantity}'**
  String itemSoldQuantity(int quantity);

  /// No description provided for @itemRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue: \${revenue}'**
  String itemRevenue(String revenue);

  /// No description provided for @ordersByStatus.
  ///
  /// In en, this message translates to:
  /// **'Orders by Status'**
  String get ordersByStatus;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get orderStatusReady;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get orderStatusPickedUp;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get orderStatusReturned;

  /// No description provided for @orderStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get orderStatusExpired;

  /// No description provided for @itemAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item added successfully'**
  String get itemAddedSuccessfully;

  /// No description provided for @itemUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item updated successfully'**
  String get itemUpdatedSuccessfully;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'IQD '**
  String get currencyPrefix;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @deleteItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteItemConfirmation;

  /// No description provided for @itemDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully'**
  String get itemDeletedSuccessfully;

  /// No description provided for @addNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get addNewItem;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @newCategoryName.
  ///
  /// In en, this message translates to:
  /// **'New Category Name'**
  String get newCategoryName;

  /// No description provided for @pleaseEnterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter category name'**
  String get pleaseEnterCategoryName;

  /// No description provided for @selectExistingCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Existing Category'**
  String get selectExistingCategory;

  /// No description provided for @addNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addNewCategory;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @pleaseEnterItemName.
  ///
  /// In en, this message translates to:
  /// **'Please enter item name'**
  String get pleaseEnterItemName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get pleaseEnterPrice;

  /// No description provided for @pleaseEnterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get pleaseEnterValidPrice;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @orderReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get orderReady;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @orderReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get orderReturned;

  /// No description provided for @noOrdersFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No orders found for {filter}'**
  String noOrdersFoundFor(String filter);

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFile;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @cloudKitchen.
  ///
  /// In en, this message translates to:
  /// **'Cloud Kitchen'**
  String get cloudKitchen;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @registrationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Registration Submitted'**
  String get registrationSubmitted;

  /// No description provided for @registrationSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your registration has been submitted for review'**
  String get registrationSubmittedMessage;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected'**
  String get notSelected;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @neighbourhoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood'**
  String get neighbourhoodLabel;

  /// No description provided for @streetLabel.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get streetLabel;

  /// No description provided for @buildingHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Building/Home'**
  String get buildingHomeLabel;

  /// No description provided for @zipCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCodeLabel;

  /// No description provided for @businessOwnerInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Owner Information'**
  String get businessOwnerInformation;

  /// No description provided for @nationalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalIdLabel;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @registrationSuccessLogin.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You can now log in with your credentials.'**
  String get registrationSuccessLogin;

  /// No description provided for @gettingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingYourLocation;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied permanently'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @couldNotDeterminePlacemark.
  ///
  /// In en, this message translates to:
  /// **'Could not determine placemark'**
  String get couldNotDeterminePlacemark;

  /// No description provided for @businessRegistration.
  ///
  /// In en, this message translates to:
  /// **'Business Registration'**
  String get businessRegistration;

  /// No description provided for @businessAndOwnerInformation.
  ///
  /// In en, this message translates to:
  /// **'Business and Owner Information'**
  String get businessAndOwnerInformation;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @selectBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Please select a business type'**
  String get selectBusinessType;

  /// No description provided for @pleaseEnterBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Please enter business name'**
  String get pleaseEnterBusinessName;

  /// No description provided for @pleaseEnterOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter owner name'**
  String get pleaseEnterOwnerName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @pleaseEnterCountry.
  ///
  /// In en, this message translates to:
  /// **'Please enter country'**
  String get pleaseEnterCountry;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter city'**
  String get pleaseEnterCity;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @pleaseEnterDistrict.
  ///
  /// In en, this message translates to:
  /// **'Please enter district'**
  String get pleaseEnterDistrict;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCode;

  /// No description provided for @pleaseEnterZipCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter zip code'**
  String get pleaseEnterZipCode;

  /// No description provided for @neighbourhood.
  ///
  /// In en, this message translates to:
  /// **'Neighbourhood'**
  String get neighbourhood;

  /// No description provided for @pleaseEnterNeighbourhood.
  ///
  /// In en, this message translates to:
  /// **'Please enter neighbourhood'**
  String get pleaseEnterNeighbourhood;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @pleaseEnterStreet.
  ///
  /// In en, this message translates to:
  /// **'Please enter street'**
  String get pleaseEnterStreet;

  /// No description provided for @buildingNumber.
  ///
  /// In en, this message translates to:
  /// **'Building Number'**
  String get buildingNumber;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @pleaseEnterNationalId.
  ///
  /// In en, this message translates to:
  /// **'Please enter national ID'**
  String get pleaseEnterNationalId;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @pleaseEnterDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please enter date of birth'**
  String get pleaseEnterDateOfBirth;

  /// No description provided for @ownerNationalId.
  ///
  /// In en, this message translates to:
  /// **'Owner National ID'**
  String get ownerNationalId;

  /// No description provided for @ownerNationalIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of the national ID'**
  String get ownerNationalIdSubtitle;

  /// No description provided for @ownerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Owner Photo'**
  String get ownerPhoto;

  /// No description provided for @ownerPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of the owner'**
  String get ownerPhotoSubtitle;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @commercialLicense.
  ///
  /// In en, this message translates to:
  /// **'Commercial License'**
  String get commercialLicense;

  /// No description provided for @commercialLicenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your business commercial license'**
  String get commercialLicenseSubtitle;

  /// No description provided for @healthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Health Certificate'**
  String get healthCertificate;

  /// No description provided for @healthCertificateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for food-related businesses'**
  String get healthCertificateSubtitle;

  /// No description provided for @submitRegistration.
  ///
  /// In en, this message translates to:
  /// **'Submit Registration'**
  String get submitRegistration;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent'**
  String get emailSent;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'A password reset link has been sent to your email'**
  String get passwordResetLinkSent;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @pleaseEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP'**
  String get pleaseEnterOtp;

  /// No description provided for @resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get resetYourPassword;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @pleaseEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmailAddress;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get pleaseConfirmPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @newOrderReceived.
  ///
  /// In en, this message translates to:
  /// **'New order received from {customerName}'**
  String newOrderReceived(String customerName);

  /// No description provided for @passwordResetSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password Reset Successful'**
  String get passwordResetSuccessful;

  /// No description provided for @passwordResetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully.'**
  String get passwordResetSuccessMessage;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @passwordLengthRequirement.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordLengthRequirement;

  /// No description provided for @passwordComplexityRequirement.
  ///
  /// In en, this message translates to:
  /// **'Password must include uppercase, lowercase, and numbers.'**
  String get passwordComplexityRequirement;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @enterNewPasswordBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below.'**
  String get enterNewPasswordBelow;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements'**
  String get passwordRequirements;

  /// No description provided for @passwordRequirementsDetails.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters, include uppercase, lowercase, and a number.'**
  String get passwordRequirementsDetails;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @autoFillAddress.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill Address'**
  String get autoFillAddress;

  /// No description provided for @validityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Validity Period'**
  String get validityPeriod;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown Status'**
  String get unknownStatus;

  /// No description provided for @discountCombinationWarning.
  ///
  /// In en, this message translates to:
  /// **'This discount type cannot be combined with existing active discounts'**
  String get discountCombinationWarning;

  /// No description provided for @freeDeliveryCombinable.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery can be combined with other discounts'**
  String get freeDeliveryCombinable;

  /// No description provided for @discountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Discount created successfully'**
  String get discountCreatedSuccessfully;

  /// No description provided for @discountUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Discount updated successfully'**
  String get discountUpdatedSuccessfully;

  /// No description provided for @combinableDiscount.
  ///
  /// In en, this message translates to:
  /// **'Combinable'**
  String get combinableDiscount;

  /// No description provided for @discountApplicability.
  ///
  /// In en, this message translates to:
  /// **'Discount Applicability'**
  String get discountApplicability;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get allItems;

  /// No description provided for @specificItems.
  ///
  /// In en, this message translates to:
  /// **'Specific Items'**
  String get specificItems;

  /// No description provided for @specificCategories.
  ///
  /// In en, this message translates to:
  /// **'Specific Categories'**
  String get specificCategories;

  /// No description provided for @selectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items'**
  String get selectItems;

  /// No description provided for @selectCategories.
  ///
  /// In en, this message translates to:
  /// **'Select Categories'**
  String get selectCategories;

  /// No description provided for @noItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'No items selected'**
  String get noItemsSelected;

  /// No description provided for @noCategoriesSelected.
  ///
  /// In en, this message translates to:
  /// **'No categories selected'**
  String get noCategoriesSelected;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @conflictingDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Some selected items or categories already have active discounts. Each item can only have one discount at a time.'**
  String get conflictingDiscounts;

  /// No description provided for @wizzBusiness.
  ///
  /// In en, this message translates to:
  /// **'Wizz Business'**
  String get wizzBusiness;

  /// No description provided for @businessManagement.
  ///
  /// In en, this message translates to:
  /// **'Business Management'**
  String get businessManagement;

  /// No description provided for @welcomeToOrderReceiver.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Order Receiver'**
  String get welcomeToOrderReceiver;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your business orders efficiently with our powerful order management system.'**
  String get welcomeDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @testRegistrationForm.
  ///
  /// In en, this message translates to:
  /// **'Test Registration Form'**
  String get testRegistrationForm;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @returnOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Order'**
  String get returnOrderTitle;

  /// No description provided for @enterOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Order Number'**
  String get enterOrderNumber;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order Not Found'**
  String get orderNotFound;

  /// No description provided for @orderReturnedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order Returned Successfully'**
  String get orderReturnedSuccessfully;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location Saved'**
  String get locationSaved;

  /// No description provided for @businessLocation.
  ///
  /// In en, this message translates to:
  /// **'Business Location'**
  String get businessLocation;

  /// No description provided for @locationSet.
  ///
  /// In en, this message translates to:
  /// **'Location Set'**
  String get locationSet;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @updateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// No description provided for @noLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No Location Set'**
  String get noLocationSet;

  /// No description provided for @chooseLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose Location on Map'**
  String get chooseLocationOnMap;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Enable Location Services'**
  String get enableLocationServices;

  /// No description provided for @locationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Location Not Selected'**
  String get locationNotSelected;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @tapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to Select Location'**
  String get tapToSelectLocation;

  /// No description provided for @registrationDate.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDate;

  /// No description provided for @smartBusinessControls.
  ///
  /// In en, this message translates to:
  /// **'Smart business controls'**
  String get smartBusinessControls;

  /// No description provided for @readyToReceiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Ready to receive orders'**
  String get readyToReceiveOrders;

  /// No description provided for @ordersArePaused.
  ///
  /// In en, this message translates to:
  /// **'Orders are paused'**
  String get ordersArePaused;

  /// No description provided for @menuItemsAndCategories.
  ///
  /// In en, this message translates to:
  /// **'Menu items & categories'**
  String get menuItemsAndCategories;

  /// No description provided for @businessInsights.
  ///
  /// In en, this message translates to:
  /// **'Business insights'**
  String get businessInsights;

  /// No description provided for @offersAndPromotions.
  ///
  /// In en, this message translates to:
  /// **'Offers & promotions'**
  String get offersAndPromotions;

  /// No description provided for @appConfiguration.
  ///
  /// In en, this message translates to:
  /// **'App configuration'**
  String get appConfiguration;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeAppLanguage;

  /// No description provided for @cancelRecentOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel recent order'**
  String get cancelRecentOrder;

  /// No description provided for @tapOutsideOrPressEscToClose.
  ///
  /// In en, this message translates to:
  /// **'Tap outside or press ESC to close'**
  String get tapOutsideOrPressEscToClose;

  /// No description provided for @languageChangedToArabic.
  ///
  /// In en, this message translates to:
  /// **'تم تغيير اللغة إلى العربية'**
  String get languageChangedToArabic;

  /// No description provided for @languageChangedToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChangedToEnglish;

  /// No description provided for @managePromotionalOffers.
  ///
  /// In en, this message translates to:
  /// **'Manage promotional offers'**
  String get managePromotionalOffers;

  /// No description provided for @viewBusinessInsights.
  ///
  /// In en, this message translates to:
  /// **'View business insights'**
  String get viewBusinessInsights;

  /// No description provided for @manageItemsAndCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage items & categories'**
  String get manageItemsAndCategories;

  /// No description provided for @platformIntegration.
  ///
  /// In en, this message translates to:
  /// **'Platform Integration'**
  String get platformIntegration;

  /// No description provided for @centralizedDeliveryPlatform.
  ///
  /// In en, this message translates to:
  /// **'Centralized delivery platform'**
  String get centralizedDeliveryPlatform;

  /// No description provided for @appAndAccountPreferences.
  ///
  /// In en, this message translates to:
  /// **'App & account preferences'**
  String get appAndAccountPreferences;

  /// No description provided for @keyboardShortcutsTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Use keyboard shortcuts for faster actions'**
  String get keyboardShortcutsTip;

  /// No description provided for @conditionalDiscountConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Conditional Discount Configuration'**
  String get conditionalDiscountConfiguration;

  /// No description provided for @buyXGetYConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Buy X Get Y Configuration'**
  String get buyXGetYConfiguration;

  /// No description provided for @buyConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Buy Configuration'**
  String get buyConfiguration;

  /// No description provided for @getConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Get Configuration'**
  String get getConfiguration;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @selectItem.
  ///
  /// In en, this message translates to:
  /// **'Select Item'**
  String get selectItem;

  /// No description provided for @itemSelected.
  ///
  /// In en, this message translates to:
  /// **'Item Selected'**
  String get itemSelected;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter valid quantity'**
  String get enterValidQuantity;

  /// No description provided for @missingItems.
  ///
  /// In en, this message translates to:
  /// **'Missing Items'**
  String get missingItems;

  /// No description provided for @pleasSelectBothBuyAndGetItems.
  ///
  /// In en, this message translates to:
  /// **'Please select both buy and get items for {discountType} discount.'**
  String pleasSelectBothBuyAndGetItems(String discountType);

  /// No description provided for @addFreeDeliveryToDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add free delivery to this discount'**
  String get addFreeDeliveryToDiscount;

  /// No description provided for @conflictingDiscountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conflicting Discounts'**
  String get conflictingDiscountsTitle;

  /// No description provided for @someSelectedItemsAlreadyHaveDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Some selected items or categories already have active discounts. Each item can only have one discount at a time.'**
  String get someSelectedItemsAlreadyHaveDiscounts;

  /// No description provided for @applicabilityNotConfigurable.
  ///
  /// In en, this message translates to:
  /// **'Applicability is not configurable for this discount type as items are already specified in the configuration above.'**
  String get applicabilityNotConfigurable;

  /// No description provided for @noItemSelected.
  ///
  /// In en, this message translates to:
  /// **'No item selected'**
  String get noItemSelected;

  /// No description provided for @appliesToAllItems.
  ///
  /// In en, this message translates to:
  /// **'Applies to all items'**
  String get appliesToAllItems;

  /// No description provided for @appliesToSpecificItems.
  ///
  /// In en, this message translates to:
  /// **'Applies to {count} specific items'**
  String appliesToSpecificItems(int count);

  /// No description provided for @appliesToCategories.
  ///
  /// In en, this message translates to:
  /// **'Applies to {count} categories'**
  String appliesToCategories(int count);

  /// No description provided for @appliesToOrdersAboveMinimum.
  ///
  /// In en, this message translates to:
  /// **'Applies to orders above minimum amount'**
  String get appliesToOrdersAboveMinimum;

  /// No description provided for @validFromTo.
  ///
  /// In en, this message translates to:
  /// **'Valid: {startDay}/{startMonth}/{startYear} - {endDay}/{endMonth}/{endYear}'**
  String validFromTo(int startDay, int startMonth, int startYear, int endDay,
      int endMonth, int endYear);

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min: \${amount}'**
  String minAmount(String amount);

  /// No description provided for @categoriesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} categories selected'**
  String categoriesSelected(int count);

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String itemsSelected(int count);

  /// No description provided for @missingItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select both buy and get items for {discountType} discount.'**
  String missingItemsMessage(String discountType);

  /// No description provided for @selectBuyItem.
  ///
  /// In en, this message translates to:
  /// **'Select Buy Item'**
  String get selectBuyItem;

  /// No description provided for @selectGetItem.
  ///
  /// In en, this message translates to:
  /// **'Select Get Item'**
  String get selectGetItem;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found. Please add categories first.'**
  String get noCategoriesFound;

  /// No description provided for @appliesToMinimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Applies to orders above minimum amount'**
  String get appliesToMinimumOrder;

  /// No description provided for @startSimulation.
  ///
  /// In en, this message translates to:
  /// **'Start Simulation'**
  String get startSimulation;

  /// No description provided for @stopSimulation.
  ///
  /// In en, this message translates to:
  /// **'Stop Simulation'**
  String get stopSimulation;

  /// No description provided for @simulateNewOrder.
  ///
  /// In en, this message translates to:
  /// **'Simulate New Order'**
  String get simulateNewOrder;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @notConnectedToNotifications.
  ///
  /// In en, this message translates to:
  /// **'Not connected to real-time notifications'**
  String get notConnectedToNotifications;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @newOrderNotificationsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New order notifications will appear here'**
  String get newOrderNotificationsAppearHere;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear All Notifications'**
  String get clearAllNotifications;

  /// No description provided for @testNotificationSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent successfully'**
  String get testNotificationSentSuccessfully;

  /// No description provided for @failedToSendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send test notification'**
  String failedToSendTestNotification(String error);

  /// No description provided for @failedToConnectToNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to notifications: {error}'**
  String failedToConnectToNotifications(String error);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'urgent'**
  String get urgent;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get high;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get normal;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get low;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @todaysRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todaysRevenue;

  /// No description provided for @avgOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Avg Order Value'**
  String get avgOrderValue;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @customersServed.
  ///
  /// In en, this message translates to:
  /// **'Customers Served'**
  String get customersServed;

  /// No description provided for @cancellationRate.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Rate'**
  String get cancellationRate;

  /// No description provided for @revenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue Trend'**
  String get revenueTrend;

  /// No description provided for @revenueBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Revenue Breakdown'**
  String get revenueBreakdown;

  /// No description provided for @dailyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Daily Revenue'**
  String get dailyRevenue;

  /// No description provided for @weeklyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Weekly Revenue'**
  String get weeklyRevenue;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @avgPrepTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Prep Time'**
  String get avgPrepTime;

  /// No description provided for @successRate.
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get successRate;

  /// No description provided for @specialDish.
  ///
  /// In en, this message translates to:
  /// **'Special Dish'**
  String get specialDish;

  /// No description provided for @popularItem.
  ///
  /// In en, this message translates to:
  /// **'Popular Item'**
  String get popularItem;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @errorLoadingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error loading user data'**
  String get errorLoadingUserData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @passwordChangeAvailableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Password change is available in the main Settings page.'**
  String get passwordChangeAvailableInSettings;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @kitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get kitchen;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @centralizedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Centralized Platform'**
  String get centralizedPlatform;

  /// No description provided for @platformConnection.
  ///
  /// In en, this message translates to:
  /// **'Platform Connection'**
  String get platformConnection;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @platformApps.
  ///
  /// In en, this message translates to:
  /// **'Platform Apps'**
  String get platformApps;

  /// No description provided for @localBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Local Businesses'**
  String get localBusinesses;

  /// No description provided for @syncRecommended.
  ///
  /// In en, this message translates to:
  /// **'Sync Recommended'**
  String get syncRecommended;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get noAppsFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @setupPlatform.
  ///
  /// In en, this message translates to:
  /// **'Setup Platform'**
  String get setupPlatform;

  /// No description provided for @syncAllBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Sync All Businesses'**
  String get syncAllBusinesses;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// No description provided for @failedToLoadPlatformStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to load platform status'**
  String get failedToLoadPlatformStatus;

  /// No description provided for @platformSetupCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Platform setup completed successfully!'**
  String get platformSetupCompletedSuccessfully;

  /// No description provided for @platformSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Platform setup failed'**
  String get platformSetupFailed;

  /// No description provided for @errorSettingUpPlatform.
  ///
  /// In en, this message translates to:
  /// **'Error setting up platform'**
  String get errorSettingUpPlatform;

  /// No description provided for @allBusinessesSyncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'All businesses synced successfully!'**
  String get allBusinessesSyncedSuccessfully;

  /// No description provided for @errorSyncingBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Error syncing businesses'**
  String get errorSyncingBusinesses;

  /// No description provided for @noBusinessFoundForThisUser.
  ///
  /// In en, this message translates to:
  /// **'No business found for this user'**
  String get noBusinessFoundForThisUser;

  /// No description provided for @loginFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailedMessage;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @pleaseEnterOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your old password'**
  String get pleaseEnterOldPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @generateTestOrders.
  ///
  /// In en, this message translates to:
  /// **'Generate test orders to help with development and testing.'**
  String get generateTestOrders;

  /// No description provided for @createRealisticOrders.
  ///
  /// In en, this message translates to:
  /// **'This will create realistic orders with random customer data, items, and pricing.'**
  String get createRealisticOrders;

  /// No description provided for @createOneOrder.
  ///
  /// In en, this message translates to:
  /// **'Create 1 Order'**
  String get createOneOrder;

  /// No description provided for @createThreeOrders.
  ///
  /// In en, this message translates to:
  /// **'Create 3 Orders'**
  String get createThreeOrders;

  /// No description provided for @failedToCreateOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to create orders'**
  String get failedToCreateOrders;

  /// No description provided for @categoriesLoaded.
  ///
  /// In en, this message translates to:
  /// **'Categories loaded'**
  String get categoriesLoaded;

  /// No description provided for @createFirstCategory.
  ///
  /// In en, this message translates to:
  /// **'Create First Category'**
  String get createFirstCategory;

  /// No description provided for @noCategoriesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No categories found. Create your first category to organize your items.'**
  String get noCategoriesFoundMessage;

  /// No description provided for @failedToDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item'**
  String get failedToDeleteItem;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @failedToAddItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item'**
  String get failedToAddItem;

  /// No description provided for @failedToUpdateItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to update item'**
  String get failedToUpdateItem;

  /// No description provided for @pleaseSelectCategoryOrCreate.
  ///
  /// In en, this message translates to:
  /// **'Please select a category or create a new one'**
  String get pleaseSelectCategoryOrCreate;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @pleaseCompleteAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields'**
  String get pleaseCompleteAllRequiredFields;

  /// No description provided for @documentSelectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document selected successfully'**
  String get documentSelectedSuccessfully;

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location'**
  String get errorGettingLocation;

  /// No description provided for @pleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmailAddress;

  /// No description provided for @phoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberIsRequired;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @passwordMustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordMustBeAtLeast8Characters;

  /// No description provided for @passwordMustContainLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordMustContainLowercase;

  /// No description provided for @passwordMustContainUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMustContainUppercase;

  /// No description provided for @passwordMustContainNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordMustContainNumber;

  /// No description provided for @passwordMustContainSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character'**
  String get passwordMustContainSpecialCharacter;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatchRegistration.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchRegistration;

  /// No description provided for @pleaseEnterExactly10Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter exactly 10 digits'**
  String get pleaseEnterExactly10Digits;

  /// No description provided for @pleaseEnterOnlyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Please enter only numbers'**
  String get pleaseEnterOnlyNumbers;

  /// No description provided for @pleaseEnterValidIraqiNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Iraqi number (77X/78X/79X for mobile)'**
  String get pleaseEnterValidIraqiNumber;

  /// No description provided for @userWithEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A user with this email already exists'**
  String get userWithEmailAlreadyExists;

  /// No description provided for @passwordResetEmailSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent successfully'**
  String get passwordResetEmailSentSuccessfully;

  /// No description provided for @failedToSendPasswordResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email'**
  String get failedToSendPasswordResetEmail;

  /// No description provided for @registrationFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailedStatus;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation error'**
  String get validationError;

  /// No description provided for @failedToFetchTestUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch test user profile'**
  String get failedToFetchTestUserProfile;

  /// No description provided for @unknownErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownErrorOccurred;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @noAccessTokenFound.
  ///
  /// In en, this message translates to:
  /// **'No access token found'**
  String get noAccessTokenFound;

  /// No description provided for @sessionExpiredPleaseLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpiredPleaseLoginAgain;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @errorDuringLogout.
  ///
  /// In en, this message translates to:
  /// **'Error during logout'**
  String get errorDuringLogout;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registrationSuccessful;

  /// No description provided for @passwordResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccessfully;

  /// No description provided for @failedToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get failedToResetPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @otpSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccessfully;

  /// No description provided for @viewAndManageOrders.
  ///
  /// In en, this message translates to:
  /// **'View and manage orders'**
  String get viewAndManageOrders;

  /// No description provided for @businessDashboardVersion.
  ///
  /// In en, this message translates to:
  /// **'Business Dashboard v2.0'**
  String get businessDashboardVersion;

  /// No description provided for @modernMaterialDesign.
  ///
  /// In en, this message translates to:
  /// **'Modern Material Design'**
  String get modernMaterialDesign;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @aUserWithThisEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A user with this email already exists'**
  String get aUserWithThisEmailAlreadyExists;

  /// No description provided for @anUnknownErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get anUnknownErrorOccurred;

  /// No description provided for @failedToCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to create category'**
  String get failedToCreateCategory;

  /// No description provided for @failedToLoadItems.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items'**
  String get failedToLoadItems;

  /// No description provided for @failedToCreateItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to create item'**
  String get failedToCreateItem;

  /// No description provided for @failedToLoadNotificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notification history'**
  String get failedToLoadNotificationHistory;

  /// No description provided for @failedToMarkNotificationAsRead.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark notification as read'**
  String get failedToMarkNotificationAsRead;

  /// No description provided for @failedToCreateOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order'**
  String get failedToCreateOrder;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failedToLoadOrders;

  /// No description provided for @failedToUpdateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order status'**
  String get failedToUpdateOrderStatus;

  /// No description provided for @failedToLoadSupportedPosSystems.
  ///
  /// In en, this message translates to:
  /// **'Failed to load supported POS systems'**
  String get failedToLoadSupportedPosSystems;

  /// No description provided for @failedToLoadPosSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load POS settings'**
  String get failedToLoadPosSettings;

  /// No description provided for @failedToCreatePosSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to create POS settings'**
  String get failedToCreatePosSettings;

  /// No description provided for @failedToUpdatePosSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to update POS settings'**
  String get failedToUpdatePosSettings;

  /// No description provided for @failedToDeletePosSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete POS settings'**
  String get failedToDeletePosSettings;

  /// No description provided for @failedToTestPosConnection.
  ///
  /// In en, this message translates to:
  /// **'Failed to test POS connection'**
  String get failedToTestPosConnection;

  /// No description provided for @failedToGetPosSystemHealth.
  ///
  /// In en, this message translates to:
  /// **'Failed to get POS system health'**
  String get failedToGetPosSystemHealth;

  /// No description provided for @failedToRetryPosSync.
  ///
  /// In en, this message translates to:
  /// **'Failed to retry POS sync'**
  String get failedToRetryPosSync;

  /// No description provided for @failedToLoadPosIntegrationStatistics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load POS integration statistics'**
  String get failedToLoadPosIntegrationStatistics;

  /// No description provided for @failedToBulkSyncOrdersToPos.
  ///
  /// In en, this message translates to:
  /// **'Failed to bulk sync orders to POS'**
  String get failedToBulkSyncOrdersToPos;

  /// No description provided for @failedToUpdateWebhookConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Failed to update webhook configuration'**
  String get failedToUpdateWebhookConfiguration;

  /// No description provided for @failedToValidatePosCredentials.
  ///
  /// In en, this message translates to:
  /// **'Failed to validate POS credentials'**
  String get failedToValidatePosCredentials;

  /// No description provided for @failedToLoadUserBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user businesses'**
  String get failedToLoadUserBusinesses;

  /// No description provided for @failedToLoadComparativeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comparative analytics'**
  String get failedToLoadComparativeAnalytics;

  /// No description provided for @failedToTestPlatformConnection.
  ///
  /// In en, this message translates to:
  /// **'Failed to test platform connection'**
  String get failedToTestPlatformConnection;

  /// No description provided for @errorTestingPlatformConnection.
  ///
  /// In en, this message translates to:
  /// **'Error testing platform connection'**
  String get errorTestingPlatformConnection;

  /// No description provided for @failedToGetPlatformApps.
  ///
  /// In en, this message translates to:
  /// **'Failed to get platform apps'**
  String get failedToGetPlatformApps;

  /// No description provided for @errorGettingPlatformApps.
  ///
  /// In en, this message translates to:
  /// **'Error getting platform apps'**
  String get errorGettingPlatformApps;

  /// No description provided for @failedToDeployCentralizedApp.
  ///
  /// In en, this message translates to:
  /// **'Failed to deploy centralized app'**
  String get failedToDeployCentralizedApp;

  /// No description provided for @errorDeployingCentralizedApp.
  ///
  /// In en, this message translates to:
  /// **'Error deploying centralized app'**
  String get errorDeployingCentralizedApp;

  /// No description provided for @failedToSyncBusinessToPlatform.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync business to platform'**
  String get failedToSyncBusinessToPlatform;

  /// No description provided for @errorSyncingBusinessToPlatform.
  ///
  /// In en, this message translates to:
  /// **'Error syncing business to platform'**
  String get errorSyncingBusinessToPlatform;

  /// No description provided for @failedToSyncAllBusinessesToPlatform.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync all businesses to platform'**
  String get failedToSyncAllBusinessesToPlatform;

  /// No description provided for @errorSyncingAllBusinessesToPlatform.
  ///
  /// In en, this message translates to:
  /// **'Error syncing all businesses to platform'**
  String get errorSyncingAllBusinessesToPlatform;

  /// No description provided for @failedToGetPlatformSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to get platform sync status'**
  String get failedToGetPlatformSyncStatus;

  /// No description provided for @errorGettingPlatformSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Error getting platform sync status'**
  String get errorGettingPlatformSyncStatus;

  /// No description provided for @failedToSetupCentralizedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Failed to setup centralized platform'**
  String get failedToSetupCentralizedPlatform;

  /// No description provided for @errorSettingUpCentralizedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Error setting up centralized platform'**
  String get errorSettingUpCentralizedPlatform;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in. Please log in first.'**
  String get userNotLoggedIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @showLocalNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show Local Notifications'**
  String get showLocalNotifications;

  /// No description provided for @showLocalNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Display notifications in system notification area'**
  String get showLocalNotificationsDescription;

  /// No description provided for @playNotificationSounds.
  ///
  /// In en, this message translates to:
  /// **'Play Notification Sounds'**
  String get playNotificationSounds;

  /// No description provided for @playNotificationSoundsDescription.
  ///
  /// In en, this message translates to:
  /// **'Play sound when notifications are received'**
  String get playNotificationSoundsDescription;

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @testNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'This will send a test notification to verify your settings are working correctly.'**
  String get testNotificationDescription;

  /// No description provided for @photoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get photoLibrary;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @errorSelectingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error selecting document'**
  String get errorSelectingDocument;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// No description provided for @orderSimulation.
  ///
  /// In en, this message translates to:
  /// **'Order Simulation'**
  String get orderSimulation;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @minimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order'**
  String get minimumOrder;

  /// No description provided for @freeDeliveryIncludedWith.
  ///
  /// In en, this message translates to:
  /// **'Free delivery included with {title}'**
  String freeDeliveryIncludedWith(String title);

  /// No description provided for @freeDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} - Free Delivery'**
  String freeDeliveryTitle(String title);

  /// No description provided for @kwd.
  ///
  /// In en, this message translates to:
  /// **'KWD'**
  String get kwd;

  /// No description provided for @categoryAndPrice.
  ///
  /// In en, this message translates to:
  /// **'{category} • {currency} {price}'**
  String categoryAndPrice(String category, String currency, String price);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
