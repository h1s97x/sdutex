# SDUTeX 项目 Code Wiki

> 山东大学 LaTeX 论文模板核心包 | Shandong University LaTeX Thesis Template Core Package
>
> 版本:v2.2.0 | 最后更新:2026/08/18(与示例模板仓库 sduthesis v2.2.0 架构完全对齐)

---

## 目录

1. [项目概述](#1-项目概述)
2. [整体架构](#2-整体架构)
3. [目录结构](#3-目录结构)
4. [核心模块详解](#4-核心模块详解)
   - 4.1 [内核 sduthesis.dtx](#41-内核-sduthesisdtx)
   - 4.2 [工具宏包 sdutex.sty](#42-工具宏包-sdutexsty)
   - 4.3 [参考文献样式 sduthesis.bst](#43-参考文献样式-sduthesisbst)
   - 4.4 [模块系统 modules/](#44-模块系统-modules)
5. [插件化架构:内核 + 模块 + Hook](#5-插件化架构内核--模块--hook)
6. [配置系统](#6-配置系统)
7. [核心变量与命名约定](#7-核心变量与命名约定)
8. [关键函数与命令](#8-关键函数与命令)
9. [依赖关系图](#9-依赖关系图)
10. [构建系统](#10-构建系统)
11. [测试体系](#11-测试体系)
12. [CI/CD 流程](#12-cicd-流程)
13. [项目运行方式](#13-项目运行方式)
14. [版本管理与发布](#14-版本管理与发布)
15. [设计决策与权衡](#15-设计决策与权衡)
16. [开发指南与最佳实践](#16-开发指南与最佳实践)
17. [常见问题 FAQ](#17-常见问题-faq)

---

## 1. 项目概述

### 1.1 项目简介

**SDUTeX** 是山东大学学位论文 LaTeX 模板的核心代码仓库。该项目提供一套符合山东大学学位论文格式规范的 LaTeX 工具集,支持本科、硕士、专业硕士、博士四种学位类型,支持中英文双语写作和盲审模式。

### 1.2 核心产物

| 产物文件 | 类型 | 说明 |
|---------|------|------|
| `sduthesis.cls` | Document Class | 学位论文文档类(核心引擎) |
| `sdutex.sty` | Style Package | 工具宏包(数学/浮动体/格式工具) |
| `sduthesis.bst` | BibTeX Style | GB/T 7714-2015 参考文献样式 |
| `sduthesis-undergraduate.sty` | Module | 本科毕业论文模块 |
| `sduthesis-master.sty` | Module | 硕士学位论文模块 |
| `sduthesis-blindreview.sty` | Module | 盲审模式模块 |

> 注:v2.2.0 起不再维护独立的 `doctor` 模块,博士学位论文统一由 `master` 模块 + `degree={博士}` 覆盖。

### 1.3 技术栈

| 分类 | 技术 |
|------|------|
| 编程语言 | LaTeX3 (expl3), TeX, BibTeX |
| 构建系统 | l3build (Lua), GNU Make |
| 文档格式 | DTX (Documented LaTeX sources) |
| 测试引擎 | XeLaTeX, LuaLaTeX |
| CI/CD | GitHub Actions |
| 基础类 | ctexbook (中文书籍类) |

### 1.4 关键特性

- ✅ **多学位支持**:本科、硕士学位论文(博士通过 `degree={博士}`)
- ✅ **中英文支持**:中文论文、英文论文
- ✅ **盲审模式**:自动隐藏作者、学号、导师等敏感信息,跳过答辩委员会页
- ✅ **插件化架构**:内核 + 模块 + Hook,支持组合加载(`module={master, blindreview}`)
- ✅ **LaTeX3 现代化语法**:基于 ctexbook + l3keys + expl3
- ✅ **双引擎兼容**:XeLaTeX 与 LuaLaTeX 均支持
- ✅ **GB/T 7714-2015 参考文献**:biblatex/biber(.bst 兜底)
- ✅ **完善的测试体系**:l3build .tex/.tlg 回归测试(双引擎)

---

## 2. 整体架构

### 2.1 四层分层架构

```
┌──────────────────────────────────────────────────────┐
│                   用户层 (User)                        │
│  \documentclass{sduthesis}  \SDUSetup{...}             │
│  \makecoverpage  \begin{cnabstract}  \GetTitle  ...    │
└──────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────┐
│                   模块层 (Modules)                     │
│  undergraduate / master / blindreview .sty            │
└──────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────┐
│                   内核 (Core Engine)                   │
│  SDUSetup 引擎 (l3keys) · 6 个命名 Hook               │
│  模块加载器 · 变量系统 · 基础排版引擎                  │
│  页面布局 · 字体配置 · 章节标题样式                    │
└──────────────────────────────────────────────────────┘
```

> 内核只负责引擎、Hook 与基础排版;学位类型逻辑(封面 / 摘要 / 页眉页脚)由模块承载。

### 2.2 Hook 系统数据流

```
用户代码
  │
  ├─ \documentclass{sduthesis}
  ├─ \SDUSetup{ module = {master, blindreview}, info = {...}, option = {...} }
  │     → \keys_set:nn { sdu } 处理(info/option 代理键)
  │
  ├─ \begin{document}
  │     → \AddToHook { begindocument } 触发 \sdu_load_module:
  │     → 盲审回退:若 blindreview 无基础模块,前置加载 undergraduate
  │     → \RequirePackage{sduthesis-master.sty}
  │     → \RequirePackage{sduthesis-blindreview.sty}
  │     → 模块通过 \AddToHook 注册 Hook 代码
  │     → 触发 Hook: sduthesis/after-setup
  │
  ├─ \makecoverpage
  │     → 模块 \renewcommand 覆盖后的封面实现
  │
  ├─ \frontmatter / \mainmatter / \backmatter
  │     → 触发对应 Hook,供模块/用户扩展
```

---

## 3. 目录结构

```
/workspace
├── .cnb/                         # CNB (Cloud Native Buildpacks) 配置
│   └── web_trigger.yml
├── .github/                      # GitHub 项目配置
│   ├── ISSUE_TEMPLATE/           # Issue 模板
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── workflows/                # CI/CD Workflows
│   │   ├── release.yml           # 发布流水线
│   │   ├── sync-cnb.yml          # CNB 同步
│   │   └── test.yml              # 测试流水线
│   ├── CODEOWNERS                # 代码所有者
│   ├── PULL_REQUEST_TEMPLATE.md  # PR 模板
│   └── tl_packages               # TeX Live 包清单
├── doc/                          # 开发者文档
│   ├── ARCHITECTURE.md           # 架构设计文档
│   ├── DEVELOP.md                # 开发者指南
│   ├── INTERNALS.md              # 内部实现文档
│   └── README.md                 # 项目概述
├── modules/                      # 学位模块 (v2.2.0 插件化)
│   ├── sduthesis-blindreview.sty     # 盲审模块
│   ├── sduthesis-master.sty          # 硕士学位模块(含博士,degree 键覆盖)
│   └── sduthesis-undergraduate.sty   # 本科学位模块
├── src/                          # 核心源代码
│   ├── sdutex.sty                # 工具宏包
│   ├── sduthesis.bst             # BibTeX 参考文献样式(传统工程兜底)
│   ├── sduthesis.dtx             # 主文档类 (DTX 格式,核心)
│   └── sduthesis.ins             # DocStrip 安装脚本
├── test/                         # l3build 回归测试(.tex/.tlg)
│   ├── README.md                 # 测试索引说明
│   ├── support/setup-test.tex    # 测试公共配置
│   ├── cover.tex / abstract.tex / appendix.tex / toc.tex
│   ├── bib.tex / blindreview.tex / master.tex / master-blindreview.tex
│   └── nested-setup.tex + 对应 .tlg 基线
├── .cnb.yml                      # CNB 构建配置
├── .gitignore
├── CHANGELOG.md                  # 变更日志 (Keep a Changelog)
├── LICENSE                       # LPPL 许可证
├── Makefile                      # Make 构建脚本
├── build.lua                     # l3build 配置
└── README.md                     # 项目主 README
```

---

## 4. 核心模块详解

### 4.1 内核 sduthesis.dtx

**文件**:[sduthesis.dtx](file:///workspace/src/sduthesis.dtx)

这是整个项目的核心文件,采用 **DTX (Documented LaTeX sources)** 格式编写,代码与文档合二为一。通过 `DocStrip` 工具(`\input docstrip.tex` + `sduthesis.ins`)从 DTX 中抽取 `%<!CLASS>` 标记的代码,生成最终的 `sduthesis.cls`。

#### 4.1.1 代码结构分区

`src/sduthesis.dtx`（内核）采用 `%<*cls>` / `%</cls>` 包裹可抽取代码，结构如下：

| 区块 | 内容 |
|------|------|
| 存储层 | 变量声明：`\l__sdu_*_tl` / `_dim` / `_bool` / `_seq` |
| 定义层 | l3keys 键注册：`sdu/info`、`sdu/option`、`sdu` 顶层 |
| 命令层 | `\SDUSetup` 配置入口 |
| 导出层 | Getter 命令族（`\GetTitle` / `\GetAuthor` 等） |
| 模块加载器 | `\sdu_load_module:` + 盲审回退 |
| Hook 系统 | 6 个命名 Hook + `\IfBlindReviewTF` |
| 宏包加载 | biblatex / amsmath / xeCJK 等依赖 |
| 字体引擎 | Fandol 中文字体 + 宋/黑/楷命令 |
| 页面/章节/交叉引用/图表标题/数学/代码排版引擎 | 基础排版 |
| 占位命令与环境 | `\makecoverpage` / `cnabstract` 等（模块覆盖） |
| 通用环境定义 | `\printbib` / `myacknowledgement` / `myappendix` / `\maketable` |

#### 4.1.2 DTX 格式说明

DTX 文件的特点:
- **注释即文档**:以 `%%` 开头的行是可被提取生成 PDF 手册的 LaTeX 文档
- **条件抽取**:`%<*cls>` 标记的代码块会被 `sduthesis.ins` 抽取进 `sduthesis.cls`

安装脚本 [sduthesis.ins](file:///workspace/src/sduthesis.ins) 的核心行:
```tex
\generate{\file{sduthesis.cls}{\from{sduthesis.dtx}{cls}}}
```

---

### 4.2 工具宏包 sdutex.sty

**文件**:[sdutex.sty](file:///workspace/src/sdutex.sty)

独立于文档类的辅助宏包,提供三类可按需加载的工具集。用户可通过 `\usepackage[math,float,format]{sdutex}` 或 `\usepackage[all]{sdutex}` 使用。

#### 4.2.1 模块划分

| 模块开关 | 变量 | 默认 | 说明 |
|---------|------|------|------|
| `math` | `\g__sdut_math_bool` | true | 数学符号与定理工具 |
| `float` | `\g__sdut_float_bool` | true | 浮动体间距与子图兼容 |
| `format` | `\g__sdut_format_bool` | true | 排版格式工具(间距/列表) |
| `all` | - | - | 全部启用(choice 节点) |
| `none` | - | - | 全部禁用 |

#### 4.2.2 数学工具模块 (math)

| 命令/函数 | 说明 |
|----------|------|
| `\SDUTN` | 自然数集 $\mathbb{N}$ |
| `\SDUTZ` | 整数集 $\mathbb{Z}$ |
| `\SDUTQ` | 有理数集 $\mathbb{Q}$ |
| `\SDUTR` | 实数集 $\mathbb{R}$ |
| `\SDUTC` | 复数集 $\mathbb{C}$ |
| `\SDUT@eqref{#1}` | 带编号公式引用:`equation~\ref{#1}` |
| `\SDUT@begintheorem{#1}{#2}` | 定理环境开头:`\trivlist` + 粗体标题 |

#### 4.2.3 浮动体工具模块 (float)

| 命令/函数 | 说明 |
|----------|------|
| `\SDUT@floatbox` | 水平间距校正 (1em 偏移) |
| `\SDUT@setfloatskip` | 设置 `textfloatsep`/`intextsep`/`floatsep` = 12pt± |
| (AtBeginDocument) | listings 配置(keepspaces, ttfamily\small) |
| (包检测) | subfig / subcaption 兼容配置 |

#### 4.2.4 格式工具模块 (format)

| 命令/函数 | 说明 |
|----------|------|
| `\SDUT@textCJK` | 加载 xeCJKfntef 并开启 CJKspace/CJKmath |
| `\SDUT@urlsetup` | `\urlstyle{same}`(等宽字体同正文) |
| `\SDUT@setlist` | itemsep=3pt, parsep=3pt, parskip=0pt |
| `\SDUT@setparagraph` | parindent=2em, parskip=6pt± |

#### 4.2.5 公共工具函数

| 函数 | 说明 |
|------|------|
| `\sdut_if_empty:nTF` | 空值判断 (p/T/F/TF 四种形式) |
| `\sdut_if_odd:nTF` | 奇数判断 (p/T/F/TF 四种形式) |
| `\sdut_safe_width:n` | 安全宽度计算 (返回 \max_dimen) |
| `\sdut_length:nn{#1}{#2}` | 带单位数字格式化 |

---

### 4.3 参考文献样式 sduthesis.bst

**文件**:[sduthesis.bst](file:///workspace/src/sduthesis.bst)

自定义 BibTeX 样式文件,实现 **GB/T 7714-2015** 国家标准参考文献格式。在 `sduthesis.dtx` L435 中通过 `\bibliographystyle{sduthesis}` 自动启用。

---

### 4.4 模块系统 modules/

每个模块通过 `\AddToHook` 在对应的文档阶段钩子中注入行为（封面、摘要、页眉页脚等），并通过 `\renewcommand` 覆盖内核占位命令（如 `\makecoverpage`）。模块通过 `\SDUSetup{ module = {...} }` 组合加载。

#### 4.4.1 本科模块 sduthesis-undergraduate.sty

**文件**：[sduthesis-undergraduate.sty](file:///workspace/modules/sduthesis-undergraduate.sty)

**职责**：本科论文封面、中英摘要环境、关键词命令、页眉页脚。

封面布局元素：
1. 校徽 `logos/sdu_logo_2.pdf`
2. 标题横幅 `logos/sdu_title.png`
3. "论文（设计）题目：" 标签 + 标题值
4. 信息表格（姓名、学号、学院、专业、指导教师，盲审时隐藏前四项）
5. 底部年份/月份

页眉页脚通过 Hook 注入：
```latex
\AddToHook{sduthesis/mainmatter/begin}{
  \fancypagestyle{plain}{
    \fancyhf{}
    \renewcommand{\headrulewidth}{0.5pt}
    \fancyhead[C]{\zihao{-5}\songti 山东大学本科毕业论文（设计）}
    \fancyfoot[C]{\zihao{-5}\thepage}
  }
  \pagestyle{plain}
  \linespread{1.3}\selectfont
}
```

#### 4.4.2 硕士模块 sduthesis-master.sty

**文件**：[sduthesis-master.sty](file:///workspace/modules/sduthesis-master.sty)

**职责**：硕博封面、答辩委员会页（`\makecommittee`）、中英摘要、页眉页脚。

封面布局元素：
1. 校徽 + 标题横幅
2. "论文题目：" 标签 + 标题值
3. 信息表格（学位类型、姓名、学号、学院、专业、指导教师，盲审时隐藏后四项）
4. 底部年份/月份

答辩委员会页（盲审时整页跳过）：
```latex
\renewcommand{\makecommittee}{
    \IfBlindReviewF{
    ... 主席 / 委员 / 答辩日期 / 答辩地点 ...
    }
}
```

> 博士学位论文：设置 `degree = {博士}` 即可，无需独立模块。

#### 4.4.3 盲审模块 sduthesis-blindreview.sty

**文件**：[sduthesis-blindreview.sty](file:///workspace/modules/sduthesis-blindreview.sty)

**机制**：加载时将内核布尔开关 `\l__sdu_blindreview_bool` 置为 true，并覆盖 `\makestatement` 以跳过声明页。基础模块通过 `\IfBlindReviewTF` / `\IfBlindReviewF` 隐藏封面中的作者姓名、学号、导师姓名等敏感信息，并跳过答辩委员会页。

**注意**：该模块与学位模块（undergraduate/master）组合使用；单独使用时内核自动前置加载本科模块。

---

## 5. 插件化架构:内核 + 模块 + Hook

### 5.1 架构原则（v2.2.0）

v1.1.0 之前：所有学位特定逻辑集中在 `sduthesis.dtx` 单文件，难以维护和扩展。

v2.2.0（与 sduthesis 对齐）之后：采用**内核 + 模块 + Hook**三元架构：
- **内核 (Kernel)**：只保留学位无关的通用能力（引擎、变量系统、6 个 Hook、模块加载器、基础排版）
- **模块 (Module)**：学位相关逻辑独立到 `modules/*.sty`，通过 `\AddToHook` / `\renewcommand` 接入
- **Hook (钩子)**：6 个命名生命周期钩子，允许模块在正确时机注入代码

### 5.2 六个命名 Hook

| Hook 名称 | 触发时机 | 典型用途 |
|----------|---------|----------|
| `sduthesis/after-setup` | `\SDUSetup` 处理完、begindocument | 用户/模块在配置完成后执行自定义逻辑 |
| `sduthesis/before-cover` | 封面生成前 | 盲审预处理、封面样式调整 |
| `sduthesis/cover-style` | 封面样式注入 | 各学位模块注入封面样式 |
| `sduthesis/frontmatter/begin` | 前言开始 | 前置内容页码样式、摘要前置 |
| `sduthesis/mainmatter/begin` | 正文开始 | 正文页眉切换、计数器重置 |
| `sduthesis/backmatter/begin` | 后记开始 | 参考文献/附录/致谢样式切换 |

### 5.3 Hook 使用示例

```latex
% 模块注册 Hook 代码（以本科页眉为例）
\AddToHook{sduthesis/mainmatter/begin}{
  \fancypagestyle{plain}{
    \fancyhf{}
    \fancyhead[C]{\zihao{-5}\songti 山东大学本科毕业论文（设计）}
    \fancyfoot[C]{\zihao{-5}\thepage}
  }
  \pagestyle{plain}
}

% 用户自定义扩展（在 \SDUSetup 后打印信息）
\AddToHook{sduthesis/after-setup}{
  \typeout{* 标题：\GetTitle}
}
```

### 5.4 模块加载流程

```
\SDUSetup{ module = {master, blindreview}, ... }
        │
        ▼
写入 \l__sdu_module_tl = {master, blindreview}
        │
        ▼
\begin{document}  （\AddToHook { begindocument } 触发）
        │
        ▼
\sdu_load_module:
   ├─ 分割 module 序列（逗号分隔，去空白、跳空项）
   ├─ 预扫描：是否含 blindreview？是否已有基础模块？
   ├─ 若 blindreview 无基础模块 → 前置加载 undergraduate
   └─ 按用户顺序逐个加载：\RequirePackage{sduthesis-<name>}
```

### 5.5 组合加载示例

```latex
% 场景 1：硕士 + 盲审
\documentclass{sduthesis}
\SDUSetup{
  module = {master, blindreview},
  info = { title = {...}, ... }
}

% 场景 2：博士（master 模块 + degree 键）
\SDUSetup{
  module = {master},
  info = { title = {...}, degree = {博士}, ... }
}

% 场景 3：本科 + 盲审（默认顺序亦可）
\SDUSetup{
  module = {blindreview, undergraduate},
  info = { ... }
}
```

---

## 6. 配置系统

SDUTeX 的配置统一通过 `\SDUSetup{...}` 完成，基于 LaTeX3 l3keys。支持 `info` / `option` 嵌套分组，也保留顶层平铺写法（向后兼容）。

### 6.1 `\SDUSetup` 键值

```latex
\SDUSetup{
  module = {master, blindreview},   % 模块（逗号分隔多模块组合）
  info = {
    title      = {基于深度学习的图像识别研究},
    author     = {张三},
    studentId  = {2021001234},
    school     = {计算机科学与技术学院},
    major      = {计算机科学与技术},
    supervisor = {李四 教授},
    year       = {2025},
    month      = {6},
    % 学位信息（master 模块）
    degree           = {硕士},
    committeeChair   = {王五 教授},
    committeeMembers = {赵六 教授、孙七 副教授},
    defenseDate      = {2025年5月25日},
    defensePlace     = {山东大学信息科学与工程学院会议室},
  },
  option = {
    lineSpread = 1.5,     % 行距倍数（默认 1.5）
    pageLeft   = 3cm,     % 左边距（默认 3cm）
    pageRight  = 3cm,     % 右边距（默认 3cm）
    pageTop    = 2.5cm,   % 上边距（默认 2.5cm）
    pageBottom = 2.5cm,   % 下边距（默认 2.5cm）
  },
}
```

### 6.2 键值映射表

`module` 键：

| 值 | 说明 |
|----|------|
| `undergraduate` | 本科论文模块 |
| `master` | 硕士学位论文模块（含博士，`degree` 键覆盖） |
| `blindreview` | 盲审模块（可与基础模块组合） |

`info` 分组键：

| 键 | 对应变量 | 说明 |
|----|---------|------|
| `title` | `\l__sdu_title_tl` | 论文标题 |
| `author` | `\l__sdu_author_tl` | 作者 |
| `studentId` | `\l__sdu_studentid_tl` | 学号 |
| `school` | `\l__sdu_school_tl` | 学院 |
| `major` | `\l__sdu_major_tl` | 专业 |
| `supervisor` | `\l__sdu_supervisor_tl` | 指导教师 |
| `year` / `month` | `\l__sdu_year_tl` / `_month_tl` | 年份/月份 |
| `degree` | `\l__sdu_degree_tl` | 学位类型（默认“硕士”） |
| `committeeChair` | `\l__sdu_committee_chair_tl` | 答辩委员会主席 |
| `committeeMembers` | `\l__sdu_committee_members_tl` | 答辩委员会委员 |
| `defenseDate` | `\l__sdu_defense_date_tl` | 答辩日期 |
| `defensePlace` | `\l__sdu_defense_place_tl` | 答辩地点 |

`option` 分组键：

| 键 | 对应变量 | 默认值 |
|----|---------|--------|
| `lineSpread` | `\l__sdu_line_spread_dim` | 1.5 |
| `pageLeft` | `\l__sdu_page_left_tl` | 3cm |
| `pageRight` | `\l__sdu_page_right_tl` | 3cm |
| `pageTop` | `\l__sdu_page_top_tl` | 2.5cm |
| `pageBottom` | `\l__sdu_page_bottom_tl` | 2.5cm |

---

## 7. 核心变量与命名约定

### 7.1 LaTeX3 命名约定

SDUTeX 严格遵循 LaTeX3 (expl3) 命名规范:

```
\ <scope> _ <namespace> _ <name> : <signature>
│     │            │              │
│     │            │              └─ 参数签名:n / m / o / T / F / TF / V / N / c 等
│     │            └───────────────── 变量/函数的语义名
│     └────────────────────────────── 命名空间前缀(@@ = sdu)
└──────────────────────────────────── 作用域前缀
```

#### 作用域前缀

| 前缀 | 含义 | 示例 |
|------|------|------|
| `l_` | 局部 (local) | `\l__sdu_title_tl` |
| `c_` | 常量 (constant) | `\c__sdu_version_tl`（在 sdutex.sty 中） |

> 内核配置变量统一使用 `l_` 局部作用域，命名空间为 `__sdu`（双下划线 = 内部命名空间）。

SDUTeX 内核配置变量遵循 LaTeX3 命名规范，统一使用局部变量 `\l__sdu_<名称>_tl`（模块前缀 `sdu`）：

```
\l _ _sdu _ <name> _ tl
│     │        │
│     │        └─ 类型后缀（tl / dim / bool / seq）
│     └─────────── 命名空间前缀 __sdu（双下划线 = 内部）
└───────────────── 作用域前缀 l（局部）
```

#### 类型后缀

| 后缀 | 含义 | 示例 |
|------|------|------|
| `_tl` | Token List（文本/字符串） | `\l__sdu_title_tl` |
| `_dim` | 尺寸/长度 | `\l__sdu_line_spread_dim` |
| `_bool` | 布尔 | `\l__sdu_blindreview_bool` |
| `_seq` | 序列 | `\l__sdu_module_seq` |

### 7.2 核心变量一览

#### 论文信息（info 组）

| 变量 | 类型 | 说明 |
|------|------|------|
| `\l__sdu_title_tl` | tl | 论文标题 |
| `\l__sdu_author_tl` | tl | 作者 |
| `\l__sdu_studentid_tl` | tl | 学号 |
| `\l__sdu_school_tl` | tl | 学院 |
| `\l__sdu_major_tl` | tl | 专业 |
| `\l__sdu_supervisor_tl` | tl | 指导教师 |
| `\l__sdu_year_tl` / `\l__sdu_month_tl` | tl | 年份/月份 |

#### 学位信息（master 模块）

| 变量 | 类型 | 说明 |
|------|------|------|
| `\l__sdu_degree_tl` | tl | 学位类型（默认“硕士”） |
| `\l__sdu_committee_chair_tl` | tl | 答辩委员会主席 |
| `\l__sdu_committee_members_tl` | tl | 答辩委员会委员 |
| `\l__sdu_defense_date_tl` / `\l__sdu_defense_place_tl` | tl | 答辩日期/地点 |

#### 样式（option 组）

| 变量 | 类型 | 默认值 |
|------|------|--------|
| `\l__sdu_line_spread_dim` | dim | 1.5 |
| `\l__sdu_page_left_tl` / `_right_tl` | tl | 3cm |
| `\l__sdu_page_top_tl` / `_bottom_tl` | tl | 2.5cm |

#### 模块与盲审

| 变量 | 类型 | 说明 |
|------|------|------|
| `\l__sdu_module_tl` | tl | module 键原始值 |
| `\l__sdu_module_seq` | seq | 拆分后的模块序列 |
| `\l__sdu_blindreview_bool` | bool | 盲审标志 |
| `\l__sdu_has_blindreview_bool` | bool | 是否含盲审模块 |
| `\l__sdu_has_base_module_bool` | bool | 是否含基础模块 |

---

## 8. 关键函数与命令

### 8.1 模块加载器

| 函数 | 说明 |
|------|------|
| `\sdu_load_module:` | 在 begindocument 执行，拆分 module 序列、盲审回退、逐个加载 |
| `\IfBlindReviewTF` / `\IfBlindReviewF` | 盲审标志条件命令（非盲审才输出） |

### 8.2 Hook 系统

| 函数/命令 | 说明 |
|----------|------|
| `\NewHook`（内置） | 内核声明 6 个命名 Hook |
| `\AddToHook`（内置） | 模块/用户向 Hook 注册代码 |
| `\UseHook`（内置） | 内核在文档阶段触发 Hook |

### 8.3 用户公开命令

#### 配置与信息获取

| 命令 | 参数 | 说明 |
|------|------|------|
| `\SDUSetup` | `{m}` 键值列表 | 主配置入口（module / info / option） |
| `\GetTitle` / `\GetAuthor` / `\GetStudentId` | 无 | 获取标题/作者/学号 |
| `\GetSchool` / `\GetMajor` / `\GetSupervisor` | 无 | 获取学院/专业/指导教师 |
| `\GetYear` / `\GetMonth` | 无 | 获取年份/月份 |
| `\GetDegree` / `\GetCommitteeChair` / `\GetCommitteeMembers` | 无 | 获取学位/答辩委员会信息 |
| `\GetDefenseDate` / `\GetDefensePlace` | 无 | 获取答辩日期/地点 |

#### 页面生成命令

| 命令 | 说明 |
|------|------|
| `\makecoverpage` | 生成封面（内核占位，模块 `\renewcommand` 覆盖） |
| `\makestatement` | 声明页（盲审模块可覆盖跳过） |
| `\makecommittee` | 答辩委员会页（master 模块） |
| `\maketable` | 目录（罗马页码 + 书签） |
| `\printbib` | 参考文献（biblatex/biber） |
| `\frontmatter` / `\mainmatter` / `\backmatter` | 触发对应阶段 Hook |

#### 文档环境

| 环境 | 说明 |
|------|------|
| `cnabstract` | 中文摘要（默认标题“摘 要”） |
| `enabstract` | 英文摘要（默认标题 ABSTRACT） |
| `myacknowledgement` | 致谢环境 |
| `myappendix` | 附录环境（自动切换章节编号） |

#### 关键词命令

| 命令 | 说明 |
|------|------|
| `\cnkeywords{...}` | 中文关键词 |
| `\enkeywords{...}` | 英文关键词 |

---

## 9. 依赖关系图

### 9.1 宏包依赖

```
sduthesis.cls (内核)
  │
  ├─ 基础类:ctexbook
  │     ├─ ctex(中文支持核心)
  │     └─ book(标准 LaTeX 书籍类)
  │
  ├─ 加载 expl3 / l3keys2e(LaTeX3 基础设施)
  │
  ├─ 页面与排版
  │     ├─ geometry (页面边距)
  │     ├─ fancyhdr (页眉页脚)
  │     ├─ setspace (行间距)
  │     └─ enumitem (列表)
  │
  ├─ 浮动体与图表
  │     ├─ graphicx (插图)
  │     ├─ caption (图表标题)
  │     ├─ array / booktabs / longtable (表格)
  │     └─ xcolor (颜色)
  │
  ├─ 数学与定理
  │     ├─ amsmath / amssymb / amsthm / bm
  │     └─ 自定义定理环境
  │
  ├─ 代码与算法
  │     ├─ algorithmicx + algpseudocode
  │     ├─ algorithm
  │     └─ listings
  │
  ├─ 超链接与书签
  │     └─ hyperref
  │
  └─ 中文下划线(按引擎分流)
        ├─ XeTeX  → xeCJKfntef
        └─ LuaTeX → luatexja(兼容层)

sdutex.sty (工具宏包,可选独立加载)
  ├─ expl3 / l3keys2e
  ├─ amsmath / amssymb
  └─ (按需) xeCJKfntef / graphicx / caption 等

sduthesis-undergraduate.sty / master.sty / blindreview.sty
  └─ 通过 \RequirePackage 机制依赖内核(因在内核 \begin{document} 中加载)

sduthesis-blindreview.sty
  └─ 置 \l__sdu_blindreview_bool 为真，覆盖 \makestatement 跳过声明页
```

### 9.2 模块间依赖方向

```
                        ┌──────────────────────────┐
                        │    用户 .tex 文档          │
                        │  \documentclass{sduthesis} │
                        └────────────┬─────────────┘
                                     │ 加载
                                     ▼
                        ┌──────────────────────────┐
                        │     sduthesis.cls         │
                        │  (Kernel: 变量/Hook/加载器)│
                        └────────────┬─────────────┘
                                     │
                ┌────────────────────┼────────────────────┐
                │                    │
     \begin{document} 时 \sdu_load_module: \RequirePackage 加载各模块
                │                    │
                ▼                    ▼
   ┌────────────────────┐ ┌──────────────────────┐
   │undergraduate.sty   │ │ master.sty           │
   │(本科封面/摘要/页眉)│ │(硕博封面/答辩委员会) │
   └─────────┬──────────┘ └──────────┬───────────┘
             │                      │
             └──────────┬───────────┘
                        │ 可组合
                        ▼
             ┌─────────────────────┐
             │ blindreview.sty     │
             │(置盲审开关,跳声明页)│
             └─────────────────────┘
```

### 9.3 字体依赖(按平台回退)

| 平台 | 衬线字体 (main) | 无衬线字体 (sans) | 等宽字体 (mono) |
|------|----------------|------------------|----------------|
| Windows | Times New Roman (AutoFakeBold) | Arial | Consolas |
| Linux / macOS / CI | TeX Gyre Termes | TeX Gyre Heros | TeX Gyre Cursor |

---

## 10. 构建系统

项目采用 **双轨构建体系**:传统 Makefile + l3build(LaTeX 官方标准构建工具)。

### 10.1 Makefile 目标

**文件**:[Makefile](file:///workspace/Makefile)

| 目标 | 说明 | 对应 l3build |
|------|------|-------------|
| `make all` (默认) | = `make test` | - |
| `make unpack` | 解包 DTX 生成 .cls/.sty/.bst,复制到 build/ | `l3build unpack` |
| `make test` | CI 门禁:l3build 回归测试(.tex/.tlg,双引擎) | `l3build check` |
| `make test-l3` | (已并入 `make test`) | `l3build check` |
| `make install` | 安装到用户目录 `~/texmf/tex/latex/sdutex/`,运行 texhash | `l3build install` |
| `make ctan` | 生成 CTAN 发布包 sdutex-ctan.zip | `l3build ctan` |
| `make clean` | 删除 build/、test/build/、tlpkg/、src/*.cls、src/*.sty、日志等 | `l3build clean` + 自定义 |
| `make help` | 打印帮助信息 | - |

### 10.2 l3build 配置详解

**文件**:[build.lua](file:///workspace/build.lua)

核心配置项:

```lua
module = "sdutex"                        -- 模块名
sourcefiledir = "src"                    -- 源文件目录
sourcefiles = {"sduthesis.dtx", "sduthesis.ins"}
modulefiledir = "modules"                -- 模块文件目录
modulefiles = { -- 4 个学位模块 .sty }

-- 双引擎回归测试
checkengines = {"xetex", "luatex"}       -- 测试引擎
stdengine   = "xetex"
checkruns   = 3                          -- 每个测试编译 3 轮(toc/bib 等)
checkopts   = "-file-line-error -halt-on-error -interaction=nonstopmode"

-- 回归测试文件(10 组 lvt/tlg)
testfiles = {
  "test_cover", "test_abstract", "test_math", "test_float",
  "test_module", "test_info", "test_lang", "test_theorem",
  "test_listoffigures", "test_mathstyle"
}

-- CTAN / TDS 目录映射
ctanpkg  = "sdutex"
ctanpath = "latex/sdutex"
tdslocations = { ... }                   -- TDS 标准路径映射

-- Git 版本注入
gitverfiles = {"src/sduthesis.dtx"}
extract_git_version() / expand_git_version() -- 自定义函数

-- 自定义钩子
update_tag(file, content, tagname, tagdate) -- 发版时自动更新版本号
clean()       -- 自定义清理
unpackonly()  -- 仅解包不测试
```

### 10.3 解包流程 (unpack)

```
sduthesis.dtx  (DTX 源码)
      │  latex sduthesis.ins
      ▼
DocStrip 引擎 (docstrip.tex)
      │  按 %<!CLASS> 条件抽取 + 替换 @@ → sdu
      ▼
sduthesis.cls  (build/ 目录)
      │
      └─ 同时复制 modules/*.sty → build/
         同时复制 sdutex.sty, sduthesis.bst → build/
```

---

## 11. 测试体系

SDUTeX 采用 **l3build 回归测试体系**（`.tex` 测试文件 + `.tlg` 基线），与示例模板 sduthesis 完全一致：

```
┌────────────────────────────────────────────┐
│  l3build 回归测试 (.tex + .tlg)            │
│  · 9 个回归测试，覆盖核心功能               │
│  · 通过 \input{regression-test} + \START/\END  │
│    产生可对比的 .tlg 基线                    │
│  · xetex + luatex 双引擎                    │
│  · 对比实际日志与预期基线,逐行比对           │
│  · 命令:l3build check / make test          │
└────────────────────────────────────────────┘
```

### 11.1 回归测试用例

测试文件位于 [test/](file:///workspace/test/)，公共配置在 `test/support/setup-test.tex`：

| 测试文件 | 覆盖内容 |
|---------|---------|
| [cover.tex](file:///workspace/test/cover.tex) | 封面生成 |
| [abstract.tex](file:///workspace/test/abstract.tex) | 摘要环境 |
| [appendix.tex](file:///workspace/test/appendix.tex) | 附录环境 |
| [bib.tex](file:///workspace/test/bib.tex) | 参考文献（biblatex/biber） |
| [blindreview.tex](file:///workspace/test/blindreview.tex) | 盲审模式 |
| [master.tex](file:///workspace/test/master.tex) | 硕士学位论文模块 |
| [master-blindreview.tex](file:///workspace/test/master-blindreview.tex) | 硕士 + 盲审组合 |
| [nested-setup.tex](file:///workspace/test/nested-setup.tex) | SDUSetup info/option 嵌套分组 |
| [toc.tex](file:///workspace/test/toc.tex) | 目录 |

### 11.2 CI 门禁测试（make test）

`make test` 为 CI 门禁，直接运行 l3build 回归测试套件（`.tex/.tlg`，xetex/luatex 双引擎），对齐 sduthesis 的 CI 设计，由 l3build 统一负责解包、TDS 布局与测试编译，避免手工维护解包/拷贝步骤导致反复修补缺失宏包的脆弱逻辑：

```bash
make test
  → l3build check
  → 自动解包 DTX
  → 对 xetex 和 luatex 引擎分别执行:
       对每个测试文件运行编译
       收集 .log 输出
       与对应的 .tlg 基线逐行比对
       差异 → FAIL
```

> `test/smoke.tex` 为整篇论文的端到端编译示例，无 `.tlg` 基线，不参与回归对比；
> 其覆盖的封面/摘要/目录/附录等能力已由 `cover/abstract/toc/appendix` 等回归用例覆盖。

### 11.3 回归测试执行细节

```bash
l3build check
  → 自动解包 DTX
  → 对 xetex 和 luatex 引擎分别执行:
       对每个测试文件运行编译
       收集 .log 输出
       与对应的 .tlg 基线逐行比对
       差异 → FAIL
```

---

## 12. CI/CD 流程

### 12.1 GitHub Actions Workflows

**目录**:[.github/workflows/](file:///workspace/.github/workflows/)

#### 12.1.1 测试流水线 (test.yml)

**触发条件**:push 到 main 分支 / PR 到 main 分支 / workflow_dispatch(路径限定:src/**、test/**、Makefile、build.lua、tl_packages、test.yml)

**执行步骤**:
1. `actions/checkout@v4` - 检出代码
2. `TeX-Live/setup-texlive-action@v4` - 安装 TeX Live,包清单来自 `.github/tl_packages`
3. `make test` - 运行 l3build 回归测试套件（xetex/luatex 双引擎）
4. 失败时上传差异 Artifact:`build/test*/*.diff`(`actions/upload-artifact@v4`)

#### 12.1.2 发布流水线 (release.yml)

Tag 触发自动发布,构建 CTAN 包并创建 GitHub Release。

#### 12.1.3 CNB 同步流水线 (sync-cnb.yml)

同步 Cloud Native Buildpacks 相关配置。

---

## 13. 项目运行方式

### 13.1 环境要求

| 依赖 | 最低版本 | 推荐版本 | 说明 |
|------|---------|---------|------|
| TeX Live | 2020 | 2024 | 需包含 l3build、ctex、geometry、fancyhdr 等 |
| XeLaTeX / LuaLaTeX | - | 随 TeX Live 2024 | 双引擎均支持;pdfLaTeX 不支持中文 |
| Git | 任意 | 最新 | 版本管理 |
| Make | GNU Make 3.8+ | 4.x | Makefile 驱动构建 |
| Lua | 随 TeX Live | 5.3+ | l3build 运行时 |

### 13.2 安装流程

#### 方式一:从源码安装(推荐)

```bash
# 1. 克隆仓库
git clone https://github.com/h1s97x/sdutex.git
cd sdutex

# 2. 解包 DTX 文件
make unpack     # 或 l3build unpack

# 3. 安装到本地 TeX 目录
make install    # 或 l3build install
# 该步骤复制文件到 ~/texmf/tex/latex/sdutex/ 并运行 texhash
```

#### 方式二:直接复制使用

将 `src/` 下的 `.cls`、`.sty`、`.bst` 文件和 `modules/*.sty` 复制到用户的论文项目目录中即可使用(无需安装到系统)。

### 13.3 验证安装

```bash
# 运行测试套件
make test         # CI 门禁:l3build 回归测试(.tex/.tlg,双引擎)
```

### 13.4 用户论文项目最小示例

```latex
% main.tex
\documentclass{sduthesis}

\SDUSetup{
  module = {undergraduate},
  info = {
    title      = {基于深度学习的图像识别研究},
    author     = {张三},
    studentId  = {2021001234},
    school     = {计算机科学与技术学院},
    major      = {计算机科学与技术},
    supervisor = {李教授},
    year       = {2025},
    month      = {6},
  },
  option = {
    lineSpread = 1.5,
  },
}

\begin{document}

\frontmatter
\makecoverpage

\begin{cnabstract}
本文研究了基于深度学习的图像识别方法...
\cnkeywords{深度学习, 图像识别, 卷积神经网络}
\end{cnabstract}

\begin{enabstract}
This paper studies image recognition methods based on deep learning...
\enkeywords{Deep Learning, Image Recognition, CNN}
\end{enabstract}

\maketable

\mainmatter

\chapter{引言}
研究背景与意义...

\chapter{相关理论}
\section{深度学习基础}
\begin{definition}
卷积神经网络是...
\end{definition}

\begin{equation}\label{eq:cross-entropy}
  L = -\sum_{i=1}^N y_i \log \hat{y}_i
\end{equation}
如式 \eqref{eq:cross-entropy} 所示...

\chapter{实验结果}
\begin{figure}[htbp]
  \centering
  \includegraphics[width=0.6\textwidth]{figures/result.png}
  \caption{实验结果对比}
\end{figure}

\backmatter

\begin{myacknowledgement}
感谢我的导师...
\end{myacknowledgement}

\end{document}
```

编译命令:
```bash
xelatex main.tex
biber main
xelatex main.tex
xelatex main.tex
```

---

## 14. 版本管理与发布

### 14.1 版本号规范

严格遵循 **语义版本号 (Semantic Versioning 2.0.0)**:

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─ 向后兼容的问题修复
  │     └─────── 向后兼容的功能新增
  └───────────── 不兼容的 API 修改
```

### 14.2 变更日志

**文件**:[CHANGELOG.md](file:///workspace/CHANGELOG.md)

采用 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 格式,分节:
- `Unreleased` - 开发中的变更
- `Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`

### 14.3 发版步骤

1. **更新 `sduthesis.dtx` 版本号**:
   ```tex
   \ProvidesClass{sduthesis}[2025/06/01 1.2.0 Shandong University Thesis Template]
   ```
   `build.lua` 中的 `update_tag` 函数在 `l3build tag` 时会自动做此替换。

2. **更新 `CHANGELOG.md`**:将 `Unreleased` 移至 `[1.2.0] - 2025-06-01`。

3. **打 Git Tag**:
   ```bash
   git tag -a v1.2.0 -m "Version 1.2.0"
   git push origin v1.2.0
   ```

4. **构建 CTAN 包**:
   ```bash
   l3build ctan
   # 生成 sdutex.ctan.zip
   ```

5. **可选:上传至 CTAN**。

6. **GitHub Actions release.yml** 自动创建 Release 并上传产物。

---

## 15. 设计决策与权衡

### 15.1 决策 1:使用 DTX 格式管理核心代码

| 维度 | 选择 | 替代方案 |
|------|------|---------|
| 源代码形式 | DTX(代码 + 文档合一) | 直接维护 .cls / 代码文档分离 |

**理由**:
- LaTeX 社区标准格式,CTAN 发布要求
- 一份源文件同时生成 `.cls` 和 PDF 开发文档
- 通过 `%<!CLASS>` guard 精细控制抽取内容

**代价**:
- 开发时需在 DTX 注释与代码间切换,学习曲线略高
- 需要 DocStrip 解包步骤

### 15.2 决策 2:使用 LaTeX3 (expl3) 语法

**理由**:
- 现代语法、命名规范一致、可读性高
- 原生支持 tl/int/bool/dim/clist/seq/prop 等丰富数据结构
- 强大的键值对系统 (`l3keys`)、Hook 机制(v1.1.0 核心)
- LaTeX 项目官方推荐

### 15.3 决策 3:v1.1.0 插件化架构(内核 + 模块 + Hook)

**问题背景**:v1.0.0 时代码全部集中在 `sduthesis.dtx`,每增加一个学位类型就要在 switch-case 结构中插入分支,维护困难,难以独立定制。

**方案选择**:
```
内核 (sduthesis.cls)
  ├─ 仅保留通用能力
  ├─ 6 个命名 Hook(生命周期)
  └─ 模块加载器 (\begin{document} 触发)

模块 (modules/*.sty)
  └─ 通过 Hook 注册学位特定逻辑(如封面)
```

**收益**:
- 核心包"瘦身"为唯一真源,与 sduthesis 示例模板仓库解耦
- 学位类型可独立维护与版本演进
- 支持 `module={master, blindreview}` 组合加载(盲审 + 任意学位)
- 用户可自定义扩展 Hook

### 15.4 决策 4:字体平台回退策略

**问题**:CI 环境(Ubuntu)无 Windows 系统字体(Times New Roman / Arial / Consolas),直接使用会编译失败。

**方案**:
```tex
\sys_if_platform_windows:TF {
  \setmainfont{Times New Roman}
  \setsansfont{Arial}
  \setmonofont{Consolas}
} {
  \setmainfont{TeX Gyre Termes}   % 类 Times
  \setsansfont{TeX Gyre Heros}    % 类 Helvetica/Arial
  \setmonofont{TeX Gyre Cursor}   % 类 Courier
}
```

**收益**:Windows 用户获得最佳视觉一致性,Linux/macOS/CI 保持编译可通过。

### 15.5 决策 5:双引擎兼容(XeTeX + LuaTeX)

**分流点**:中文下划线/着重号包
- XeTeX → `xeCJKfntef`(原生 xeCJK 配套)
- LuaTeX → `luatexja`(luatexja 兼容层)

---

## 16. 开发指南与最佳实践

### 16.1 添加新选项

在 `sduthesis.dtx` 中找到 `\keys_define:nn { sdu / info }`（或 `sdu / option`）追加键:
```latex
\keys_define:nn { sdu / info } {
  myinfo .tl_set:N = \l__sdu_myinfo_tl,
}
```

同时声明对应变量（存储层）：
```latex
\tl_new:N \l__sdu_myinfo_tl
```

### 16.2 添加新模块

1. 在 `modules/` 下创建 `sduthesis-mymodule.sty`，通过 `\AddToHook` 注入行为:
   ```latex
   \NeedsTeXFormat{LaTeX2e}
   \ProvidesPackage{sduthesis-mymodule}[2026/08/18 v2.2.0 My module]

   % 通过 Hook 注入行为（或其他 Hook）
   \AddToHook{sduthesis/after-setup}{
     \typeout{* mymodule loaded}
   }

   \endinput
   ```

2. 在 `build.lua` 的 `tdsdirs` / `installfiles` / `tdslocations` 中注册该模块。
3. 可选:在内核 `\sdu_load_module:` 的盲审回退逻辑中考虑新模块。
4. 创建 `test/mymodule.tex` + 对应 `.tlg` 回归测试。

### 16.3 添加新测试

**回归测试**（推荐，l3build）：
```latex
% test/myfeature.tex
\documentclass{sduthesis}
\input{setup-test}
\input{regression-test}
\begin{document}
\START
\makecoverpage
\END
\end{document}
```


### 16.4 常见问题与解决

| 问题 | 解决 |
|------|------|
| 解包失败 "l3build not found" | `tlmgr install l3build` |
| 编译 "File sduthesis.cls not found" | 先 `make unpack` 或 `l3build unpack`,检查文件是否在搜索路径 |
| 测试不通过 | 检查 TeX Live 版本:`texlua -v`;推荐 2024 |
| 字体找不到 (Windows 正常 / Linux 失败) | 检查 TeX Gyre 字体包是否安装:`tlmgr install tex-gyre tex-gyre-math` |
| LuaTeX 编译失败 (xeCJKfntef 缺失) | v1.1.0+ 已按引擎分流;升级至最新版 |

---

## 17. 常见问题 FAQ

**Q1:如何切换到盲审模式?**
```latex
\SDUSetup{ module = {master, blindreview} }
```

**Q2:本科、硕士、博士封面如何切换?**
通过 `module` 键 + `degree` 键:
```latex
\SDUSetup{ module = {undergraduate} }              % 本科
\SDUSetup{ module = {master}, info = { degree = {硕士} } }  % 硕士
\SDUSetup{ module = {master}, info = { degree = {博士} } }  % 博士
```

**Q3:旧式 `\title`、`\author` 命令还能用吗?**
可以,完全向后兼容（顶层平铺写法）。但推荐使用 `info` 分组。

**Q4:如何自定义行距/页边距?**
```latex
\SDUSetup{
  option = {
    lineSpread = 1.5,
    pageLeft   = 3cm,
    pageRight  = 3cm,
    pageTop    = 2.5cm,
    pageBottom = 2.5cm,
  }
}
```

**Q5:如何加载自定义模块?**
```latex
% 通过 module=(推荐,begin{document} 时自动加载)
\SDUSetup{ module = {master, blindreview, my-custom-module} }
```

**Q6:定理环境如何编号?**
所有定理环境(theorem/definition/lemma/...)按章节编号(1.1, 1.2, 2.1...),通过 `\counterwithin{<env>}{chapter}` 实现。

---

## 附录 A:文件快速索引

| 文件 | 链接 |
|------|------|
| 核心文档类 (DTX) | [sduthesis.dtx](file:///workspace/src/sduthesis.dtx) |
| DocStrip 安装脚本 | [sduthesis.ins](file:///workspace/src/sduthesis.ins) |
| 工具宏包 | [sdutex.sty](file:///workspace/src/sdutex.sty) |
| 参考文献样式 | [sduthesis.bst](file:///workspace/src/sduthesis.bst) |
| 本科模块 | [sduthesis-undergraduate.sty](file:///workspace/modules/sduthesis-undergraduate.sty) |
| 硕士模块（含博士） | [sduthesis-master.sty](file:///workspace/modules/sduthesis-master.sty) |
| 盲审模块 | [sduthesis-blindreview.sty](file:///workspace/modules/sduthesis-blindreview.sty) |
| l3build 配置 | [build.lua](file:///workspace/build.lua) |
| Makefile | [Makefile](file:///workspace/Makefile) |
| 架构设计文档 | [ARCHITECTURE.md](file:///workspace/doc/ARCHITECTURE.md) |
| 内部实现文档 | [INTERNALS.md](file:///workspace/doc/INTERNALS.md) |
| 开发者指南 | [DEVELOP.md](file:///workspace/doc/DEVELOP.md) |
| 项目 README | [README.md](file:///workspace/README.md) |
| 测试流水线 | [test.yml](file:///workspace/.github/workflows/test.yml) |
| 测试索引 | [test/README.md](file:///workspace/test/README.md) |
| 变更日志 | [CHANGELOG.md](file:///workspace/CHANGELOG.md) |

---

> **文档版本**:Code Wiki v1.0
> **适用项目版本**:SDUTeX v1.1.0
> **生成日期**:2026-08-16
