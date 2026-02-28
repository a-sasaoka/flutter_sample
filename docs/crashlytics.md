# Firebase Crashlytics（クラッシュレポート）

本プロジェクトでは **Firebase Crashlytics** を導入し、アプリのクラッシュを自動収集できるようにしています。

## ⭐ セットアップ内容

- `firebase_core` / `firebase_crashlytics` を追加
- `flutterfire configure` による iOS / Android アプリ登録
- `main.dart` で以下のハンドラーを登録
  - Flutter エラー送信
  - Dart の未処理例外送信
- iOS
  - Build Settings → Debug Information Format を **DWARF with dSYM File** に設定
- Android
  - `build.gradle.kts` に Crashlytics 用設定を追加
  - シンボルアップロードを自動有効化済み

## 🔥 動作確認方法

1. HomeScreen の「クラッシュテスト」ボタンを押す
2. アプリが強制終了する
3. アプリを再起動すると Crashlytics にログが送信される
4. Firebase Console → Crashlytics でクラッシュログを確認する

## 📂 関連ファイル（確認用）

- `lib/main.dart`
  - `Firebase.initializeApp` 後に Crashlytics ハンドラーを登録
- `lib/src/core/widgets/home_screen.dart`
  - テスト用クラッシュボタン（`FirebaseCrashlytics.instance.crash();`）
- `android/app/build.gradle.kts`
  - Crashlytics プラグインとシンボルアップロード設定
- `ios/Runner`
  - dSYM が生成されるよう Xcode の設定済み

Crashlytics を導入することで、アプリの安定性向上とバグ検知が容易になります。
