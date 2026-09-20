# QRコードリーダー機能 (QR Scanner Feature)

## 概要

本機能は、`mobile_scanner` を活用した高速・高精度なQRコード読み取り、写真アルバムからのQR画像解析、およびDrift (SQLite) によるスキャン履歴のローカル永続化機能を提供します。\
端末のカメラを用いたリアルタイムスキャンはもちろん、保存されている写真からの解析、URLリンクの直接ブラウザ起動、クリップボードへのコピー、履歴の閲覧・削除など、実用的な機能を網羅しています。

---

## 📁 ディレクトリ構成

```plaintext
qr_scanner/
 ├── domain/
 │    ├── qr_scanner_state.dart          # スキャン画面の状態定義 (Dart 3 sealed class + Freezed)
 │    └── qr_scan_history_model.dart     # スキャン履歴のドメインモデル (Freezed)
 ├── data/
 │    ├── qr_scan_histories_table.dart   # Drift (SQLite) テーブル定義 (QrScanHistories)
 │    └── qr_scan_histories_dao.dart     # 履歴のCRUD操作を行うDAO
 ├── application/
 │    ├── qr_scanner_controller.dart     # スキャナーのロジック・状態管理 (Notifier)
 │    ├── qr_scanner_history_controller.dart # 履歴一覧のストリーム監視 Notifier
 │    └── url_launcher_service.dart      # URL検証・外部ブラウザ起動サービス
 └── presentation/
      ├── qr_scanner_screen.dart         # QRコードスキャン画面（カメラプレビュー）
      ├── qr_scanner_history_screen.dart # スキャン履歴一覧画面（スワイプ削除・全削除）
      └── widgets/
           ├── qr_scanner_overlay.dart   # スキャン枠・暗転マスクを描画するCustomPaint
           └── qr_scan_result_sheet.dart # スキャン結果モーダルボトムシート
```

---

## 💡 実装のポイント

### 1. 状態管理（Dart 3 sealed class + Freezed）

スキャナーの動作状態を `QrScannerState` として sealed class で型安全に定義しています。

- **`QrScannerScanning`**: カメラによるリアルタイムスキャン受付中。
- **`QrScannerProcessingImage`**: 写真アルバムから選択した画像を解析中（多重タップやスキャンの割り込みを防止）。
- **`QrScannerPaused`**: 結果ボトムシート表示中や他画面への遷移中（カメラ解析を一時停止して省電力化＆二重読み取りを防止）。
- **ライト状態（`isTorchOn`）**: 各状態にライトの点灯フラグを持たせ、どの状態からでもトーチのON/OFFがスムーズに追従します。

### 2. 二重読み取り防止と触覚フィードバック

カメラがQRコードを検知した瞬間、即座に状態を `QrScannerPaused` に切り替えます。
さらに `HapticFeedback.lightImpact()` を実行してユーザーの手元へ「ブルッ」と心地よい振動を伝え、読み取り成功を直感的にフィードバックします。

### 3. アルバム画像からのQRコード解析

`image_picker` で写真ライブラリから画像を取得し、`MobileScannerController.analyzeImage(path)` を呼び出すことで、カメラを起動せず静止画内のQRコードを素早く抽出します。
画像内にQRコードが存在しない場合や無効なデータの場合は、自動的にスキャン状態へ復帰します。

### 4. モーダルボトムシート（結果表示）

スキャン成功時は、画面下部から `QrScanResultSheet` がスライドアップ表示されます。

- **URL自動判定**: `Uri.tryParse` により `http`/`https` スキームの有効なWeb URLであるかを判定。
- **URLを開く**: 有効なURLの場合は「URLを開く」ボタンが表示され、`url_launcher` を介して外部ブラウザで起動します。
- **クリップボードへコピー**: ボタン1タップで端末のクリップボードへコピーし、SnackBarで通知します。
- **再スキャン**: シートを閉じると自動的にカメラのスキャンが再開されます。

### 5. Drift (SQLite) による履歴のローカル永続化

読み取ったQRコードは、ローカルデータベース（`QrScanHistories` テーブル）に自動保存されます。

- **重複排除と日時更新**: 既に保存されているQRコードと同じ値を読み取った場合、レコードを重複作成せず、既存レコードの `scannedAt`（スキャン日時）を最新に更新してリストの最上部に移動させます。
- **リアルタイム監視**: DAOが提供する `watchAllHistories()` ストリームを `QrScannerHistoryController` が `ref.watch` することで、データの変更が即座にUIへリアクティブに反映されます。
- **個別削除**: `Dismissible` により、スワイプ1つで特定の履歴をサッと削除できます。
- **全件削除**: AppBarのゴミ箱アイコンから確認ダイアログを経て、一括削除が可能です。

### 6. カメラ権限エラー & シミュレーター環境の親切なハンドリング

エラーの種類（`MobileScannerErrorCode`）に応じて、適切な案内画面を表示します。

- **カメラ権限拒否時（`permissionDenied`）**:
  カメラアクセスが拒否されている場合、分かりやすいアイコン（`Icons.videocam_off`）と案内を表示し、「設定を開く」ボタンから端末の設定画面へ直接誘導します。
- **シミュレーター・カメラ未搭載時（`unsupported`）**:
  iOSシミュレーター等のカメラハードウェアが存在しない環境では、権限エラーと誤認させずに「カメラを利用できません」と案内を表示します。さらに「画像から読み取り」ボタンを表示することで、シミュレーター環境でもアルバムの写真からQRコードをスムーズに読み取って動作確認できます。

### 7. OS画面遷移時の誤ロック防止連携 (`runWithLockSuppression`)

写真アルバムの選択画面、外部ブラウザ、スマホの端末設定など、OSが提供する別画面を開く際はアプリが一瞬バックグラウンド扱いになります。\
アプリロック機能が有効な場合に誤ってロック画面が表示されてしまうのを防ぐため、以下の操作を `AppLockService.runWithLockSuppression` で保護しています。

- **アルバムからのQR画像選択** (`QrScannerController.pickAndScanImage`)
- **外部ブラウザでのURL起動** (`UrlLauncherService.openUrl`)
- **端末の設定画面オープン** (`QrScannerScreen` の「設定を開く」ボタン)

---

## 🧪 テスト仕様

本機能は、プロジェクト基準である「**package:checks の使用**」「**カバレッジ100%達成**」「**ゴールデンテスト完備**」を達成しています。

1. **単体・状態管理テスト**:
   - `QrScannerController`: スキャン、画像選択、一時停止/再開、ライト切替、DB保存失敗時のエラーハンドリング（Talker記録）など全分岐を検証。
   - `QrScanHistoriesDao`: 新規保存、重複時の日時更新、削除、全削除、ストリーム監視をインメモリSQLiteで検証。
   - `UrlLauncherService`: 有効なURLの起動、無効なURLの拒否、プラットフォーム例外時のエラーハンドリングをモックで検証。
2. **ウィジェットテスト**:
   - `QrScannerScreen`: AppBar、操作ボタン、スキャン枠、権限エラービュー、シミュレーター非対応ビュー（画像読み取り導線）、画面遷移を検証。
   - `QrScannerHistoryScreen`: 空状態表示、リスト表示、スワイプ個別削除、全削除ダイアログを検証。
   - `QrScanResultSheet`: URL・通常テキスト時のボタン切り替え、コピー、URL起動を検証。
   - `QrScannerOverlay`: CustomPaintの描画と、サイズ・色変更時の `shouldRepaint` を検証。
3. **ゴールデンテスト**:
   - `qr_scanner_screen_golden_test.dart`: 通常スキャン画面、カメラ権限エラー画面、カメラ非対応エラー画面（ライト/ダーク）
   - `qr_scanner_history_screen_golden_test.dart`: 履歴一覧画面（空状態、データあり、ライト/ダーク）
   - `qr_scan_result_sheet_golden_test.dart`: 結果シート（URL、通常テキスト、ライト/ダーク）
