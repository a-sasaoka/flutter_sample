# 法的情報・Markdown閲覧機能 (Legal Document Feature)

## 概要

本機能は、アプリ内で「利用規約」や「プライバシーポリシー」などの法的文書をMarkdown形式で型安全かつ快適に閲覧できるようにする機能です。
外部サーバーと通信することなく、アプリバンドル内のMarkdownアセットを読み込んでレンダリングするため、オフライン環境や初回起動時・未ログイン状態でも高速に表示できます。

---

## 主な特徴

- **型安全なアセット管理**: `flutter_gen` により生成された `Assets.markdown` を使用し、ファイルパスの文字列直書きによるタイポやリンク切れを防止。
- **誰でもアクセス可能（Public Route）**: 未ログインユーザーでも会員登録前や設定画面から閲覧できるよう、認証ガード（`authGuard` / `firebaseAuthGuard`）の `alwaysPublicPaths` に登録。
- **安全な外部リンク連携**: Markdown内のWebリンク（URL）をタップした際、`UrlLauncherService`（アプリ誤ロック防止のロック抑止機構付き）を通じて外部ブラウザで起動。
- **堅牢な状態管理とUI**: Riverpodの非同期プロバイダーによるキャッシュ、ローディングインジケータ、エラーハンドリング（再試行ボタン）を完備。

---

## アーキテクチャと実装詳細

Feature-Driven Architecture に従い、`lib/src/features/legal` 配下に集約されています。

```plaintext
lib/src/features/legal/
 ├── domain/
 │    └── legal_document_type.dart     # ドキュメント種別定義（利用規約 / プライバシーポリシー）
 ├── application/
 │    ├── legal_document_provider.dart # AssetBundleを用いたMarkdownテキスト取得プロバイダー
 │    └── legal_document_provider.g.dart
 └── presentation/
      └── legal_document_screen.dart   # Markdown表示・リンクタップ・エラー対応画面
```

### 1. ドメイン層 (`legal_document_type.dart`)

`LegalDocumentType` は `enum` で定義され、各ドキュメント種別に対応するアセットパスを保持します。

```dart
enum LegalDocumentType {
  termsOfService,
  privacyPolicy;

  String get assetPath {
    return switch (this) {
      LegalDocumentType.termsOfService => Assets.markdown.termsOfService,
      LegalDocumentType.privacyPolicy => Assets.markdown.privacyPolicy,
    };
  }
}
```

### 2. アプリケーション層 (`legal_document_provider.dart`)

- **`assetBundleProvider`**: テスト時に `AssetBundle` をモックに差し替え可能にする関数プロバイダ。
- **`legalDocumentProvider`**: `LegalDocumentType` をキーとして、対応するアセットファイルを非同期で読み込みます。

### 3. プレゼンテーション層 (`legal_document_screen.dart`)

- `flutter_markdown_plus` の `Markdown` ウィジェットを採用。
- `selectable: true` によりユーザーによるテキスト選択・コピーが可能。
- `onTapLink` コールバックで `urlLauncherServiceProvider` を呼び出し、安全にURLを起動します。

---

## 画面遷移とルーティング

GoRouter（`go_router_builder`）による型安全なルートとして定義されています。

| 画面名 | パス | ルートクラス | 遷移コード例 |
| :--- | :--- | :--- | :--- |
| 利用規約 | `/terms` | `TermsRoute` | `const TermsRoute().push(context);` |
| プライバシーポリシー | `/privacy` | `PrivacyPolicyRoute` | `const PrivacyPolicyRoute().push(context);` |

※ 設定画面などから遷移する際は、戻るボタンで元の画面へ復帰できるよう `.push(context)` を推奨しています。

---

## 規約文の更新手順

1. `assets/markdown/terms_of_service.md` または `assets/markdown/privacy_policy.md` を編集します。
2. 新しいファイルを追加した場合は、`fvm flutter pub run build_runner build` を実行して `Assets.markdown` を更新します。

---

## テスト方針

- **単体テスト (`legal_document_provider_test.dart`)**:
  - `MockAssetBundle` を用いて、各ドキュメントが正常に読み込まれること、例外時に `AsyncError` となることを検証（`package:checks` 使用）。
- **Widgetテスト (`legal_document_screen_test.dart`)**:
  - タイトル・Markdown本文の表示、ローディング中インジケータ、エラー時の再試行ボタン押下によるリフレッシュ、リンクタップ時の外部ブラウザ連携およびエラー時SnackBarの表示を網羅。
- **ゴールデンテスト (`legal_document_screen_golden_test.dart`)**:
  - 利用規約およびプライバシーポリシーのLightモード／Darkモードの描画結果を記録・検証。
