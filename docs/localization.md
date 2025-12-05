# 多言語対応（Localization）

本プロジェクトでは Flutter の公式ローカライズ機能（gen-l10n）を利用し、**lib/l10n + l10n.yaml** を用いた安定した多言語対応を実現しています。

## 📁 ディレクトリ構成

```plaintext
lib/
 └── l10n/
      ├── app_en.arb
      └── app_ja.arb
l10n.yaml
```

## 📝 l10n.yaml（プロジェクトルート）

```plaintext
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
  "hello": "Hello",
  "login": "Login",
  "logout": "Logout"
}
```

```json
app_ja.arb:
{
  "@@locale": "ja",
  "hello": "こんにちは",
  "login": "ログイン",
  "logout": "ログアウト"
}
```

## ⚙️ コード生成

`fvm flutter gen-l10n`

ARB を編集した場合は再度コード生成が必要です。
ホットリロードでは翻訳が更新されないため、
アプリを一度完全に停止して再起動してください。

## 🏗 MaterialApp への組み込み

```dart
MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

## 🧩 翻訳の利用例

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.hello);
```

---
