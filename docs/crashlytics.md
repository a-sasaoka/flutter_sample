# Firebase Crashlytics（クラッシュレポート）

本プロジェクトでは **Firebase Crashlytics** を導入し、アプリの致命的なクラッシュ（Fatal Error）および非致命的な例外（Non-fatal Error）を自動収集し、品質改善に役立てる基盤を構築しています。

## 📁 関連ファイル構成

```plaintext
lib/main.dart                                           # アプリ全体のエラーハンドラーを登録
lib/src/core/network/firebase_crashlytics_provider.dart # インスタンスを提供するRiverpodプロバイダ
lib/src/features/home/presentation/home_screen.dart     # 動作確認用のクラッシュボタン配置
```

---

## 🛠 実装のポイント（Flutter / Dart側）

### 1. グローバルエラーハンドリング (`main.dart`)

アプリ起動時に、Flutterフレームワーク内で発生したエラーと、Dartの非同期処理などで発生した未処理例外の両方をキャッチし、Crashlyticsへ送信する設定を行っています。

- **`FlutterError.onError`**: Flutterフレームワークがキャッチしたエラー（UIの描画エラーなど）を送信します。
- **`PlatformDispatcher.instance.onError`**: どのゾーンでもキャッチされなかったDartの非同期例外（API通信の予期せぬ切断など）を送信します。

### 2. Riverpodによるインスタンス提供

`FirebaseCrashlytics.instance` を直接呼び出すのではなく、`firebaseCrashlyticsProvider` を経由して取得する設計にしています。
これにより、UIや各機能のRepositoryから手動で例外ログ（`recordError`）を送りたい場合でも、テスト時にモックへ差し替えることが可能です。

---

## ⚙️ ネイティブ側のセットアップ内容

クラッシュ時のスタックトレース（エラーの発生箇所）を人間が読める形式（シンボル化）に変換するため、iOS/Androidそれぞれのビルド設定を行っています。

- **🍎 iOS (`ios/Runner.xcodeproj`)**
  - Build Settings → Debug Information Format を **DWARF with dSYM File** に設定済みです。これにより、ビルド時にdSYMファイルが生成され、Crashlytics上で正確なコード行数が表示されます。
- **🤖 Android (`android/app/build.gradle.kts`)**
  - Crashlytics 用の Gradle プラグインを追加し、難読化されたコードを復元するためのシンボルアップロードを自動有効化しています。

---

## 🔥 動作確認方法（強制クラッシュテスト）

Crashlytics が正しく設定されているかを確認するためには、実際にアプリをクラッシュさせる必要があります。

1. アプリを起動し、HomeScreen（ホーム画面）を表示します。
2. 画面内に配置された **「クラッシュテスト（Throw Test Exception）」** ボタンを押します。
   （裏側で `FirebaseCrashlytics.instance.crash();` が呼ばれます）
3. アプリが強制終了（クラッシュ）します。
4. **アプリをもう一度起動します。**（※起動時に前回のクラッシュログがFirebaseへ送信される仕様です）
5. Firebase Console の Crashlytics ページを開き、クラッシュログが記録されていることを確認します（反映に数分かかる場合があります）。

この基盤により、開発中はもちろん、本番環境リリース後もユーザーの手元で起きているバグを迅速に検知・修正することが可能になります。

---
