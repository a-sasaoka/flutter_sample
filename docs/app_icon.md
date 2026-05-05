# アプリアイコンの変更手順

本プロジェクトでは、`flutter_launcher_icons` パッケージを利用して、各環境（Flavor）ごとのアプリアイコンを一括管理・自動生成しています。

---

## 📋 事前準備

1. **アイコン画像の作成**:
   - 1024x1024 px の PNG ファイルを推奨します。
   - 各環境（local, dev, stg, prod）ごとに異なるデザインにする場合は、それぞれの画像を準備してください。
2. **画像の配置**:
   - プロジェクト内の `assets/images/` 等のディレクトリに画像を配置します（ディレクトリがない場合は作成してください）。

---

## ⚙️ 1. pubspec.yaml の設定

`pubspec.yaml` の `flutter_launcher_icons` セクションを編集します。

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  # 全環境共通のデフォルト（または本番用）
  image_path: "assets/images/app_icon_prod.png"

  flavors:
    local:
      image_path: "assets/images/app_icon_local.png"
      adaptive_icon_background: "#9E9E9E" # Android用背景色
      adaptive_icon_foreground: "assets/images/app_icon_local.png" # Android用前面ロゴ
    dev:
      image_path: "assets/images/app_icon_dev.png"
      adaptive_icon_background: "#F44336"
      adaptive_icon_foreground: "assets/images/app_icon_dev.png"
    # ... stg, prod も同様に設定
```

### 💡 設定のポイント

- **`flavors:` 配下の名前**: `flavorizr` で定義した環境名（`local`, `dev` 等）と一致させる必要があります。
- **Android アダプティブアイコン**: `adaptive_icon_background`（背景色または画像）と `adaptive_icon_foreground`（前面のロゴ画像）を指定することで、Android 8.0 以降の動的なアイコン形状に対応できます。

---

## 🚀 2. アイコン生成コマンドの実行

設定を更新した後、以下のコマンドを実行してネイティブ側のアイコンファイルを更新します。

```bash
fvm flutter pub run flutter_launcher_icons
```

このコマンドを実行すると、以下の処理が自動で行われます：

- **Android**: `android/app/src/{flavor}/res/` 配下に各解像度のアイコンが生成される。
- **iOS**: `Assets.xcassets` 内に `{flavor}AppIcon` という名前のアイコンセットが生成される。

---

## ⚠️ 注意事項

- **手動修正は不要**: `android/app/src/.../mipmap-*` フォルダや iOS のアセットカタログを手動で編集する必要はありません。常に `pubspec.yaml` を正として、コマンドで上書き生成してください。
- **iOS の反映確認**: アイコンを変更してもシミュレータ上で反映されない場合は、一度アプリをアンインストールしてから再ビルドしてください。
