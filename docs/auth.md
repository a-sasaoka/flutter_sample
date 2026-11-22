# トークン認証対応（Bearer Token + 自動リフレッシュ）

このプロジェクトでは、独自のバックエンドAPIとの通信を想定し、Bearerトークン認証と**トークンの自動付与・自動リフレッシュ処理**を実装しています。  
これにより、ログイン後のすべての通信で認証ヘッダーを自動的に付与し、有効期限切れ（401 Unauthorized）時にバックグラウンドで再取得を行います。

---

## 📁 ファイル構成（レイヤードアーキテクチャ）

トークン認証に関わるファイルは、責務ごとに適切なレイヤー（基盤層・機能層）に美しく分離されています。

```plaintext
lib/src/core/
 ├── exceptions/
 │    └── reauth_exception.dart                    # 再認証・退会フロー制御用の例外クラス (Freezed + sealed class)
 └── utils/
      └── jwt_utils.dart                           # JWTペイロードデコード（sub / emailクレーム抽出）
lib/src/app/constants/
 └── storage_keys.dart                             # customUserId等のセキュアストレージキー定義
lib/src/features/auth/
 ├── domain/
 │    └── account_deletion_precheck.dart           # 退会前の再認証要否・利用可能手段モデル (Freezed + sealed class)
 ├── application/
 │    ├── account_deletion_notice_notifier.dart    # 退会完了後の遷移先画面向けワンショット通知フラグ
 │    ├── auth_service.dart                        # 共通ログアウト・認証状態判定・ユーザーID提供・プロフィール更新・アカウント完全退会
 │    └── auth_state_notifier.dart                 # トークン認証状態の管理
 └── data/
      ├── token_storage.dart                       # トークンおよびユーザーIDの永続化（SecureStorage利用）
      ├── token_interceptor.dart                   # DioのInterceptor（トークン自動付与・排他リフレッシュ制御）
      ├── auth_session_lock.dart                   # 認証セッション読み書き・ユーザー照合の直列化ロック
      ├── auth_repository.dart                     # ログイン・トークンリフレッシュ・再認証・アカウント削除APIの呼び出し
      └── auth_overrides.dart                      # 認証系プロバイダーの動的切り替え・オーバーライド設定
```

---

## 🔑 JWTによるユーザー識別情報の暗号化保持と統合 (Issue #314)

独自認証（Custom Auth）において、バックエンドAPIのレスポンス形式（`access_token` と `refresh_token` のみ返却）を変更することなく、標準的なJWT仕様に基づいてログインユーザーIDを安全に抽出・保持する仕組みを備えています。

1. **JWTペイロードからの自動抽出**:
   [jwt_utils.dart](../lib/src/core/utils/jwt_utils.dart) の `extractUserIdFromJwt` により、外部パッケージに依存せず標準ライブラリ（`dart:convert`）のみで `access_token` のペイロード（第2パート）をBase64Urlデコードし、`sub`（Subject = ユーザー識別子）を安全に取り出します（不正な形式や数値型などの例外時も安全にガード）。
2. **ハードウェア暗号化保存**:
   [token_storage.dart](../lib/src/features/auth/data/token_storage.dart) の `saveTokens()` 内で、トークン保存と同時に [storage_keys.dart](../lib/src/app/constants/storage_keys.dart) の `SecureStorageKeys.customUserId` として端末の暗号化領域（`FlutterSecureStorage`）へ自動保存します。
3. **認証方式非依存の単一インターフェース**:
   [auth_service.dart](../lib/src/features/auth/application/auth_service.dart) において `customUserIdProvider` を新設し、統合プロバイダー `currentUserIdProvider` から「Firebase認証時（`User.uid`）」および「独自認証時（`customUserId`）」のいずれであっても、同一のインターフェースでログインユーザーIDを提供します。
4. **ライフサイクル連動**:
   サインアウト時（`tokenStorage.clear()`）にトークンと共に `customUserId` も物理削除され、アカウント切り替え時（`previousUserId != nextUserId`）には各機能の自律的データ破棄が確実に連動します。

---

## 🧩 循環参照を防ぐ Riverpod DI（高度な設計）

`TokenInterceptor` や `TokenStorage` は認証固有の機能であるため、基盤層（`core`）ではなく `features/auth/data/` に配置されています。
`core/network/dio_provider.dart` が `features/auth` を直接参照すると **レイヤーの逆参照** が発生してしまうため、以下の通り **依存関係の逆転（Dependency Inversion）** パターンを採用しています。

1. **基盤層（core）での定義**:
   [dio_provider.dart](../lib/src/core/network/dio_provider.dart) では、抽象的な `authInterceptorsProvider`（デフォルトは空リスト `[]`）を定義し、それを `dioProvider` が読み込みます。
2. **アプリ起動時（auth_overrides.dart）での注入**:
   [auth_overrides.dart](../lib/src/features/auth/data/auth_overrides.dart) の `getAuthOverrides()` 内で `authInterceptorsProvider` をオーバーライドし、`tokenInterceptorProvider` を動的に注入します。

この設計により、Core層が特定機能へ依存せず、完全な自己完結性と再利用性を保持する**極めて独立性の高いネットワーク基盤**を実現しています。

---

## 🧩 Dioへの組み込み順序（重要）

[dio_provider.dart](../lib/src/core/network/dio_provider.dart) において、Interceptor の登録順序は以下のように意図して制御されています。

1. **① tokenInterceptor (`additionalInterceptors`)**: リクエスト前に認証ヘッダーを追加し、401検知時にトークンをリフレッシュ（追加のインターセプターとして先頭に挿入）。
2. **② retryInterceptor**: 一時的な電波瞬断・タイムアウト・502/503/504検知時の指数バックオフ自動再送、およびPOST/PUT/PATCHへの `Idempotency-Key` 付与。
3. **③ dioInterceptor**: 共通の通信例外変換および簡易ログ出力。
4. **④ firebasePerformanceDioInterceptor**: Firebase Performance による通信時間・データサイズの自動計測。
5. **⑤ talkerDioLogger** (デバッグ時のみ): Talkerによる詳細な通信ログ出力。

> ⚠️ 順番を意図通りに保つことで、認証ヘッダーの付与、リトライ処理、ログ出力、パフォーマンス計測が正しい順序で透過的に実行されます。

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
  - `tokenStorageProvider` はオーバーライドされて Secure Storage で裏付けされた `TokenStorage` を返し、そこからアクセストークンを取得します。
  - `tokenRefreshCallbackProvider` はリフレッシュ開始時のユーザーIDを受け取り、`authRepository.refreshToken` を通じてセッション世代・ユーザーID・リフレッシュトークンが開始時と一致する場合のみ新トークンを保存します（[auth_session_lock.dart](../lib/src/features/auth/data/auth_session_lock.dart) によりログイン／ログアウトと直列化）。
- **Firebase Auth モード (`useFirebaseAuth: true`)**:
  - `tokenStorageProvider` を `FirebaseAuthTokenStorage` に差し替え、Firebase から直接 ID トークンを取得します。
  - `tokenRefreshCallbackProvider` は Firebase の `user.getIdToken(true)` を実行して強制的に更新します。

この切り替えは、`getAuthOverrides()`（`lib/src/features/auth/data/auth_overrides.dart`）で提供されるオーバーライド定義（`overrideWith`）内で `ref.watch(envConfigProvider)` を監視し、条件分岐によって返却するインスタンスや処理を動的に切り替えることで実現しています。  
これにより、Riverpodの仕様である「起動後に上書き設定（overrides）の数を動的に変更できない」という制約を回避し、クラッシュを防止しつつ安全に動作を切り替えています。
詳細な仕様は [Firebase Authenticationによる認証対応](firebase_authentication.md) を参照してください。

---

## 🔐 アプリロック機能（App Lock）との連携

本プロジェクトでは、認証状態（`AuthStateNotifier` または `FirebaseAuthStateNotifier`）と連動して **アプリロック機能 (`AppLockService`)** が動作します。

- **ログイン成功時**:
  - `ref.watch(authStateProvider)` の変更を検知し、パスコード未設定の場合は `PasscodeSetupScreen`（初期設定画面）へ自動誘導します。
  - パスコード登録済みの場合は、アプリ起動時およびフォアグラウンド復帰時に `PasscodeLockScreen`（ロック解除画面）を最前面にオーバーレイ描画します。
- **ログアウト時**:
  - `AuthService.signOut()` により認証セッションが終了し、認証状態が未ログインへ遷移すると、`AppLockService` がそれをリアクティブに検知して、暗号化保存されたパスコードおよび生体認証設定を自動的にクリアして `disabled` 状態へ遷移させます（Feature間の循環依存を排除した疎結合設計）。

詳細な仕様は [アプリロック機能 (App Lock)](app_lock.md) を参照してください。

---

## 🚪 共通ログアウト基盤（AuthService）と自律的データ破棄

本プロジェクトでは、画面側（設定画面など）が「現在 Firebase Auth を使っているか、自前のトークン認証を使っているか」を意識せずに安全にログアウトできるよう、`AuthService` を提供しています。

- **完全な依存性注入 (DI)**: `Ref` への直接依存を排除し、必要なロガー・設定・リポジトリ・Notifier をコンストラクタ引数として個別に受け取る設計になっており、単体テスト時のモック差し替えが容易です。実装詳細は [auth_service.dart](../lib/src/features/auth/application/auth_service.dart) を参照してください。
- **認証方式の隠蔽**: `EnvConfig.useFirebaseAuth` の値に応じて、Firebase のサインアウトまたはローカルトークンの破棄を適切に実行します。
- **統一されたログイン判定**: `isAuthenticatedProvider` および `currentUserIdProvider` により、UI や各機能は「何らかの方式でログイン中か」「誰がログインしているか」を1行で安全に監視・判定できます。
- **循環依存を排除した自律的データ破棄**: `AuthService` は他の各機能（キャッシュ、通知、ウィジェット等）を直接呼び出さず、純粋に認証セッションの終了のみを担当します。各機能が `auth_service.dart` の認証プロバイダー（`currentUserIdProvider` / `isAuthenticatedProvider`）をリアクティブに監視（`ref.listen`）し、ログアウトやアカウント切り替えを検知して**自律的に自身のデータ破棄や初期化を実行**します（Feature-Driven Architecture に従った疎結合設計）。

### 連携する各機能の自律破棄一覧

| 対象機能 | 監視クラス / プロバイダー | サインアウト・アカウント変更時の自律動作 | 参照ドキュメント |
| :--- | :--- | :--- | :--- |
| **アプリロック** | `AppLockService` | パスコードおよび生体認証設定を消去し、未設定（disabled）状態へ遷移 | [アプリロック仕様](app_lock.md) |
| **AIチャット** | `ChatNotifier` | メモリ上の会話メッセージ履歴および Vertex AI セッションを破棄 | [AIチャット仕様](chat.md) |
| **グラフ一時入力** | `ChartNotifier` | メモリ上に一時保持されたグラフ入力データと選択種別を初期化（`reset()`） | [グラフ仕様](chart.md) |
| **マップ現在地** | `MapNotifier` | プライバシー保護のため、取得済みの現在地状態を初期状態へ自律リセット（`reset()`） | [地図仕様](map.md) |
| **アクセス解析** | `analyticsServiceProvider` | `AnalyticsService.setUserId(null)` を呼び出し、アナリティクスのユーザー識別をクリア | [アクセス解析仕様](analytics.md) |
| **画像キャッシュ** | `imageCacheServiceProvider` | メモリキャッシュと端末ストレージ（ディスク）上の全キャッシュ画像を一括消去（`clearCache()`） | [パフォーマンス仕様](performance.md) |
| **ホーム画面ウィジェット** | `HomeWidgetSyncCoordinator` | OS共有ストレージ（App Groups等）のデータを空状態に更新し、ウィジェット再描画を要求 | [ウィジェット仕様](home_widget.md) |
| **プッシュ通知** | `NotificationNotifier` | FCMトークン破棄、端末通知全消去、状態リセットを実行。再ログイン時に新トークンを自動再取得 | [プッシュ通知仕様](notification.md) |
| **メモ機能** | `MemoNotifier` | 未ログイン時は空リストを返却し、ログイン時に当該ユーザー（`userId`）のメモのみをリアクティブに再読み込み | [メモ仕様](memos.md) |

### アカウント完全退会（4段階クリーンアップ＆再認証オーケストレーション） (Issue #324)

`AuthService`（[auth_service.dart](../lib/src/features/auth/application/auth_service.dart)）では、Firebase Auth とカスタム認証（`useFirebaseAuth: false`）のいずれにおいても統一されたフローでアカウント完全退会を実行できるよう、`checkReauthRequirement()`・`reauthenticateWithPassword()`・`reauthenticateWithGoogle()`・`deleteAccount()` を提供しています。

- **4段階の安全な実行順序**: 削除開始前に `targetUserId` とアバター URL 候補を退避した上で、**① Firebase Storage アバター削除**（[storage_service.dart](../lib/src/features/profile/data/storage_service.dart)、非 Storage URL や `object-not-found` は安全にスキップ）➔ **② サーバー DB 削除（`DELETE /users/me`）**（[profile_repository.dart](../lib/src/features/profile/data/profile_repository.dart)）➔ **③ Auth アカウント削除**（[firebase_auth_repository.dart](../lib/src/features/auth/data/firebase_auth_repository.dart) / [auth_repository.dart](../lib/src/features/auth/data/auth_repository.dart) ＋ [auth_state_notifier.dart](../lib/src/features/auth/application/auth_state_notifier.dart)）➔ **④ ローカル一括クリーンアップ** の順で実行します。
- **ローカル一括消去と端末設定の保持**: ④ではサインアウト連動の自律破棄に加え、該当ユーザーのメモ物理削除（[memos_dao.dart](../lib/src/features/memos/data/memos_dao.dart) / [memo_repository.dart](../lib/src/features/memos/data/memo_repository.dart)）、QR スキャン履歴全削除（[qr_scan_histories_dao.dart](../lib/src/features/qr_scanner/data/qr_scan_histories_dao.dart)）、ユーザー一覧キャッシュ削除（`CacheManager.clear('users')`）を実行し、端末設定（テーマ・文字サイズ・ロケール・オンボーディング完了状態）のみ保持します。
- **途中失敗時の補償と再認証フォールバック**: ①・②の段階で失敗した場合は③へ進まず中断し、システム例外を `talker.handle()` 経由で Crashlytics へ送信しつつリトライ可能エラーを表示します。③で `requires-recent-login` が返された場合もローカルデータ削除前のためデータを失わずに再認証フローへ復帰でき、③成功後の④で失敗した場合は Crashlytics へ記録しつつ強制的にサインアウト完了状態へ移行します。また、カスタム認証の `deleteAccount()` では、サーバーへの `DELETE /auth/account` 要求を送る**前**に [custom_auth_invalidation_store.dart](../lib/src/features/auth/data/custom_auth_invalidation_store.dart) を用いて専用 SQLite DB（`PRAGMA journal_mode = DELETE`・`PRAGMA synchronous = EXTRA`・`PRAGMA fullfsync = ON`）へ削除対象アカウント識別子付きでセッション無効化状態を永続化し、保存に失敗した場合は削除要求を送信せず中断します。API 待機中に同じアカウントの再ログインが完了した場合は無効化状態を解除せず削除完了時・再起動時の双方で消去を徹底し、別アカウントへ切り替わった場合のみ新セッションを保護します。さらに、[auth_session_lock.dart](../lib/src/features/auth/data/auth_session_lock.dart) でセッション世代・削除世代に加えて現在のセッション識別情報（ログイン中アカウントのユーザーID・メールアドレス／サインアウト済み状態）も直列化ロック内で追跡しており、削除前に開始した `login()` の応答が `deleteAccount()` 完了後に遅延到着した場合は、セッションロック内で世代不一致を検知してトークン保存を行わずに応答を破棄（`false` を返却）し、未ログイン状態と `/login` 画面を維持します（成功通知・Analytics 送信も行いません）。また、削除完了時にセッション世代が進んでいてトークンストレージからの現在セッション読み取りが失敗した場合でも、`talker.handle()` へ記録した上でロック内に追跡しているセッション識別情報へフォールバックすることで、同一アカウントの再ログイン（トークン消去・未ログイン遷移）と別アカウントへの切り替え（新セッション保護）やサインアウト済み状態を確実に見分けます。また、`AuthRepository.login()` と `AuthStateNotifier.login()` は共通の資格情報確定処理（`commitValidatedLoginCredentials`）を利用し、無効化 DB 確認（`clearIfAllowedForLogin`）の後に未確定ログイン状態（`markLoginPending`）を専用テーブルへ永続化してからトークン保存を行い、保存成功後にのみ未確定状態を解除（`clearLoginPending`）します。これにより、保存途中の失敗時に部分保存された資格情報をロールバック消去するだけでなく、ロールバック消去自体にも失敗してアクセストークンが残留した場合でも未確定状態を保持することで、次回起動時に `AuthStateNotifier.build()` が残留トークンによる誤復元を防いで再消去を試みます（未確定ログインテーブルは退会用の無効化テーブルと分離されているため、退会進行中の別アカウントレコードとは競合しません。また、退会処理進行中の別アカウントログイン時やログアウト時は進行中の退会レコードを削除せず保持し、複数アカウントで退会が並行開始された場合もアカウントごとに独立して無効化レコードを保持した上で、各退会処理の完了時に `clearInvalidatedIfMatches` で自身の対応レコードのみ解除します。もし完了前に再起動した場合も `AuthStateNotifier.build()` で現在セッションがどの無効化レコードにも一致しない場合のみ古いレコードを整理して別アカウントのトークンを維持します。あわせて [token_storage.dart](../lib/src/features/auth/data/token_storage.dart) の `saveTokens()` でも新トークンに `sub` がない場合は保存済み `customUserId` を削除し、古い ID 残留による誤照合を防ぎます）。サーバー削除成功後のトークン消去では、[token_storage.dart](../lib/src/features/auth/data/token_storage.dart) の `clear()` が3キー（`accessToken`・`refreshToken`・`customUserId`）すべての削除を試行し、消去や無効化解除に失敗しても `talker.handle()` へ記録した上で [auth_repository.dart](../lib/src/features/auth/data/auth_repository.dart) が削除対象セッションを終了すべきか（`bool`）を呼び出し元へ直接返却するため、[auth_state_notifier.dart](../lib/src/features/auth/application/auth_state_notifier.dart) や [auth_service.dart](../lib/src/features/auth/application/auth_service.dart) は無効化 DB の再読込に依存せず（別アカウントへ切り替わった場合のみ `false` を受けて新セッションや共有履歴・キャッシュ・完了通知を取り消さず保護しつつ）、未ログイン遷移と対象ユーザーのメモ削除を完了します（削除途中での終了時も含め、次回起動時は [auth_state_notifier.dart](../lib/src/features/auth/application/auth_state_notifier.dart) の `AuthStateNotifier.build()` が当該状態を確認して削除対象アカウントのログイン復元を防ぎ、残留トークンの再消去を試みます）。
- **カスタム認証（非Firebase）の再認証・退会 API**: [jwt_utils.dart](../lib/src/core/utils/jwt_utils.dart) の `getEmail()` でアクセストークンの `email` クレームを取得し、[auth_repository.dart](../lib/src/features/auth/data/auth_repository.dart) で `POST /auth/reauthenticate` および `DELETE /auth/account`（`TokenInterceptor` ループ回避のため認証用 `ApiClient` と明示的 Bearer ヘッダーを利用）を実行します。
- **型安全な再認証モデル・例外・完了通知**: 再認証要否と利用可能手段は [account_deletion_precheck.dart](../lib/src/features/auth/domain/account_deletion_precheck.dart)、フロー制御用エラーは [reauth_exception.dart](../lib/src/core/exceptions/reauth_exception.dart) で定義しています。また GoRouter リダイレクト時に `SnackBarNavigationObserver` が SnackBar を消去するのを防ぐため、[account_deletion_notice_notifier.dart](../lib/src/features/auth/application/account_deletion_notice_notifier.dart) のワンショット通知フラグを遷移後の [login_screen.dart](../lib/src/features/auth/presentation/login_screen.dart) / [firebase_login_screen.dart](../lib/src/features/auth/presentation/firebase_login_screen.dart) の `useEffect` ＋ `addPostFrameCallback` で消費して完了 SnackBar を表示します。

---

## 🖥️ ログイン画面と入力バリデーション

ログイン画面（[`LoginScreen`](../lib/src/features/auth/presentation/login_screen.dart)）では、誤入力や不正なリクエストを未然に防止するため、`Form` ＋ `TextFormField` による厳格な入力バリデーションを実装しています。

### 検証ルール

- **メールアドレス (`email`)**:
  - **空白のみ禁止**: `FormValidators.notOnlyWhitespace` により、空白文字のみの入力を防止。
  - **必須入力**: `FormBuilderValidators.required` により、未入力を防止。
  - **メール形式チェック**: `FormBuilderValidators.email` により、一般的なメールアドレス書式を検証。
- **パスワード (`password`)**:
  - **空白のみ禁止**: `FormValidators.notOnlyWhitespace` により、空白文字のみの入力を防止。
  - **必須入力**: `FormBuilderValidators.required` により、未入力を防止。
  - **最小文字数チェック**: `FormValidators.password(minLength: 6)` により、6文字以上の入力を要求。

共通バリデータの詳細仕様については、[共通ユーティリティ（FormValidators）](core_utilities.md#-8-共通フォームバリデータformvalidators) を参照してください。
