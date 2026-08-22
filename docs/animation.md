# リッチアニメーションとアセット管理 (Lottie & flutter_gen)

本ドキュメントでは、ベクターアニメーションライブラリ **Lottie** と、画像やアニメーションなどのアセットファイルを型安全（プログラムのエラーを事前に防ぐ仕組み）に管理する **flutter_gen** の導入・設計・活用方法について解説します。

---

## 🎯 導入の目的とメリット

1. **リッチで軽量なアニメーション表現 (Lottie)**:
   - GIFや動画と異なり、ベクターデータ（JSON形式のパス情報）を描画するため、ファイルサイズが非常に小さく、高解像度端末でも境界線がぼやけず滑らかに再生されます。
   - 再生、一時停止、逆再生、特定フレームへのシーク（進行度指定）、ループ再生などの細かいアニメーション制御が可能です。
2. **文字列指定をゼロにする型安全なアセット管理 (flutter_gen)**:
   - 通常の Flutter アセット読み込み（`'assets/animations/loading.json'` のような文字列の直接入力）は、ファイル名やパスの typo（打ち間違い）があっても実行時までエラーに気付けません。
   - `flutter_gen` を導入することで、コード生成されたクラス（`Assets.animations.onboardingMemo` など）を通じて静的型チェックが効くようになり、IDEの自動補完やコンパイル時エラー検出が可能になります。

---

## 🛠️ 技術スタックとアーキテクチャ

| パッケージ                                                            | 役割                                                                                                                                                                   |
| :-------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[lottie](https://pub.dev/packages/lottie)**                         | Airbnb社が開発した Lottie アニメーション（JSONファイル）を Flutter 上で描画・制御するライブラリ                                                                        |
| **[flutter_gen_runner](https://pub.dev/packages/flutter_gen_runner)** | `pubspec.yaml` のアセット定義を解析し、Dart の型安全なアセットクラス（`Assets.*`）を自動生成するツール                                                                 |
| **[flutter_hooks](https://pub.dev/packages/flutter_hooks)**           | `useAnimationController` を用いて、StatefulWidget の冗長なボイラープレート（`TickerProviderStateMixin` や `dispose()` 管理）を不要にし、アニメーション状態を簡潔に管理 |

---

## 📁 ディレクトリ構成とファイル配置

```plaintext
assets/
└── animations/                                  # Lottie アニメーションJSONファイル
    ├── onboarding_memo.json                     # オンボーディング1（メモ管理）
    ├── onboarding_sync.json                     # オンボーディング2（クラウド同期）
    ├── onboarding_chat.json                     # オンボーディング3（AIチャット）
    ├── empty_box.json                           # 空データ状態（Empty State）
    ├── not_found_404.json                       # 404 画面
    └── success_check.json                       # 処理成功チェックマーク

lib/
├── gen/
│   └── assets.gen.dart                          # flutter_gen が自動生成したアセットコード
└── src/
    ├── core/widgets/
    │   ├── app_lottie_widget.dart               # Lottie描画用の汎用共通コンポーネント
    │   ├── empty_state_widget.dart              # 空データ・エラー状態表示用の共通UI部品
    │   └── not_found_screen.dart                # 404画面（Lottieアニメーション適用）
    └── features/
        ├── onboarding/presentation/
        │   └── onboarding_screen.dart           # オンボーディング画面（Lottieアニメーション適用）
        └── dev_tools/presentation/
            └── lottie_demo_screen.dart          # Lottie再生・制御の開発者向けデモ画面
```

---

## 🧩 共通コンポーネントの使い方

### 1. `AppLottieWidget` (汎用Lottieウィジェット)

プロジェクト全体で Lottie を安全かつ統一的に表示するための基本コンポーネントです。

#### ローカルアセットの表示 (`AppLottieWidget.asset`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';

class MyAnimationCard extends StatelessWidget {
  const MyAnimationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLottieWidget.asset(
      // flutter_gen で生成されたアセットオブジェクトを指定
      lottie: Assets.animations.onboardingMemo,
      width: 200,
      height: 200,
      repeat: true,       // ループ再生するか
      animate: true,      // 自動再生するか（テスト時は false に指定可能）
      fit: BoxFit.contain,
    );
  }
}
```

#### ネットワークURLからの表示 (`AppLottieWidget.network`)

```dart
AppLottieWidget.network(
  url: 'https://assets5.lottiefiles.com/packages/lf20_example.json',
  width: 150,
  height: 150,
)
```

---

### 2. `EmptyStateWidget` (空状態・エラー状態表示)

データが0件の時や通信エラー時に、ユーザーにわかりやすく状態を伝える共通Widgetです。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/widgets/empty_state_widget.dart';

class MemoListEmptyView extends StatelessWidget {
  const MemoListEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      // Lottie アニメーションを指定（未指定時はデフォルトで Assets.animations.emptyBox が使用されます）
      lottie: Assets.animations.emptyBox,
      title: 'メモがまだありません',
      description: '右下の「＋」ボタンから新しいメモを作成してみましょう。',
      actionLabel: 'メモを作成',
      onAction: () {
        // ボタンタップ時の処理
      },
    );
  }
}
```

---

## 🎮 開発者デモ画面 (LottieDemoScreen)

開発者がアニメーションの動作や制御を実際に手元で確認できるよう、デモ画面を用意しています。

- **画面パス**: `/dev-tools/lottie`（ホーム画面の開発者メニュー「Lottie アニメーションデモ」から遷移可能）
- **利用可能な機能**:
  - **再生コントロール**: 再生（Play）、一時停止（Pause）、逆再生（Reverse）、停止/巻き戻し（Reset）
  - **進捗シークバー**: アニメーションの進行状況（0%〜100%）をスライダーで自由に変更
  - **ループ切り替え**: 単発再生とループ再生のスイッチ切り替え（単発再生完了時はSnackBarでお知らせ）
  - **アセット切り替え**: プロジェクト内の全 Lottie アセットを Chip 選択で即座にプレビュー
  - **ネットワーク読み込み**: Web上の Lottie JSON URL からの非同期読み込みデモ

---

## 🏗️ アセット追加とコード生成手順

新しいアニメーション JSON ファイルを追加した際は、以下の手順でアセットコードを再生成します。

### 1. JSON ファイルの配置

`assets/animations/` ディレクトリに `.json` ファイルを配置します（例: `assets/animations/my_anim.json`）。

### 2. コード生成の実行

本プロジェクトでは `flutter_gen_runner` が `build_runner` に統合されているため、他のジェネレーター（Riverpod, Freezed, GoRouter, Envied）と合わせて **1つのコマンド** で一括生成します。

```bash
# 基本の一括生成コマンド（作業対象の Flavor に応じた .env.{flavor} を指定）
# 例: ローカル開発環境 (.env.local) の場合
fvm dart run build_runner build --define "envied_generator:envied=path=.env.local"

# 例: dev環境 (.env.dev) の場合
fvm dart run build_runner build --define "envied_generator:envied=path=.env.dev"
```

> [!NOTE]
> アセットコード（`Assets.animations.*`）自体の生成結果は全環境共通ですが、本プロジェクトでは Envied による環境別シークレット生成を同時に行うため、作業中の環境に合わせた `.env.{flavor}` を指定します。詳細は [コード生成と環境切り替え](code_generation.md) を参照してください。

これにより、`lib/gen/assets.gen.dart` に `Assets.animations.myAnim` が自動で追加され、型安全に呼び出せるようになります。

---

## 🧪 テスト時の注意点とベストプラクティス

### ⚠️ Lottie アニメーションとテスト時のタイムアウト問題

ウィジェットテストやゴールデンテストにおいて、Lottie アニメーションが無限ループ（自動再生）している状態で `await tester.pumpAndSettle()` を呼び出すと、**フレームの描画更新が永遠に終わらないため、30秒でテストがタイムアウトして失敗**します。

### ✅ 解決策

1. **`animate: false` を渡す（推奨）**:
   各Widget（`AppLottieWidget`, `OnboardingScreen`, `NotFoundScreen`, `LottieDemoScreen`）には `bool animate` パラメータが用意されています。テスト時は `animate: false` を渡すことで静止画として1フレームのみを描画させ、安全に `pumpAndSettle()` を通過させます。
2. **`tester.pump()` を使用する**:
   アニメーションの進行をテストしたい場合は、`pumpAndSettle()` ではなく `await tester.pump(const Duration(milliseconds: 500));` のように明示的に時間を進める `pump` メソッドを使用します。

---

## ❓ トラブルシューティング

| 現象                                           | 原因                                                   | 解決策                                                                                                      |
| :--------------------------------------------- | :----------------------------------------------------- | :---------------------------------------------------------------------------------------------------------- |
| `Assets.animations.*` が見つからない           | `build_runner` によるコード生成が行われていない        | `fvm dart run build_runner build --define "envied_generator:envied=path=.env.local"` を実行してください。   |
| アニメーションが表示されず灰色のアイコンが出る | JSON ファイルのパス間違い、またはパースエラー          | `assets/animations/` のファイル名と `pubspec.yaml` の `assets:` セクションの記述を確認してください。        |
| ゴールデンテストで文字化け（豆腐）が発生する   | `ChipThemeData` 等のスタイルにフォント設定が欠けている | `test/golden_test_helper.dart` で `NotoSansJP` フォントがテーマ全体に適用されていることを確認してください。 |
