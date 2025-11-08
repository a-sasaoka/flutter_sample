#!/bin/bash

# ============================================
# Flutter Sample Project 初期構成セットアップスクリプト
# ============================================

echo "📁 Flutterディレクトリ構成を作成中..."

# --- メイン構造 ---
mkdir -p lib/src/{core/{config,router,exceptions,utils,widgets},data/{models,repository,datasource},features/sample_feature/{presentation,application,domain,data}}

# --- 各ディレクトリに .gitkeep を追加 ---
find lib/src -type d -exec touch {}/.gitkeep \;

echo "✅ ディレクトリと .gitkeep ファイルの作成が完了しました！"
echo ""
echo "作成された構成:"
tree lib/src