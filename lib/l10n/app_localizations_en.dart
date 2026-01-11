// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Sample';

  @override
  String get hello => 'Hello';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get ok => 'OK';

  @override
  String get errorNetwork => 'A network error has occurred.';

  @override
  String get errorTimeout => 'The request timed out.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get errorOccurred => 'An error has occurred.';

  @override
  String get errorServer => 'A server error occurred.';

  @override
  String get errorDialogTitle => 'An error has occurred';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeDescription =>
      '👋 This is the home screen. Use the buttons below to navigate to each page.';

  @override
  String get homeCurrentEnv => 'Current Environment';

  @override
  String get homeToSettings => 'Go to Settings';

  @override
  String get homeToSample => 'Go to Sample Page';

  @override
  String get homeToUserList => 'Go to User List (API Fetch)';

  @override
  String get homeToResetPassword => 'Go to Reset Password';

  @override
  String get homeToNotFound => 'Navigate to invalid path (NotFound test)';

  @override
  String get homeGetAppInfo => 'Get App Info';

  @override
  String get homeAppName => 'App Name';

  @override
  String get homeBundleId => 'Bundle ID';

  @override
  String get notFoundTitle => 'Page Not Found';

  @override
  String get notFoundMessage => 'The page could not be found.';

  @override
  String get notFoundBackToHome => 'Back to Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThemeSection => '🎨 Theme Settings';

  @override
  String get settingsThemeSystem => 'System (follow device)';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeToggle => 'Toggle Dark Mode (simple)';

  @override
  String get settingsLocaleSection => '🌐 Locale Settings';

  @override
  String get settingsLocaleSystem => 'System (follow device)';

  @override
  String get settingsLocaleJa => 'Japanese (ja)';

  @override
  String get settingsLocaleEn => 'English (en)';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginEmailLabel => 'Email Address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get sampleTitle => 'Sample Feature';

  @override
  String get sampleDescription =>
      'This is the sample feature screen. UI and state management will be added here.';

  @override
  String get userListTitle => 'User List';

  @override
  String get homeCrashTest => 'Crash Test';

  @override
  String get homeAnalyticsTest => 'Analytics Test';

  @override
  String get errorLoginFailed => 'Login failed.';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get signUp => 'Create Account';

  @override
  String get googleSignUp => 'Google Sign In';

  @override
  String get errorSignUpFailed => 'Sign up failed.';

  @override
  String get loading => 'Loading...';

  @override
  String get emailVerificationTitle => 'Email Verification';

  @override
  String get emailVerificationDescription =>
      'A verification email has been sent.';

  @override
  String get resendVerificationMail => 'Resend verification email';

  @override
  String get emailVerificationWaiting =>
      'Once your email is verified, you will be redirected automatically.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordMailSent => 'Password reset email has been sent.';

  @override
  String get send => 'Send';
}
