# AIチャット機能 (Firebase AI Logic)

## 概要

本機能は、Googleの最新の生成AIモデル（Gemini）を活用し、アプリ内でユーザーと自然言語による対話を行うチャットアシスタント機能です。
バックエンドとして「Firebase AI Logic」を利用し、高速かつコンテキスト（会話履歴）を保持したストリーミング応答を実現しています。

## 技術スタック

- **AI SDK**: `firebase_ai` パッケージ（Firebase AI Logic）
- **モデル**: `gemini-2.5-flash` （高速・低コストな標準モデル）
- **状態管理**: Riverpod (`@riverpod`), Freezed
- **UI制御**: Flutter Hooks (`flutter_hooks`)
- **セキュリティ**: Firebase App Check

## ディレクトリ構成

本プロジェクトのフィーチャー駆動設計（Feature-Driven Architecture）に基づき、`lib/src/features/chat/` 配下に各層を配置しています。

```text
chat/
 ├── domain/
 │    └── chat_message.dart      # メッセージのドメインモデル (Sealed class)
 ├── data/
 │    └── chat_repository.dart   # Firebase AIとの通信を担うリポジトリ
 ├── application/
 │    └── chat_notifier.dart     # UI状態の管理とビジネスロジック (Notifier)
 └── presentation/
      └── chat_screen.dart       # チャット画面のUI

```

## 実装のコアコンセプトとポイント

### 1. Sealed Class による安全な状態モデリング (Domain)

チャットメッセージのモデル（`ChatMessage`）には Dart 3 の `sealed class` と Freezed の Union 型を採用しています。
フラグ（`bool isUser`, `bool isLoading` 等）による曖昧な状態管理を排除し、以下の4つの状態をコンパイラレベルで厳密に区別しています。

- `ChatMessage.user`: ユーザーの送信メッセージ
- `ChatMessage.ai`: AIの返答メッセージ
- `ChatMessage.loading`: AIの考え中（ストリーミング開始前）
- `ChatMessage.error`: 通信エラー等

### 2. ストリーミング API を用いたリアルタイム応答 (Data / Application)

ユーザーを待たせないUXを実現するため、AIからの返答は一括で受け取るのではなく、チャンク（断片）ごとに受け取るストリーミング方式を採用しています。

- **Repository**: `_chatSession.sendMessageStream()` を使用し、テキストのStreamを返却。
- **Notifier**: `await for` ループを用いてチャンクを受信するたびに State を更新し、文字がタイピングされるようなリアルタイムなUI描画を実現。

### 3. 会話履歴（コンテキスト）の保持とライフサイクル管理

AIが文脈を理解した対話を行えるよう、`ChatSession` クラスを利用しています。

- Repository の初期化時に `_model.startChat()` を呼び出し、セッションを確立。
- Riverpod の `autoDispose` の特性を考慮し、Notifier の `build` メソッド内で `ref.watch(chatRepositoryProvider)` を宣言。
  これにより、**「チャット画面を開いている間は会話の文脈（記憶）を保持し、画面を閉じると綺麗にリセットされる」** という実務的なライフサイクルを実現しています。

### 4. UI とエラーのローカライズ (Presentation)

- UI層（`ChatScreen`）では Dart 3 のパターンマッチング（`switch` 文）を使用し、`ChatMessage` の状態に応じた吹き出しやローディングUIを安全に出し分けています。
- Repository で発生した通信エラー等は Exception として投げ、最終的なエラーメッセージの多言語翻訳（日本語・英語）は、`BuildContext` を持つ UI 層の責任として実装しています。

## セキュリティ (Firebase App Check)

本機能のAPI呼び出しは、不正なクライアントからのアクセスを防ぐため **Firebase App Check** によって保護されています。

- **開発環境（デバッグ時）**: `main.dart` にて `AndroidDebugProvider` および `AppleDebugProvider` を有効化し、固定のデバッグトークン（UUID）を Firebase コンソールに登録することでアクセスを許可しています。
- **本番環境**: リリース時には Play Integrity (Android) および DeviceCheck/App Attest (iOS) を用いた強力な認証が適用されます（現在は「非適用(Unenforced)」モードで稼働中）。

---
