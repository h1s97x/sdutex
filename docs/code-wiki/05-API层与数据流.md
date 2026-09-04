# 05 API层与数据流

> 回到 [Code Wiki 索引](./README.md) | 上一章：[04 权限体系](./04-权限体系.md)

## 1. 文档生命周期与数据流

```mermaid
flowchart TB
  subgraph CLS["类加载 \\documentclass{sduthesis}"]
    A[\\LoadClass openany ctexbook] --> B[加载 expl3 / l3keys2e]
    B --> C[声明变量 存储层]
    C --> D[注册 l3keys 定义层]
    D --> E[声明 6 个 Hook + 定义 \\IfBlindReviewTF]
    E --> F[加载字体/页面/章节/引用/图表/数学/代码基础引擎]
    F --> G[定义 \\makecoverpage 等占位命令]
    G --> H[modules/ 加入 input@path]
  end
```

```
用户代码
  ├─ \documentclass{sduthesis}
  │     → \LoadClass[openany]{ctexbook}，加载 expl3 / l3keys2e
  │     → ExplSyntaxOn 进入 LaTeX3 语法
  │     → 声明变量（存储层）、注册 l3keys（定义层）
  │     → 声明 6 个 Hook、定义 \IfBlindReviewTF 等
  │     → 加载字体/页面/章节/引用/图表/数学/代码等基础引擎
  │     → 定义 \makecoverpage 等占位命令（模块可覆盖）
  │     → 若 modules/ 存在则把 modules/ 加入 \input@path
  │
  ├─ \SDUSetup{ module={...}, info={...}, option={...} }
  │     → \keys_set:nn { sdu } { ... }，info/option 为 .code:n 代理键
  │     → 递归 \keys_set:nn { sdu/info } / { sdu/option }，写入 \l__sdu_* 变量
  │
  ├─ \begin{document}
  │     → \AddToHook{begindocument}：
  │       ① \sdu_load_module:（拆分模块→盲审回退→逐个 \RequirePackage）
  │       ② \UseHook{sduthesis/after-setup}
  │
  ├─ \frontmatter / \makecoverpage / \maketable
  │     → \UseHook{sduthesis/before-cover}、{cover-style}、{frontmatter/begin}
  │     → \makecoverpage 由模块 \renewcommand 覆盖为真实排版
  │
  ├─ \mainmatter / \backmatter
  │     → \UseHook{sduthesis/mainmatter/begin} / {backmatter/begin}，切换页眉页脚等
```

---

## 2. 数据流要点

- **配置数据路径**：`\SDUSetup{...}` → `\keys_set:nn { sdu } {...}` → 代理键分发到 `sdu/info`、`sdu/option` 递归求值 → 写入 `\l__sdu_*` 存储层变量 → 由 Getter 命令族（`\GetTitle` 等）在文档中消费。键值与变量映射见 [03 配置系统与数据模型](./03-配置系统与数据模型.md)。
- **模块加载数据流**：`module` 值 → 逗号拆分 `\l__sdu_module_seq` → 预扫描（是否含 `blindreview` / 基础模块）→ 盲审回退 → 按序 `\RequirePackage{sduthesis-<name>}`（执行过程见 [02 目录结构与模块职责](./02-目录结构与模块职责.md) 2.1.2 节）。
- **Hook 触发数据流**：内核在各文档阶段 `\UseHook{sduthesis/xx}`，模块与用户通过 `\AddToHook{sduthesis/xx}{...}` 注入行为，实现"内核定时触发、外层按需挂接"的解耦。

---

## 3. 公开 API 一览

用户可调用的主要 API（完整清单见 [06 关键函数与命令](./06-关键函数与命令.md)）：

- 配置入口：`\SDUSetup{...}`
- 页面命令：`\makecoverpage` / `\makestatement` / `\makecommittee` / `\maketable`
- 引用与常量：`\equref` / `\tabref` / `\figref` / `\subfigref`、`\citex` / `\citing`、`\mye` / `\myi` / `\myj`
- 中文字体：`\song` / `\hei` / `\kai` 及 bf/it 变体