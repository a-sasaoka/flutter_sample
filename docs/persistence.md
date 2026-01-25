# SharedPreferences の永続化設定

テーマモードなどの設定値を永続化するために、`SharedPreferences` をアプリ全体で共有する仕組みを導入しています。\
Riverpod のアノテーション構文（`@Riverpod(keepAlive: true)`）を使い、どのプロバイダからでも安全にアクセス可能です。

この構成により、`SharedPreferences` のインスタンスをアプリ全体で共有し、 I/O を最小化しつつテスト可能な形で永続化処理を行えます。

---
