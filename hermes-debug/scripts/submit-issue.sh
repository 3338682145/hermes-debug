#!/usr/bin/env bash
# submit-issue.sh: 运行诊断 -> 提交到 GitHub Issue
# 用法: bash submit-issue.sh [问题描述] [GitHub Token]
set -e

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_REPO="${HERMES_DEBUG_REPO:-3338682145/hermes-debug}"
GITHUB_TOKEN="${2:-${GITHUB_TOKEN:-}}"

ISSUE_TITLE="${1:-Hermes Debug Report}"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "需要 GitHub Token"
  echo "用法: bash submit-issue.sh '问题描述' ghp_xxxxx"
  echo "或设置环境变量: export GITHUB_TOKEN=ghp_xxxxx"
  exit 1
fi

echo "正在运行诊断..."
echo ""

REPORT=$(bash "$SKILL_DIR/scripts/diagnose.sh" "$ISSUE_TITLE" 2>&1)

echo "$REPORT"
echo ""

BODY=$(cat <<EOF
$REPORT
EOF
)

BODY_ESCAPED=$(echo "$BODY" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

echo "正在提交到 https://github.com/$TARGET_REPO/issues ..."

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "{\"title\": \"[Debug]: $ISSUE_TITLE\", \"body\": $BODY_ESCAPED, \"labels\": [\"bug\"]}" \
  "https://api.github.com/repos/$TARGET_REPO/issues")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY_RESP=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
  ISSUE_URL=$(echo "$BODY_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['html_url'])")
  ISSUE_NUM=$(echo "$BODY_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['number'])")
  echo "Issue 创建成功!"
  echo "  #$ISSUE_NUM: $ISSUE_URL"
else
  echo "提交失败 (HTTP $HTTP_CODE)"
  echo "$BODY_RESP" | python3 -m json.tool 2>/dev/null || echo "$BODY_RESP"
  exit 1
fi
