# hermes-debug

Hermes Agent 专用调试技能 — 自动诊断 `~/.hermes/` 目录，生成包含问题现象/根因/证据/影响/建议的结构化报告。

## 安装方式

### 方式一：hermes skills install（推荐）

```bash
hermes skills install 3338682145/hermes-debug/hermes-debug
```

### 方式二：手动安装

```bash
# 克隆仓库
git clone https://github.com/3338682145/hermes-debug.git

# 复制到 skills 目录
cp -r hermes-debug/hermes-debug ~/.hermes/skills/

# 设置脚本权限
chmod +x ~/.hermes/skills/hermes-debug/scripts/*.sh
```

### 方式三：curl 一键安装

```bash
curl -sL https://raw.githubusercontent.com/3338682145/hermes-debug/main/install.sh | bash
```

## 使用方法

### 在对话中使用

直接说以下任意一句，agent 会自动执行诊断：

- "debug 这个问题"
- "hermes debug"
- "调试 hermes"

### 命令行使用

```bash
# 仅诊断
bash ~/.hermes/skills/hermes-debug/scripts/diagnose.sh "问题描述"

# 诊断 + 提交到 GitHub Issue
bash ~/.hermes/skills/hermes-debug/scripts/submit-issue.sh "问题描述" ghp_xxxxx
```

## 配置

在 `~/.hermes/.env` 中添加：

```bash
# GitHub Issue 目标仓库（默认: 3338682145/hermes-debug）
HERMES_DEBUG_REPO=owner/repo

# GitHub Token（用于提交 Issue）
GITHUB_TOKEN=ghp_xxxxx
```

## 报告示例

```markdown
# Hermes Debug Report

## 1. 摘要
本次排查发现 3 个问题：
1. 外部服务通信存在持续性 SSL 连接中断；
2. cron 作业因 deliver=origin 无法解析目标，结果未投递；
3. 当前版本落后上游 86 个提交。

## 6. 问题清单

### F1 — SSL 连接中断
- 级别：高
- 现象：HTTPS 连接频繁中断，共 55 次
- 根因：网络层 TLS 握手被中断
- 证据：open.feishu.cn 和 openrouter.ai 均受影响
- 影响：飞书回调失败、模型元数据拉取失败
- 建议：curl -v https://api.nousresearch.com 测试连通性
```

## 兼容性

| 项目 | 要求 |
|------|------|
| Hermes | >= 0.8.0 |
| Python | >= 3.9 |
| 系统 | Linux / macOS / Jetson |
| 依赖 | bash, sed, grep, curl, python3 |

## 许可证

MIT
