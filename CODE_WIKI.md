# SDUTeX 项目 Code Wiki

> 山东大学 LaTeX 论文模板核心包 | Shandong University LaTeX Thesis Template Core Package
>
> 版本：v2.2.0 | 最后更新：2026-08-18 | 本 Wiki 依据仓库当前源码实况编写，与示例模板仓库 sduthesis v2.2.0 架构对齐

---

## 目录

1. [项目概述](#1-项目概述)
2. [整体架构](#2-整体架构)
3. [目录结构](#3-目录结构)
4. [核心模块详解](#4-核心模块详解)
5. [插件化架构：内核 + 模块 + Hook](#5-插件化架构内核--模块--hook)
6. [配置系统](#6-配置系统)
7. [核心变量与命名约定](#7-核心变量与命名约定)
8. [关键函数与命令](#8-关键函数与命令)
9. [依赖关系图](#9-依赖关系图)
10. [构建系统](#10-构建系统)
11. [测试体系](#11-测试体系)
12. [CI/CD 与双仓同步](#12-cicd-与双仓同步)
13. [项目运行方式](#13-项目运行方式)
14. [版本管理与发布](#14-版本管理与发布)
15. [设计决策与权衡](#15-设计决策与权衡)
16. [开发指南与最佳实践](#16-开发指南与最佳实践)
17. [常见问题 FAQ](#17-常见问题-faq)

---

## 1. 项目概述

### 1.1 项目简介

**SDUTeX** 是山东大学学位论文 LaTeX 模板的**核心代码仓库（引擎）**。它提供一套符合山东大学学位论文格式规范的 LaTeX 工具集，支持本科、硕士学位论文（博士学位论文通过 `degree={博士}` 键复用 master 模块），支持中英文双语写作和盲审模式。

配套的 **sduthesis** 是面向用户的示例模板仓库（开箱即用）。本仓库是"引擎"，两者构成"核心包 → 示例模板"的单一真源关系，v2.2.0 起已把 sduthesis 成熟架构同步回本仓库，消除双仓库漂移。

### 1.2 核心产物

| 产物文件 | 类型 | 说明 |
|---------|------|------|
| `sduthesis.cls` | Document Class | 学位论文文档类（核心引擎），由 DTX 解包生成 |
| `sdutex.sty` | Style Package | 独立工具宏包（数学 / 浮动体 / 格式工具） |
| `sduthesis.bst` | BibTeX Style | GB/T 7714-2015 参考文献样式（传统工程兜底） |
| `sduthesis-common.sty` | Module | 公共模块（封面命令 + 摘要环境，消除组合加载冲突） |
| `sduthesis-undergraduate.sty` | Module | 本科毕业论文模块 |
| `sduthesis-master.sty` | Module | 硕士学位论文模块（含博士，`degree` 键覆盖） |
| `sduthesis-blindreview.sty` | Module | 盲审模式模块（叠加层） |

> 注：v2.2.0 起不再维护独立 `doctor` 模块，博士学位统一由 `master` 模块 + `degree={博士}` 覆盖。

### 1.3 技术栈

| 分类 | 技术 |
|------|------|
| 语言 | LaTeX3 (expl3)、TeX、BibTeX |
| 构建 | l3build (Lua)、GNU Make |
| 源码格式 | DTX（Documented LaTeX Sources），`sduthesis.ins` 用 DocStrip 解包 |
| 编译引擎 | XeLaTeX（测试/手册仅 XeTeX；LuaLaTeX 不再纳入回归） |
| 基础类 | ctexbook（中文书籍类，`openany`） |
| CI/CD | GitHub Actions + CNB（双向同步） |

### 1.4 关键特性

- ✅ 多学位支持：本科、硕士（博士通过 `degree` 键）
- ✅ 中英文支持：中文论文 + 英文摘要
- ✅ 盲审模式：隐藏作者/学号/导师等个人信息，跳过声明页与答辩委员会页
- ✅ 插件化架构：内核 + 模块 + Hook，支持组合加载（`module={master, blindreview}`）
- ✅ `\SDUSetup` 集中配置：基于 l3keys，支持 `info`/`option` 嵌套分组 + 顶层平铺兼容
- ✅ 参考文献：biblatex/biber（GB/T 7714-2015）；`.bst` 兜底
- ✅ 完善的 l3build `.tex/.tlg` 回归测试（XeTeX 引擎）

---

## 2. 整体架构

### 2.1 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                    用户层 (User Layer)                    │
│  \documentclass{sduthesis}  \SDUSetup{...}                │
│  \makecoverpage  \begin{cnabstract}  \GetTitle  ...       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   模块层 (Module Layer)                   │
│  common / undergraduate / master / blindreview .sty      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    内核 (Core Engine)                    │
│  \SDUSetup 引擎 (l3keys) · 6 个命名 Hook                 │
│  模块加载器 (\input@path + \sdu_load_module:)             │
│  变量系统 · 基础排版引擎（字体/页面/章节/图表/数学/代码）  │
└─────────────────────────────────────────────────────────┘
```

> 内核只负责引擎、Hook 与基础排版；学位类型逻辑（封面 / 摘要 / 页眉页脚）由模块承载。公共实现抽取到 `common` 模块，避免多模块组合加载时重定义冲突。

### 2.2 文档生命周期与数据流

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

## 3. 目录结构

```
/workspace
├── .cnb/                         # CNB 流水线 Web 触发器
│   └── web_trigger.yml
├── .github/                      # GitHub 项目配置
│   ├── ISSUE_TEMPLATE/           # Issue 模板 (bug_report / feature_request)
│   ├── workflows/
│   │   ├── test.yml              # 测试流水线（push/PR，l3build check）
│   │   ├── release.yml           # 发布流水线（v* tag）
│   │   └── sync-cnb.yml          # GitHub → CNB 反向同步
│   ├── CODEOWNERS                # 代码所有者
│   ├── PULL_REQUEST_TEMPLATE.md  # PR 模板
│   └── tl_packages               # TeX Live 包清单（CI 用）
├── doc/                          # 开发者文档
│   ├── ARCHITECTURE.md           # 架构设计
│   ├── DEVELOP.md                # 开发者指南
│   ├── INTERNALS.md              # 内部实现
│   └── README.md                 # 项目概述
├── figures/
│   └── logos/sdu_title.png       # 封面标题横幅（用户模板的图表目录）
├── modules/                      # 学位模块（插件化）
│   ├── sduthesis-common.sty          # 公共模块（封面命令 + 摘要环境）
│   ├── sduthesis-undergraduate.sty   # 本科模块
│   ├── sduthesis-master.sty          # 硕士模块（含博士）
│   └── sduthesis-blindreview.sty     # 盲审模块
├── src/                          # 核心源码
│   ├── sdutex.sty                # 工具宏包
│   ├── sduthesis.bst             # BibTeX 参考文献样式（兜底）
│   ├── sduthesis.dtx             # 主文档类（DTX 格式，核心）
│   └── sduthesis.ins             # DocStrip 安装脚本
├── test/                         # l3build 回归测试（.tex/.tlg）
│   ├── README.md                 # 测试索引
│   ├── support/setup-test.tex    # 测试公共配置
│   ├── cover / abstract / appendix / toc / bib
│   ├── blindreview / master / master-blindreview
│   └── nested-setup.tex、smoke.tex（均被排除在回归外）
├── .cnb.yml                      # CNB 流水线配置（CNB → GitHub + 发布/分配）
├── .gitignore
├── CHANGELOG.md                  # 变更日志（Keep a Changelog）
├── LICENSE                       # LPPL-1.3c
├── Makefile                      # Make 构建脚本
├── build.lua                     # l3build 配置
├── README.md                     # 项目主 README
└── CODE_WIKI.md                  # 本文档
```

---

## 4. 核心模块详解

### 4.1 内核 `sduthesis.dtx`

**文件**：[sduthesis.dtx](file:///workspace/src/sduthesis.dtx)

整个项目的核心文件，采用 **DTX** 格式（代码与文档合一）。文件头部是 `%<*driver>`…`</driver>` 文档驱动（用 `l3doc` + `ctex` 排版 PDF 手册），可抽取代码块用 `%<*cls>`…`%</cls>` 包裹。`[sduthesis.ins](file:///workspace/src/sduthesis.ins)` 调用 DocStrip 抽取 `cls` 守卫段生成 `sduthesis.cls`：

```tex
\generate{\file{sduthesis.cls}{\from{sduthesis.dtx}{cls}}}
```

#### 4.1.1 代码结构分区

| 区块 | 内容 | 关键实现 |
|------|------|---------|
| 文档类声明 | `\NeedsTeXFormat` / `\ProvidesClass` | `\LoadClass[openany]{ctexbook}` |
| LaTeX3 引擎 | 加载 expl3 / l3keys2e | `\ExplSyntaxOn` |
| 存储层 | 变量声明 | `\l__sdu_*_tl` / `_dim` / `_seq` / `_bool` |
| 定义层 | l3keys 键注册 | `sdu/info`、`sdu/option`、`sdu` 顶层 |
| 命令层 | `\SDUSetup` | `\keys_set:nn { sdu } { #1 }` |
| 导出层 | Getter 命令族 | `\GetTitle`…`\GetDefensePlace` |
| 模块加载器 | `\input@path` 注入 + `\sdu_load_module:` | 盲审回退逻辑 |
| Hook 系统 | 6 个命名 Hook | `\NewHook` / `\AddToHook` / `\UseHook` |
| 盲审标志命令 | `\IfBlindReviewTF/F` | `\bool_if:NTF \l__sdu_blindreview_bool` |
| 宏包加载 | biblatex/amsmath/xeCJK/geometry 等 24+ 个 | — |
| 字体引擎 | Fandol 宋/黑/楷 | `\song` `\hei` `\kai` 及加粗/斜体族 |
| 排版引擎 | 页面/章节/引用/图表/数学/代码 | `\ctexset`、`\captionsetup`、`\lstset` |
| 占位命令 | `\makecoverpage` 等空实现 | 模块 `\renewcommand` 覆盖 |
| 通用环境 | `\printbib` `myacknowledgement` `myappendix` `\maketable` | — |

#### 4.1.2 模块加载器（含盲审回退）

内核在 `\ExplSyntaxOn` 外通过 `\IfFileExists{modules/...}` 把 `modules/` 目录追加到 `\input@path`，使 `\RequirePackage` 能搜到模块文件。真正的加载在 `\sdu_load_module:` 完成（[dtx L651](file:///workspace/src/sduthesis.dtx#L651-L687)）：

1. 用逗号拆分 `\l__sdu_module_tl` → `\l__sdu_module_seq`
2. 预扫描：是否有 `blindreview`？是否有基础模块（`undergraduate`/`master`）？
3. **盲审回退**：含 `blindreview` 但无基础模块时，前置 `\RequirePackage{sduthesis-undergraduate}`
4. 按用户顺序，对每个非空项 `\RequirePackage{sduthesis-<name>}`

模块未找到时通过 `\msg_new:nnn { sdu } { module-not-found }` 报错。

#### 4.1.3 字体引擎

先 `\let\songti\relax` 释放 ctex 预定义命令，再用 Fandol 重新定义可导出中文字体命令：

- 单字符命令：`\song{}\hei{}\kai{}`、加粗 `\bfsong{}\bfhei{}\bfkai{}`、斜体 `\itsong{}`…、加粗斜体 `\bfitsong{}`…
- 开关命令：`\allbfsong`、`\allbfhei`、`\allbfkai`、`\allitsong` 等

默认正文为 `\zihao{-4}\songti`（小四宋体），行距 `\setstretch{1.5}`。

#### 4.1.4 占位命令

内核提供以下空实现，模块加载后 `\renewcommand` 覆盖（dtx L994-L1037）：

| 占位 | 说明 | 真正实现者 |
|------|------|-----------|
| `\makecoverpage` | 封面 | undergraduate / master |
| `\makestatement` | 声明页 | blindreview 覆盖为空（跳过） |
| `\makecommittee` | 答辩委员会页 | master（盲审时整页跳过） |
| `cnabstract` / `enabstract` | 中英摘要 | common |
| `\cnkeywords` / `\enkeywords` | 中英关键词 | common |

#### 4.1.5 通用环境/命令

- `\printbib`：新建页 + `\printbibliography[heading=none]`，`\bibfont` 五号
- `myacknowledgement`：致谢环境（`\chapter*{致\quad 谢}` + 目录项）
- `myappendix`：附录环境（`\appendix` 切换章节编号，重定义 equation/table/figure 编号为 `\thechapter.\arabic{...}`）
- `\maketable`：目录，罗马页码 + `\bookmark[dest=tableofcontent]` 书签
- 引用快捷命令：`\equref` / `\tabref` / `\figref` / `\subfigref`；`\let\citing\supercite`、`\let\citex\citep`
- 数学常量：`\mye` `\myi` `\myj`

### 4.2 工具宏包 `sdutex.sty`

**文件**：[sdutex.sty](file:///workspace/src/sdutex.sty)

独立于文档类的辅助宏包，通过选项按需加载：`\usepackage[math,float,format]{sdutex}` 或 `[all]` / `[none]`。

| 选项 | 变量（bool） | 默认 | 说明 |
|------|-------------|------|------|
| `math` | `\g__sdut_math_bool` | true | 数学符号与定理工具 |
| `float` | `\g__sdut_float_bool` | true | 浮动体间距与子图兼容 |
| `format` | `\g__sdut_format_bool` | true | 排版格式工具（间距/列表） |
| `all` / `none` | - | - | 全部启用 / 全部禁用 |

工具函数：`\sdut_if_empty:nTF`、`\sdut_if_odd:nTF`、`\sdut_safe_width:n`、`\sdut_length:nn`；版本常量 `\c__sdut_version_tl`（1.0.0）`\c__sdut_date_tl`。

### 4.3 参考文献样式 `sduthesis.bst`

**文件**：[sduthesis.bst](file:///workspace/src/sduthesis.bst)

实现 GB/T 7714-2015 的 BibTeX 样式，作为传统 LaTeX 工程（无 biblatex/biber）时的兜底。主路径使用 biblatex（`backend=biber, style=gb7714-2015, gbnamefmt=givenahead`，见 [dtx L748](file:///workspace/src/sduthesis.dtx#L748-L752)）。

### 4.4 模块系统 `modules/`

模块通过 `\AddToHook` 在文档阶段注入行为、通过 `\renewcommand` 覆盖内核占位命令。

#### 4.4.1 公共模块 `sduthesis-common.sty`

**文件**：[sduthesis-common.sty](file:///workspace/modules/sduthesis-common.sty)

**职责**：提供 `undergraduate`/`master` 组合加载时的公共实现，消除重定义冲突。

- 封面命令（用 `\providecommand` 守卫，仅首次生效）：
  - `\Lwidth`(2.3cm)、`\Rwidth`(5.5cm)、`\titlewidth`(0.9\textwidth)
  - `\Lcolumn{标签}`、`\Rcolumn{值}`
- 摘要环境（用 `\renewenvironment` / `\renewcommand`）：
  - `cnabstract`（标题 "摘 要"）/ `enabstract`（标题 ABSTRACT）
  - `\cnkeywords{}` / `\enkeywords{}`

> 背景：`master` 与 `undergraduate` 原先各自定义这些命令/环境，`module={master,undergraduate}` 组合加载时触发 "already defined" 冲突；抽到 common 后用守卫解决。

#### 4.4.2 本科模块 `sduthesis-undergraduate.sty`

**文件**：[sduthesis-undergraduate.sty](file:///workspace/modules/sduthesis-undergraduate.sty)

**职责**：本科封面、页眉页脚。

- 加载：`\RequirePackage{sduthesis-common}`
- 封面 `\makecoverpage`：校徽 `sdu_logo_2.pdf` + 标题横幅 `sdu_title.png` + "论文（设计）题目：" + 信息表格（姓名/学号/学院/专业/指导教师，前两项与指导教师用 `\IfBlindReviewF` 包裹）+ 底部年份/月份
- Hook 注入：
  - `frontmatter/begin`：`\pagestyle{empty}`
  - `mainmatter/begin`：页眉 "山东大学本科毕业论文（设计）" + 页脚页码 + `\linespread{1.3}`
  - `backmatter/begin`：不编号章标题、小二号

#### 4.4.3 硕士模块 `sduthesis-master.sty`

**文件**：[sduthesis-master.sty](file:///workspace/modules/sduthesis-master.sty)

**职责**：硕博封面、答辩委员会页、页眉页脚。

- 新增配置键：`degree`、`committeeChair`、`committeeMembers`、`defenseDate`、`defensePlace`（键在**内核** sdu/info 注册 + 对应 Getter）
- 封面：学位类型行始终显示，姓名/学号/指导教师用 `\IfBlindReviewF{}` 隐藏
- `\makecommittee`：答辩委员会页（主席/委员/答辩日期/答辩地点），外层 `\IfBlindReviewF{...}`，盲审时整页跳过
- 页眉 "山东大学硕士学位论文"，页脚页码，正文 `\linespread{1.3}`

#### 4.4.4 盲审模块 `sduthesis-blindreview.sty`

**文件**：[sduthesis-blindreview.sty](file:///workspace/modules/sduthesis-blindreview.sty)

**机制**（叠加层，需与基础模块组合使用）：

1. 置盲审标志 `\l__sdu_blindreview_bool` 为真（`\bool_set_true:N`）
2. 用 **`\renewcommand`**（而非 `\RenewDocumentCommand`）覆盖 Getter：`\GetAuthor` `\GetStudentId` `\GetSupervisor` `\GetCommitteeChair` `\GetCommitteeMembers` → `***`
   > 原因：回归测试的 `\ASSERT` 内部用 `\edef` 比较展开值，而 xparse 命令不可 `\edef` 展开；`\renewcommand` 后退化为普通宏可直接展开。与 sduthesis 仓库一致。
3. 跳过声明页：`\renewcommand{\makestatement}{}`
4. 跳过答辩委员会页：`\renewcommand{\makecommittee}{}`

> 单独使用（`module={blindreview}`）时，内核加载器自动前置加载本科模块，此处不再重复。

---

## 5. 插件化架构：内核 + 模块 + Hook

### 5.1 与模块组合加载顺序

`module` 键支持逗号分隔，`\sdu_load_module:` 按顺序加载。模块文件命名 `sduthesis-<name>.sty`，包名由 `sduthesis-` + 模块名拼接后 `\RequirePackage`。

### 5.2 六个命名 Hook

| Hook 名称 | 触发时机 | 典型用途 |
|----------|---------|----------|
| `sduthesis/after-setup` | `\SDUSetup` 处理完、begindocument | 配置后初始化 |
| `sduthesis/before-cover` | 封面生成前 | 盲审预处理等 |
| `sduthesis/cover-style` | 封面样式注入 | 封面版式 |
| `sduthesis/frontmatter/begin` | 前言开始 | 空白页眉页脚 |
| `sduthesis/mainmatter/begin` | 正文开始 | 正文页眉页脚切换 |
| `sduthesis/backmatter/begin` | 后记开始 | 参考文献/致谢/附录样式 |

触发方式：内核在对应阶段调用 `\UseHook{sduthesis/xx}`；模块/用户用 `\AddToHook{sduthesis/xx}{...}` 注册。定义见 [dtx L694](file:///workspace/src/sduthesis.dtx#L694-L699)。

### 5.3 组合加载示例

```latex
\SDUSetup{ module = {master, blindreview}, ... }   % 硕士 + 盲审
\SDUSetup{ module = {master}, info = { degree = {博士}, ... } }  % 博士
\SDUSetup{ module = {blindreview} }                % 仅盲审（自动前置本科）
```

---

## 6. 配置系统

统一通过 `\SDUSetup{...}`（`\NewDocumentCommand \SDUSetup { m }`）完成，内部调用 `\keys_set:nn { sdu } { #1 }`。支持 `info` / `option` 嵌套分组（代理键 `.code:n`）与顶层平铺两种写法，可混用。

### 6.1 键值总览（内核 sdu/info、sdu/option、sdu）

**`info` 分组键**（论文元数据 + 学位信息）：

| 键 | 对应变量 | 默认 | 说明 |
|----|---------|------|------|
| `title` | `\l__sdu_title_tl` | - | 论文标题 |
| `author` | `\l__sdu_author_tl` | - | 作者 |
| `studentId` | `\l__sdu_studentid_tl` | - | 学号 |
| `school` | `\l__sdu_school_tl` | - | 学院 |
| `major` | `\l__sdu_major_tl` | - | 专业 |
| `supervisor` | `\l__sdu_supervisor_tl` | - | 指导教师 |
| `year` / `month` | `\l__sdu_year_tl` / `\l__sdu_month_tl` | - | 年份/月份 |
| `degree` | `\l__sdu_degree_tl` | `硕士` | 学位类型 |
| `committeeChair` | `\l__sdu_committee_chair_tl` | - | 答辩委员会主席 |
| `committeeMembers` | `\l__sdu_committee_members_tl` | - | 答辩委员会委员 |
| `defenseDate` / `defensePlace` | `\l__sdu_defense_date_tl` / `_place_tl` | - | 答辩日期/地点 |

**`option` 分组键**（排版参数）：

| 键 | 对应变量 | 默认 |
|----|---------|------|
| `lineSpread` | `\l__sdu_line_spread_dim` | `1.5` |
| `pageLeft` / `pageRight` | `\l__sdu_page_left_tl` / `_right_tl` | `3cm` |
| `pageTop` / `pageBottom` | `\l__sdu_page_top_tl` / `_bottom_tl` | `2.5cm` |

**顶层键（`sdu`）**：`module`（默认 `undergraduate`）+ `info`/`option` 代理键 + 全部平铺别名（向后兼容）。

### 6.2 Getter 命令

`\GetTitle` `\GetAuthor` `\GetStudentId` `\GetSchool` `\GetMajor` `\GetSupervisor` `\GetYear` `\GetMonth` `\GetDegree` `\GetCommitteeChair` `\GetCommitteeMembers` `\GetDefenseDate` `\GetDefensePlace`

---

## 7. 核心变量与命名约定

### 7.1 LaTeX3 命名规范

```
\ <scope> _ <namespace> _ <name> : <signature>
```

- 作用域：`l_`（局部）、`c_`（常量）、`g_`（全局）
- 命名空间：内核 `__sdu`，工具包 `__sdut`
- 类型后缀：`_tl` / `_dim` / `_bool` / `_seq`

### 7.2 内核核心变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `\l__sdu_title_tl` 等 8 个 | tl | 论文基本信息 |
| `\l__sdu_degree_tl` 等 5 个 | tl | 学位/答辩信息 |
| `\l__sdu_line_spread_dim` | dim | 行距 |
| `\l__sdu_page_*_tl` ×4 | tl | 页边距 |
| `\l__sdu_module_tl` | tl | module 键原始值 |
| `\l__sdu_module_seq` | seq | 拆分后的模块序列 |
| `\l__sdu_module_tmp_tl` / `_item_tl` / `_pkg_tl` | tl | 加载过程临时变量 |
| `\l__sdu_blindreview_bool` | bool | 盲审标志 |
| `\l__sdu_has_blindreview_bool` | bool | 是否含盲审模块 |
| `\l__sdu_has_base_module_bool` | bool | 是否含基础模块 |

---

## 8. 关键函数与命令

### 8.1 模块加载与盲审

| 函数/命令 | 说明 | 定义位置 |
|----------|------|---------|
| `\sdu_load_module:` | 拆分模块、盲审回退、逐个加载 | [dtx L651](file:///workspace/src/sduthesis.dtx#L651-L687) |
| `\IfBlindReviewTF{#1}{#2}` | 盲审标志条件 | [dtx L714](file:///workspace/src/sduthesis.dtx#L714-L717) |
| `\IfBlindReviewF{#1}` | 非盲审才输出 | [dtx L718](file:///workspace/src/sduthesis.dtx#L718-L721) |
| `\IfBlindReview{#1}{#2}` | 文档命令版 | [dtx L722](file:///workspace/src/sduthesis.dtx#L722) |

### 8.2 公开命令与环境

| 命令/环境 | 说明 |
|----------|------|
| `\SDUSetup{...}` | 主配置入口 |
| `\makecoverpage` / `\makestatement` / `\makecommittee` | 页面（模块覆盖） |
| `\maketable` | 目录 |
| `\printbib` | 参考文献（biblatex/biber） |
| `cnabstract` / `enabstract` | 中英摘要环境 |
| `\cnkeywords{}` / `\enkeywords{}` | 中英关键词 |
| `myacknowledgement` / `myappendix` | 致谢 / 附录环境 |
| `\equref` / `\tabref` / `\figref` / `\subfigref` | 公式/表/图/子图引用 |
| `\citing` / `\citex` | supercite / citep 别名 |
| `\mye` / `\myi` / `\myj` | 自然底数/虚数/复数单位 |
| `\song` / `\hei` / `\kai` 及 bf/it 变体 | 中文字体命令 |

---

## 9. 依赖关系图

### 9.1 宏包依赖（内核）

```
sduthesis.cls（内核）── \LoadClass[openany]{ctexbook}
  ├─ 基础：expl3、l3keys2e
  ├─ 中文：xeCJK、unicode-math（Fandol 字体）
  ├─ 页面：geometry、fancyhdr、setspace
  ├─ 图表：graphicx、caption、subfig、booktabs、float
  ├─ 数学：amsmath、amsthm、amsfonts、amssymb
  ├─ 算法：algorithm、algorithmicx、algpseudocode
  ├─ 代码：listings
  ├─ 参考：biblatex（backend=biber, style=gb7714-2015）、addbibresource
  ├─ 链接：hyperref、bookmark、etoolbox
  ├─ 表格：tabularx、tocloft
  └─ 颜色：xcolor
```

### 9.2 模块依赖方向

```
用户传 module 列表
   ↓ \RequirePackage{sduthesis-<name>}
   ├─ sduthesis-common.sty  ←── 被 undergraduate 与 master 均 RequirePackage
   ├─ sduthesis-undergraduate.sty
   ├─ sduthesis-master.sty
   └─ sduthesis-blindreview.sty（叠加层，置盲审开关 + 覆盖 Getter/页面）
```

> `common` 无独立存在价值，仅作为 undergraduate/master 的共享依赖；运行时由 `\input@path` 指向 `modules/` 解析。

### 9.3 源码安装清单（build.lua textfiles）

安装到 TDS 的文件包括：`sdutex.sty`、`sduthesis.bst`、以及 4 个模块 `.sty`（common/master/undergraduate/blindreview）。

---

## 10. 构建系统

采用 **Makefile + l3build** 双轨。[Makefile](file:///workspace/Makefile) 提供人性化入口，[build.lua](file:///workspace/build.lua) 是标准构建引擎。

### 10.1 Makefile 目标

| 目标 | 说明 |
|------|------|
| `make`（默认） | = `make test` |
| `make unpack` | `latex sduthesis.ins` 解包生成 `sduthesis.cls` 到 `build/` |
| `make test` | CI 门禁：`l3build check`（XeTeX 引擎回归） |
| `make install` | 安装到 `~/texmf/tex/latex/sdutex/` + `texhash` |
| `make ctan` | 生成 CTAN 发布包 `sdutex-ctan.zip` |
| `make manual` | 编译中文使用手册 `build/sduthesis.pdf`（XeLaTeX + makeindex） |
| `make clean` | 删除 build/、tlpkg/、src/*.cls、测试日志 |
| `make help` | 打印帮助 |

### 10.2 l3build 配置要点（build.lua）

```lua
module = "sdutex"
sourcefiles = {"src/*.dtx", "src/*.ins"}
unpackdir   = "./build/unpacked"
installfiles= {"*.cls"}                    -- 解包产物
textfiles   = { "src/sdutex.sty","src/sduthesis.bst",
                "modules/*.sty" ... }      -- 直接源码安装
typesetexe  = "xelatex"                    -- 手册用 XeTeX（fandol 字体）
checkengines= {"xetex"}                    -- 仅 XeTeX（.tlg 基线为 XeTeX 生成）
checkopts   = "-file-line-error -halt-on-error -interaction=nonstopmode"
testfiledir = "test"
lvtext      = ".tex"                       -- 测试文件用 .tex 扩展名
excludetests= {"smoke", "nested-setup"}    -- 排除非独立回归用例
tdsdirs     = { modules / build/unpacked / figures → tex/latex/sdutex }
tdslocations= { ... }                      -- TDS 标准路径映射
packtdszip  = true
ctanpkg = "sdutex"; ctanpath = "latex/sdutex"
```

> `tdsdirs` 把 `modules` 与 `build/unpacked` 暴露给 `build/test` 的隔离编译目录，保证 xelatex 能找到 `sduthesis.cls` / `modules/*.sty`。

---

## 11. 测试体系

采用 **l3build `.tex/.tlg` 回归测试**，与示例模板 sduthesis 一致。测试文件通过 `\input{regression-test}` + `\START/\END` 产生可对比基线；使用 `\ASSERT`（内部 `\edef`）做断言式校验。

### 11.1 测试用例（test/）

公共配置在 [setup-test.tex](file:///workspace/test/support/setup-test.tex)（本科模块 + 示例个人信息）。

| 测试文件 | 覆盖内容 |
|---------|---------|
| [cover.tex](file:///workspace/test/cover.tex) | 封面生成 |
| [abstract.tex](file:///workspace/test/abstract.tex) | 摘要环境 |
| [appendix.tex](file:///workspace/test/appendix.tex) | 附录环境 |
| [toc.tex](file:///workspace/test/toc.tex) | 目录 |
| [bib.tex](file:///workspace/test/bib.tex) | 参考文献（biblatex/biber） |
| [blindreview.tex](file:///workspace/test/blindreview.tex) | 盲审模式 |
| [master.tex](file:///workspace/test/master.tex) | 硕士模块 |
| [master-blindreview.tex](file:///workspace/test/master-blindreview.tex) | 硕士 + 盲审组合（`\ASSERT` 掩码断言） |
| [nested-setup.tex](file:///workspace/test/nested-setup.tex) | SDUSetup info/option 嵌套（`excludetests` 排除） |
| [smoke.tex](file:///workspace/test/smoke.tex) | 端到端整篇编译（无基线，排除） |

调用方式示例（[master-blindreview.tex](file:///workspace/test/master-blindreview.tex#L17-L31)）：

```latex
\documentclass{sduthesis}
\input{setup-test}
\input{regression-test}
\SDUSetup{ module = {master, blindreview}, degree = {硕士}, ... }
\begin{document}
\START
\ASSERT{\GetAuthor}{***}                     % 盲审掩码断言
\ASSERT{\IfBlindReviewTF{BLIND-ON}{BLIND-OFF}}{BLIND-ON}
\makecoverpage
\makecommittee
\END
\end{document}
```

### 11.2 运行

```bash
make test             # l3build check（XeTeX）
l3build check -e xetex
l3build save          # 有意变更输出时更新 .tlg 基线
```

> 只测 **XeTeX** 引擎。`.tlg` 基线由 XeTeX 生成，模板源码也仅加载 XeTeX 专用 `xeCJKfntef`；加入 luatex 会因缺基线导致 check 全失败。

---

## 12. CI/CD 与双仓同步

### 12.1 GitHub Actions

| Workflow | 触发 | 作用 |
|----------|------|------|
| [test.yml](file:///workspace/.github/workflows/test.yml) | push/PR 到 main（路径限定）| 安装 TeX Live（`zauguin/install-texlive@v4` + `tl_packages` 清单）、软链字体供 XeLaTeX 识别 Fandol、`make test`；失败上传 `build/test*/*.diff` |
| [release.yml](file:///workspace/.github/workflows/release.yml) | `v*` tag | 安装 CJK 字体 → `l3build ctan` → 命名 `sdutex-v<ver>-<sha>.zip` → 从 dtx `\changes` 生成 release notes（兜底 git log）→ 等待 test CI 通过 → `gh release create` |
| [sync-cnb.yml](file:///workspace/.github/workflows/sync-cnb.yml) | push 到 main（代码路径）| GitHub → CNB 反向同步（`tencentcom/git-sync`，仓库 `h1s97x/sdutex`)；排除 `.cnb*`/`.github` 防同步环 |

### 12.2 CNB 流水线（.cnb.yml）

**文件**：[.cnb.yml](file:///workspace/.cnb.yml)

- `main.push`：CNB → GitHub 同步（`sync_mode: rebase`）
- `main.pull_request`：自动分配处理人/审查人（PR 编译门禁在 GitHub test.yml，CNB 不做）
- `$.api_trigger`：手动验证 `l3build ctan` + `make manual`
- `$.web_trigger_pull_from_github`：GitHub → CNB 拉取（按钮见 [.cnb/web_trigger.yml](file:///workspace/.cnb/web_trigger.yml)）
- `$.issue.open`：Issue 自动分配处理人
- `$.tag_push`：`l3build ctan` + `make manual` + 释放 Release 与资源

> `tl_packages` 清单见 [.github/tl_packages](file:///workspace/.github/tl_packages)。

---

## 13. 项目运行方式

### 13.1 环境要求

| 依赖 | 建议 | 说明 |
|------|------|------|
| TeX Live | 2024+ | 需含 l3build、ctex、Fandol 等 |
| XeLaTeX | 随发行版 | 主编译引擎（中文 + unicode-math） |
| Biber | 随发行版 | 参考文献处理 |
| Make | 4.x | Makefile 构建 |
| Lua | 随 TeX Live | l3build 运行时 |

### 13.2 安装（开发者）

```bash
git clone https://github.com/h1s97x/sdutex.git && cd sdutex
make unpack      # 或 l3build unpack：dtx → build/sduthesis.cls
make install     # 或 l3build install：装入 ~/texmf/... + texhash
make test        # 运行回归测试（CI 门禁）
```

### 13.3 用户直接使用（无需安装）

将解包后的 `sduthesis.cls`、`src/sdutex.sty`、`src/sduthesis.bst` 与 `modules/*.sty` 复制进用户论文项目目录（`modules/` 需保持相对位置以便内核 `\input@path` 找到）。

### 13.4 用户论文最小示例

```latex
\documentclass{sduthesis}
\SDUSetup{
  module = undergraduate,
  info = {
    title = {基于深度学习的图像识别研究},
    author = {张三}, studentId = {2021001234},
    school = {计算机科学与技术学院},
    major = {计算机科学与技术},
    supervisor = {李四 教授},
    year = {2025}, month = {6},
  },
  option = { lineSpread = 1.5 },
}
\begin{document}
\frontmatter
\makecoverpage
\begin{cnabstract}
本文研究了基于深度学习的图像识别方法...
\cnkeywords{深度学习, 图像识别, 卷积神经网络}
\end{cnabstract}
\begin{enabstract}
This paper studies image recognition methods based on deep learning.
\enkeywords{Deep Learning, Image Recognition, CNN}
\end{enabstract}
\maketable
\mainmatter
\chapter{引言}
...
\backmatter
\begin{myacknowledgement} 感谢导师... \end{myacknowledgement}
\end{document}
```

编译命令（四次，处理引用/目录/参考文献）：

```bash
xelatex main.tex
biber main
xelatex main.tex
xelatex main.tex
```

---

## 14. 版本管理与发布

### 14.1 版本号

遵循 SemVer 2.0.0。版本号同时维护在 [CHANGELOG.md](file:///workspace/CHANGELOG.md)（Keep a Changelog）与 `sduthesis.dtx` 头部：

```tex
\ProvidesClass{sduthesis}[2026/08/18 v2.2.0 Thesis template for Shandong University]
\date{v2.2.0 \quad 2026/08/18}
```

### 14.2 发布步骤

1. 更新 `sduthesis.dtx`（`\date` 与 `\ProvidesClass`）与 CHANGELOG
2. 打 tag：`git tag -a v2.2.0 -m "..." && git push origin v2.2.0`
3. GitHub Actions [release.yml](file:///workspace/.github/workflows/release.yml) 自动构建 CTAN 包并创建 Release（等待 test CI 通过）
4. CNB `$.tag_push` 并行构建 CTAN + 手册并发布

---

## 15. 设计决策与权衡

### 15.1 DTX 格式管理核心代码

代码 + 文档合一，CTAN 发布标准；代价是需 DocStrip 解包、开发时需在注释/代码间切换。

### 15.2 插件化架构（内核 + 模块 + Hook）

v1.0.0 时代码全部集中在 dtx，每加学位类型都要在 switch-case 中插分支。重构后内核只留通用引擎 + 6 个 Hook + 模块加载器，学位逻辑下沉到 `modules/*.sty`，支持组合加载与独立演进。**公共实现抽到 `common` 模块**并用 `\providecommand`/`\renewenvironment` 守卫，解决 `master`+`undergraduate` 组合加载的重定义冲突。

### 15.3 盲审 Getter 用 `\renewcommand` 而非 xparse

回归测试 `\ASSERT` 用 `\edef` 比较展开值，xparse 命令不可 `\edef`；改用 `\renewcommand` 后 `\GetAuthor` 等退化为普通宏，掩码断言可通过（issue #35）。

### 15.4 仅测 XeTeX 引擎

`.tlg` 基线由 XeTeX 生成、源码仅加载 XeTeX 专用 `xeCJKfntef`；luaTeX 会因缺基线导致 check 全失败，故 `checkengines={"xetex"}`。

### 15.5 盲审回退放在内核加载器

`module={blindreview}` 单独使用时由内核自动前置加载本科模块，与书写顺序无关（`{blindreview, master}` 不会重复加载两个基础模块）。

### 15.6 参考文献主路径 biblatex/biber

GB/T 7714-2015（`gb7714-2015`），`.bst` 仅作传统工程兜底。

---

## 16. 开发指南与最佳实践

### 16.1 添加新选项

在 dtx `sdu/info` 或 `sdu/option` 组追加键 + 在存储层声明变量：

```latex
\tl_new:N \l__sdu_myinfo_tl          % 存储层
\keys_define:nn { sdu / info } {
  myinfo .tl_set:N = \l__sdu_myinfo_tl,
}
% 可选：在 sdu 顶层加平铺别名
```

### 16.2 添加新模块

1. 在 `modules/` 建 `sduthesis-<name>.sty`，`\RequirePackage{sduthesis-common}`（如需公共能力），用 `\renewcommand` / `\AddToHook` 注入行为
2. 在 [build.lua](file:///workspace/build.lua) 的 `textfiles` / `tdslocations` 注册
3. 在内核 `\sdu_load_module:` 盲审回退逻辑中考虑新模块
4. 新建 `test/<name>.tex` + `.tlg` 回归测试（XeTeX 生成基线）

### 16.3 添加回归测试

```latex
\documentclass{sduthesis}
\input{setup-test}
\input{regression-test}
\begin{document}
\START
<要校验的代码，可用 \ASSERT>
\END
\end{document}
```

运行 `make test`；有意变更输出时 `l3build save` 更新基线。

### 16.4 常见问题

| 问题 | 解决 |
|------|------|
| `l3build not found` | `tlmgr install l3build` |
| `File sduthesis.cls not found` | `make unpack` / `l3build unpack` |
| `The font "FandolSong" cannot be found` | 确认 TeX Live Fandol 字体在；CI 需把 TeX 字体软链到 `~/.fonts`（见 test.yml） |
| 测试不通过 | 推荐 TeX Live 2024，`texlua -v` 检查；确认修改是否有意变更 → `l3build save` |

---

## 17. 常见问题 FAQ

**Q1：如何启用盲审？**
```latex
\SDUSetup{ module = {master, blindreview} }
```

**Q2：本科 / 硕士 / 博士封面如何切换？**
```latex
\SDUSetup{ module = {undergraduate} }                        % 本科
\SDUSetup{ module = {master}, info = { degree = {硕士} } }   % 硕士
\SDUSetup{ module = {master}, info = { degree = {博士} } }   % 博士
```

**Q3：旧式平铺写法（`\SDUSetup{title=...}`）还能用吗？**
能，`sdu` 顶层保留全部平铺别名，向后兼容；推荐 `info={...}`/`option={...}` 嵌套分组。

**Q4：如何改行距 / 页边距？**
```latex
\SDUSetup{ option = { lineSpread=1.5, pageLeft=3cm, pageTop=2.5cm } }
```
（默认：行距 1.5，左右 3cm，上下 2.5cm）

**Q5：自定义模块如何接入？**
```latex
\SDUSetup{ module = {master, blindreview, my-custom-module} }
```
新建 `modules/sduthesis-my-custom-module.sty` 并注册到 build.lua。

**Q6：盲审会隐藏哪些信息？**
封面中 `\GetAuthor`/`\GetStudentId`/`\GetSupervisor` 及答辩委员会主席/委员 Getted 均被掩码为 `***`；声明页与答辩委员会页整页跳过，且 `\IfBlindReviewTF` 控制相关分支不输出。

**Q7：参考文献用 biblatex 还是 bst？**
主路径 biblatex/biber（GB/T 7714-2015）；`sduthesis.bst` 为传统工程兜底。

---

## 附录 A：文件快速索引

| 文件 | 链接 |
|------|------|
| 核心文档类（DTX） | [sduthesis.dtx](file:///workspace/src/sduthesis.dtx) |
| DocStrip 安装脚本 | [sduthesis.ins](file:///workspace/src/sduthesis.ins) |
| 工具宏包 | [sdutex.sty](file:///workspace/src/sdutex.sty) |
| 参考文献样式 | [sduthesis.bst](file:///workspace/src/sduthesis.bst) |
| 公共模块 | [sduthesis-common.sty](file:///workspace/modules/sduthesis-common.sty) |
| 本科模块 | [sduthesis-undergraduate.sty](file:///workspace/modules/sduthesis-undergraduate.sty) |
| 硕士模块（含博士） | [sduthesis-master.sty](file:///workspace/modules/sduthesis-master.sty) |
| 盲审模块 | [sduthesis-blindreview.sty](file:///workspace/modules/sduthesis-blindreview.sty) |
| l3build 配置 | [build.lua](file:///workspace/build.lua) |
| Makefile | [Makefile](file:///workspace/Makefile) |
| 测试索引 | [test/README.md](file:///workspace/test/README.md) |
| 测试公共配置 | [setup-test.tex](file:///workspace/test/support/setup-test.tex) |
| 测试流水线 | [test.yml](file:///workspace/.github/workflows/test.yml) |
| 发布流水线 | [release.yml](file:///workspace/.github/workflows/release.yml) |
| CNB 反向同步 | [sync-cnb.yml](file:///workspace/.github/workflows/sync-cnb.yml) |
| CNB 流水线 | [.cnb.yml](file:///workspace/.cnb.yml) |
| 架构设计 | [ARCHITECTURE.md](file:///workspace/doc/ARCHITECTURE.md) |
| 内部实现 | [INTERNALS.md](file:///workspace/doc/INTERNALS.md) |
| 开发者指南 | [DEVELOP.md](file:///workspace/doc/DEVELOP.md) |
| 变更日志 | [CHANGELOG.md](file:///workspace/CHANGELOG.md) |
| 项目 README | [README.md](file:///workspace/README.md) |

---

> **文档版本**：Code Wiki v2.0
> **适用项目版本**：SDUTeX v2.2.0
> **校对基准**：依据仓库当前源码（`src/`、`modules/`、`build.lua`、`Makefile`、`.github/`、`test/`）实况复核，修正了此前对引擎数量、模块清单与构建/测试配置的描述偏差。