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

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'A network error has occurred.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out.'**
  String get errorTimeout;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnknown;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred.'**
  String get errorOccurred;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred.'**
  String get errorServer;

  /// No description provided for @errorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred'**
  String get errorDialogTitle;

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

  /// No description provided for @homeToSample.
  ///
  /// In en, this message translates to:
  /// **'Go to Sample Page'**
  String get homeToSample;

  /// No description provided for @homeToUserList.
  ///
  /// In en, this message translates to:
  /// **'Go to User List (API Fetch)'**
  String get homeToUserList;

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

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
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
  /// **'System (follow device)'**
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
  /// **'System (follow device)'**
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

  /// No description provided for @sampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample Feature'**
  String get sampleTitle;

  /// No description provided for @sampleDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the sample feature screen. UI and state management will be added here.'**
  String get sampleDescription;

  /// No description provided for @userListTitle.
  ///
  /// In en, this message translates to:
  /// **'User List'**
  String get userListTitle;

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

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get errorLoginFailed;

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

  /// No description provided for @errorSignUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed.'**
  String get errorSignUpFailed;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;
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
