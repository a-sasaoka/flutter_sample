# トークン認証対応（Bearer Token + 自動リフレッシュ）

このプロジェクトでは、独自のバックエンドAPIとの通信を想定し、Bearerトークン認証と**トークンの自動付与・自動リフレッシュ処理**を実装しています。
これにより、ログイン後のすべての通信で認証ヘッダーを自動的に付与し、有効期限切れ（401 Unauthorized）時にバックグラウンドで再取得を行います。

---

## 📁 ファイル構成（レイヤードアーキテクチャ）

トークン認証に関わるファイルは、責務ごとに適切なレイヤー（基盤層・機能層）に美しく分離されています。

```plaintext
lib/src/core/storage/
 └── token_storage.dart       # トークンの永続化（SharedPreferencesAsync利用）

lib/src/core/network/
 └── token_interceptor.dart   # DioのInterceptor（トークン自動付与・排他リフレッシュ制御）

lib/src/features/auth/data/
 └── auth_repository.dart     # ログイン処理・トークンリフレッシュAPIの呼び出し
```

---

## 🧩 循環参照を防ぐ Riverpod DI（高度な設計）

`TokenInterceptor`（基盤層: core）が、リフレッシュのために `AuthRepository`（機能層: features）を直接読み込むと、**レイヤーの逆参照（循環参照）** が発生してしまいます。

この問題を解決するため、本プロジェクトでは **コールバックプロバイダを用いた依存性の注入（DI）** を行っています。

1. **基盤層（core）での定義**:
   `tokenInterceptor` は、実体のない `tokenRefreshCallbackProvider`（関数）を監視します。
2. **アプリ起動時（main.dart）での注入**:
   `ProviderContainer` の初期化時に、機能層の `refreshToken` メソッドを基盤層に注入（override）します。

```dart
// main.dart での依存関係の注入例
tokenRefreshCallbackProvider.overrideWith(
  (ref) => ref.watch(authRepositoryProvider).refreshToken,
)
```

この設計により、Core層を他のプロジェクトにコピペして使い回すことができる**極めて独立性の高いネットワーク基盤**を実現しています。

---

## 🧩 Dioへの組み込み順序（重要）

`dio_provider.dart` にて、Interceptorの登録順序は以下の通りに設定されています👇

```dart
// ① トークン付与・リフレッシュ（追加のインターセプターとして先頭に挿入）
if (additionalInterceptors.isNotEmpty) {
  dio.interceptors.addAll(additionalInterceptors);
}
// ② ログ出力・エラーハンドリング（共通の例外処理）
dio.interceptors.add(ref.watch(dioInterceptorProvider));
```

### 💡 理由

| 順番               | 説明                                                    |
| ------------------ | ------------------------------------------------------- |
| ① tokenInterceptor | リクエスト前に認証ヘッダーを追加・401検知でリフレッシュ |
| ② dioInterceptor   | 通信全体のログ・例外処理を担当（最終層で処理）          |

> ⚠️ 順番を逆にすると、ログに出力されるリクエストにトークンが含まれなかったり、401エラー時の自動リフレッシュ（再リクエスト）が正常にログに記録されない・動作しないことがあります。

---

## ✅ 動作確認手順

1. 任意のログイン画面から、有効なユーザー情報でログイン処理を実行。
2. `TokenStorage` (FlutterSecureStorage) にアクセストークンとリフレッシュトークンが保存されることを確認。
3. 以降のAPI通信（例: ユーザー一覧取得など）で、`Authorization: Bearer <token>` ヘッダーが自動付与されることをログで確認。
4. トークンの有効期限が切れた状態でAPIを叩き、401エラーをフックして自動的にリフレッシュAPIが呼ばれ、元のリクエストが再試行されることを確認。

---

## 🔒 信頼性のための設計：排他リフレッシュ制御

本プロジェクトの `TokenInterceptor` は、**「排他リフレッシュ制御（ロック機構）」** を備えています。

### 解決している課題

通信環境が不安定な場合や、画面遷移時に複数の API リクエストが同時に 401 エラー（認証切れ）を受け取ることがあります。
対策がない場合、リクエストの数だけリフレッシュ API が呼ばれてしまい、サーバー負荷の増大や、古いリフレッシュトークンが無効化されることによる意図しないログアウトが発生します。

### 仕組み

- 最初に 401 エラーを検知したリクエストがリフレッシュ処理を開始し、その `Future` を保持します。
- その間に発生した他の 401 エラーは、新しいリフレッシュを行わず、**最初に開始された処理の完了を待ちます**。
- リフレッシュが成功すると、待機していたすべてのリクエストが一斉に新しいトークンで再試行されます。

この高度な制御により、並列通信が多い場面でもセッション維持の信頼性が極限まで高められています。

---

この構成により、UI層（画面側）のコードは一切トークンの存在を意識することなく、シンプルにAPIを呼び出すだけで安全な認証フローを実現できます。

---

## 🔄 Firebase Auth モードとの自動切り替え

本プロジェクトでは、環境設定（`EnvConfig`）の `useFirebaseAuth` フラグに基づいて、認証トークン方式を動的に切り替えます。

- **自前サーバー認証モード (`useFirebaseAuth: false`)**:
  - `tokenStorageProvider` は上書きされず、デフォルトのままで動作し、Secure Storage からアクセストークンを取得します。
  - `tokenRefreshCallbackProvider` は自前の `authRepository.refreshToken()` を実行します。
- **Firebase Auth モード (`useFirebaseAuth: true`)**:
  - `tokenStorageProvider` を `FirebaseAuthTokenStorage` に差し替え、Firebase から直接 ID トークンを取得します。
  - `tokenRefreshCallbackProvider` は Firebase の `user.getIdToken(true)` を実行して強制的に更新します。

この切り替えは、アプリのエントリーポイント（`main.dart`）の `ProviderContainer` のオーバーライド定義（`overrideWith`）内で `ref.watch(envConfigProvider)` を監視し、条件分岐によって返却するインスタンスや処理を動的に切り替えることで実現しています。
これにより、Riverpodの仕様である「起動後に上書き設定（overrides）の数を動的に変更できない」という制約を回避し、クラッシュを防止しつつ安全に動作を切り替えています。
詳細な仕様は [Firebase Authenticationによる認証対応](firebase_authentication.md) を参照してください。
