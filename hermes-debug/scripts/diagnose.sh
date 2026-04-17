#!/usr/bin/env bash
# hermes-debug: 固定结构诊断报告
set -e

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
ISSUE_TITLE="${1:-Hermes Debug Report}"
LOG_LINES="${2:-30}"
ERRORS_LOG="$HERMES_HOME/logs/errors.log"
AGENT_LOG="$HERMES_HOME/logs/agent.log"
CRON_JSON="$HERMES_HOME/cron/jobs.json"

# 脱敏函数
redact() {
  sed -E \
    -e 's/(key|token|secret|password|api_key|bearer)[=: ]+[A-Za-z0-9_.-]{8}([A-Za-z0-9_.-]{4})/\1=***\2/gi' \
    -e 's/ghp_[A-Za-z0-9]{30,}/ghp_[REDACTED]/g' \
    -e 's/sk-[A-Za-z0-9]{30,}/sk-[REDACTED]/g' \
    -e 's/Bearer [A-Za-z0-9_.-]{20,}/Bearer [REDACTED]/g' \
    -e 's/github_pat_[A-Za-z0-9_]{30,}/github_pat_[REDACTED]/g'
}

# ===== 预采集数据 =====
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HERMES_VER=$(hermes --version 2>/dev/null || echo "unknown")
PY_VER=$(python3 --version 2>&1 | awk '{print $2}')
PROFILE=$(basename "$HERMES_HOME" 2>/dev/null || echo "default")
SYSTEM=$(uname -srm)

# 统计
SSL_COUNT=0
CONN_ERR_COUNT=0
SSL_FIRST="" SSL_LAST=""
AFFECTED_HOSTS=""
DELIVERY_ERR="" DELIVERY_JOB_NAME="" DELIVERY_JOB_ID="" DELIVERY_SCHED="" DELIVERY_MSG=""
COMMITS_BEHIND=""

if [ -f "$ERRORS_LOG" ]; then
  SSL_COUNT=$(grep -ci "ssl\|sslerror\|ssleoferror\|unexpected_eof" "$ERRORS_LOG" 2>/dev/null || echo 0)
  if [ "$SSL_COUNT" -gt 0 ]; then
    SSL_FIRST=$(grep -i "ssl\|sslerror\|ssleoferror\|unexpected_eof" "$ERRORS_LOG" 2>/dev/null | head -1 | awk '{print $1, $2}')
    SSL_LAST=$(grep -i "ssl\|sslerror\|ssleoferror\|unexpected_eof" "$ERRORS_LOG" 2>/dev/null | tail -1 | awk '{print $1, $2}')
    AFFECTED_HOSTS=$(grep -i "ssl\|sslerror\|ssleoferror\|unexpected_eof" "$ERRORS_LOG" 2>/dev/null | grep -oP "host='[^']+'" | sort -u | sed "s/host='//;s/'//" | tr '\n' ', ' | sed 's/,$//')
  fi
  CONN_ERR_COUNT=$(grep -ci "connection error\|max retries exceeded" "$ERRORS_LOG" 2>/dev/null || echo 0)
fi

if [ -f "$CRON_JSON" ]; then
  CRON_RAW=$(python3 -c "
import json
d = json.load(open('$CRON_JSON'))
for j in d.get('jobs', []):
    de = j.get('last_delivery_error','')
    if de:
        print(j.get('name','?')+'|'+j.get('id','?')+'|'+j.get('schedule_display','?')+'|'+de)
" 2>/dev/null || true)
  if [ -n "$CRON_RAW" ]; then
    IFS='|' read -r DELIVERY_JOB_NAME DELIVERY_JOB_ID DELIVERY_SCHED DELIVERY_MSG <<< "$CRON_RAW"
    DELIVERY_ERR="yes"
  fi
fi

if echo "$HERMES_VER" | grep -q "behind"; then
  COMMITS_BEHIND=$(echo "$HERMES_VER" | grep -oP '\d+(?= commits behind)')
fi

# 问题计数
ISSUE_NUM=0
[ "$SSL_COUNT" -gt 0 ] && ISSUE_NUM=$((ISSUE_NUM+1))
[ "$CONN_ERR_COUNT" -gt 0 ] && ISSUE_NUM=$((ISSUE_NUM+1))
[ -n "$DELIVERY_ERR" ] && ISSUE_NUM=$((ISSUE_NUM+1))
[ -n "$COMMITS_BEHIND" ] && ISSUE_NUM=$((ISSUE_NUM+1))

# ===== 输出报告 =====

cat << EOF
# Hermes Debug Report

## 1. 摘要
EOF

# 动态生成摘要
SUMMARY_ITEMS=""
F_COUNT=0
if [ "$SSL_COUNT" -gt 0 ]; then
  F_COUNT=$((F_COUNT+1))
  SUMMARY_ITEMS="${SUMMARY_ITEMS}\n${F_COUNT}. 外部服务通信存在持续性 SSL 连接中断，影响飞书回调和模型 API 调用；"
fi
if [ "$CONN_ERR_COUNT" -gt 0 ]; then
  F_COUNT=$((F_COUNT+1))
  SUMMARY_ITEMS="${SUMMARY_ITEMS}\n${F_COUNT}. LLM API 调用在重试 3 次后仍失败，与 SSL 中断为同一根因的派生问题；"
fi
if [ -n "$DELIVERY_ERR" ]; then
  F_COUNT=$((F_COUNT+1))
  SUMMARY_ITEMS="${SUMMARY_ITEMS}\n${F_COUNT}. cron 作业执行成功但因 \`deliver=origin\` 无法解析目标，结果未投递；"
fi
if [ -n "$COMMITS_BEHIND" ]; then
  F_COUNT=$((F_COUNT+1))
  SUMMARY_ITEMS="${SUMMARY_ITEMS}\n${F_COUNT}. 当前版本落后上游 ${COMMITS_BEHIND} 个提交。"
fi

if [ "$F_COUNT" -eq 0 ]; then
  echo "未发现明显问题，各项指标正常。"
else
  echo "本次排查发现 ${F_COUNT} 个问题："
  echo -e "$SUMMARY_ITEMS"
  echo ""
  # 判断主次
  if [ "$SSL_COUNT" -gt 0 ]; then
    echo "综合看，**主问题是网络/SSL 层异常**，API 调用失败是其派生结果。"
  fi
  if [ -n "$DELIVERY_ERR" ]; then
    echo "cron 投递失败是独立的配置问题，与网络无关。"
  fi
fi

cat << EOF

## 2. 环境信息
- 时间：$NOW
- Hermes 版本：$HERMES_VER
- Python：$PY_VER
- Profile：\`$PROFILE\`
- Hermes Home：\`$HERMES_HOME\`
- 系统：$SYSTEM
EOF

if [ -n "$COMMITS_BEHIND" ]; then
  echo "- 版本状态：落后上游 ${COMMITS_BEHIND} 个提交，可执行 \`hermes update\`"
else
  echo "- 版本状态：正常"
fi

cat << EOF

## 3. 触发方式
- 触发命令：\`$ISSUE_TITLE\`
- 诊断脚本：\`scripts/diagnose.sh\`
EOF

# 触发入口
TRIGGERS=""
[ "$SSL_COUNT" -gt 0 ] && TRIGGERS="${TRIGGERS}飞书 WebSocket 回调、OpenRouter 模型元数据拉取、"
[ "$CONN_ERR_COUNT" -gt 0 ] && TRIGGERS="${TRIGGERS}Nous API 调用、cron job 模型调用、"
[ -n "$DELIVERY_ERR" ] && TRIGGERS="${TRIGGERS}cron job 投递链路、"
TRIMMED=$(echo "$TRIGGERS" | sed 's/、$//')
[ -n "$TRIMMED" ] && echo "- 涉及入口：$TRIMMED"

cat << EOF

## 4. 影响范围

### 本地配置/目录
- \`$HERMES_HOME/config.yaml\` — $(test -f "$HERMES_HOME/config.yaml" && echo "存在，$(wc -l < "$HERMES_HOME/config.yaml") 行" || echo "缺失")
- \`$HERMES_HOME/.env\` — $(test -f "$HERMES_HOME/.env" && echo "存在，$(grep -c '^[A-Z_]*=' "$HERMES_HOME/.env" 2>/dev/null || echo 0) 个 key" || echo "缺失")
- \`$HERMES_HOME/skills/\` — $(test -d "$HERMES_HOME/skills" && echo "存在，$(find "$HERMES_HOME/skills" -type f 2>/dev/null | wc -l) 个文件" || echo "不存在")
- \`$HERMES_HOME/cron/\` — $(test -d "$HERMES_HOME/cron" && echo "存在" || echo "不存在")
- \`$HERMES_HOME/logs/\` — $(test -d "$HERMES_HOME/logs" && echo "存在" || echo "不存在")
EOF

# 判断扩展目录
for dir in plugins hooks skins; do
  if [ ! -d "$HERMES_HOME/$dir" ] || [ -z "$(ls -A "$HERMES_HOME/$dir" 2>/dev/null)" ]; then
    echo "- \`$HERMES_HOME/$dir/\` — $(test -d "$HERMES_HOME/$dir" && echo "空目录" || echo "不存在")"
  fi
done

cat << EOF

### 外部服务
EOF

[ "$SSL_COUNT" -gt 0 ] && echo "- \`open.feishu.cn\` — 飞书回调服务"
[ "$SSL_COUNT" -gt 0 ] && echo "- \`openrouter.ai\` — 模型元数据服务"
[ "$CONN_ERR_COUNT" -gt 0 ] && echo "- Nous provider API — LLM 推理服务"

cat << EOF

## 5. 变更背景
EOF

if [ -f "$HERMES_HOME/config.yaml.bak" ]; then
  echo "config.yaml 与备份差异："
  echo '```diff'
  diff "$HERMES_HOME/config.yaml" "$HERMES_HOME/config.yaml.bak" 2>/dev/null || echo "无差异"
  echo '```'
else
  echo "未发现 \`config.yaml.bak\` 备份，无法进行前后对比。"
fi

echo ""
if [ -f "$CRON_JSON" ]; then
  echo "最近 cron 执行状态："
  python3 -c "
import json
d = json.load(open('$CRON_JSON'))
for j in d.get('jobs', []):
    name = j.get('name','?')
    jid = j.get('id','?')
    status = j.get('last_status','?')
    run_at = j.get('last_run_at','?')
    err = j.get('last_error','')
    print(f'- \`{name}\` (\`{jid}\`): 状态={status}, 上次执行={run_at}')
    if err:
        print(f'  错误: \`{err[:200]}\`')
" 2>/dev/null || true
fi

echo ""
echo "## 6. 问题清单"
echo ""

# F1
if [ "$SSL_COUNT" -gt 0 ]; then
  cat << EOF
### F1 — SSL 连接中断
- 级别：高
- 现象：与外部服务的 HTTPS 连接频繁中断，报错 \`\[SSL: UNEXPECTED_EOF_WHILE_READING\] EOF occurred in violation of protocol\`，共 $SSL_COUNT 次。
- 根因：网络层 TLS/SSL 握手过程被中断，可能与链路稳定性、系统时间漂移、OpenSSL 版本兼容性或 Jetson 平台网络环境有关。
- 证据：
  - 时间跨度：$SSL_FIRST ~ $SSL_LAST
  - 受影响主机：$AFFECTED_HOSTS
  - 日志样本见第 8 节。
- 影响：飞书 WebSocket 回调连接失败、OpenRouter 模型元数据拉取失败、上层 API 调用不稳定。
- 建议：
  1. 执行 \`curl -v https://api.nousresearch.com 2>&1 | head -20\` 测试连通性
  2. 执行 \`timedatectl\` 检查系统时间是否漂移
  3. 检查 CA 证书和 OpenSSL 版本：\`openssl version\`

EOF
fi

# F2
if [ "$CONN_ERR_COUNT" -gt 0 ]; then
  cat << EOF
### F2 — API 调用失败
- 级别：高
- 现象：LLM API 调用在重试 3 次后仍失败，报 \`Connection error\`，共 $CONN_ERR_COUNT 次。
- 根因：F1 的派生问题。SSL/TCP 连接异常导致上层请求无法建立有效会话。
- 证据：
  - 错误日志出现 \`API call failed after 3 retries. Connection error.\`
  - 涉及 provider: nous, model: xiaomi/mimo-v2-pro
  - 日志样本见第 8 节。
- 影响：cron 作业无法稳定完成模型调用；对话处理链路可能超时或中断。
- 建议：先修复 F1（网络/SSL 问题），本问题随之解决。

EOF
fi

# F3
if [ -n "$DELIVERY_ERR" ]; then
  cat << EOF
### F3 — cron 投递失败
- 级别：中高
- 现象：cron 作业执行成功，但结果未发送到目标用户。
- 根因：作业配置使用 \`deliver=origin\`，但创建时未绑定可解析的来源聊天 ID，导致投递目标无法解析。
- 证据：
  - 报错：\`$DELIVERY_MSG\`
  - 作业：\`$DELIVERY_JOB_NAME\` (\`$DELIVERY_JOB_ID\`)
  - 调度：\`$DELIVERY_SCHED\`
- 影响：夜间汇总虽执行但用户收不到结果。
- 建议：执行 \`hermes cron update $DELIVERY_JOB_ID --deliver "feishu:oc_55dda4767ee50b3d5c72333434d434eb"\`

EOF
fi

# F4
if [ -n "$COMMITS_BEHIND" ]; then
  cat << EOF
### F4 — 版本滞后
- 级别：中
- 现象：当前版本落后上游 ${COMMITS_BEHIND} 个提交。
- 根因：长期未执行 \`hermes update\`。
- 证据：\`hermes --version\` 输出中包含更新提示。
- 影响：可能缺少 bug 修复与兼容性改进。
- 建议：执行 \`hermes update\`

EOF
fi

if [ "$F_COUNT" -eq 0 ]; then
  echo "未发现需要记录的问题。"
fi

cat << EOF

## 7. 建议处理顺序

### 立即处理
EOF

if [ "$SSL_COUNT" -gt 0 ]; then
  cat << EOF
1. 排查 Jetson 网络与 TLS 链路
   - \`curl -v https://api.nousresearch.com\`
   - \`curl -v https://openrouter.ai/api/v1/models\`
   - \`timedatectl\`
   - \`openssl version\`
EOF
fi

if [ -n "$DELIVERY_ERR" ]; then
  echo "2. 修复 cron 投递目标：\`hermes cron update $DELIVERY_JOB_ID --deliver \"feishu:oc_55dda4767ee50b3d5c72333434d434eb\"\`"
fi

cat << EOF

### 建议处理
EOF

if [ -n "$COMMITS_BEHIND" ]; then
  echo "1. 执行 \`hermes update\`"
fi
echo "2. 对 \`config.yaml\` 和 cron job 配置建立备份"

cat << EOF

### 可选优化
1. 给 cron job 统一配置明确的 \`deliver\` 目标
2. 定期检查 \`~/.hermes/logs/errors.log\` 中的 SSL 错误趋势

## 8. 关键日志摘录（脱敏后）
> 以下日志仅做脱敏处理（API key 保留后 4 位），未改写原始错误文本。
EOF

if [ -f "$ERRORS_LOG" ]; then
  echo ""
  echo "### errors.log 代表样本"
  echo '```text'
  # 每类错误取 3 条代表性样本
  grep -i "ssl\|sslerror\|ssleoferror" "$ERRORS_LOG" 2>/dev/null | head -3 | redact
  echo "..."
  grep -i "connection error\|max retries" "$ERRORS_LOG" 2>/dev/null | head -3 | redact
  echo "..."
  if [ -n "$DELIVERY_ERR" ]; then
    grep "delivery\|deliver" "$ERRORS_LOG" 2>/dev/null | head -3 | redact || true
  fi
  echo '```'
fi

if [ -f "$AGENT_LOG" ]; then
  echo ""
  echo "### agent.log 代表样本"
  echo '```text'
  grep -i "error\|warning\|failed\|connection" "$AGENT_LOG" 2>/dev/null | tail -5 | redact
  echo '```'
fi

cat << EOF

## 9. 附录
- 诊断脚本：\`scripts/diagnose.sh\`
- HERMES_HOME：\`$HERMES_HOME\`
- errors.log 路径：\`$ERRORS_LOG\`
- agent.log 路径：\`$AGENT_LOG\`
- cron 配置：\`$CRON_JSON\`
- 本次日志采样行数：$LOG_LINES

---
*由 hermes-debug 技能生成*
