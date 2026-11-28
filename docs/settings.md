# 設定機能 (Settings Feature)

## 概要

設定画面では、アプリ全体のユーザー設定（テーマや言語）の管理、およびアカウント操作（ログアウト・アカウント完全退会）を行うことができます。

---

## 主な機能

### 1. テーマ設定 (Theme Settings)

アプリの見た目（ライト／ダーク／システム）を切り替えることができます。

- **SegmentedButton**: 直感的な 3 つの選択肢からモードを選択できます。
- **ダークモードトグル**: 簡易的にライト／ダークを反転させるスイッチを備えています。
- **永続化**: 変更されたテーマ設定は `SharedPreferencesAsync` を通じて即座に保存され、次回のアプリ起動時に自動で適用されます。

### 2. テーマカラー設定 (Theme Color Settings)

アプリ全体のアクセントとなる基本カラーを切り替えることができます。

- **ChoiceChip**: 4 つのカラー（インディゴ、ティール、オレンジ、ピンク）から直感的に選択できます。
- **FlexColorScheme との連動**: 選択したカラースキーム（`FlexScheme`）に合わせて、アプリ全体のUIカラーが一括で切り替わります。
- **永続化**: 変更されたカラー設定は `SharedPreferencesAsync` を通じて即座に保存され、次回のアプリ起動時に自動で適用されます。

### 3. 文字サイズ設定 (Text Scale Settings)

アプリ全体のテキスト表示サイズを切り替えることができます。

- **SegmentedButton**: 3 つのサイズ（小: 0.85倍、標準: 1.0倍、大: 1.15倍）から選択できます。
- **プレビュー**: 変更内容が即座にカード内のプレビュー用テキストに反映され、実際の文字の大きさを確認できます。
- **アプリ全体への一括反映**: `main.dart`（`MyApp`）の `MediaQuery` を通じて、アプリ内の全画面の文字サイズへ一貫して反映されます。
- **永続化**: 変更された文字サイズ設定は `SharedPreferencesAsync` を通じて即座に保存され、次回のアプリ起動時に自動で適用されます。

### 4. 言語設定 (Locale Settings)

アプリの表示言語を切り替えることができます。

- **対応言語**: 日本語、英語、およびシステム標準の設定を選択可能です。
- **プレビュー**: 変更内容が即座に画面上の「こんにちは」などのテキストに反映され、確認が可能です。

### 5. 法的情報 (Legal Documents)

アプリの利用規約およびプライバシーポリシーを閲覧できます。

- **利用規約**: `TermsRoute`（`/terms`）へプッシュ遷移し、アプリバンドル内のMarkdownを閲覧可能。
- **プライバシーポリシー**: `PrivacyPolicyRoute`（`/privacy`）へプッシュ遷移し、アプリバンドル内のMarkdownを閲覧可能。
- **詳細仕様**: [法的情報・Markdown閲覧機能 (Legal)](legal.md) を参照してください。

### 6. アカウント操作

利用している認証方式（Firebase Auth または 自前サーバー／トークン認証）を問わず、安全にログアウトおよびアカウント完全退会を行うことができます。

- **ログアウト**: `authServiceProvider.signOut()` を通じてセッションを終了し、アプリロック（パスコード・生体認証設定）のクリアを試行した上でログイン画面へ遷移します（※アプリロックの解除に失敗した場合でもセッションの切断と画面遷移は継続して行われ、エラー内容はログに記録されます）。
- **アカウント削除（退会）**: `_LogoutButton` の下（`if (isAuthed)` 内）に控えめなエラーカラー枠線ボタン（`_DeleteAccountButton`）を配置し、2 段階確認（Step 1 影響範囲・復元不可説明 ➔ Step 2 赤色ボタン最終確認）を行います。事前鮮度チェックによる再認証（または `requires-recent-login` 発生時の再認証モーダル表示：Password / Google / 両方切替対応、エラーバナー付きダイアログ内再試行可能）と、実行中の操作ブロック（`barrierDismissible: false` / `PopScope(canPop: false)`）を経て、完了後はログイン画面へ自動遷移して完了 SnackBar を表示します。実装詳細は [settings_screen.dart](../lib/src/features/settings/presentation/settings_screen.dart)・[account_deletion_dialogs.dart](../lib/src/features/settings/presentation/widgets/account_deletion_dialogs.dart)・[reauthenticate_dialog.dart](../lib/src/features/settings/presentation/widgets/reauthenticate_dialog.dart)・[auth_service.dart](../lib/src/features/auth/application/auth_service.dart)・[認証仕様](auth.md) を参照してください。
- **一貫性**: 他の認証画面と共通の `errorContainer` / `error` 配色を使用したボタンデザインを採用しています。

---

## 📁 ディレクトリ構成

```plaintext
lib/src/core/config/
 ├── theme_mode_provider.dart   # テーマモード（明暗）状態の管理
 ├── theme_scheme_provider.dart # テーマカラー（FlexScheme）状態の管理
 ├── text_scale_provider.dart   # 文字サイズ倍率状態の管理
 └── locale_provider.dart       # 言語状態の管理

lib/src/features/settings/
 └── presentation/
      ├── settings_screen.dart                  # 設定画面のUI
      └── widgets/
           ├── account_deletion_dialogs.dart    # 退会2段階確認・処理中ダイアログ群
           └── reauthenticate_dialog.dart       # 本人確認（再認証）ダイアログ
```

---

## 💡 実装のポイント

- **ColorScheme の活用**: `SegmentedButton` や `Card` の配色、ログアウトボタンの警告色など、すべて `Theme.of(context).colorScheme` に連動しており、テーマ変更時に一貫したデザインを維持します。
- **堅牢な非同期処理**: ログアウト処理等の非同期操作において `context.mounted` チェックを徹底し、画面遷移後の予期せぬクラッシュを防止しています。
- **パーツごとの自立化（疎結合設計）**: 設定画面（`SettingsScreen`）は各設定カードごとに必要なプロバイダー（`themeModeProvider`, `themeSchemeProvider`, `textScaleProvider`, `localeProvider`）を直接監視しています。これにより、1つの設定（例: 文字サイズ）を変えたときに画面全体が無駄に再描画（リビルド）されるのを防いでいます。
- **ルートでの一括適用 (`appConfigProvider`)**: 一方でアプリの最上位（`main.dart`）では、`appConfigProvider` を介してこれら個別の設定をまとめて受け取り、`MaterialApp.router` のテーマ、ロケール、文字サイズ倍率（`textScaler`）へ一括で反映しています。

---

## テスト

本機能は、あらゆる状態変化と UI 操作に対して 100% のテストカバレッジを実現しています。

- **Widget Test**:
  - ローディング・エラー状態の表示。
  - SegmentedButton によるテーマ・言語の切り替え。
  - スイッチによるダークモードの反転。
  - ログアウト処理の成功／失敗（SnackBar表示）のパス。
  - アカウント削除（退会）ボタンの未認証時非表示・認証時表示、2段階確認ダイアログ、事前再認証／`requires-recent-login` 事後再認証フォールバック、エラー表示、各ダイアログの操作検証（[settings_screen_test.dart](../test/src/features/settings/presentation/settings_screen_test.dart), [account_deletion_dialogs_test.dart](../test/src/features/settings/presentation/widgets/account_deletion_dialogs_test.dart), [reauthenticate_dialog_test.dart](../test/src/features/settings/presentation/widgets/reauthenticate_dialog_test.dart)）。
  - ビューポートサイズ固定によるスクロール操作の安定性。
- **Golden Test**:
  - `SettingsScreen`: 設定画面のライトモード/ダークモードでの表示確認（[settings_screen_golden_test.dart](../test/src/features/settings/presentation/settings_screen_golden_test.dart)）。
  - `AccountDeletionDialogs` / `ReauthenticateDialog`: 退会確認 Step 1・Step 2・処理中ダイアログ、および再認証モーダル（パスワードのみ・エラーバナー・Google のみ・両方連携タブ）のライト/ダークモード表示確認（[account_deletion_dialogs_golden_test.dart](../test/src/features/settings/presentation/widgets/account_deletion_dialogs_golden_test.dart), [reauthenticate_dialog_golden_test.dart](../test/src/features/settings/presentation/widgets/reauthenticate_dialog_golden_test.dart)）。
