# アプリアイコンの変更手順

本プロジェクトでは、`flutter_launcher_icons` パッケージを利用して、各環境（Flavor）ごとのアプリアイコンを一括管理しています。
安定性の向上のため、環境ごとに個別の設定ファイルを用意しています。

---

## 📋 事前準備

1. **アイコン画像の作成**:
   - 1024x1024 px の PNG ファイルを推奨します。
2. **画像の配置**:
   - `assets/icons/` ディレクトリに、各環境用の画像を配置します。
   - `local.png`, `dev.png`, `stg.png`, `prod.png`

---

## ⚙️ 1. 設定ファイルの編集

プロジェクト直下にある、以下の各環境用設定ファイルを編集します。

- `flutter_launcher_icons-local.yaml`
- `flutter_launcher_icons-dev.yaml`
- `flutter_launcher_icons-stg.yaml`
- `flutter_launcher_icons-prod.yaml`

### 設定例 (`flutter_launcher_icons-dev.yaml`)

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/dev.png"
  adaptive_icon_background: "#F44336" # Android用背景色
  adaptive_icon_foreground: "assets/icons/dev.png" # Android用前面ロゴ
```

---

## 🚀 2. アイコン生成コマンドの実行

設定を更新した後、以下のコマンドを実行してネイティブ側のアイコンファイルを一括更新します。

```bash
# 全環境のアイコンを生成
fvm dart run flutter_launcher_icons
```

このコマンドを実行すると、ツールが `flutter_launcher_icons-*.yaml` ファイルを自動的に検知し、それぞれの環境に対応するアイコンを以下の場所に生成します：

- **Android**: `android/app/src/{flavor}/res/`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon-{flavor}.appiconset`

---

## ⚠️ 注意事項

- **個別実行も可能**: 特定の環境だけ更新したい場合は `fvm flutter pub run flutter_launcher_icons -f flutter_launcher_icons-dev.yaml` のようにファイルを指定して実行してください。
- **手動修正は不要**: ネイティブフォルダ内の画像を直接編集しないでください。常に設定ファイルを正として、コマンドで生成してください。
