#!/bin/sh

# ビルド設定名（例: Debug-local, Release-dev 等）から Flavor 名を取得
# ハイフンで分割し、2番目の要素（local, dev, stg, prod）を抽出
FLAVOR=$(echo "${CONFIGURATION}" | cut -d "-" -f 2)

# コピー元ファイルパス
SOURCE_FILE="${SRCROOT}/Runner/Firebase/${FLAVOR}/GoogleService-Info.plist"

# コピー先ファイルパス（Xcodeがプロジェクトリソースとして参照している場所）
DEST_FILE="${SRCROOT}/Runner/GoogleService-Info.plist"

# 指定された Flavor の設定ファイルが存在するか確認
if [ -f "$SOURCE_FILE" ]; then
    echo "Firebase config found for flavor: ${FLAVOR}. Copying to destination..."
    cp -f "$SOURCE_FILE" "$DEST_FILE"
else
    echo "Warning: Firebase config NOT found at ${SOURCE_FILE}. Using existing file if any."
fi
