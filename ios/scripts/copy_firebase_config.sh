#!/bin/sh

# ビルド設定名（例: Debug-local, Release-dev 等）から Flavor 名を取得
# ハイフンで分割し、2番目の要素（local, dev, stg, prod）を抽出し、小文字に変換
FLAVOR=$(echo "${CONFIGURATION}" | cut -d "-" -f 2 | tr '[:upper:]' '[:lower:]')

# 有効な Flavor 名であるかチェック
case "${FLAVOR}" in
    local|dev|stg|prod)
        echo "Firebase config found for flavor: ${FLAVOR}. Copying to destination..."
        ;;
    *)
        # 該当しない場合（標準の Debug/Release 設定など）は、コピーをスキップ
        echo "Warning: No valid flavor detected in configuration '${CONFIGURATION}'. Skipping Firebase config copy."
        exit 0
        ;;
esac

# コピー元ファイルパス
SOURCE_FILE="${SRCROOT}/Runner/Firebase/${FLAVOR}/GoogleService-Info.plist"

# コピー先ファイルパス（Xcodeがプロジェクトリソースとして参照している場所）
DEST_FILE="${SRCROOT}/Runner/GoogleService-Info.plist"

# 指定された Flavor の設定ファイルが存在するか確認
if [ -f "$SOURCE_FILE" ]; then
    cp -f "$SOURCE_FILE" "$DEST_FILE"
else
    echo "Error: Firebase config NOT found at ${SOURCE_FILE}."
    exit 1
fi
