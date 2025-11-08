#!/bin/bash
# ===============================================
# Setup repository to use version-controlled hooks
# ===============================================

set -euo pipefail

# Gitに「hooksは tool/hooks を見てね」と設定
git config core.hooksPath tool/hooks

# 念のため実行権限を付与
chmod +x tool/hooks/* || true

echo "✅ Set core.hooksPath to tool/hooks"
echo "   Git hooks are now shared via the repository."