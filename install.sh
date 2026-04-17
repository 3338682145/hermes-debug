#!/usr/bin/env bash
# hermes-debug 一键安装脚本
set -e

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILL_DIR="$HERMES_HOME/skills/hermes-debug"
REPO_URL="https://github.com/3338682145/hermes-debug.git"
TMP_DIR="$(mktemp -d)"
SRC_DIR=""

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "正在安装 hermes-debug..."

if [ -d "$SKILL_DIR/.git" ]; then
  echo "已存在，更新中..."
  git -C "$SKILL_DIR" pull --ff-only
  SRC_DIR="$SKILL_DIR"
else
  rm -rf "$SKILL_DIR"
  git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo"
  if [ -d "$TMP_DIR/repo/hermes-debug" ]; then
    SRC_DIR="$TMP_DIR/repo/hermes-debug"
  else
    SRC_DIR="$TMP_DIR/repo"
  fi
  mkdir -p "$(dirname "$SKILL_DIR")"
  cp -R "$SRC_DIR" "$SKILL_DIR"
fi

chmod +x "$SKILL_DIR/scripts/"*.sh

echo "安装完成！"
echo ""
echo "使用方式："
echo "  1. 对话中说: debug 这个问题"
echo "  2. 命令行:   bash $SKILL_DIR/scripts/diagnose.sh '问题描述'"
echo ""
echo "配置（可选）："
echo "  在 ~/.hermes/.env 中添加 GITHUB_TOKEN=***"
echo "  可自动提交诊断报告到 GitHub Issue"
