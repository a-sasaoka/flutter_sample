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
  - 自前サーバーの `/users/me` に保存したのち、Firebase Auth の現在のユーザー情報（表示名 `displayName` とメールアドレス `email`）を更新し、`reload()` を実行して同期を完了させます。

---

## 📁 関連ファイル構成

```plaintext
lib/src/features/profile/
 ├── domain/
 │    └── user_profile.dart           # プロフィールのドメインモデル
 ├── data/
 │    └── profile_repository.dart     # 自前サーバー /users/me API の通信管理
 ├── application/
 │    └── profile_notifier.dart       # 保存処理と Firebase Auth 同期のビジネスロジック
 └── presentation/
      └── profile_edit_screen.dart    # 入力バリデーションと UI 画面
```

---

## 💡 技術的なポイント

- **カスタム `TextInputFormatter` による入力拒否**:
  `StrictDigitsTextInputFormatter` を自作し、文字が入力・ペーストされた瞬間に半角数字のみで構成されているかをチェックします。もし1文字でもそれ以外の文字（ハイフン等）が含まれていれば、変更を無効化（入力前の状態を維持）します。これにより無効な入力を根本的にブロックします。
- **差分更新による最適化**:
  `FirebaseAuthRepository.updateAuthProfile` 内では、変更が検知された項目（現在の値と異なる場合）のみ Firebase Auth の `updateDisplayName` や `verifyBeforeUpdateEmail` を呼び出すようにし、不要な通信負荷を低減させています。
