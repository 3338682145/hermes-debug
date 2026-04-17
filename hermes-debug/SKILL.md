---
name: hermes-debug
description: Hermes 专用调试技能 — 自动诊断 ~/.hermes/ 目录，生成包含问题现象/根因/证据/影响/建议的结构化报告，支持提交到 GitHub Issue。
version: 1.1.0
author: Video Agent
license: MIT
metadata:
  hermes:
    tags: [debugging, hermes, troubleshooting, diagnostics, config, plugins, cron]
    related_skills: [systematic-debugging, hermes-agent]
    min_version: "0.8.0"
---

# hermes-debug

## 功能

Hermes Agent 专用调试技能，提供：

1. **自动诊断** — 扫描 `~/.hermes/` 全部配置、扩展目录、日志
2. **问题分析** — 每个问题自动生成：现象、根因、证据、影响、建议
3. **日志脱敏** — 自动脱敏 API key、token、密码
4. **提交 Issue** — 诊断报告自动提交到指定 GitHub 仓库
5. **跨版本兼容** — 不依赖 Hermes 源码，纯 shell + sed 实现

## 触发条件

当用户说以下任意表达时触发：
- "debug 这个问题"
- "hermes debug"
- "调试 hermes"
- "/debug"

## 安装

```bash
# 从 GitHub 安装
hermes skills install 3338682145/hermes-debug/hermes-debug

# 或手动克隆
git clone https://github.com/3338682145/hermes-debug.git
cp -r hermes-debug/hermes-debug ~/.hermes/skills/
```

## 配置

在 `~/.hermes/.env` 中添加（可选）：

```bash
# GitHub Issue 目标仓库（默认: 3338682145/hermes-debug）
HERMES_DEBUG_REPO=owner/repo

# GitHub Token（用于提交 Issue）
GITHUB_TOKEN=ghp_xxxxx
```

## 使用

### 诊断（输出到终端/聊天）

```bash
bash ~/.hermes/skills/hermes-debug/scripts/diagnose.sh "问题描述"
```

### 诊断 + 提交到 GitHub Issue

```bash
bash ~/.hermes/skills/hermes-debug/scripts/submit-issue.sh "问题描述" ghp_xxxxx
```

### 作为 agent 技能使用

在对话中说 "debug 这个问题"，agent 会自动：
1. 调用 `diagnose.sh` 生成报告
2. 用 `submit-issue.sh` 提交到 GitHub

## 报告结构

```
1. 摘要 — 问题数量 + 主次判断
2. 环境信息 — 版本/Python/Profile/系统
3. 触发方式 — 触发命令 + 涉及入口
4. 影响范围 — 本地目录 + 外部服务
5. 变更背景 — 配置差异/cron 状态
6. 问题清单 — F1/F2/F3... 每条含 现象/根因/证据/影响/建议
7. 建议处理顺序 — 立即处理 / 建议处理 / 可选优化
8. 关键日志摘录 — 每类错误 3 条代表样本（已脱敏）
9. 附录 — 路径/脚本/采样参数
```

## 脱敏规则

- API key：保留后 4 位（`***xxxx`）
- `ghp_xxx` → `ghp_[REDACTED]`
- `sk-xxx` → `sk-[REDACTED]`
- `Bearer xxx` → `Bearer [REDACTED]`
- `github_pat_xxx` → `github_pat_[REDACTED]`

## 兼容性

- Hermes >= 0.8.0
- Python >= 3.9
- 依赖：bash, sed, grep, curl, python3（均为系统自带）
- 不依赖 Hermes 源码或 venv
- 支持所有平台：Linux, macOS, Jetson

## 目录结构

```
hermes-debug/
├── SKILL.md                 # 技能定义
├── README.md                # 安装说明
├── LICENSE                  # MIT
└── scripts/
    ├── diagnose.sh          # 诊断脚本
    └── submit-issue.sh      # 诊断 + 提交 Issue
```
