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
  String get ok => 'OK';

  @override
  String get loading => 'Loading...';

  @override
  String get send => 'Send';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

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
  String get signUpTitle => 'Sign Up';

  @override
  String get signUp => 'Create Account';

  @override
  String get googleSignUp => 'Google Sign In';

  @override
  String get emailVerificationTitle => 'Email Verification';

  @override
  String get emailVerificationDescription =>
      'A verification email has been sent.';

  @override
  String get checkVerificationStatus => 'Check verification status';

  @override
  String get resendVerificationMail => 'Resend verification email';

  @override
  String get resendVerificationMailSuccess =>
      'Verification email has been resent.';

  @override
  String get emailVerificationWaiting =>
      'Once your email is verified, you will be redirected automatically.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordMailSent => 'Password reset email has been sent.';

  @override
  String get errorNetwork => 'Please check your internet connection.';

  @override
  String get errorTimeout =>
      'The request is taking too long. Please try again in a place with better signal.';

  @override
  String get errorUnknown =>
      'An error occurred. Please try restarting the app or try again later.';

  @override
  String get errorOccurred => 'An error has occurred.';

  @override
  String get errorServer =>
      'A temporary server problem occurred. Please try again later.';

  @override
  String get errorUnauthenticated =>
      'Authentication required. Please login again.';

  @override
  String get errorUnauthorized =>
      'You don\'t have permission to perform this action.';

  @override
  String get errorDataParse =>
      'Failed to process data. Please try updating the app.';

  @override
  String get errorDatabase => 'Failed to save or load local data.';

  @override
  String get errorBadRequest => 'The request is invalid.';

  @override
  String get errorDialogTitle => 'An error has occurred';

  @override
  String get errorLoginFailed => 'Login failed.';

  @override
  String get errorSignUpFailed => 'Sign up failed.';

  @override
  String get errorInvalidEmail => 'The email address is badly formatted.';

  @override
  String get errorUserDisabled => 'This account has been disabled.';

  @override
  String get errorEmailAlreadyInUse => 'This email address is already in use.';

  @override
  String get errorWeakPassword =>
      'The password is too weak. Please make it more complex.';

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
  String get homeToChat => 'Go to AI Chat';

  @override
  String get homeToMemos => 'Go to Memos';

  @override
  String get homeToNotFound => 'Navigate to invalid path (NotFound test)';

  @override
  String get homeGetAppInfo => 'Get App Info';

  @override
  String get homeAppName => 'App Name';

  @override
  String get homeBundleId => 'Bundle ID';

  @override
  String get homeCrashTest => 'Crash Test';

  @override
  String get homeAnalyticsTest => 'Analytics Test';

  @override
  String get homeToGraph => 'Go to the chart creation screen';

  @override
  String get chatTitle => 'Gemini Assistant';

  @override
  String get chatHint => 'Enter a message...';

  @override
  String get thinking => 'AI is thinking...';

  @override
  String get chatEmptyMessage => 'The response from AI was empty.';

  @override
  String chatError(Object error) {
    return 'An error occurred: $error';
  }

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
  String get memoTitle => 'Offline Memos';

  @override
  String get memoEmpty => 'No memos yet!';

  @override
  String get memoInputTitleHint => 'Title';

  @override
  String get memoInputContentHint => 'Content';

  @override
  String get memoAdd => 'Add Memo';

  @override
  String get memoSave => 'Save';

  @override
  String get memoSyncing => 'Syncing...';

  @override
  String get memoSynced => 'Synced';

  @override
  String get memoUnsynced => 'Not Synced';

  @override
  String get memoDeleteConfirm => 'Are you sure you want to delete this memo?';

  @override
  String get chartLine => 'Line Chart';

  @override
  String get chartBar => 'Bar Chart';

  @override
  String get chartPie => 'Pie Chart';

  @override
  String chartDisplayTitle(String chartName) {
    return '$chartName Display';
  }

  @override
  String get chartInputTitle => 'Chart Data Input';

  @override
  String get chartItemLabel => 'Item Name';

  @override
  String get chartItemValue => 'Value';

  @override
  String get chartViewGraph => 'View Graph';

  @override
  String get chartNoData => 'No data available. Please add items first.';

  @override
  String get chartAddItem => 'Add Item';

  @override
  String get chartDataList => 'Data List';

  @override
  String get chartClearAll => 'Clear All';

  @override
  String get chartClearConfirm => 'Are you sure you want to clear all data?';

  @override
  String get sampleTitle => 'Sample Feature';

  @override
  String get sampleDescription =>
      'This is the sample feature screen. UI and state management will be added here.';

  @override
  String get userListTitle => 'User List';

  @override
  String userListLastFetched(String dateTime) {
    return 'Last fetched: $dateTime';
  }

  @override
  String get userListEmpty => 'No users found.';

  @override
  String get userListFetchError =>
      'Failed to fetch users. Please pull down to refresh.';

  @override
  String get retry => 'Retry';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'The page could not be found.';

  @override
  String get notFoundBackToHome => 'Back to Home';

  @override
  String get versionUpTitle => 'Update Available';

  @override
  String get versionUpMessageOptional => 'A new version is available.';

  @override
  String get versionUpMessageMandatory => 'A new version is required.';

  @override
  String get versionUpCancel => 'Later';

  @override
  String get versionUpUpdate => 'Update';

  @override
  String get developerLogTitle => 'Developer Log';

  @override
  String get navHome => 'Home';

  @override
  String get navChat => 'Chat';

  @override
  String get navMemos => 'Memos';

  @override
  String get navChart => 'Chart';

  @override
  String get navUsers => 'Users';
}
