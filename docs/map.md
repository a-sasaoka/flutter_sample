# 🗺️ 地図機能 (Map Feature)

本モジュールは、Google Maps Platform (`google_maps_flutter`)、Geolocator (`geolocator`)、および Geocoding (`geocoding`) を採用し、ネイティブ地図の表示、位置情報の動的取得・カメラ移動、住所・ランドマーク検索機能、複数候補地インタラクティブ選択モーダル、カスタムスポット（施設・ピン）のプロットおよびスポット詳細モーダル表示機能を提供します。（※ ルート案内・ナビゲーションは今後の拡張実装予定です）

---

## 📁 ディレクトリ構造

```plaintext
lib/src/features/map/
 ├── domain/
 │    ├── location_candidate.dart           # 検索候補地モデル (Freezed)
 │    ├── location_candidate.freezed.dart   # Freezed自動生成コード
 │    ├── location_state.dart               # 位置情報および権限状態モデル (Sealed class)
 │    ├── location_state.freezed.dart       # Freezed自動生成コード
 │    ├── map_search_state.dart             # 検索状態モデル (Sealed class)
 │    ├── map_search_state.freezed.dart     # Freezed自動生成コード
 │    ├── map_spot.dart                     # カスタムスポットモデル & SpotCategory 列挙型 (Freezed)
 │    └── map_spot.freezed.dart             # Freezed自動生成コード
 ├── data/
 │    ├── location_repository.dart          # Geolocator ネイティブAPIの安全なラッパー
 │    ├── location_repository.g.dart        # Riverpod生成プロバイダー
 │    ├── geocoding_repository.dart         # Geocoding プラットフォームAPIの安全なラッパー
 │    ├── geocoding_repository.g.dart       # Riverpod生成プロバイダー
 │    ├── spot_repository.dart              # 周辺スポットデータ取得リポジトリ
 │    └── spot_repository.g.dart            # Riverpod生成プロバイダー
 ├── application/
 │    ├── map_notifier.dart                 # 地図のカメラ位置・パーミッション制御 Notifier
 │    ├── map_notifier.g.dart               # Riverpod生成 Notifier
 │    ├── map_search_notifier.dart          # 住所・ランドマーク検索状態 Notifier
 │    ├── map_search_notifier.g.dart        # Riverpod生成 Notifier
 │    ├── spot_notifier.dart                # カスタムスポット一覧状態 Notifier
 │    └── spot_notifier.g.dart              # Riverpod生成 Notifier
 └── presentation/
      ├── map_screen.dart                    # ネイティブ地図描画・現在地取得UI・Floating検索バー・カスタムピン描画 (多言語対応)
      └── widgets/
           └── spot_detail_bottom_sheet.dart # スポット詳細モーダル表示ウィジェット (多言語対応)
```

---

## 💡 仕様と設計のコアコンセプト

### 1. 安全な権限ハンドリングと状態モデル (Domain層)

`LocationState` および `MapSearchState` に Sealed class を採用し、位置情報の取得状態（初期値、ロード中、成功、権限拒否、権限永久拒否、GPS無効、エラー）および住所検索状態（初期値、検索中、成功、該当なし、エラー）をコンパイラレベルで厳密にモデリングしています。検索結果は `LocationCandidate` リストとして保持されます。また、`MapSpot` および `SpotCategory` により地図上にプロットする施設データとカテゴリ属性（アイコン、カラー、Hue値）を厳密にカプセル化しています。

### 2. Geolocator, Geocoding および SpotRepository のカプセル化 (Data層)

`LocationRepository` および `GeocodingRepository` にて OS / プラットフォーム API を集約し、テスト時にモックやテスト用ハンドラを注入可能とすることで、100% 決定論的な単体・ウィジェットテストを可能にしています。`SpotRepository` は周辺スポット（カフェ、公園、レストラン、観光地、ショッピング等）のデータを提供します。

### 3. 多言語対応 (Presentation層)

画面上のすべてのタイトル、ボタン、SearchBar ヒント文言、候補地選択タイトル、スポットカテゴリ名、評価ラベル、ルート案内ボタン、SnackBar、ダイアログ文言は `context.l10n` を使用し、日本語・英語ロケールに動的対応しています。

### 4. 住所・ランドマーク検索と複数候補地選択モーダル

画面上部の Floating SearchBar から入力された住所やランドマークのキーワードを `MapSearchNotifier` が処理し、`GeocodingRepository` 経由で緯度経度座標および住所候補リスト (`LocationCandidate`) へ変換します。

- **候補地が1件の場合**: 自動で該当位置へカメラアニメーション移動し、マーカーをプロットします。
- **候補地が複数件の場合**: 画面下部に `showModalBottomSheet` を表示し、ユーザーに目的の施設・住所を選択させます。選択された候補地へスムーズなカメラ移動とマーカープロットを行います。

### 5. カスタムプロット・ピン表示と詳細モーダル (`SpotDetailBottomSheet`)

地図上には `SpotRepository` から取得した周辺スポットが、カテゴリ別に色分けされたカスタムマーカー (`BitmapDescriptor.defaultMarkerWithHue`) としてプロットされます。

- **ピンタップ時**: タップされたスポットの中心へカメラが滑らかにフォーカス移動し、画面下部に `SpotDetailBottomSheet` が表示されます。
- **詳細表示内容**: カテゴリバッジ、スポット名称、評価（★）、住所、詳細説明文言、およびルート案内ボタンが表示されます。

---

## 🛡️ パーミッション設定

### iOS (`ios/Runner/Info.plist`)

- `NSLocationWhenInUseUsageDescription`: 地図画面で現在地を表示・取得するために位置情報を使用します。
- `NSLocationAlwaysAndWhenInUseUsageDescription`: 地図画面で現在地を表示・取得するために位置情報を使用します。

### Android (`android/app/src/main/AndroidManifest.xml`)

- `android.permission.ACCESS_FINE_LOCATION` (GPS高精度)
- `android.permission.ACCESS_COARSE_LOCATION` (概算位置)
