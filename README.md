# Flutter Sample Project

Flutter開発のベストプラクティスをまとめたサンプルプロジェクトです。  
初学者から中級者まで、実践的なアプリ構成や開発環境の整備方法を学ぶことができます。

---

## 🚀 プロジェクト概要

このプロジェクトは、Flutterを用いたアプリ開発で役立つ構成・設定を体系的にまとめたテンプレートです。  
特に以下の技術スタックを採用し、実務でも通用する設計を意識しています。

### 🧠 採用技術

| 分類 | 使用技術 |
|------|-----------|
| 状態管理 | [Riverpod](https://riverpod.dev) + [Flutter Hooks](https://pub.dev/packages/flutter_hooks) |
| ルーティング | [GoRouter](https://pub.dev/packages/go_router) + [go_router_builder](https://pub.dev/packages/go_router_builder) |
| 通信 | [Dio](https://pub.dev/packages/dio) + [pretty_dio_logger](https://pub.dev/packages/pretty_dio_logger) |
| モデル生成 | [Freezed](https://pub.dev/packages/freezed) + [json_serializable](https://pub.dev/packages/json_serializable) |
| 環境変数 | [Envied](https://pub.dev/packages/envied) |
| テーマ管理 | [Flex Color Scheme](https://pub.dev/packages/flex_color_scheme) |
| ログ | [Logger](https://pub.dev/packages/logger) |
| Lint / 静的解析 | [very_good_analysis](https://pub.dev/packages/very_good_analysis), [custom_lint](https://pub.dev/packages/custom_lint), [riverpod_lint](https://pub.dev/packages/riverpod_lint) |
| Flutterバージョン管理 | [FVM](https://fvm.app) (`3.35.7` 使用) |

---

## ⚙️ 開発環境

| 項目 | 内容 |
|------|------|
| IDE | Visual Studio Code |
| Flutter SDK | 管理: FVM / バージョン: 3.35.7 |
| Dart SDK | 3.9.2 |
| GitHub管理 | Git（`.gitkeep`で空ディレクトリ管理） |

---

## 📁 ディレクトリ構成

```bash
lib/
└── src/
    ├── core/                     # 共通設定・ルーター・ユーティリティ
    │   ├── config/               # 定数・テーマ設定
    │   ├── router/               # GoRouter関連
    │   ├── exceptions/           # 共通例外
    │   ├── utils/                # 共通ユーティリティ
    │   └── widgets/              # 共通Widget
    ├── data/                     # 共通データアクセス層
    │   ├── models/               # Freezedモデル
    │   ├── repository/           # Repository層
    │   └── datasource/           # Dio等のデータソース層
    ├── features/                 # 機能ごとのモジュール
    │   └── sample_feature/
    │       ├── presentation/     # UI層
    │       ├── application/      # Provider・状態管理層
    │       ├── domain/           # Entity・ビジネスロジック
    │       └── data/             # 機能専用データアクセス
    └── main.dart                 # エントリーポイント
```

---

## 🧱 初期セットアップ

### 1️⃣ FVMによるFlutterバージョン指定

```bash
fvm use 3.35.7
```

### 2️⃣ 依存パッケージのインストール

```bash
flutter pub get
```

### 3️⃣ ディレクトリ構成を自動生成（スクリプト実行）

```bash
chmod +x setup_project_structure.sh
./setup_project_structure.sh
```

---

## 🧩 GoRouterを使ったルーティング設定

本プロジェクトでは [GoRouter](https://pub.dev/packages/go_router) を利用し、アプリ全体の画面遷移を管理しています。  
さらに [go_router_builder](https://pub.dev/packages/go_router_builder) を導入し、アノテーションによる**型安全なルーティング定義**を実現しています。

### 主な特徴

- `@TypedGoRoute` アノテーションでルートを定義し、`build_runner` により自動生成。
- 各画面は `GoRouteData` を継承し、IDE補完で安全に遷移可能。
- `const SampleRoute().go(context)` のように記述でき、パス文字列を直接書く必要がありません。
- `routerProvider` により、`Riverpod` 経由で `GoRouter` インスタンスを提供します。

### コード例

```dart
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(path: 'settings'),
    TypedGoRoute<SampleRoute>(path: 'sample'),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}
```

コード生成コマンド：

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🧩 Lint設定

### 利用パッケージ

- very_good_analysis  
- custom_lint  
- riverpod_lint  

`analysis_options.yaml` の主要設定例：

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    avoid_print: true
    sort_pub_dependencies: false
```

---

## 💡 VSCode推奨設定

`.vscode/settings.json` には以下の設定を含めます：

```jsonc
{
  "dart.flutterSdkPath": ".fvm/versions/3.35.7",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit"
  },
  "dart.lineLength": 100,
  "dart.showLintNames": true,
  "dart.previewFlutterUiGuides": true
}
```

---

## 🧰 コード生成コマンド

コード生成（Freezed / Json Serializable / Enviedなど）を行う際は以下を使用します：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

継続監視モードで実行する場合：

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## 🧾 備考

- `.gitkeep` ファイルにより空ディレクトリもGitで管理しています。  
- すべての設定・構成は実務で再利用できるよう設計されています。  
- 今後、GoRouterやFlexColorSchemeによる画面構築のサンプルを追加予定。

---

## 👨‍💻 作者メモ

このプロジェクトはFlutterの学習・検証・ベストプラクティス共有を目的としています。  
自由にフォークして、自分の環境に合わせたカスタマイズを行ってください。
