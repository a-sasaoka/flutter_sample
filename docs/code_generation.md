# コード生成コマンド

## 環境の切り替え、設定値変更

コード生成時に使用する `.env` ファイルを環境ごとに切り替えることができます。以下のコマンドを使用して、対象の環境設定に合わせて生成してください。

### Local環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
```

### Dev環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.dev"
```

### Staging環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.stg"
```

### Production環境

```bash
fvm dart run build_runner build --delete-conflicting-outputs --define "envied_generator:envied=path=.env.prod"
```

---

## 通常のコード生成

### 都度実行する場合

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

### 監視モードで実行する場合

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

---

## ネイティブ部分の環境による切り替え

### iOS

`ios/scripts/extract_dart_defines.sh` をPreActionsとして実行することで `.env` ファイルから値を取得します。  
取得した値は `ios/Runner/Info.plist` や `ios/Runner.xcodeproj/project.pbxproj` 内で `$(APP_NAME)` のように参照できます。

### Android

`android/app/build.gradle.kts` 内で `.env` ファイルから値を取得し、`dartDefines["APP_NAME"]` のように参照できます。  
`resValue("string", "app_name", dartDefines["APP_NAME"] ?: "Flutter Sample")` のようにすることで、`android/app/src/main/AndroidManifest.xml` 内で `@string/app_name` のように参照できます。

---

## 💡 補足：再生成が必要なタイミング

| 状況                                           | コード生成の要否      |
| ---------------------------------------------- | --------------------- |
| 環境（.env）を切り替えた                       | 🔁 Envied再生成が必要 |
| モデル（Freezed / JsonSerializable）を更新した | ✅ 通常生成のみでOK   |
| `.env` の値を修正した                          | 🔁 Envied再生成が必要 |
| コードのみ変更した                             | 🚫 Envied不要         |

**ポイント:**

- Enviedは環境変数をビルド時に暗号化して生成するため、環境を切り替えた場合や`.env`の値を変更した場合にのみ再生成が必要です。
- FreezedやJsonなど、通常のコード変更に関しては通常の`build_runner`実行で十分です。

---
