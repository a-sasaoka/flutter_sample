# 多言語対応（Localization）

本プロジェクトでは Flutter の公式ローカライズ機能（gen-l10n）を利用し、**lib/l10n + l10n.yaml** を用いた安定した多言語対応を実現しています。

## 📁 ディレクトリ構成

自動生成された翻訳クラスが `lib/l10n/` 配下に直接配置される設定にしているため、通常のインポート（`import 'package:flutter_sample/l10n/app_localizations.dart';`）で簡単に利用できます。

```plaintext
lib/
 └── l10n/
      ├── app_en.arb                  # 英語翻訳ファイル (テンプレート)
      ├── app_ja.arb                  # 日本語翻訳ファイル
      └── app_localizations.dart      # 自動生成される翻訳クラス（Git管理対象）
l10n.yaml
```

## 📝 l10n.yaml（プロジェクトルート）

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

## 🌐 ARB ファイル例

```json
app_en.arb:
{
  "@@locale": "en",
  "appTitle": "Flutter Sample App",
  "errorUnknown": "An unexpected error occurred.",
  "login": "Login",
  "logout": "Logout"
}
```

```json
app_ja.arb:
{
  "@@locale": "ja",
  "appTitle": "Flutter サンプルアプリ",
  "errorUnknown": "予期せぬエラーが発生しました。",
  "login": "ログイン",
  "logout": "ログアウト"
}
```

## ⚙️ コード生成

Flutterの標準機能により、`pub get` や `run` 時に自動生成されますが、手動で即座に反映させたい場合は以下のコマンドを実行します。

```bash
fvm flutter gen-l10n
```

※ ARB を編集した場合、ホットリロードでは翻訳が更新されないことがあります。その場合はアプリを一度完全に停止して再起動してください。

## 🏗 MaterialApp への組み込み

`main.dart` などで、アプリ全体の `MaterialApp` にローカライズ設定を注入します。

```dart
MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

## 🧩 翻訳の利用例

```dart
// context を経由して翻訳テキストを取得
final l10n = AppLocalizations.of(context)!;

Text(l10n.appTitle);
Text(l10n.errorUnknown);
```

---

## 🧪 Widgetテストでの多言語化のモック（ベストプラクティス）

画面（Widget）のテストを行う際、翻訳データが存在しないとエラーになるため、`mocktail` を用いて多言語化クラスをモック（偽装）して注入します。

```dart
import 'package:mocktail/mocktail.dart';

// 1. モッククラスの定義
class MockAppLocalizations extends Mock implements AppLocalizations {}

// 2. テスト用の Delegate を作成
class _MockLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;

  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant _) => false;
}

void main() {
  testWidgets('テスト例', (tester) async {
    final mockL10n = MockAppLocalizations();

    // 3. 必要な翻訳テキストをモックする
    when(() => mockL10n.appTitle).thenReturn('Test Title');

    // 4. MaterialApp に注入してテスト環境を構築
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
        home: const TargetScreen(),
      ),
    );

    check(find.text('Test Title')).findsOne();
  });
}
```

---

## 🧭 多言語化対応ポリシー（開発時のルール）

本プロジェクトで新しい画面や機能を追加する際は、以下のローカライズルールを必ず遵守してください。

### 1. 日付・時刻のローカライズ

- 画面上で日付や時刻を表示する際、`yyyy/MM/dd` などのフォーマット文字列をハードコードしてはいけません。
- `DateTime` オブジェクトに対して、[core_utilities.md](core_utilities.md) で定義されている `toFormattedString(locale)` 拡張メソッドを使用してください。これにより、ユーザーのアプリロケール（`ja` / `en`）に応じた最適な日付書式で自動表示されます。

### 2. エラーメッセージのローカライズ

- リポジトリ層などのデータ・ロジック層で `AppException` などの例外をスロー・返却する際、例外オブジェクト内に「ハードコードされた英語メッセージ」を埋め込むことは禁止されています。
- 例外は型（例: `AppException.network()` など）で表現し、UI層に表示する具体的なテキスト（エラーメッセージ）は、`ErrorHandler` や `AppLocalizations` を経由して ARB ファイル（多言語化リソース）から動的に取得する設計にしてください。
- ログ出力用のメッセージは、ユーザーへ表示されないため多言語化不要です。

---
