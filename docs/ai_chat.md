# AIチャット機能 (Firebase AI Logic)

## 概要

本機能は、Googleの最新の生成AIモデル（Gemini）を活用し、アプリ内でユーザーと自然言語による対話を行うチャットアシスタント機能です。
バックエンドとして「Firebase AI Logic」を利用し、高速かつコンテキスト（会話履歴）を保持したストリーミング応答を実現しています。

## 技術スタック

- **AI SDK**: `firebase_ai` パッケージ（Firebase AI Logic）
- **モデル**: 公開設定ファイル (`config/flavor_*.json`) に定義された `AI_MODEL` （例: `gemini-2.5-flash`）を `envConfigProvider` で読み込み
- **状態管理**: Riverpod (`@riverpod`), Freezed
- **UI制御**: Flutter Hooks (`flutter_hooks`)
- **セキュリティ**: Firebase App Check

## 📁 ディレクトリ構成

本プロジェクトのフィーチャー駆動設計（Feature-Driven Architecture）に基づき、`lib/src/features/chat/` 配下に各層を配置し、さらにデータ層では**インターフェースの分離**を行っています。

```plaintext
chat/
 ├── domain/
 │    └── chat_message.dart         # メッセージのドメインモデル (Sealed class)
 ├── data/
 │    ├── chat_api_client.dart      # AI通信のインターフェース定義（抽象）
 │    ├── gemini_api_client.dart    # Firebase AI Logic を用いた実処理
 │    ├── chat_repository.dart      # クライアントを利用し、エラーハンドリング等をラップする層
 │    └── chat_provider.dart        # 各クラスの依存関係を解決するProvider定義
 ├── application/
 │    └── chat_notifier.dart        # UI状態の管理とストリーミング処理 (Notifier)
 └── presentation/
      ├── chat_bubble_shimmer.dart  # チャットの返答待ち骨組み（Shimmer）表示
      └── chat_screen.dart          # チャット画面のUI
```

## 💡 実装のコアコンセプトとポイント

### 1. インターフェース分離と強力なテスト容易性 (Data層)

FirebaseのSDKに直接依存するのではなく、`ChatApiClient` というインターフェースを定義し、実装（`GeminiApiClient`）をRiverpodのDIで注入しています。
これにより、テスト時にはモックのクライアントに差し替えるだけで、実際にAPI通信を発生させることなく、ストリーミングのUI描画やエラー処理のテストが100%安全かつ高速に行えます。

### 2. Sealed Class による安全な状態モデリング (Domain層)

チャットメッセージのモデル（`ChatMessage`）には Dart 3 の `sealed class` と Freezed の Union 型を採用しています。
フラグ（`bool isUser`, `bool isLoading` 等）による曖昧な状態管理を排除し、以下の4つの状態をコンパイラレベルで厳密に区別しています。

- `ChatMessage.user`: ユーザーの送信メッセージ
- `ChatMessage.ai`: AIの返答メッセージ
- `ChatMessage.loading`: AIの考え中（ストリーミング開始前）
- `ChatMessage.error`: 通信エラー等

### 3. ストリーミング API を用いたリアルタイム応答 (Application層)

ユーザーを待たせないUXを実現するため、AIからの返答は一括で受け取るのではなく、チャンク（断片）ごとに受け取るストリーミング方式を採用しています。

- **Repository**: クライアントから受け取ったテキストの Stream を返却。
- **Notifier**: `await for` ループを用いてチャンクを受信するたびに State を更新し、文字がタイピングされるようなリアルタイムなUI描画を実現。

### 4. 会話履歴（コンテキスト）の保持と永続性

AIが文脈を理解した対話を行えるよう、クライアント内で `ChatSession` クラスを利用しています。
本プロジェクトでは `keepAlive: true` を設定した `ChatRepository` および `ChatNotifier` により、**「画面を閉じたりホームに戻ったりしても、会話の履歴をアプリ内で保持し続ける」** という、モダンなチャットアプリの挙動を実現しています。

- **明示的なリセット**: ユーザーが会話を新しくやり直したい場合は、画面上部の「履歴をすべて削除」ボタンからいつでもコンテキストをリセットできます。

### 5. UI とエラーのローカライズ (Presentation層)

- **テーマ連動**: メッセージの吹き出し（Bubble）は、アプリ全体の `ColorScheme` に完全に連動します。ユーザーは `primaryContainer`、AI は `surfaceContainerHighest` を使用し、視覚的な一貫性を保っています。
- **リッチな表現**: AI からの返答には `flutter_markdown_plus` を採用し、コードブロックや強調表示などを美しくレンダリングします。
- **オフライン制御**: デバイスがオフラインの際、送信ボタンを自動的に非活性化（タップ不可・グレーアウト）し、無効なリクエストを防止します。テキスト入力自体は継続可能とし、オンライン復帰後にスムーズに送信できるUXに配慮しています。
- **エラーハンドリング**: 通信エラー発生時は `errorContainer` の配色でメッセージを表示し、エラー内容の多言語翻訳は、`BuildContext` を持つ UI 層で行うという責務の分離を徹底しています。

## 🛡️ セキュリティ (Firebase App Check)

本機能のAPI呼び出しは、不正なクライアントからのアクセスを防ぐため **Firebase App Check** によって保護されています。

- **開発環境（デバッグ時）**: `main.dart` にて `AndroidDebugProvider` および `AppleDebugProvider` を有効化し、秘匿情報として管理されているデバッグトークン（`.env` の `DEBUG_TOKEN`）から注入して通信を許可しています。
- **本番環境**: リリース時には Play Integrity (Android) や DeviceCheck (iOS) を用いた強力な端末認証が適用されます。

---
