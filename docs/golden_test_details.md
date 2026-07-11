# 🎨 ゴールデンテスト画面状態 詳細仕様書 (Golden Test Details)

この資料は、アプリ内に導入されているすべてのゴールデンテスト（画面の見た目の写真テスト）が、どのような画面状態（背景色、データの中身、言語など）をテストしているかを詳しくまとめたものです。

実際のテスト結果（画像ファイル）を手元で開き、デザインが崩れていないか（文字化けやレイアウト崩れがないか）を確認するためのチェックリストとしても活用してください。

---

## 📌 ゴールデンテストとは？

画面の**「お手本の写真（スクリーンショット）」**をあらかじめ保存しておき、プログラムを変更したときに画面が崩れてしまっていないかを写真同士を重ね合わせて自動で比べるテストです。

- **お手本画像（Master）**: 各テストファイルと同じディレクトリにある `goldens/macos/` 内に保存されています。
- **今回のテスト実行結果（Test）**: テストが失敗したときのみ `failures/` 内に保存されます。

---

## 👁️ 画像の目視確認チェックリスト

手元のPCで、各項目にある **「📷 画像を表示する」** をクリックして画像を開き、以下のポイントを確認してください。

> [!IMPORTANT]
>
> - 文字が「□□□」のように文字化け（トーフ現象）していないか？
> - ライトモードとダークモードで、文字が背景色と同化して読みにくくなっていないか？
> - ボタンや入力フォームの位置がズレて重なったりしていないか？

---

### 1. 共通コンポーネント (Core Widgets)

#### 404エラー画面 (NotFoundScreen)

存在しない画面にアクセスした際のエラー画面です。

- **テスト対象**: ライトモード（パス表示あり/なし）、ダークモード（パスなし）の計3状態
- **チェックポイント**:
  - エラーメッセージ（Page Not Found / The page could not be found.）が正しく表示されているか。
  - 無効なパス情報がある場合（`/invalid/path/test`）に、そのパスがレイアウト内に綺麗に収まっているか。
- **画像リンク**: [📷 画像を表示する (not_found_screen.png)](../test/src/core/widgets/goldens/macos/not_found_screen.png)

#### バージョンアップ通知ダイアログ (VersionUpDialog)

新しいアプリアップデートがある場合に表示されるダイアログです。

- **テスト対象**: 任意アップデート（ライト/ダーク）、強制アップデート（ライト/ダーク）の計4状態
- **チェックポイント**:
  - 任意アップデート（`isCancelable: true`）のとき、「後で」と「更新」の2つのボタンが表示されているか。
  - 強制アップデート（`isCancelable: false`）のとき、「後で」ボタンが表示されず、「更新」ボタンだけになっているか。
- **画像リンク**: [📷 画像を表示する (version_up_dialog.png)](../test/src/core/widgets/goldens/macos/version_up_dialog.png)

---

### 2. 認証機能 (Auth Features)

#### Firebaseメール認証待ち画面 (FirebaseEmailVerificationScreen)

会員登録後、メールアドレスの認証完了を待つ画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - 「メール認証」「確認メールを送信しました。」などのテキストが正しく表示されているか。
  - 「再送信する」「認証を完了したか確認する」「ログアウトして戻る」ボタンのレイアウト。
- **画像リンク**: [📷 画像を表示する (firebase_email_verification_screen.png)](../test/src/features/auth/presentation/goldens/macos/firebase_email_verification_screen.png)

#### Firebaseログイン画面 (FirebaseLoginScreen)

Firebase Auth を使用したログイン画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - メールアドレス・パスワードの入力欄、および「Googleでログイン」ボタンなどのレイアウト。
  - 「新規登録へ」や「パスワードをお忘れですか？」といったリンクテキストの配置。
- **画像リンク**: [📷 画像を表示する (firebase_login_screen.png)](../test/src/features/auth/presentation/goldens/macos/firebase_login_screen.png)

#### Firebaseパスワード再設定画面 (FirebaseResetPasswordScreen)

パスワード再設定用のメール送信画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - メールアドレス入力フィールドと「送信する」ボタンの配置。
- **画像リンク**: [📷 画像を表示する (firebase_reset_password_screen.png)](../test/src/features/auth/presentation/goldens/macos/firebase_reset_password_screen.png)

#### Firebase新規登録画面 (FirebaseSignUpScreen)

新規会員登録画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - メールアドレスとパスワードの入力フォーム、「登録する」ボタン、および「ログインへ戻る」ボタンの配置。
- **画像リンク**: [📷 画像を表示する (firebase_sign_up_screen.png)](../test/src/features/auth/presentation/goldens/macos/firebase_sign_up_screen.png)

#### 通常のログイン画面 (LoginScreen)

Firebaseを使用しない、通常のメール・パスワードによるログイン画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - シンプルなメール/パスワード入力フォームと「ログインする」ボタン。
- **画像リンク**: [📷 画像を表示する (login_screen.png)](../test/src/features/auth/presentation/goldens/macos/login_screen.png)

---

### 3. グラフ機能 (Chart Features)

#### グラフ表示画面 (ChartDisplayScreen)

各種グラフの描画画面です。

- **テスト対象**: 折れ線グラフ（ライト）、棒グラフ（ダーク）、円グラフ（ライト）、データなし空状態（ライト）の計4状態
- **チェックポイント**:
  - グラフ（折れ線・棒・円）が綺麗にレンダリングされ、線や面がはみ出ていないか。
  - データが空のとき、「データがありません」というメッセージが適切に表示されているか。
- **画像リンク**: [📷 画像を表示する (chart_display_screen.png)](../test/src/features/chart/presentation/goldens/macos/chart_display_screen.png)

#### グラフ用データ入力画面 (ChartInputScreen)

グラフ用データを入力・編集する画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - データ追加のための入力フォーム、追加されたデータの一覧表示。
- **画像リンク**: [📷 画像を表示する (chart_input_screen.png)](../test/src/features/chart/presentation/goldens/macos/chart_input_screen.png)

---

### 4. AIチャット機能 (Chat Features)

#### AIチャット画面 (ChatScreen)

Vertex AI（Gemini API）等とやりとりするチャット画面です。

- **テスト対象**: 会話履歴がある状態、AIが考え中のローディング状態の計2状態
- **チェックポイント**:
  - ユーザーの発言（右側・青色吹き出し）とAIの発言（左側・グレー吹き出し）が正しく配置されているか。
  - AIが考え中のときに、メッセージ末尾にローディングアニメーションの枠（Shimmer）が表示されているか。
- **画像リンク**: [📷 画像を表示する (chat_screen.png)](../test/src/features/chat/presentation/goldens/macos/chat_screen.png)

---

### 5. 開発者用ツール (Dev Tools Features)

#### 開発者用データ管理画面 (DeveloperStorageScreen)

ローカルストレージに保存されているデータを確認・編集する開発者向け画面です。

- **テスト対象**:
  - **SharedPreferencesデータあり**: [📷 画像を表示 (developer_storage_screen_prefs_data.png)](../test/src/features/dev_tools/presentation/goldens/macos/developer_storage_screen_prefs_data.png)（ライト/ダーク）
  - **SecureStorageデータあり**: [📷 画像を表示 (developer_storage_screen_secure_data.png)](../test/src/features/dev_tools/presentation/goldens/macos/developer_storage_screen_secure_data.png)（ライト/ダーク、SecureStorageタブ選択）
  - **データなし（空）状態**: [📷 画像を表示 (developer_storage_screen_empty.png)](../test/src/features/dev_tools/presentation/goldens/macos/developer_storage_screen_empty.png)（SharedPreferences/SecureStorage空、ライト）
- **チェックポイント**:
  - ストレージキーと値（文字列、数値、真偽値など）がリスト形式で綺麗に整列しているか。
  - SecureStorageタブでトークンなどの秘匿情報が表示されているか。
  - データが無いときに「データがありません」等のメッセージが見えるか。

---

### 6. ホーム画面 & スプラッシュ・その他 (Main & Others)

#### ホーム画面 (HomeScreen)

各機能へのリンクボタンが集約されたアプリのメイン画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - 開発用ツールやデバッグ用のメニュー、およびアプリ情報が正しく並んでいるか。
  - 画面下部にアプリ情報（アプリ名、バージョン、Bundle ID、現在の環境）が正しく配置されているか。
- **画像リンク**: [📷 画像を表示する (home_screen.png)](../test/src/features/home/presentation/goldens/macos/home_screen.png)

#### メモ帳画面 (MemoScreen)

Drift（SQLite）を使用したローカルメモ帳画面です。

- **テスト対象**: メモなし状態、メモあり状態（それぞれライト/ダークモード）の計4状態
- **チェックポイント**:
  - メモがないとき、「メモがありません」というメッセージが表示されているか。
  - メモがあるとき、タイトル・内容、作成日時、および「同期済み」「未同期」のバッジが正しく表示されているか。
  - ダークモード時でもメモカードの文字やバッジの色が正しく表示され、視認できるか。
- **画像リンク**: [📷 画像を表示する (memo_screen.png)](../test/src/features/memos/presentation/goldens/macos/memo_screen.png)

#### チュートリアル画面 (OnboardingScreen)

アプリ初回起動時に表示されるチュートリアル画面です。

- **テスト対象**: 最初のスライド状態（ライト/ダークモード）の計2状態
- **チェックポイント**:
  - イラスト、説明タイトル、説明文、および「Skip」と「次へ」ボタンが正しく表示されているか。
  - ダークモード時でも背景や説明文、各種ボタンの視認性が保たれているか。
- **画像リンク**: [📷 画像を表示する (onboarding_screen.png)](../test/src/features/onboarding/presentation/goldens/macos/onboarding_screen.png)

#### プロフィール編集画面 (ProfileEditScreen)

ユーザー情報の編集画面です。

- **テスト対象**:
  - **正常系**: [📷 画像を表示 (profile_edit_screen_basic.png)](../test/src/features/profile/presentation/goldens/macos/profile_edit_screen_basic.png)（ライト/ダーク）
  - **ローディング状態**: [📷 画像を表示 (profile_edit_screen_loading.png)](../test/src/features/profile/presentation/goldens/macos/profile_edit_screen_loading.png)（ライト）
  - **エラー状態**: [📷 画像を表示 (profile_edit_screen_error.png)](../test/src/features/profile/presentation/goldens/macos/profile_edit_screen_error.png)（ライト）
- **チェックポイント**:
  - 正常系で、氏名やメールアドレスの入力フォームに初期データ（テスト太郎など）が入っているか。
  - ローディング状態で中央に読み込みインジケータが表示されているか。
  - エラー状態で適切なエラーメッセージが表示されているか。

#### 設定画面 (SettingsScreen)

テーマ切り替えや言語切り替えができる設定画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - テーマ設定（システム、ライト、ダーク）のボタンが選択したテーマに応じてアクティブに切り替わっているか。
  - 言語設定（システム依存、日本語、英語）、およびログアウトボタンが表示されているか。
  - ダークモード時にもスイッチや設定項目が正しく視認できるか。
- **画像リンク**: [📷 画像を表示する (settings_screen.png)](../test/src/features/settings/presentation/goldens/macos/settings_screen.png)

#### 起動画面 (SplashScreen)

アプリ起動時に一瞬だけ表示されるスプラッシュ画面です。

- **テスト対象**: ライトモード、ダークモードの計2状態
- **チェックポイント**:
  - グラデーション背景の中央に、アプリタイトル「Flutter Sample App」が綺麗に配置されているか。
- **画像リンク**: [📷 画像を表示する (splash_screen.png)](../test/src/features/splash/presentation/goldens/macos/splash_screen.png)

#### ユーザー一覧画面 (UserListScreen)

API経由で取得したユーザー一覧を表示する画面です。

- **テスト対象**: ユーザーあり状態（ライト/ダーク）、ユーザーなし状態（ライト/ダーク）の計4状態
- **チェックポイント**:
  - ユーザーありのとき、名前やメールアドレス、電話番号などのカードが正しくリスト表示されているか。
  - ユーザーなしのとき、「No users found.」というメッセージが表示されているか。
- **画像リンク**: [📷 画像を表示する (user_list_screen.png)](../test/src/features/user/presentation/goldens/macos/user_list_screen.png)
