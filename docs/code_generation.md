# コード生成コマンド

## コード生成

Riverpodなどのコード生成には`build_runner`を使用します。

当該ファイルを変更した場合は`build_runner`を再実行してください。

---

## 環境の切り替え、設定値変更

コード生成時に使用する `.env` ファイルを環境ごとに切り替えることができます。以下のコマンドを使用して、対象の環境設定に合わせて生成してください。

なお、`envied_generator:envied`が指定されなかった場合はLocal環境用のファイルを使用します。

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

## 監視モード

`build`の代わりに`watch`を使用するとソースの変更を監視し、ソースが変更されると自動でコード生成が行われます。

```bash
fvm dart run build_runner watch --delete-conflicting-outputs --define "envied_generator:envied=path=.env.local"
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
