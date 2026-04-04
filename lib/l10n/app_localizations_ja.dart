// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'フラッターサンプル';

  @override
  String get hello => 'こんにちは';

  @override
  String get ok => 'OK';

  @override
  String get loading => '読み込み中';

  @override
  String get send => '送信';

  @override
  String get close => '閉じる';

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get loginEmailLabel => 'メールアドレス';

  @override
  String get loginPasswordLabel => 'パスワード';

  @override
  String get loginButton => 'ログイン';

  @override
  String get loginSuccess => 'ログイン成功！';

  @override
  String get signUpTitle => '新規登録';

  @override
  String get signUp => '登録';

  @override
  String get googleSignUp => 'Googleでログイン';

  @override
  String get emailVerificationTitle => 'メール確認';

  @override
  String get emailVerificationDescription => '登録したメールアドレスに確認メールを送信しました。';

  @override
  String get checkVerificationStatus => '認証を完了したか確認する';

  @override
  String get resendVerificationMail => '確認メールを再送する';

  @override
  String get resendVerificationMailSuccess => '確認メールを再送信しました';

  @override
  String get emailVerificationWaiting => 'メールを確認後、この画面に戻ると自動的に次の画面へ進みます。';

  @override
  String get resetPassword => 'パスワード再設定';

  @override
  String get resetPasswordMailSent => '再設定メールを送信しました';

  @override
  String get errorNetwork => 'ネットワークエラーが発生しました。';

  @override
  String get errorTimeout => '通信がタイムアウトしました。';

  @override
  String get errorUnknown => '予期しないエラーが発生しました。';

  @override
  String get errorOccurred => 'エラーが発生しました。';

  @override
  String get errorServer => 'サーバーエラーが発生しました。';

  @override
  String get errorDialogTitle => 'エラーが発生しました';

  @override
  String get errorLoginFailed => 'ログインに失敗しました。';

  @override
  String get errorSignUpFailed => '登録に失敗しました';

  @override
  String get errorInvalidEmail => 'メールアドレスの形式が正しくありません。';

  @override
  String get errorUserDisabled => 'このアカウントは無効化されています。';

  @override
  String get errorEmailAlreadyInUse => 'このメールアドレスは既に登録されています。';

  @override
  String get errorWeakPassword => 'パスワードが弱すぎます。もう少し複雑にしてください。';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get homeDescription => '👋 ここはホーム画面です。下のボタンから各画面へ移動してみましょう。';

  @override
  String get homeCurrentEnv => '現在の環境';

  @override
  String get homeToSettings => '設定画面へ';

  @override
  String get homeToSample => 'サンプル画面へ';

  @override
  String get homeToUserList => 'ユーザー一覧画面へ（APIで情報取得）';

  @override
  String get homeToResetPassword => 'パスワードリセット画面へ';

  @override
  String get homeToChat => 'AIチャット画面へ';

  @override
  String get homeToNotFound => '存在しないパスに遷移（NotFoundの動作確認）';

  @override
  String get homeGetAppInfo => 'アプリ情報取得';

  @override
  String get homeAppName => 'アプリ名';

  @override
  String get homeBundleId => 'バンドルID';

  @override
  String get homeCrashTest => 'クラッシュテスト';

  @override
  String get homeAnalyticsTest => 'アナリティクステスト';

  @override
  String get chatTitle => 'Gemini アシスタント';

  @override
  String get chatHint => 'メッセージを入力...';

  @override
  String get chatEmptyMessage => 'AIからの返答が空でした。';

  @override
  String chatError(Object error) {
    return 'エラーが発生しました: $error';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsThemeSection => '🎨 テーマ設定';

  @override
  String get settingsThemeSystem => 'システム（端末に合わせる）';

  @override
  String get settingsThemeLight => 'ライト（明るい）';

  @override
  String get settingsThemeDark => 'ダーク（暗い）';

  @override
  String get settingsThemeToggle => 'ダークモードに切り替える（簡易）';

  @override
  String get settingsLocaleSection => '🌐 ロケール設定';

  @override
  String get settingsLocaleSystem => 'システム（端末に合わせる）';

  @override
  String get settingsLocaleJa => '日本語（ja）';

  @override
  String get settingsLocaleEn => '英語（en）';

  @override
  String get sampleTitle => 'サンプル機能';

  @override
  String get sampleDescription => 'サンプル機能の画面です。ここにUIや状態管理を追加します。';

  @override
  String get userListTitle => 'ユーザー一覧';

  @override
  String get notFoundTitle => 'ページが見つかりません';

  @override
  String get notFoundMessage => 'ページが見つかりませんでした。';

  @override
  String get notFoundBackToHome => 'ホームへ戻る';

  @override
  String get versionUpTitle => '最新の更新があります。\nアップデートをお願いします。';

  @override
  String get versionUpCancel => 'キャンセル';

  @override
  String get versionUpUpdate => 'アップデート';
}
