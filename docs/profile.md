# プロフィール登録・変更機能 (Profile)

アプリ内でユーザー本人のプロフィール情報（会員情報）を管理・更新する機能です。

## 🎯 仕様・要件

### 0. 入力フォームのレイアウトと初期値

- 各入力項目の `TextFormField` は、初期状態で空（`""`）の状態で表示されます。
- 各入力項目の上部に、現在保存されている設定値を `現在の設定: 〇〇`（未設定時は `現在の設定: 未設定`）の形式でテキスト表示します。
- バリデーションチェックは、各入力項目に入力を行っている最中にその項目単体の判定がリアルタイムで行われます（他の未入力の項目で不要なエラーが表示されるのを防ぐため、各 `TextFormField` に対して個別に `AutovalidateMode.onUserInteraction` を設定しています）。

### 1. 管理項目とバリデーション

- **氏名 (name)**:
  - 必須入力です（空白のみの入力も不可）。
  - 最大128文字までの制限があります。
- **メールアドレス (email)**:
  - 必須入力です。
  - 有効なメールアドレスの形式であるかチェックします。
  - 最大256文字までの制限があります。
- **表示名 (displayName)**:
  - 任意入力です。
  - 最大128文字までの制限があります。
- **電話番号 (phone)**:
  - 任意入力です。
  - **入力制限**: 半角数字以外の文字（ハイフンなど）は、入力・貼り付け（コピペ）時に完全にブロックされます。
  - **桁数バリデーション**:
    - 先頭が `090` / `080` / `070` / `050` の場合（携帯電話・IP電話）：**必ず11桁**
    - それ以外の場合（固定電話など）：**必ず10桁**

### 2. 保存と Firebase Auth 同期

- **自前サーバー (`useFirebaseAuth: false`)**:
  - API エンドポイント `/users/me` に対して `PUT` リクエストを送り、プロフィール情報を保存します。
- **Firebase Auth 連動 (`useFirebaseAuth: true`)**:
  - 自前サーバーの `/users/me` に保存したのち、Firebase Auth の現在のユーザー情報（表示名 `displayName`、メールアドレス `email`、アバター画像URL `photoUrl`）を更新し、`reload()` を実行して同期を完了させます。

### 3. アバター画像（プロフィール写真）設定・切り抜き・クラウド同期

- **画像選択とカメラ撮影**:
  - `image_picker` を用いて、端末のカメラでの撮影、またはフォトライブラリ（アルバム）からの画像選択が可能です。
- **円形切り抜き（トリミング）**:
  - `image_cropper` を連携させ、アバター画像に適した円形・正方形のトリミング画面（Android: UCropActivity / iOS: TOCropViewController）を起動します。
- **パーミッション（アクセス権限）チェック**:
  - `permission_handler` を用いて実行時にカメラや写真へのアクセス許可を確認します。
  - ユーザーがアクセスを拒否または「今後表示しない（Permanently Denied）」に設定している場合、設定アプリを開く案内ダイアログを表示し、スムーズに権限設定を促します。
- **保存タイミングとプレビュー**:
  - 画像を選択した時点ではローカルの一時ファイルとして保持し、画面上で即時プレビューします。
  - 画面下部の「保存」ボタンが押されたタイミングで、Firebase Storage へのアップロード（`/avatars/{userId}_{timestamp}.jpg`）とプロフィール情報の保存が一括で実行されます。
- **画像の削除（初期化）**:
  - ボトムシートから「現在の写真を削除」を選択して保存すると、Firebase Storage 上の画像ファイルが安全に削除され、プロフィール情報の `avatarUrl` が空文字にリセットされます。
- **端末内キャッシュ**:
  - 共通ウィジェット [`AppCachedImage.circle`](../lib/src/core/widgets/app_cached_image.dart) を使用し、ネットワークから読み込んだ画像はディスクおよびメモリに自動キャッシュされ、通信量と描画パフォーマンスを最適化します。
- **ローカルモック環境 (`useFirebaseAuth: false`) への配慮**:
  - Firebase を利用しない環境では外部 Storage との通信を自動スキップし、自前サーバーの更新のみを正常に行う安全設計となっています。

---

## 📁 関連ファイル構成

```plaintext
lib/src/features/profile/
 ├── domain/
 │    └── user_profile.dart                     # プロフィールのドメインモデル（avatarUrl を含む）
 ├── data/
 │    ├── profile_repository.dart               # 自前サーバー /users/me API の通信管理
 │    ├── image_picker_service.dart             # 画像選択・切り抜き・パーミッション制御
 │    └── storage_service.dart                  # Firebase Storage アップロード・削除管理
 ├── application/
 │    └── profile_notifier.dart                 # アバター保存・削除を含むビジネスロジック
 └── presentation/
      ├── profile_edit_screen.dart              # アバター表示・入力バリデーション・UI画面
      └── widgets/
           └── avatar_action_bottom_sheet.dart  # カメラ/アルバム/削除の選択ボトムシート
```

---

## 💡 技術的なポイント

- **カスタム `TextInputFormatter` による入力拒否**:
  `StrictDigitsTextInputFormatter` を自作し、文字が入力・ペーストされた瞬間に半角数字のみで構成されているかをチェックします。  
  もし1文字でもそれ以外の文字（ハイフン等）が含まれていれば、変更を無効化（入力前の状態を維持）します。これにより無効な入力を根本的にブロックします。
- **差分更新による最適化**:
  `FirebaseAuthRepository.updateAuthProfile` 内では、変更が検知された項目（現在の値と異なる場合）のみ Firebase Auth の `updateDisplayName` や `verifyBeforeUpdateEmail`、`updatePhotoURL` を呼び出すようにし、不要な通信負荷を低減させています。
- **外部依存の分離とテスタビリティ**:
  ネイティブ機能であるカメラ・アルバム（`image_picker`）、切り抜き（`image_cropper`）、権限（`permission_handler`）は `ImagePickerService`、Firebase Storage 操作は `StorageService` としてカプセル化されています。これにより、UI や Notifier の単体テスト時にモック（`mocktail`）へ容易に差し替え可能となり、テストカバレッジ 100% を達成しています。
- **同期処理と非同期処理の切り分け（FakeAsync対策）**:
  ウィジェットテスト環境下での FakeAsync デッドロックを回避するため、画像の一時ファイル生成には同期API（`Directory.systemTemp.createTempSync()`）を採用しています。
- **アプリロック（AppLock）とのシームレスな連携**:
  カメラ起動やアルバム選択、切り抜き画面などの OS 画面を開く間は、アプリが一時的にバックグラウンドと判定されます。`AppLockService.runWithLockSuppression` を通じて写真選択処理を実行することで、写真を選んでアプリに戻った瞬間に誤って画面ロックがかかるのを確実に防止しています。
