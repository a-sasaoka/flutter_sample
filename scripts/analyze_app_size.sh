#!/usr/bin/env bash
# ==============================================================================
# 📊 Flutter App Size Analyzer Script
# ==============================================================================
# アプリのビルドサイズを分析し、DevTools で可視化できる JSON スナップショットを出力します。
#
# 使用例:
#   ./scripts/analyze_app_size.sh android prod
#   ./scripts/analyze_app_size.sh ios prod
#   ./scripts/analyze_app_size.sh android dev
# ==============================================================================

set -euo pipefail

PLATFORM="${1:-android}"
FLAVOR="${2:-prod}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

OUTPUT_DIR="${ROOT_DIR}/build/size_analysis"
mkdir -p "${OUTPUT_DIR}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CONFIG_FILE="config/flavor_${FLAVOR}.json"

if [ ! -f "${CONFIG_FILE}" ]; then
  echo "❌ エラー: 設定ファイル ${CONFIG_FILE} が見つかりません。"
  exit 1
fi

echo "========================================================"
echo "⚡️ アプリサイズ分析ビルドを開始します..."
echo "📱 Platform : ${PLATFORM}"
echo "🏷️ Flavor   : ${FLAVOR}"
echo "⚙️ Config   : ${CONFIG_FILE}"
echo "========================================================"

case "${PLATFORM}" in
  android|appbundle)
    OUTPUT_JSON="${OUTPUT_DIR}/size_analysis_android_${FLAVOR}_${TIMESTAMP}.json"
    echo "🔨 Android AppBundle をビルド中 (--analyze-size)..."
    fvm flutter build appbundle \
      --flavor "${FLAVOR}" \
      --target "lib/main_${FLAVOR}.dart" \
      --dart-define-from-file="${CONFIG_FILE}" \
      --analyze-size \
      --code-size-directory="${OUTPUT_DIR}"

    echo ""
    echo "✅ Android のサイズ分析データが出力されました:"
    echo "📁 出力先ディレクトリ: ${OUTPUT_DIR}"
    ;;

  apk)
    OUTPUT_JSON="${OUTPUT_DIR}/size_analysis_apk_${FLAVOR}_${TIMESTAMP}.json"
    echo "🔨 Android APK をビルド中 (--analyze-size)..."
    fvm flutter build apk \
      --flavor "${FLAVOR}" \
      --target "lib/main_${FLAVOR}.dart" \
      --dart-define-from-file="${CONFIG_FILE}" \
      --analyze-size \
      --code-size-directory="${OUTPUT_DIR}"

    echo ""
    echo "✅ APK のサイズ分析データが出力されました:"
    echo "📁 出力先ディレクトリ: ${OUTPUT_DIR}"
    ;;

  ios|ipa)
    OUTPUT_JSON="${OUTPUT_DIR}/size_analysis_ios_${FLAVOR}_${TIMESTAMP}.json"
    echo "🔨 iOS (IPA) をビルド中 (--analyze-size)..."
    fvm flutter build ipa \
      --flavor "${FLAVOR}" \
      --target "lib/main_${FLAVOR}.dart" \
      --dart-define-from-file="${CONFIG_FILE}" \
      --analyze-size \
      --code-size-directory="${OUTPUT_DIR}"

    echo ""
    echo "✅ iOS のサイズ分析データが出力されました:"
    echo "📁 出力先ディレクトリ: ${OUTPUT_DIR}"
    ;;

  *)
    echo "❌ サポートされていないプラットフォームです: ${PLATFORM}"
    echo "💡 指定可能なプラットフォーム: android (または appbundle), apk, ios (または ipa)"
    exit 1
    ;;
esac

echo ""
echo "========================================================"
echo "📊 Flutter DevTools でサイズを可視化する手順:"
echo "1. 以下のコマンドで DevTools を起動します:"
echo "   $ fvm dart devtools"
echo "2. ブラウザで DevTools を開き、「App Size」タブを選択します。"
echo "3. 上記で生成された JSON ファイルを読み込んで分析します。"
echo "========================================================"
