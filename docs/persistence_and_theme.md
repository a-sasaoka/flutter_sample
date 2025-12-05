# SharedPreferences の永続化設定

テーマモードなどの設定値を永続化するために、`SharedPreferences` をアプリ全体で共有する仕組みを導入しています。\
Riverpod のアノテーション構文（`@Riverpod(keepAlive: true)`）を使い、どのプロバイダからでも安全にアクセス可能です。

この構成により、`SharedPreferences` のインスタンスをアプリ全体で共有し、 I/O を最小化しつつテスト可能な形で永続化処理を行えます。

---

## テーマ設定（FlexColorScheme）

アプリ全体のデザインテーマは [FlexColorScheme](https://pub.dev/packages/flex_color_scheme) を利用して構築しています。
Material 3 対応で、ライト／ダーク／システムモードの切り替えに対応しています。

### 主なファイル構成

```plaintext
lib/src/core/config/
 ├── app_theme.dart           # テーマ定義（FlexColorScheme）
 └── theme_mode_provider.dart # テーマモードを管理するRiverpodプロバイダ
```

💡 `SharedPreferences` と連携し、ユーザーが選択したテーマモードを永続化しています。
アプリ起動時に前回のテーマ設定を自動的に復元します。

---
