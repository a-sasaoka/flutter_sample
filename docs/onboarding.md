# オンボーディング機能 (Onboarding)

アプリを初めて起動したときに、アプリの特徴や使い方の紹介をスライドショー形式で見せる機能です。
このドキュメントでは、オンボーディング画面の仕組みや構造について、わかりやすく説明します。

---

## 💡 機能の概要

1. **初回起動時のスライド表示**:
   アプリの使い方の紹介（3枚のスライド）を見ることができます。右上の「スキップ」または最後の「はじめる」ボタンを押すと、オンボーディングが完了します。
2. **完了状態の記憶**:
   オンボーディングが完了したかどうかを、スマートフォンの中に記憶（永続化）します。次回起動したときは、このスライド画面は自動的にスキップされます。
3. **強制リダイレクト（自動案内）**:
   オンボーディングが終わっていないユーザーが他の画面を開こうとすると、自動的にオンボーディング画面に誘導（リダイレクト）します。

---

## 🛠️ 技術スタックとファイルの役割

オンボーディング機能は、以下のフォルダに分割して開発されています（Feature-Driven Architecture）。

### 1. UI（見た目）

- **[onboarding_screen.dart](../lib/src/features/onboarding/presentation/onboarding_screen.dart)**
  - `PageView.builder` を使って、横スクロールできるスライドショーを実現しています。
  - スライドの動きに合わせて動く「ドットインジケータ（今どのスライドを見ているかを示す目印）」も自作しています。
  - アセット画像は使わず、グラデーションの背景とマテリアルアイコンを使って、スッキリしたモダンなデザインに仕上げています。

### 2. 状態管理（データのやり取り）

- **[onboarding_notifier.dart](../lib/src/features/onboarding/application/onboarding_notifier.dart)**
  - スマートフォンの保存領域にアクセスできる `SharedPreferencesAsync` を使って、「オンボーディングが完了した（`onboarding_completed: true`）」というフラグを保存・管理します。
  - Riverpod の `@riverpod` アノテーションを使って自動生成される `onboardingProvider` を通じて、アプリ全体にオンボーディングの状態を提供します。

### 3. ルーティング（画面遷移のルール）

- **[onboarding_routes.dart](../lib/src/app/router/routes/onboarding_routes.dart)**
  - `GoRouter` を使って、オンボーディング画面を `/onboarding` というパスで登録しています。
- **[auth_guard.dart](../lib/src/app/router/auth_guard.dart) / [firebase_auth_guard.dart](../lib/src/app/router/firebase_auth_guard.dart)**
  - 画面遷移をする際の門番（ガード）の役割です。
  - スプラッシュ画面（起動中ロゴ画面）が終わった直後に `onboardingProvider` の値をチェックします。
  - まだオンボーディングが終わっていない場合は、ログイン画面やホーム画面ではなく、強制的にオンボーディング画面へジャンプさせます。

---

## 🧪 テスト方針

この機能は、品質を保つために 3 種類のテストがしっかりと書かれています（すべてカバレッジ100%を達成しています）。

1. **単体テスト ([onboarding_notifier_test.dart](../test/src/features/onboarding/application/onboarding_notifier_test.dart))**
   - 初期起動時にデータがない場合は「未完了 (false)」を返すこと。
   - すでに完了フラグがある場合は「完了 (true)」を返すこと。
   - 完了ボタンを押した際に正しくデータが保存されること。
   - これらを `package:checks` を使って検証しています。
2. **ウィジェットテスト ([onboarding_screen_test.dart](../test/src/features/onboarding/presentation/onboarding_screen_test.dart))**
   - スライドをめくったときにタイトルや文章が切り替わること。
   - ボタン表示が「次へ」から「はじめる」に変わること。
   - 「スキップ」や「はじめる」をタップすると完了処理が呼ばれること。
3. **ゴールデンテスト ([onboarding_screen_golden_test.dart](../test/src/features/onboarding/presentation/onboarding_screen_golden_test.dart))**
   - スマートフォンの見た目通りに正しく画面が描画されるかを、画像比較（Alchemist）を用いてビジュアルテストしています。
