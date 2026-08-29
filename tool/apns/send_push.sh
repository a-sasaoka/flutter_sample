#!/usr/bin/env bash

# ==============================================================================
# 🔔 iOS シミュレーター Push 通知送信スクリプト (APNs)
# ==============================================================================
# このスクリプトは、起動中の iOS シミュレーターに対して xcrun simctl push を使用し、
# リモートプッシュ通知（APNsペイロード）を送信して動作確認を行うためのツールです。
#
# 使い方:
#   1. 対話型モード（おすすめ）:
#      ./tool/apns/send_push.sh
#
#   2. CLI 引数指定モード:
#      ./tool/apns/send_push.sh --flavor local --path /chat --title "テスト" --body "通知本文"
#
#   3. .apns ファイル直接指定モード:
#      ./tool/apns/send_push.sh --file tool/apns/chat_local.apns
# ==============================================================================

set -euo pipefail

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# フレーバーと Bundle ID のマッピング定義
get_bundle_id() {
  local flavor="$1"
  case "$flavor" in
    local) echo "jp.example.sample.local" ;;
    dev)   echo "jp.example.sample.dev" ;;
    stg)   echo "jp.example.sample.stg" ;;
    prod)  echo "jp.example.sample" ;;
    *)
      echo "❌ 未知のフレーバーです: $flavor (local, dev, stg, prod のいずれかを指定してください)" >&2
      exit 1
      ;;
  esac
}

# ヘルプ表示
show_help() {
  cat << EOF
🔔 iOS シミュレーター Push 通知送信ツール

使用方法:
  $0 [オプション]

オプション:
  -f, --flavor FLAVOR   対象環境を指定 (local [デフォルト], dev, stg, prod)
  -p, --path PATH       通知タップ時の遷移先パス (例: /chat, /memos, /settings/profile)
  -t, --title TITLE     通知タイトル (デフォルト: "💬 テスト通知")
  -b, --body BODY       通知本文 (デフォルト: "シミュレーターでのリモートプッシュ通知テストです。")
  -i, --file FILE_PATH  送信する .apns ファイルのパス (直接ファイルを送信する場合)
  -h, --help            このヘルプメッセージを表示

使用例:
  $0                                                      # 対話型メニューで実行
  $0 -p /chat                                             # AIチャット画面宛てに送信
  $0 -f dev -p /memos -t "新着メモ" -b "新しいメモがあります"   # Dev環境のメモ一覧宛てに送信
  $0 --file tool/apns/profile_local.apns                  # 既存のAPNsファイルを直接送信

EOF
}

# 起動中の iOS シミュレーターの存在チェック
check_simulator() {
  if ! command -v xcrun &> /dev/null; then
    echo "❌ エラー: Xcode コマンドラインツール (xcrun) がインストールされていません。" >&2
    exit 1
  fi

  local booted
  booted=$(xcrun simctl list devices | grep -E "Booted" || true)
  if [ -z "$booted" ]; then
    echo "❌ エラー: 起動中の iOS シミュレーターが見つかりません。" >&2
    echo "💡 解決策: Xcode または VSCode から iOS シミュレーターを起動し、アプリを実行した状態で再度お試しください。" >&2
    exit 1
  fi
}

# 変数初期化
FLAVOR=""
TARGET_PATH=""
TITLE=""
BODY=""
APNS_FILE=""
INTERACTIVE=true

# コマンドライン引数のパース
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--flavor)
      if [[ $# -lt 2 ]]; then
        echo "❌ エラー: $1 オプションには値（フレーバー名）が必要です。" >&2
        echo "💡 '$0 --help' で使用方法を確認してください。" >&2
        exit 1
      fi
      FLAVOR="$2"
      INTERACTIVE=false
      shift 2
      ;;
    -p|--path)
      if [[ $# -lt 2 ]]; then
        echo "❌ エラー: $1 オプションには値（遷移先パス）が必要です。" >&2
        echo "💡 '$0 --help' で使用方法を確認してください。" >&2
        exit 1
      fi
      TARGET_PATH="$2"
      INTERACTIVE=false
      shift 2
      ;;
    -t|--title)
      if [[ $# -lt 2 ]]; then
        echo "❌ エラー: $1 オプションには値（通知タイトル）が必要です。" >&2
        echo "💡 '$0 --help' で使用方法を確認してください。" >&2
        exit 1
      fi
      TITLE="$2"
      INTERACTIVE=false
      shift 2
      ;;
    -b|--body)
      if [[ $# -lt 2 ]]; then
        echo "❌ エラー: $1 オプションには値（通知本文）が必要です。" >&2
        echo "💡 '$0 --help' で使用方法を確認してください。" >&2
        exit 1
      fi
      BODY="$2"
      INTERACTIVE=false
      shift 2
      ;;
    -i|--file)
      if [[ $# -lt 2 ]]; then
        echo "❌ エラー: $1 オプションには値（ファイルパス）が必要です。" >&2
        echo "💡 '$0 --help' で使用方法を確認してください。" >&2
        exit 1
      fi
      APNS_FILE="$2"
      INTERACTIVE=false
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "❌ 未知のオプション: $1" >&2
      echo "💡 '$0 --help' で使用方法を確認してください。" >&2
      exit 1
      ;;
  esac
done

# シミュレーター確認
check_simulator

# 対話型メニューモード
if [ "$INTERACTIVE" = true ]; then
  echo "=================================================="
  echo "🔔 iOS シミュレーター Push 通知送信メニュー"
  echo "=================================================="
  echo ""

  # 1. フレーバーの選択
  echo "【1/4】送信対象の環境（フレーバー）を選択してください:"
  echo "  1) local (jp.example.sample.local) [推奨・デフォルト]"
  echo "  2) dev   (jp.example.sample.dev)"
  echo "  3) stg   (jp.example.sample.stg)"
  echo "  4) prod  (jp.example.sample)"
  read -r -p "選択 (1-4, デフォルト: 1): " flavor_choice
  case "${flavor_choice:-1}" in
    1) FLAVOR="local" ;;
    2) FLAVOR="dev" ;;
    3) FLAVOR="stg" ;;
    4) FLAVOR="prod" ;;
    *) FLAVOR="local" ;;
  esac
  echo "👉 選択されたフレーバー: $FLAVOR"
  echo ""

  # 2. 遷移先パスの選択
  echo "【2/4】通知タップ時の遷移先画面を選択してください:"
  echo "  1) 💬 AIチャット画面 (/chat) [デフォルト]"
  echo "  2) 📝 メモ一覧画面 (/memos)"
  echo "  3) 👤 プロフィール設定画面 (/settings/profile)"
  echo "  4) ⚙️  設定画面 (/settings)"
  echo "  5) ✏️  カスタムパスを自由入力"
  read -r -p "選択 (1-5, デフォルト: 1): " path_choice
  case "${path_choice:-1}" in
    1)
      TARGET_PATH="/chat"
      DEFAULT_TITLE="💬 AIチャット通知"
      DEFAULT_BODY="AIアシスタントから新しいメッセージが届きました。"
      ;;
    2)
      TARGET_PATH="/memos"
      DEFAULT_TITLE="📝 メモ一覧通知"
      DEFAULT_BODY="メモ一覧画面を確認しましょう。"
      ;;
    3)
      TARGET_PATH="/settings/profile"
      DEFAULT_TITLE="👤 プロフィール通知"
      DEFAULT_BODY="プロフィール設定画面を開きます。"
      ;;
    4)
      TARGET_PATH="/settings"
      DEFAULT_TITLE="⚙️ 設定通知"
      DEFAULT_BODY="アプリの設定画面を開きます。"
      ;;
    5)
      read -r -p "遷移先パスを入力してください (例: /chat): " custom_path
      TARGET_PATH="${custom_path:-/chat}"
      DEFAULT_TITLE="🔔 テスト通知"
      DEFAULT_BODY="カスタムディープリンク通知です。"
      ;;
    *)
      TARGET_PATH="/chat"
      DEFAULT_TITLE="💬 AIチャット通知"
      DEFAULT_BODY="AIアシスタントから新しいメッセージが届きました。"
      ;;
  esac
  echo "👉 遷移先パス: $TARGET_PATH"
  echo ""

  # 3. タイトルの入力
  read -r -p "【3/4】通知タイトルを入力 (デフォルト: ${DEFAULT_TITLE}): " input_title
  TITLE="${input_title:-$DEFAULT_TITLE}"
  echo "👉 タイトル: $TITLE"
  echo ""

  # 4. 本文の入力
  read -r -p "【4/4】通知本文を入力 (デフォルト: ${DEFAULT_BODY}): " input_body
  BODY="${input_body:-$DEFAULT_BODY}"
  echo "👉 本文: $BODY"
  echo ""
fi

# デフォルト値の設定（CLI引数で未指定の場合）
FLAVOR="${FLAVOR:-local}"
TARGET_PATH="${TARGET_PATH:-/chat}"
TITLE="${TITLE:-💬 テスト通知}"
BODY="${BODY:-シミュレーターでのリモートプッシュ通知テストです。}"
BUNDLE_ID=$(get_bundle_id "$FLAVOR")
MESSAGE_ID="sim_$(date +%s)"

echo "🚀 プッシュ通知を iOS シミュレーターへ送信中..."
echo "  - Bundle ID : $BUNDLE_ID"

if [ -n "$APNS_FILE" ]; then
  # 既存ファイルの直接送信
  if [ ! -f "$APNS_FILE" ]; then
    echo "❌ エラー: ファイルが存在しません: $APNS_FILE" >&2
    exit 1
  fi
  echo "  - 送信ファイル: $APNS_FILE"
  xcrun simctl push booted "$BUNDLE_ID" "$APNS_FILE"
else
  # 動的ペイロードの送信（Python の json.dumps を使用して安全に JSON を生成）
  echo "  - 遷移先パス: $TARGET_PATH"
  echo "  - タイトル  : $TITLE"
  echo "  - 本文      : $BODY"

  JSON_PAYLOAD=$(python3 -c '
import sys, json
title, body, path, bundle_id, msg_id = sys.argv[1:6]
payload = {
    "Simulator Target Bundle": bundle_id,
    "aps": {
        "alert": {
            "title": title,
            "body": body,
        },
        "badge": 1,
        "sound": "default",
    },
    "gcm.message_id": msg_id,
    "path": path,
    "payload": json.dumps({"path": path}),
}
print(json.dumps(payload, ensure_ascii=False, indent=2))
' "$TITLE" "$BODY" "$TARGET_PATH" "$BUNDLE_ID" "$MESSAGE_ID")

  echo "$JSON_PAYLOAD" | xcrun simctl push booted "$BUNDLE_ID" -
fi

echo ""
echo "✅ プッシュ通知の送信が完了しました！"
echo "💡 iOS シミュレーターの画面上部にバナーが表示されているか確認し、タップして画面遷移をテストしてください。"
