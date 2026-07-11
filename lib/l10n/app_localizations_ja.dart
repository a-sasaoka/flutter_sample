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
  String get delete => '削除';

  @override
  String get retry => '再試行';

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
  String get errorNetwork => 'インターネット接続を確認してください。';

  @override
  String get errorTimeout => '通信に時間がかかっています。電波の良い場所で再度お試しください。';

  @override
  String get errorUnknown => 'エラーが発生しました。アプリの再起動や、時間をおいての実行をお試しください。';

  @override
  String get errorOccurred => 'エラーが発生しました。';

  @override
  String get errorServer => 'サーバーで一時的な問題が発生しました。時間をおいて再度お試しください。';

  @override
  String get errorUnauthenticated => 'ログインが必要です。再度ログインしてください。';

  @override
  String get errorUnauthorized => 'この操作を行う権限がありません。';

  @override
  String get errorDataParse => 'データの解析に失敗しました。最新版への更新をお試しください。';

  @override
  String get errorDatabase => 'ローカルデータの保存または読み込みに失敗しました。';

  @override
  String get errorBadRequest => 'リクエストが正しくありません。';

  @override
  String get errorDialogTitle => 'エラーが発生しました';

  @override
  String get errorLoginFailed => 'ログインに失敗しました。';

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
  String get homeToUserList => 'ユーザー一覧画面へ（APIで情報取得）';

  @override
  String get homeToResetPassword => 'パスワードリセット画面へ';

  @override
  String get homeToChat => 'AIチャット画面へ';

  @override
  String get homeToMemos => 'メモ一覧画面へ';

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
  String get homeToGraph => 'グラフ作成画面へ';

  @override
  String get chatTitle => 'Gemini アシスタント';

  @override
  String get chatHint => 'メッセージを入力...';

  @override
  String get thinking => 'AIが考え中...';

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
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeToggle => 'ダークモードに切り替える（簡易）';

  @override
  String get settingsLocaleSection => '🌐 ロケール設定';

  @override
  String get settingsLocaleSystem => 'システム';

  @override
  String get settingsLocaleJa => '日本語（ja）';

  @override
  String get settingsLocaleEn => '英語（en）';

  @override
  String get settingsPreview => 'プレビュー';

  @override
  String get memoTitle => 'オフラインメモ帳';

  @override
  String get memoEmpty => 'まだメモがありません！';

  @override
  String get memoInputTitleHint => 'タイトル';

  @override
  String get memoInputContentHint => '内容';

  @override
  String get memoAdd => 'メモを追加';

  @override
  String get memoSave => '保存';

  @override
  String get memoSyncing => '同期中...';

  @override
  String get memoSynced => '同期済み';

  @override
  String get memoUnsynced => '未同期';

  @override
  String get memoDeleteConfirm => 'このメモを削除しますか？';

  @override
  String get memoSearchHint => 'メモを検索...';

  @override
  String get memoSortCreatedAtDesc => '作成日時：新しい順';

  @override
  String get memoSortCreatedAtAsc => '作成日時：古い順';

  @override
  String get memoSortUpdatedAtDesc => '更新日時：新しい順';

  @override
  String get memoSortUpdatedAtAsc => '更新日時：古い順';

  @override
  String get memoSortTitleAsc => 'タイトル：昇順';

  @override
  String get memoSortTitleDesc => 'タイトル：降順';

  @override
  String get chartLine => '折れ線グラフ';

  @override
  String get chartBar => '棒グラフ';

  @override
  String get chartPie => '円グラフ';

  @override
  String chartDisplayTitle(String chartName) {
    return '$chartNameの表示';
  }

  @override
  String get chartInputTitle => 'グラフデータ入力';

  @override
  String get chartItemLabel => '項目名';

  @override
  String get chartItemValue => '値';

  @override
  String get chartViewGraph => 'グラフを表示';

  @override
  String get chartNoData => 'データがありません。まず項目を追加してください。';

  @override
  String get chartAddItem => '項目を追加';

  @override
  String get chartDataList => 'データ一覧';

  @override
  String get chartClearAll => 'すべて削除';

  @override
  String get chartClearConfirm => '全てのデータを削除しますか？';

  @override
  String get userListTitle => 'ユーザー一覧';

  @override
  String userListLastFetched(String dateTime) {
    return '最終取得: $dateTime';
  }

  @override
  String get userListEmpty => 'ユーザーが見つかりませんでした。';

  @override
  String get userListFetchError => 'ユーザー一覧の取得に失敗しました。下へスクロールして更新してください。';

  @override
  String get notFoundTitle => 'ページが見つかりません';

  @override
  String get notFoundMessage => 'ページが見つかりませんでした。';

  @override
  String get notFoundBackToHome => 'ホームへ戻る';

  @override
  String get versionUpTitle => '最新版への更新';

  @override
  String get versionUpMessageOptional => '新しいバージョンが利用可能です。アップデートしますか？';

  @override
  String get versionUpMessageMandatory => 'アプリを利用するには最新版へのアップデートが必要です。';

  @override
  String get versionUpCancel => 'あとで';

  @override
  String get versionUpUpdate => 'アップデート';

  @override
  String get developerLogTitle => '開発者用ログ';

  @override
  String get navHome => 'ホーム';

  @override
  String get navChat => 'チャット';

  @override
  String get navMemos => 'メモ';

  @override
  String get navChart => 'グラフ';

  @override
  String get navUsers => 'ユーザー';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get onboardingPage1Title => 'シンプルなメモ機能';

  @override
  String get onboardingPage1Desc => '思いついたアイデアやタスクを、いつでもどこでもすばやくメモに残すことができます。';

  @override
  String get onboardingPage2Title => 'どこでもつながる同期機能';

  @override
  String get onboardingPage2Desc =>
      'インターネットがないオフライン環境でもメモを書くことができ、接続時に自動でクラウドへ同期されます。';

  @override
  String get onboardingPage3Title => 'AIチャットアシスタント';

  @override
  String get onboardingPage3Desc =>
      'メモのまとめを作ったり、アイデアのブレインストーミングをAIアシスタントがサポートします。';

  @override
  String get devStorageTitle => 'ストレージ確認・編集';

  @override
  String get devStoragePrefsTab => 'SharedPreferences';

  @override
  String get devStorageSecureTab => 'SecureStorage';

  @override
  String get devStorageEditDialogTitle => 'キーの編集';

  @override
  String get devStorageAddDialogTitle => 'キーの追加';

  @override
  String get devStorageConfirmClear => 'すべてのデータを削除しますか？';

  @override
  String get devStorageKey => 'キー';

  @override
  String get devStorageValue => '値';

  @override
  String get devStorageType => 'データ型';

  @override
  String get devStorageClearAll => '一括削除';

  @override
  String devStorageError(String message) {
    return 'エラー: $message';
  }

  @override
  String get devStorageNoPrefsData => 'SharedPreferencesのデータが見つかりません。';

  @override
  String get devStorageNoSecureData => 'SecureStorageのデータが見つかりません。';

  @override
  String get profileTitle => '会員情報登録・変更';

  @override
  String get profileSaveSuccess => '会員情報を保存しました';

  @override
  String get profileNameLabel => '氏名（必須）';

  @override
  String get profileNameHint => '山田 太郎';

  @override
  String get profileNameRequired => '氏名は必須入力です';

  @override
  String get profileNameEmpty => '氏名に空白のみを入力することはできません';

  @override
  String get profileNameMaxLength => '氏名は最大128文字までです';

  @override
  String get profileEmailLabel => 'メールアドレス（必須）';

  @override
  String get profileEmailRequired => 'メールアドレスは必須入力です';

  @override
  String get profileEmailInvalid => '有効なメールアドレス形式で入力してください';

  @override
  String get profileEmailMaxLength => 'メールアドレスは最大256文字までです';

  @override
  String get profileDisplayNameLabel => '表示名';

  @override
  String get profileDisplayNameHint => 'タロウ';

  @override
  String get profileDisplayNameMaxLength => '表示名は最大128文字までです';

  @override
  String get profilePhoneLabel => '電話番号（ハイフンなし）';

  @override
  String get profilePhoneInvalid => '半角数字のみで入力してください';

  @override
  String get profilePhoneMobileLength => '携帯電話・IP電話は11桁で入力してください';

  @override
  String get profilePhoneLandlineLength => '固定電話等は10桁で入力してください';

  @override
  String get profileSaveButton => '保存する';

  @override
  String profileCurrentValue(String value) {
    return '現在の設定: $value';
  }

  @override
  String get profileValueNotSet => '未設定';
}
