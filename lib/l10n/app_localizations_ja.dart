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
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get errorNetwork => 'ネットワークエラーが発生しました。';

  @override
  String get errorTimeout => '通信がタイムアウトしました。';

  @override
  String get errorUnknown => '予期しないエラーが発生しました。';

  @override
  String get errorServer => 'サーバーエラーが発生しました。';

  @override
  String get errorDialogTitle => 'エラーが発生しました';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get homeDescription => '👋 ここはホーム画面です。下のボタンから各画面へ移動してみましょう。';

  @override
  String get homeCurrentEnv => 'Current Environment';

  @override
  String get homeToSettings => '設定画面へ';

  @override
  String get homeToSample => 'サンプル画面へ';

  @override
  String get homeToUserList => 'ユーザー一覧画面へ（APIで情報取得）';

  @override
  String get homeToNotFound => '存在しないパスに遷移（NotFoundの動作確認）';

  @override
  String get homeGetAppInfo => 'アプリ情報取得';

  @override
  String get homeAppName => 'アプリ名';

  @override
  String get homeBundleId => 'バンドルID';

  @override
  String get notFoundTitle => 'ページが見つかりません';

  @override
  String get notFoundMessage => 'ページが見つかりませんでした。';

  @override
  String get notFoundBackToHome => 'ホームへ戻る';

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
  String get sampleTitle => 'サンプル機能';

  @override
  String get sampleDescription => 'サンプル機能の画面です。ここにUIや状態管理を追加します。';

  @override
  String get userListTitle => 'ユーザー一覧';
}
