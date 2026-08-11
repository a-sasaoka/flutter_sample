# 🗺️ 地図機能 (Map Feature)

本モジュールは、Google Maps Platform (`google_maps_flutter`) および Geolocator (`geolocator`) を採用し、ネイティブ地図の表示、位置情報の動的取得・カメラ移動、権限管理機能を提供します。（※ 住所・ランドマーク検索、プロット表示、ルート案内は今後の拡張実装予定です）

---

## 📁 ディレクトリ構造

```plaintext
lib/src/features/map/
 ├── domain/
 │    ├── location_state.dart         # 位置情報および権限状態モデル (Sealed class)
 │    └── location_state.freezed.dart # Freezed自動生成コード
 ├── data/
 │    ├── location_repository.dart    # Geolocator ネイティブAPIの安全なラッパー
 │    └── location_repository.g.dart  # Riverpod生成プロバイダー
 ├── application/
 │    ├── map_notifier.dart           # 地図のカメラ位置・パーミッション制御 Notifier
 │    └── map_notifier.g.dart         # Riverpod生成 Notifier
 └── presentation/
      └── map_screen.dart             # ネイティブ地図描画と現在地取得UI (多言語対応)
```

---

## 💡 仕様と設計のコアコンセプト

### 1. 安全な権限ハンドリングと状態モデル (Domain層)

`LocationState` に Sealed class を採用し、位置情報の取得状態（初期値、ロード中、成功、権限拒否、権限永久拒否、GPS無効、エラー）をコンパイラレベルで厳密にモデリングしています。

### 2. Geolocator のカプセル化 (Data層)

`LocationRepository` にて OS の Geolocator プラットフォーム API を集約し、テスト時に `GeolocatorPlatform` のモックを注入可能とすることで、100% 決定論的なテストを可能にしています。

### 3. 多言語対応 (Presentation層)

画面上のすべてのタイトル、ボタン、SnackBar、ダイアログ文言は `context.l10n` を使用し、日本語・英語ロケールに動的対応しています。

---

## 🛡️ パーミッション設定

### iOS (`ios/Runner/Info.plist`)

- `NSLocationWhenInUseUsageDescription`: 地図画面で現在地を表示・取得するために位置情報を使用します。
- `NSLocationAlwaysAndWhenInUseUsageDescription`: 地図画面で現在地を表示・取得するために位置情報を使用します。

### Android (`android/app/src/main/AndroidManifest.xml`)

- `android.permission.ACCESS_FINE_LOCATION` (GPS高精度)
- `android.permission.ACCESS_COARSE_LOCATION` (概算位置)
