# プロジェクト概要

このプロジェクトは、Flutterを用いたアプリ開発で役立つ構成・設定を体系的にまとめたテンプレートです。\
特に以下の技術スタックを採用し、実務でも通用する設計を意識しています。

---

## このプロジェクトで学べること

このサンプルプロジェクトを通して、以下の技術や設計手法を体系的に学ぶことができます。

| 分野                | 学べる内容                                                                                                                                                                                           |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🧠 状態管理         | Riverpod + Flutter Hooks による状態管理とロジックの分離                                                                                                                                              |
| 🧭 ルーティング     | GoRouter + go_router_builder による型安全なルート設計と認証ガード、ログイン後リダイレクト                                                                                                            |
| 🌐 通信             | Dio + Interceptorによる共通通信層とエラーハンドリング、接続状態の監視(Connectivity)とグローバルオフラインバナー                                                                                      |
| 🔒 認証             | Firebase Auth（メール/Googleログイン） / Bearerトークンの自動リフレッシュ                                                                                                                            |
| 💾 データ保持       | SharedPreferencesAsync / SecureStorage / Drift(SQLite) による永続化とオフライン対応                                                                                                                  |
| 🗺️ 地図/位置情報    | google_maps_flutter + geolocator + Google Places API による現在地取得・表示、場所・キーワード検索（評価・住所候補表示）、カメラアニメーション移動、パーミッション制御、2点間ルート検索・Polyline描画 |
| 📝 ロギング         | Talkerを用いた統合ログ管理（通信・状態・Crashlytics連携）とアプリ内開発者用画面                                                                                                                      |
| 🌍 多言語対応       | flutter_localizations + gen-l10n による標準的な多言語化                                                                                                                                              |
| 🔥 Firebase         | Auth / Analytics / Crashlytics / Remote Config（強制アップデート・フィーチャーフラグ・動的バナー） / App Check を組み合わせた基盤構築                                                                |
| 🏠 ホーム           | 主要機能へのナビゲーションハブ、動的お知らせバナー、環境情報の判別、デバッグツールの集約                                                                                                             |
| 📈 グラフ           | fl_chart を用いた動的なグラフ（折れ線・棒・円）の表示とデータ入力、期間切り替え付き売上推移折れ線グラフ                                                                                              |
| ⚙️ 設定             | SegmentedButton によるテーマ・言語切り替え、永続化連携、安全なログアウト処理                                                                                                                         |
| 🔐 アプリロック     | 4桁PINパスコード＋生体認証（iOS: Face ID / Touch ID, Android: 指紋認証 / 顔認証）による最前面保護・自動復帰ロック                                                                                    |
| 🤖 生成AI           | Firebase AI Logic（firebase_ai）を用いたストリーミング応答と履歴保持チャット                                                                                                                         |
| 🎬 アニメーション   | Lottie + flutter_gen によるベクターアニメーションの型安全な導入と制御（再生・一時停止・シークバー・ループ切替）、事前キャッシュ機構、および非同期処理連動アニメーションボタンの実装                  |
| 🔔 Push通知         | FCM + flutter_local_notifications による通知受信・バナー表示、通知タップ時の GoRouter 自動ディープリンク遷移                                                                                         |
| ⚡️ パフォーマンス   | cached_network_image による画像キャッシュ・メモリ最適化、Firebase Performance による通信・処理時間の自動監視、DevTools を用いたアプリサイズ分析、ウィジェット不要再ビルドの特定と撲滅検証            |
| 📷 QRコードリーダー | mobile_scanner によるリアルタイムQR読み取り・アルバム画像解析、Drift によるスキャン履歴のローカル永続化とスワイプ削除、URL判定・ブラウザ起動                                                         |
| 📜 法的情報         | flutter_markdown_plus + flutter_gen による利用規約・プライバシーポリシーの型安全な読み込みと表示、公開ルーティング設定                                                                               |
| 📢 SNSシェア        | share_plus によるOS標準共有（テキスト・URL・画像）とiPadポップオーバー対応、特定SNS（X/LINE）直接投稿連携、アプリロック誤作動抑止                                                                    |
| 🧰 コード生成       | build_runnerによる自動生成と、JSON/Enviedを組み合わせた高度な環境切替対応                                                                                                                            |
| 🎨 UI/UX            | FlexColorSchemeによるテーマ設定、共通エラーハンドリングUI、共通カスタムバリデータによる堅牢なフォーム検証、Haptic Feedback（触覚）の実装                                                             |
| 🧪 テスト           | package:checks / mocktail を用いた実践的なユニット・ウィジェットテスト、Alchemist によるゴールデンテスト、および Maestro による E2E テストの手法                                                     |
| 🧩 Lint・CI/CD      | custom_lint 等の実用設定と、GitHub Actions による自動化（CI/CD）基盤                                                                                                                                 |
| 🚀 開発効率         | FVM + VSCode設定 + Git Hooks で統一開発環境を構築                                                                                                                                                    |
| 🏗️ アーキテクチャ   | マルチエントリーポイントによるFlavor（Local/Dev/Stg/Prod）の完全分離と堅牢な管理方式                                                                                                                 |

---
