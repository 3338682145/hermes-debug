#!/usr/bin/env bash
# hermes-debug 一键安装脚本
set -e

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILL_DIR="$HERMES_HOME/skills/hermes-debug"
REPO_URL="https://github.com/3338682145/hermes-debug.git"

echo "正在安装 hermes-debug..."

if [ -d "$SKILL_DIR" ]; then
  echo "已存在，更新中..."
  cd "$SKILL_DIR" && git pull 2>/dev/null || {
    rm -rf "$SKILL_DIR"
    git clone "$REPO_URL" "$SKILL_DIR" --depth 1
  }
else
  git clone "$REPO_URL" "$SKILL_DIR" --depth 1
fi

chmod +x "$SKILL_DIR/scripts/"*.sh

echo "安装完成！"
echo ""
echo "使用方式："
echo "  1. 对话中说: debug 这个问题"
echo "  2. 命令行:   bash $SKILL_DIR/scripts/diagnose.sh '问题描述'"
echo ""
echo "配置（可选）："
echo "  在 ~/.hermes/.env 中添加 GITHUB_TOKEN=ghp_xxxxx"
echo "  可自动提交诊断报告到 GitHub Issue"
