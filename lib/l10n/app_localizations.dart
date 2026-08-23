import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Sample'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @semanticsEmailInput.
  ///
  /// In en, this message translates to:
  /// **'Email input field'**
  String get semanticsEmailInput;

  /// No description provided for @semanticsPasswordInput.
  ///
  /// In en, this message translates to:
  /// **'Password input field'**
  String get semanticsPasswordInput;

  /// No description provided for @semanticsLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login execute button'**
  String get semanticsLoginButton;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUp;

  /// No description provided for @googleSignUp.
  ///
  /// In en, this message translates to:
  /// **'Google Sign In'**
  String get googleSignUp;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent.'**
  String get emailVerificationDescription;

  /// No description provided for @checkVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Check verification status'**
  String get checkVerificationStatus;

  /// No description provided for @resendVerificationMail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationMail;

  /// No description provided for @resendVerificationMailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification email has been resent.'**
  String get resendVerificationMailSuccess;

  /// No description provided for @emailVerificationWaiting.
  ///
  /// In en, this message translates to:
  /// **'Once your email is verified, you will be redirected automatically.'**
  String get emailVerificationWaiting;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordMailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email has been sent.'**
  String get resetPasswordMailSent;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request is taking too long. Please try again in a place with better signal.'**
  String get errorTimeout;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try restarting the app or try again later.'**
  String get errorUnknown;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred.'**
  String get errorOccurred;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'A temporary server problem occurred. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please login again.'**
  String get errorUnauthenticated;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get errorUnauthorized;

  /// No description provided for @errorDataParse.
  ///
  /// In en, this message translates to:
  /// **'Failed to process data. Please try updating the app.'**
  String get errorDataParse;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to save or load local data.'**
  String get errorDatabase;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'The request is invalid.'**
  String get errorBadRequest;

  /// No description provided for @errorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred'**
  String get errorDialogTitle;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get errorLoginFailed;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is badly formatted.'**
  String get errorInvalidEmail;

  /// No description provided for @errorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errorUserDisabled;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email address is already in use.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Please make it more complex.'**
  String get errorWeakPassword;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeDescription.
  ///
  /// In en, this message translates to:
  /// **'👋 This is the home screen. Use the buttons below to navigate to each page.'**
  String get homeDescription;

  /// No description provided for @homeCurrentEnv.
  ///
  /// In en, this message translates to:
  /// **'Current Environment'**
  String get homeCurrentEnv;

  /// No description provided for @homeToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get homeToSettings;

  /// No description provided for @homeToUserList.
  ///
  /// In en, this message translates to:
  /// **'Go to User List (API Fetch)'**
  String get homeToUserList;

  /// No description provided for @homeToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Go to Reset Password'**
  String get homeToResetPassword;

  /// No description provided for @homeToChat.
  ///
  /// In en, this message translates to:
  /// **'Go to AI Chat'**
  String get homeToChat;

  /// No description provided for @homeToMemos.
  ///
  /// In en, this message translates to:
  /// **'Go to Memos'**
  String get homeToMemos;

  /// No description provided for @homeToNotFound.
  ///
  /// In en, this message translates to:
  /// **'Navigate to invalid path (NotFound test)'**
  String get homeToNotFound;

  /// No description provided for @homeGetAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Get App Info'**
  String get homeGetAppInfo;

  /// No description provided for @homeAppName.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get homeAppName;

  /// No description provided for @homeBundleId.
  ///
  /// In en, this message translates to:
  /// **'Bundle ID'**
  String get homeBundleId;

  /// No description provided for @homeCrashTest.
  ///
  /// In en, this message translates to:
  /// **'Crash Test'**
  String get homeCrashTest;

  /// No description provided for @homeAnalyticsTest.
  ///
  /// In en, this message translates to:
  /// **'Analytics Test'**
  String get homeAnalyticsTest;

  /// No description provided for @homeToGraph.
  ///
  /// In en, this message translates to:
  /// **'Go to the chart creation screen'**
  String get homeToGraph;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini Assistant'**
  String get chatTitle;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a message...'**
  String get chatHint;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'AI is thinking...'**
  String get thinking;

  /// No description provided for @chatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'The response from AI was empty.'**
  String get chatEmptyMessage;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get chatError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsThemeSection.
  ///
  /// In en, this message translates to:
  /// **'🎨 Theme Settings'**
  String get settingsThemeSection;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Dark Mode (simple)'**
  String get settingsThemeToggle;

  /// No description provided for @settingsLocaleSection.
  ///
  /// In en, this message translates to:
  /// **'🌐 Locale Settings'**
  String get settingsLocaleSection;

  /// No description provided for @settingsLocaleSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLocaleSystem;

  /// No description provided for @settingsLocaleJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese (ja)'**
  String get settingsLocaleJa;

  /// No description provided for @settingsLocaleEn.
  ///
  /// In en, this message translates to:
  /// **'English (en)'**
  String get settingsLocaleEn;

  /// No description provided for @settingsPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsPreview;

  /// No description provided for @memoTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Memos'**
  String get memoTitle;

  /// No description provided for @memoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memos yet!'**
  String get memoEmpty;

  /// No description provided for @memoInputTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get memoInputTitleHint;

  /// No description provided for @memoInputContentHint.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get memoInputContentHint;

  /// No description provided for @memoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Memo'**
  String get memoAdd;

  /// No description provided for @memoSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get memoSave;

  /// No description provided for @memoSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get memoSyncing;

  /// No description provided for @memoSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get memoSynced;

  /// No description provided for @memoUnsynced.
  ///
  /// In en, this message translates to:
  /// **'Not Synced'**
  String get memoUnsynced;

  /// No description provided for @memoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this memo?'**
  String get memoDeleteConfirm;

  /// No description provided for @memoSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search memos...'**
  String get memoSearchHint;

  /// No description provided for @memoSortCreatedAtDesc.
  ///
  /// In en, this message translates to:
  /// **'Created: Newest'**
  String get memoSortCreatedAtDesc;

  /// No description provided for @memoSortCreatedAtAsc.
  ///
  /// In en, this message translates to:
  /// **'Created: Oldest'**
  String get memoSortCreatedAtAsc;

  /// No description provided for @memoSortUpdatedAtDesc.
  ///
  /// In en, this message translates to:
  /// **'Updated: Newest'**
  String get memoSortUpdatedAtDesc;

  /// No description provided for @memoSortUpdatedAtAsc.
  ///
  /// In en, this message translates to:
  /// **'Updated: Oldest'**
  String get memoSortUpdatedAtAsc;

  /// No description provided for @memoSortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title: A-Z'**
  String get memoSortTitleAsc;

  /// No description provided for @memoSortTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Title: Z-A'**
  String get memoSortTitleDesc;

  /// No description provided for @chartLine.
  ///
  /// In en, this message translates to:
  /// **'Line Chart'**
  String get chartLine;

  /// No description provided for @chartBar.
  ///
  /// In en, this message translates to:
  /// **'Bar Chart'**
  String get chartBar;

  /// No description provided for @chartPie.
  ///
  /// In en, this message translates to:
  /// **'Pie Chart'**
  String get chartPie;

  /// No description provided for @chartDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'{chartName} Display'**
  String chartDisplayTitle(String chartName);

  /// No description provided for @chartInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart Data Input'**
  String get chartInputTitle;

  /// No description provided for @chartItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get chartItemLabel;

  /// No description provided for @chartItemValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get chartItemValue;

  /// No description provided for @chartViewGraph.
  ///
  /// In en, this message translates to:
  /// **'View Graph'**
  String get chartViewGraph;

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available. Please add items first.'**
  String get chartNoData;

  /// No description provided for @chartAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get chartAddItem;

  /// No description provided for @chartDataList.
  ///
  /// In en, this message translates to:
  /// **'Data List'**
  String get chartDataList;

  /// No description provided for @chartClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get chartClearAll;

  /// No description provided for @chartClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all data?'**
  String get chartClearConfirm;

  /// No description provided for @userListTitle.
  ///
  /// In en, this message translates to:
  /// **'User List'**
  String get userListTitle;

  /// No description provided for @userListLastFetched.
  ///
  /// In en, this message translates to:
  /// **'Last fetched: {dateTime}'**
  String userListLastFetched(String dateTime);

  /// No description provided for @userListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get userListEmpty;

  /// No description provided for @userListFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch users. Please pull down to refresh.'**
  String get userListFetchError;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page could not be found.'**
  String get notFoundMessage;

  /// No description provided for @notFoundBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get notFoundBackToHome;

  /// No description provided for @versionUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get versionUpTitle;

  /// No description provided for @versionUpMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'A new version is available.'**
  String get versionUpMessageOptional;

  /// No description provided for @versionUpMessageMandatory.
  ///
  /// In en, this message translates to:
  /// **'A new version is required.'**
  String get versionUpMessageMandatory;

  /// No description provided for @versionUpCancel.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get versionUpCancel;

  /// No description provided for @versionUpUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get versionUpUpdate;

  /// No description provided for @developerLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Log'**
  String get developerLogTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navMemos.
  ///
  /// In en, this message translates to:
  /// **'Memos'**
  String get navMemos;

  /// No description provided for @navChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get navChart;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Simple Memo Feature'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Desc.
  ///
  /// In en, this message translates to:
  /// **'Quickly write down ideas and tasks anytime, anywhere.'**
  String get onboardingPage1Desc;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Seamless Sync Everywhere'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Desc.
  ///
  /// In en, this message translates to:
  /// **'Write memos even offline; they sync to the cloud automatically once online.'**
  String get onboardingPage2Desc;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Assistant'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Desc.
  ///
  /// In en, this message translates to:
  /// **'Summarize memos and brainstorm ideas with the support of our AI assistant.'**
  String get onboardingPage3Desc;

  /// No description provided for @devStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage Viewer & Editor'**
  String get devStorageTitle;

  /// No description provided for @devStoragePrefsTab.
  ///
  /// In en, this message translates to:
  /// **'SharedPreferences'**
  String get devStoragePrefsTab;

  /// No description provided for @devStorageSecureTab.
  ///
  /// In en, this message translates to:
  /// **'SecureStorage'**
  String get devStorageSecureTab;

  /// No description provided for @devStorageEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Key'**
  String get devStorageEditDialogTitle;

  /// No description provided for @devStorageAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Key'**
  String get devStorageAddDialogTitle;

  /// No description provided for @devStorageConfirmClear.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all data?'**
  String get devStorageConfirmClear;

  /// No description provided for @devStorageKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get devStorageKey;

  /// No description provided for @devStorageValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get devStorageValue;

  /// No description provided for @devStorageType.
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get devStorageType;

  /// No description provided for @devStorageClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get devStorageClearAll;

  /// No description provided for @devStorageError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String devStorageError(String message);

  /// No description provided for @devStorageNoPrefsData.
  ///
  /// In en, this message translates to:
  /// **'No SharedPreferences data found.'**
  String get devStorageNoPrefsData;

  /// No description provided for @devStorageNoSecureData.
  ///
  /// In en, this message translates to:
  /// **'No SecureStorage data found.'**
  String get devStorageNoSecureData;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileTitle;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSaveSuccess;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name (Required)'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get profileNameHint;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get profileNameRequired;

  /// No description provided for @profileNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain only whitespace'**
  String get profileNameEmpty;

  /// No description provided for @profileNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be 128 characters or less'**
  String get profileNameMaxLength;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address (Required)'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get profileEmailRequired;

  /// No description provided for @profileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get profileEmailInvalid;

  /// No description provided for @profileEmailMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Email must be 256 characters or less'**
  String get profileEmailMaxLength;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Taro'**
  String get profileDisplayNameHint;

  /// No description provided for @profileDisplayNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Display name must be 128 characters or less'**
  String get profileDisplayNameMaxLength;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (no hyphen)'**
  String get profilePhoneLabel;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter half-width digits only'**
  String get profilePhoneInvalid;

  /// No description provided for @profilePhoneMobileLength.
  ///
  /// In en, this message translates to:
  /// **'Mobile/IP phone number must be 11 digits'**
  String get profilePhoneMobileLength;

  /// No description provided for @profilePhoneLandlineLength.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get profilePhoneLandlineLength;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSaveButton;

  /// No description provided for @profileCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current setting: {value}'**
  String profileCurrentValue(String value);

  /// No description provided for @profileValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileValueNotSet;

  /// No description provided for @appLockSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Passcode'**
  String get appLockSetupTitle;

  /// No description provided for @appLockSetupEnterFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter a new 4-digit passcode'**
  String get appLockSetupEnterFirst;

  /// No description provided for @appLockSetupEnterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Re-enter to confirm'**
  String get appLockSetupEnterConfirm;

  /// No description provided for @appLockSetupMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passcodes do not match. Please try again.'**
  String get appLockSetupMismatch;

  /// No description provided for @appLockBiometricPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometrics'**
  String get appLockBiometricPromptTitle;

  /// No description provided for @appLockBiometricPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to unlock using Biometrics (Face ID / Touch ID / Fingerprint)?'**
  String get appLockBiometricPromptMessage;

  /// No description provided for @appLockBiometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics to unlock the app'**
  String get appLockBiometricAuthReason;

  /// No description provided for @appLockEnableBiometricButton.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get appLockEnableBiometricButton;

  /// No description provided for @appLockSkipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get appLockSkipButton;

  /// No description provided for @appLockEnterPasscodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Passcode'**
  String get appLockEnterPasscodeTitle;

  /// No description provided for @appLockPasscodeIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passcode'**
  String get appLockPasscodeIncorrect;

  /// No description provided for @appLockLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Locked out. Please wait {seconds} seconds.'**
  String appLockLockedOut(int seconds);

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map (Google Maps)'**
  String get mapTitle;

  /// No description provided for @mapFetchLocation.
  ///
  /// In en, this message translates to:
  /// **'Move to Current Location'**
  String get mapFetchLocation;

  /// No description provided for @mapPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get mapPermissionDenied;

  /// No description provided for @mapPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please allow it in settings.'**
  String get mapPermissionDeniedForever;

  /// No description provided for @mapServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service (GPS) is disabled on your device.'**
  String get mapServiceDisabled;

  /// No description provided for @mapOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get mapOpenSettings;

  /// No description provided for @mapFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get mapFetchError;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search address or landmark'**
  String get mapSearchHint;

  /// No description provided for @mapSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\".'**
  String mapSearchEmpty(String query);

  /// No description provided for @mapSearchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to search location'**
  String get mapSearchError;

  /// No description provided for @mapSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get mapSearchClear;

  /// No description provided for @mapSearchSelectCandidateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select search result'**
  String get mapSearchSelectCandidateTitle;

  /// No description provided for @mapSpotDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Spot Details'**
  String get mapSpotDetailTitle;

  /// No description provided for @mapSpotCategoryCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get mapSpotCategoryCafe;

  /// No description provided for @mapSpotCategoryPark.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get mapSpotCategoryPark;

  /// No description provided for @mapSpotCategoryRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get mapSpotCategoryRestaurant;

  /// No description provided for @mapSpotCategorySightseeing.
  ///
  /// In en, this message translates to:
  /// **'Sightseeing'**
  String get mapSpotCategorySightseeing;

  /// No description provided for @mapSpotCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get mapSpotCategoryShopping;

  /// No description provided for @mapSpotCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get mapSpotCategoryOther;

  /// No description provided for @mapSpotRating.
  ///
  /// In en, this message translates to:
  /// **'Rating: {rating}'**
  String mapSpotRating(String rating);

  /// No description provided for @mapSpotStartRoute.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get mapSpotStartRoute;

  /// No description provided for @mapRouteNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Guidance'**
  String get mapRouteNavigationTitle;

  /// No description provided for @mapRouteDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get mapRouteDistance;

  /// No description provided for @mapRouteDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get mapRouteDuration;

  /// No description provided for @mapRouteMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String mapRouteMinutes(int minutes);

  /// No description provided for @mapRouteKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String mapRouteKm(String km);

  /// No description provided for @mapRouteClose.
  ///
  /// In en, this message translates to:
  /// **'End Guidance'**
  String get mapRouteClose;

  /// No description provided for @mapRouteExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand details'**
  String get mapRouteExpand;

  /// No description provided for @mapRouteCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get mapRouteCollapse;

  /// No description provided for @mapRouteCalculating.
  ///
  /// In en, this message translates to:
  /// **'Searching route...'**
  String get mapRouteCalculating;

  /// No description provided for @mapRouteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to search route'**
  String get mapRouteError;

  /// No description provided for @mapTravelModeDriving.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get mapTravelModeDriving;

  /// No description provided for @mapTravelModeWalking.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get mapTravelModeWalking;

  /// No description provided for @mapTravelModeBicycling.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get mapTravelModeBicycling;

  /// No description provided for @mapTravelModeTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get mapTravelModeTransit;

  /// No description provided for @mapRouteWalkingWarning.
  ///
  /// In en, this message translates to:
  /// **'Walking directions may lack sidewalks or pedestrian paths. Use caution.'**
  String get mapRouteWalkingWarning;

  /// No description provided for @mapRouteBicyclingWarning.
  ///
  /// In en, this message translates to:
  /// **'Bicycling directions may lack dedicated bike lanes. Follow traffic rules.'**
  String get mapRouteBicyclingWarning;

  /// No description provided for @devLottieTitle.
  ///
  /// In en, this message translates to:
  /// **'Lottie Animation Demo'**
  String get devLottieTitle;

  /// No description provided for @devLottieControlPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get devLottieControlPlay;

  /// No description provided for @devLottieControlPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get devLottieControlPause;

  /// No description provided for @devLottieControlStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get devLottieControlStop;

  /// No description provided for @devLottieControlReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get devLottieControlReverse;

  /// No description provided for @devLottieProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress (Seek): {progress}%'**
  String devLottieProgress(int progress);

  /// No description provided for @devLottieLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop Playback'**
  String get devLottieLoop;

  /// No description provided for @devLottieAssetSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Animation Asset'**
  String get devLottieAssetSelect;

  /// No description provided for @devLottieAssetOnboardingMemo.
  ///
  /// In en, this message translates to:
  /// **'Onboarding 1 (Memo)'**
  String get devLottieAssetOnboardingMemo;

  /// No description provided for @devLottieAssetOnboardingSync.
  ///
  /// In en, this message translates to:
  /// **'Onboarding 2 (Sync)'**
  String get devLottieAssetOnboardingSync;

  /// No description provided for @devLottieAssetOnboardingChat.
  ///
  /// In en, this message translates to:
  /// **'Onboarding 3 (Chat)'**
  String get devLottieAssetOnboardingChat;

  /// No description provided for @devLottieAssetEmptyBox.
  ///
  /// In en, this message translates to:
  /// **'Empty State (Empty Box)'**
  String get devLottieAssetEmptyBox;

  /// No description provided for @devLottieAssetNotFound.
  ///
  /// In en, this message translates to:
  /// **'404 Error (Not Found)'**
  String get devLottieAssetNotFound;

  /// No description provided for @devLottieAssetSuccessCheck.
  ///
  /// In en, this message translates to:
  /// **'Success Check (Success)'**
  String get devLottieAssetSuccessCheck;

  /// No description provided for @devLottieCompleted.
  ///
  /// In en, this message translates to:
  /// **'Animation completed!'**
  String get devLottieCompleted;

  /// No description provided for @devLottieNetworkSection.
  ///
  /// In en, this message translates to:
  /// **'Network Loading Example'**
  String get devLottieNetworkSection;

  /// No description provided for @notificationChannelHighImportanceName.
  ///
  /// In en, this message translates to:
  /// **'High Importance Notifications'**
  String get notificationChannelHighImportanceName;

  /// No description provided for @notificationChannelHighImportanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for important notifications and reminders.'**
  String get notificationChannelHighImportanceDescription;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @devNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications & DeepLink Demo'**
  String get devNotificationTitle;

  /// No description provided for @devNotificationTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'FCM Token'**
  String get devNotificationTokenLabel;

  /// No description provided for @devNotificationTokenCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy Token'**
  String get devNotificationTokenCopy;

  /// No description provided for @devNotificationTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'FCM Token copied to clipboard'**
  String get devNotificationTokenCopied;

  /// No description provided for @devNotificationPermissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission: {status}'**
  String devNotificationPermissionLabel(String status);

  /// No description provided for @devNotificationRequestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request Permission'**
  String get devNotificationRequestPermission;

  /// No description provided for @devNotificationTestSection.
  ///
  /// In en, this message translates to:
  /// **'Trigger Test Notifications (DeepLink Verification)'**
  String get devNotificationTestSection;

  /// No description provided for @devNotificationTestChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Notification Test'**
  String get devNotificationTestChatTitle;

  /// No description provided for @devNotificationTestChatBody.
  ///
  /// In en, this message translates to:
  /// **'You have a new message from AI Assistant. Tap to open chat.'**
  String get devNotificationTestChatBody;

  /// No description provided for @devNotificationTestMemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Memo Detail Notification Test'**
  String get devNotificationTestMemoTitle;

  /// No description provided for @devNotificationTestMemoBody.
  ///
  /// In en, this message translates to:
  /// **'Your memo has been updated. Tap to view details.'**
  String get devNotificationTestMemoBody;

  /// No description provided for @devNotificationTestProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Notification Test'**
  String get devNotificationTestProfileTitle;

  /// No description provided for @devNotificationTestProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile information was updated. Tap to check.'**
  String get devNotificationTestProfileBody;

  /// No description provided for @devNotificationSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get devNotificationSendTest;

  /// No description provided for @devNotificationLatestPayloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest Detected Notification Payload'**
  String get devNotificationLatestPayloadLabel;

  /// No description provided for @devNotificationTokenNotObtained.
  ///
  /// In en, this message translates to:
  /// **'Token not obtained (Real device or simulator)'**
  String get devNotificationTokenNotObtained;

  /// No description provided for @devNotificationStatusAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get devNotificationStatusAuthorized;

  /// No description provided for @devNotificationStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get devNotificationStatusDenied;

  /// No description provided for @devNotificationStatusNotDetermined.
  ///
  /// In en, this message translates to:
  /// **'Not Determined'**
  String get devNotificationStatusNotDetermined;

  /// No description provided for @devNotificationStatusProvisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional'**
  String get devNotificationStatusProvisional;

  /// No description provided for @notificationBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications to Stay Updated'**
  String get notificationBannerTitle;

  /// No description provided for @notificationBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Receive real-time updates for messages and important announcements.'**
  String get notificationBannerBody;

  /// No description provided for @notificationBannerEnableButton.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationBannerEnableButton;

  /// No description provided for @notificationBannerSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationBannerSettingsButton;

  /// No description provided for @notificationBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notificationBannerDismiss;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
