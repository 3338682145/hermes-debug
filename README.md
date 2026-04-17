# hermes-debug

Hermes Agent 专用调试技能 — 自动诊断 ~/.hermes/ 目录，生成包含问题现象/根因/证据/影响/建议的结构化报告。

## 安装

```bash
hermes skills install 3338682145/hermes-debug/hermes-debug
```

或手动：

```bash
git clone https://github.com/3338682145/hermes-debug.git
cp -r hermes-debug/hermes-debug ~/.hermes/skills/
chmod +x ~/.hermes/skills/hermes-debug/scripts/*.sh
```

## 使用

### 对话中

说 "debug 这个问题"，agent 会：

1. 运行诊断，输出完整报告供你查看
2. 询问是否提交到 GitHub Issue
3. 你确认后才上传，不确认则仅保留本地

### 命令行

```bash
# 仅诊断
bash ~/.hermes/skills/hermes-debug/scripts/diagnose.sh "问题描述"

# 诊断 + 提交
bash ~/.hermes/skills/hermes-debug/scripts/submit-issue.sh "问题描述" ghp_xxxxx
```

## 配置

在 ~/.hermes/.env 中添加：

```
HERMES_DEBUG_REPO=owner/repo
GITHUB_TOKEN=ghp_xxxxx
```
hermes可以先使用GITHUB_TOKEN=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
⚠️ **注意：此方式一个月后失效**

如果你希望自行提交需求，为 Hermes Agent 增加更多 TTS 语音合成服务商支持（例如 Minimax TTS），请按以下步骤获取 Token 并发送给 Hermes。

## Token 获取步骤
1. 打开网址：https://github.com/settings/tokens
2. 点击 **Generate new token (classic)**

### 经典 Token（Classic token）
- 仅勾选 **public_repo** 即可（仅用于向公开仓库提交 Issue，权限已足够）

### 细粒度 Token（Fine-grained token）
- Repository access：选择 **Only select repositories** → 选中 `NousResearch/hermes-agent`
- Permissions → **Issues** → 设置为 **Read and Write**
- 其余权限无需勾选

3. 复制生成的 Token 发送给 Hermes


## 报告结构

1. 摘要 — 问题数量 + 主次判断
2. 环境信息 — 版本/Python/Profile/系统
3. 触发方式 — 触发命令 + 涉及入口
4. 影响范围 — 本地目录 + 外部服务
5. 变更背景 — 配置差异/cron 状态
6. 问题清单 — F1/F2/F3，每条含 现象/根因/证据/影响/建议
7. 建议处理顺序 — 立即处理 / 建议处理 / 可选优化
8. 关键日志摘录 — 脱敏后的代表样本
9. 附录 — 路径/脚本/采样参数

## 兼容性

- Hermes >= 0.8.0
- Python >= 3.9
- 系统：Linux / macOS / Jetson
- 依赖：bash, sed, grep, curl, python3

  
##加入社区

![feishu](feishu.png)

## 许可证

MIT
