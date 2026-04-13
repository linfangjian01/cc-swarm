<!-- Badges (replace URLs when repo is public) -->
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Hook-blueviolet)](#)

[English](README.md) | 中文

# cc-swarm

**Claude Code 架构师模式 — 主 agent 规划，子 agent 执行。**

cc-swarm 将 Claude Code 的主 agent 配置为纯粹的**架构师**角色：只负责规划、协调和审查。所有文件编辑、代码开发、文档编写和代码 review 均委派给**子 agent** 完成。通过 [Claude Code Hook](https://docs.anthropic.com/en/docs/claude-code/hooks) 机制在运行时拦截工具调用来强制执行此约束，agent 之间通过共享的**文件系统协议**（`claude_dev/<session_id>/` 下的 markdown 文件）进行通信。

## 工作原理

| 组件 | 作用 |
|---|---|
| **SessionStart Hook** | 自动创建 `claude_dev/<session_id>/` 通信目录，并将 `session_id` 持久化为会话环境变量。 |
| **PreToolUse Hook** | 拦截主 agent 的 `Write` / `Edit` 调用。通过 `agent_id` 区分主 agent 和子 agent — 仅允许子 agent 写入文件。 |
| **CLAUDE.md** | 全局指令，定义架构师角色、委派工作流和通信协议。 |

## 快速开始

```bash
git clone <repo-url>
cd cc-swarm
./run.sh              # English (default)
./run.sh --lang cn    # 中文
```

安装后重启 Claude Code 即生效。

## 文件通信协议

所有任务文件位于 `claude_dev/<session_id>/` 目录下：

| 文件 | 用途 |
|---|---|
| `STATUS.md` | 当前会话状态和进度概览 |
| `PLAN.md` | 架构师的高层规划 |
| `TODO.md` | 任务队列，含优先级和分配信息 |
| `task-NNN-*.md` | 分派给子 agent 的任务说明 |
| `output-NNN-*.md` | 子 agent 的交付物 / 执行结果 |
| `review-NNN-*.md` | 架构师对任务产出的审查反馈 |

## 工作流程

```
主 Agent (架构师)                子 Agent
        |                           |
        |-- 写入 task-NNN-*.md --> |
        |                      [执行任务]
        |                           |
        | <-- 写入 output-NNN-*.md |
        |                           |
   [审查产出]                       |
        |-- 写入 review-NNN-*.md ->|
        |                      [按需修改]
        ...
```

1. 架构师分析用户需求，创建 `PLAN.md` 和 `TODO.md`。
2. 架构师编写 `task-NNN-*.md` 文件并启动子 agent。
3. 子 agent 读取任务、执行开发、写入 `output-NNN-*.md`。
4. 架构师审查产出，写入 `review-NNN-*.md`（通过 / 要求修改）。
5. 重复以上流程直到所有任务完成。

## 卸载

```bash
./uninstall.sh
```

## 前置要求

- [jq](https://jqlang.github.io/jq/) -- Hook 使用的 JSON 处理器
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) -- v1.0+

## 许可证

[MIT](LICENSE)
