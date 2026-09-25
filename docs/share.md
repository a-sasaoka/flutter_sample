# SNSシェア機能 (SNS Share Feature)

## 概要

本機能は、`share_plus` を活用したOS標準のシェアシート（共有ダイアログ）の呼び出し、および特定のSNS（X / LINE）への直接共有リンク機能を提供します。\
テキストやURLの共有はもちろん、アルバムからの画像選択やテスト用サンプル画像の動的生成・添付共有、iPadでのクラッシュ防止（ポップオーバー座標指定）、OS標準ダイアログ表示時の一時的なアプリロック誤作動防止連携など、実用的なアプリ運用に必要な要件を網羅しています。

---

## 📁 ディレクトリ構成

```plaintext
lib/src/features/share/
 ├── domain/
 │    └── share_config.dart                  # SNS共有URLスキーマや定数（ハッシュタグ・デフォルト座標）
 ├── application/
 │    ├── share_position_origin_extension.dart # iPad向け吹き出し座標（Rect）算出拡張
 │    └── share_service.dart                 # シェア実行、アプリロック抑止、画像生成、Talkerロギング
 └── presentation/
      └── share_demo_screen.dart             # SNSシェアデモ画面（テキスト・画像・特定SNS共有）
```

---

## 💡 実装のポイント

### 1. iPadクラッシュ対策（`sharePositionOrigin`）

iPad（iPadOS）では、共有ダイアログが画面中央ではなくタップしたボタンを起点とする「吹き出し（ポップオーバー）」として表示されます。\
アンカーとなる座標（`sharePositionOrigin`）が指定されていないとアプリがクラッシュするため、BuildContext拡張 `context.sharePositionOrigin` を用意し、タップされたボタンの位置と大きさを正確に取得して安全に渡す設計にしています。

### 2. アプリロックの誤作動防止（`runWithLockSuppression`）

本アプリには一定時間のバックグラウンド移行で生体認証・パスコードロックをかける機能があります。\
OS標準のシェアシートを開くと、OSの仕様によりアプリが一瞬非アクティブ（バックグラウンド扱い）となり、共有完了後に誤ってロック画面が表示されてしまう問題があります。\
これを防ぐため、`AppLockService.runWithLockSuppression` を活用し、シェア実行中は一時的にロック判定をスキップするように連携しています。

### 3. テキスト・URL・画像の共有（`share_plus` 13.x 準拠）

最新の `share_plus` 仕様に準拠し、引数には `ShareParams`（テキスト・画像・件名・ポップオーバー座標）を構造化して渡しています。

- **テキスト・URL共有**: メールや各種チャットアプリへテキストとリンクを送信。
- **画像共有**: `image_picker` によるアルバムからの写真選択、または `PictureRecorder` と `Canvas` を用いて動的生成したサンプル画像を即座に共有可能。

### 4. 特定SNS（X・LINE）への直接共有

OS標準シェアシートだけでなく、ワンタップで指定SNSの投稿画面を開くURLスキーム起動を実装しています。

- **X (旧Twitter)**: Web Intent (`https://twitter.com/intent/tweet`) を利用し、本文・URL・ハッシュタグ（`#Flutter` など）を事前入力して投稿画面を起動。
- **LINE**: `https://line.me/R/msg/text/` スキームを利用し、テキストとURLを送信先選択画面に引き渡し。
- `url_launcher` による外部ブラウザ・アプリ起動と、起動成否のSnackBar通知（失敗時のフォールバック）を完備。

### 5. ダークテーマ時の視認性最適化

Xのブランドカラーであるブラックは、ダークテーマ時のカード背景（ダークグレー）と同化して視認性が低下します。\
そのため、`Theme.of(context).brightness` に応じてダークモード時は白背景・黒文字へ自動反転させ、視認性と美しさを両立させています。

---

## 🧪 テスト方針

- **依存のモック化**: `SharePlatform` および `ImagePickerPlatform` を `mocktail` でモック化し、実機・OS依存のない環境で動作検証を実施。
- **GPUハング回避**: `Picture.toImage` を行う画像生成ロジックを `ShareService` に分離し、UIテストでは瞬時にダミー `XFile` を返却させることで、テスト実行の高速化（1秒未満）とハングアップ防止を実現。
- **網羅的なテストカバレッジ**:
  - `share_position_origin_extension_test.dart`: 座標算出ロジックの検証
  - `share_service_test.dart`: 各共有メソッド、成否判定、画像生成の単体テスト
  - `share_demo_screen_test.dart`: UI入力、ボタン操作、SnackBar表示、エラーハンドリングの検証（**カバレッジ100%**）
  - `share_demo_screen_golden_test.dart`: ライト/ダークモードのゴールデンテスト

---

## 🔗 関連ドキュメント

- [ルーティング設計 (routing.md)](routing.md)
- [ホーム画面と開発者ツール (home.md)](home.md)
- [アプリロック機能 (app_lock.md)](app_lock.md)
- [ゴールデンテスト仕様 (golden_test_details.md)](golden_test_details.md)
