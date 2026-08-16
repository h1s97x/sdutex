# SDUTeX 项目 Code Wiki

> 山东大学 LaTeX 论文模板核心包 | Shandong University LaTeX Thesis Template Core Package
>
> 版本：v1.1.0 | 最后更新：2024/12/01

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
5. [插件化架构：内核 + 模块 + Hook](#5-插件化架构内核--模块--hook)
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

**SDUTeX** 是山东大学学位论文 LaTeX 模板的核心代码仓库。该项目提供一套符合山东大学学位论文格式规范的 LaTeX 工具集，支持本科、硕士、专业硕士、博士四种学位类型，支持中英文双语写作和盲审模式。

### 1.2 核心产物

| 产物文件 | 类型 | 说明 |
|---------|------|------|
| `sduthesis.cls` | Document Class | 学位论文文档类（核心引擎） |
| `sdutex.sty` | Style Package | 工具宏包（数学/浮动体/格式工具） |
| `sduthesis.bst` | BibTeX Style | GB/T 7714-2015 参考文献样式 |
| `sduthesis-undergraduate.sty` | Module | 本科毕业论文模块 |
| `sduthesis-master.sty` | Module | 硕士学位论文模块 |
| `sduthesis-doctor.sty` | Module | 博士学位论文模块 |
| `sduthesis-blindreview.sty` | Module | 盲审模式模块 |

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

- ✅ **四种学位类型**：本科、学术硕士、专业硕士、博士
- ✅ **双语支持**：中文论文、英文论文、中英双语
- ✅ **盲审模式**：自动隐藏作者、学号、导师等敏感信息
- ✅ **插件化架构**：内核 + 模块 + Hook，支持组合加载
- ✅ **LaTeX3 现代化语法**：遵循 expl3 编程规范
- ✅ **双引擎兼容**：XeLaTeX 与 LuaLaTeX 均支持
- ✅ **GB/T 7714-2015 参考文献**：自定义 .bst 样式
- ✅ **完善的测试体系**：.tex 集成测试 + .lvt/.tlg 回归测试

---

## 2. 整体架构

### 2.1 四层分层架构

```
┌──────────────────────────────────────────────────────┐
│                   用户接口层                            │
│  \documentclass{sduthesis}  \SDUSetup{...}             │
│  \MakeCover  \begin{cnabstract}  \GetTitle  ...        │
└──────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────┐
│                   配置解析层                            │
│  l3keys 键值对解析 · 文档类选项处理                     │
│  info 双语分组键值 · degree → module 映射               │
└──────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────┐
│                   核心功能层 (Kernel)                  │
│  变量系统 · 6 个命名 Hook · 模块加载器                  │
│  页面布局 · 字体配置 · 章节标题样式                     │
│  共享封面入口 \@@_cover_entry:nn                      │
│  摘要/声明/致谢/附录环境 · 页眉页脚 · 定理环境          │
└──────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────┐
│                   模块扩展层 (Modules)                  │
│  ┌──────────────┐ ┌─────────────┐ ┌────────────────┐  │
│  │undergraduate │ │ master      │ │ doctor         │  │
│  │(本科封面)    │ │(硕导封面)   │ │(博士封面)      │  │
│  └──────────────┘ └─────────────┘ └────────────────┘  │
│  ┌──────────────────┐                                  │
│  │ blindreview      │  →  可与上述任意组合               │
│  │(盲审隐藏敏感信息)│                                  │
│  └──────────────────┘                                  │
└──────────────────────────────────────────────────────┘
```

### 2.2 Hook 系统数据流

```
用户代码
  │
  ├─ \documentclass[degree=master]{sduthesis}
  │     → 文档类选项解析，写入 g_@@_module_pending_clist
  │
  ├─ \SDUSetup{ info = {...}, module = {blindreview} }
  │     → sdu/setup 键值处理
  │     → 触发 Hook: sduthesis/after-setup
  │
  ├─ \begin{document}
  │     → \AtBeginDocument 触发
  │     → @@_load_pending_modules:  （去重 + 解析 degree-xxx → 模块名）
  │     → \RequirePackage{sduthesis-master.sty}
  │     → \RequirePackage{sduthesis-blindreview.sty}
  │     → 模块通过 \hook_gput_code:nnn 注册 Hook 代码
  │
  ├─ \MakeCover
  │     → 触发 Hook: sduthesis/before-cover
  │     → 触发 Hook: sduthesis/cover-style
  │        → 调用已注册的 \sdu_cover_graduate: / \sdu_cover_undergraduate: / \sdu_cover_doctor:
  │
  ├─ \frontmatter / \mainmatter / \backmatter
  │     → 触发对应 Hook，供模块/用户扩展
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
├── modules/                      # 学位模块 (v1.1.0+ 插件化)
│   ├── sduthesis-blindreview.sty     # 盲审模块
│   ├── sduthesis-doctor.sty          # 博士学位模块
│   ├── sduthesis-master.sty          # 硕士学位模块（含专业硕士）
│   └── sduthesis-undergraduate.sty   # 本科学位模块
├── src/                          # 核心源代码
│   ├── sdutex.sty                # 工具宏包
│   ├── sduthesis.bst             # BibTeX 参考文献样式
│   ├── sduthesis.dtx             # 主文档类 (DTX 格式，核心)
│   └── sduthesis.ins             # DocStrip 安装脚本
├── test/                         # 测试用例
│   ├── README.md                 # 测试索引说明
│   ├── test_bib.bib              # 参考文献测试数据
│   ├── test_*.tex                # 集成测试（11 个 .tex 文件）
│   ├── test_*.lvt                # l3build 回归测试
│   ├── test_*.tlg                # l3build 基线日志
│   └── test_*.luatex.tlg         # LuaTeX 引擎基线日志
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

**文件**：[sduthesis.dtx](file:///workspace/src/sduthesis.dtx)

这是整个项目的核心文件，采用 **DTX (Documented LaTeX sources)** 格式编写，代码与文档合二为一。通过 `DocStrip` 工具（`\input docstrip.tex` + `sduthesis.ins`）从 DTX 中抽取 `%<!CLASS>` 标记的代码，生成最终的 `sduthesis.cls`。

#### 4.1.1 代码结构分区

| 行号范围 | 功能区块 | 说明 |
|---------|---------|------|
| L1–L31 | 文件头 | 版权声明、许可证、LPPL 维护信息 |
| L33–L68 | 引擎启动 | 加载 expl3 / l3keys2e，定义命名空间 `%<@@=sdu>` |
| L70–L162 | 全局变量定义 | 学位类型、模式开关、用户配置、布局尺寸 |
| L164–L217 | 辅助函数 | 盲审判断、信息隐藏、固定长度脱敏 |
| L219–L244 | 封面共享助手 | 封面标签宽度、`\@@_cover_entry:nn` 表格条目 |
| L246–L276 | Hook 系统 | 6 个命名 Hook 定义 + `\sdu_hook_use:n` |
| L278–L343 | 文档类选项解析 | `sdu/option` 键值组（degree/blind/twoside/module/lang/math-style/preset） |
| L344–L353 | 基础类加载 | `\LoadClass[...]{ctexbook}` |
| L355–L387 | 宏包依赖加载 | geometry / fancyhdr / graphicx / amsmath 等 |
| L389–L407 | 页面布局 | geometry 参数（上下边距、页眉页脚高度） |
| L409–L443 | 样式配置 | 中英文字体（平台回退）、参考文献样式、算法包 |
| L444–L459 | 定理环境 | definition/theorem/lemma/corollary/proposition |
| L461–L530 | 用户配置接口 | `sdu/setup` 键值组、`sdu/info` 双语分组键值 |
| L533–L620 | 用户命令定义 | `\SDUSetup`、旧式兼容命令（`\title`/`\author` 等）、Getter 命令族 |
| L622–L695 | 模块加载器 | `\sdu_load_module:n`、`\@@_resolve_module:n`、`\@@_load_pending_modules:`、`\AtBeginDocument` 钩子 |
| L697–L719 | Front/back matter | 重定义 `\frontmatter`/`\mainmatter`/`\backmatter` 触发 Hook |
| L721–L742 | 封面调度器 | `\MakeCover` → 触发 before-cover + cover-style Hook |
| L744–L800 | 摘要环境 | `cnabstract` / `enabstract` |
| L802–L844 | 声明页 | `\MakeDeclaration` 独创性声明 |
| L846–L867 | 致谢环境 | `acknowledgement` |
| L869–L884 | 附录命令 | `\MakeAppendix` + 公式/图表计数器随章节重置 |
| L886–L913 | 章节标题样式 | `\ctexset` 配置 chapter/section/subsection |
| L915–L949 | 页眉页脚 | `plain` 和 `sduthesis` 两种 fancyhdr 样式 |
| L951–L966 | 图表目录 | `\ListOfFigures` / `\ListOfTables` |
| L968–L996 | 定理环境增强 + 计数器绑定 | assumption/conjecture/remark/example |
| L997–L1004 | 消息定义 | 未知模块警告消息 |
| L1006–L1016 | 收尾 | `\ExplSyntaxOff` + `\endinput` |

#### 4.1.2 DTX 格式说明

DTX 文件的特点：
- **注释即文档**：以 `%%` 开头的行是可被提取生成 PDF 手册的 LaTeX 文档
- **条件抽取**：`%<!CLASS>` 标记的代码块会被 `sduthesis.ins` 抽取进 `sduthesis.cls`
- **命名空间替换**：`%<@@=sdu>` 指令将后续代码中所有 `@@` 在抽取时替换为 `sdu`（即 `\@@_foo:` → `\__sdu_foo:`）

安装脚本 [sduthesis.ins](file:///workspace/src/sduthesis.ins) 的核心行：
```tex
\generate{\file{sduthesis.cls}{\from{sduthesis.dtx}{CLASS}}}
```

---

### 4.2 工具宏包 sdutex.sty

**文件**：[sdutex.sty](file:///workspace/src/sdutex.sty)

独立于文档类的辅助宏包，提供三类可按需加载的工具集。用户可通过 `\usepackage[math,float,format]{sdutex}` 或 `\usepackage[all]{sdutex}` 使用。

#### 4.2.1 模块划分

| 模块开关 | 变量 | 默认 | 说明 |
|---------|------|------|------|
| `math` | `\g__sdut_math_bool` | true | 数学符号与定理工具 |
| `float` | `\g__sdut_float_bool` | true | 浮动体间距与子图兼容 |
| `format` | `\g__sdut_format_bool` | true | 排版格式工具（间距/列表） |
| `all` | — | — | 全部启用（choice 节点） |
| `none` | — | — | 全部禁用 |

#### 4.2.2 数学工具模块 (math)

| 命令/函数 | 说明 |
|----------|------|
| `\SDUTN` | 自然数集 $\mathbb{N}$ |
| `\SDUTZ` | 整数集 $\mathbb{Z}$ |
| `\SDUTQ` | 有理数集 $\mathbb{Q}$ |
| `\SDUTR` | 实数集 $\mathbb{R}$ |
| `\SDUTC` | 复数集 $\mathbb{C}$ |
| `\SDUT@eqref{#1}` | 带编号公式引用：`equation~\ref{#1}` |
| `\SDUT@begintheorem{#1}{#2}` | 定理环境开头：`\trivlist` + 粗体标题 |

#### 4.2.3 浮动体工具模块 (float)

| 命令/函数 | 说明 |
|----------|------|
| `\SDUT@floatbox` | 水平间距校正 (1em 偏移) |
| `\SDUT@setfloatskip` | 设置 `textfloatsep`/`intextsep`/`floatsep` = 12pt± |
| (AtBeginDocument) | listings 配置（keepspaces, ttfamily\small） |
| (包检测) | subfig / subcaption 兼容配置 |

#### 4.2.4 格式工具模块 (format)

| 命令/函数 | 说明 |
|----------|------|
| `\SDUT@textCJK` | 加载 xeCJKfntef 并开启 CJKspace/CJKmath |
| `\SDUT@urlsetup` | `\urlstyle{same}`（等宽字体同正文） |
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

**文件**：[sduthesis.bst](file:///workspace/src/sduthesis.bst)

自定义 BibTeX 样式文件，实现 **GB/T 7714-2015** 国家标准参考文献格式。在 `sduthesis.dtx` L435 中通过 `\bibliographystyle{sduthesis}` 自动启用。

---

### 4.4 模块系统 modules/

每个模块通过 `\hook_gput_code:nnn { sduthesis/cover-style } {<标签>} { ... }` 注册封面实现。可与其他模块（如 blindreview）组合加载。

#### 4.4.1 本科模块 sduthesis-undergraduate.sty

**文件**：[sduthesis-undergraduate.sty](file:///workspace/modules/sduthesis-undergraduate.sty)

**核心函数**：`\sdu_cover_undergraduate:`

封面布局元素：
1. 校徽 `logos/sdu_logo`（缺失回退到"山东大学"文字）
2. 标题横幅 `logos/sdu_title`（缺失回退到"本科毕业论文"文字）
3. "论文题目：" 标签 + 下划线式标题值
4. 信息表格（姓名、学号、学院、专业、指导教师）
5. 底部日期

注册 Hook：
```latex
\hook_gput_code:nnn { sduthesis/cover-style } { undergraduate } {
  \sdu_cover_undergraduate:
}
```

#### 4.4.2 硕士模块 sduthesis-master.sty

**文件**：[sduthesis-master.sty](file:///workspace/modules/sduthesis-master.sty)

**核心函数**：`\sdu_cover_graduate:`

封面布局差异（相对本科）：
- 标题横幅回退文字为"研究生学位论文"
- 根据 `\g__sdu_professional_bool` 显示"专业学位"或"学术学位"副标
- 显示 **中英文双标题**
- 信息表格字段不同：研究生姓名、学科专业、指导教师（含职称）、合作导师（可选）

注册 Hook 标签：`master`

#### 4.4.3 博士模块 sduthesis-doctor.sty

**文件**：[sduthesis-doctor.sty](file:///workspace/modules/sduthesis-doctor.sty)

**核心函数**：`\sdu_cover_doctor:`

整体布局与硕士基本一致，差异在于学位副标文字：
- 专业学位 → "专业学位（博士）论文"
- 学术学位 → "学术学位（博士）论文"

独立成模块以便未来博士特有定制（不影响硕士）。

注册 Hook 标签：`doctor`

#### 4.4.4 盲审模块 sduthesis-blindreview.sty

**文件**：[sduthesis-blindreview.sty](file:///workspace/modules/sduthesis-blindreview.sty)

**机制**：极为简洁 —— 仅将内核全局布尔开关 `\g__sdu_blind_bool` 置为 true：
```latex
\bool_gset_true:N \g__sdu_blind_bool
```

效果：内核中 `\@@_secret_info:n` 和 `\@@_secret_info_fixed:Nn` 自动将内容替换为 ███ 方块，从而隐藏封面中的作者姓名、学号、导师姓名等敏感信息。

**注意**：该模块应与学位模块（undergraduate/master/doctor）组合使用，仅负责"开关翻转"，不注册封面 Hook。

---

## 5. 插件化架构：内核 + 模块 + Hook

### 5.1 架构原则（v1.1.0）

v1.1.0 之前：所有学位特定逻辑集中在 `sduthesis.dtx` 单文件，难以维护和扩展。

v1.1.0 之后：采用**内核 + 模块 + Hook**三元架构：
- **内核 (Kernel)**：唯一真源，只保留学位无关的通用能力（引擎、变量系统、6 个 Hook、模块加载器、共享封面条目助手、通用环境如摘要/声明/致谢、页眉页脚、章节样式、定理环境等）
- **模块 (Module)**：学位相关逻辑独立到 `modules/*.sty`，通过 Hook 接入
- **Hook (钩子)**：6 个命名生命周期钩子，允许模块在正确时机注入代码

### 5.2 六个命名 Hook

| Hook 名称 | 触发时机 | 典型用途 |
|----------|---------|---------|
| `sduthesis/after-setup` | `\SDUSetup{...}` 执行完毕后 | 用户/模块在配置完成后执行自定义逻辑 |
| `sduthesis/before-cover` | `\MakeCover` 第 1 步，封面渲染前 | 盲审预处理、封面样式调整 |
| `sduthesis/cover-style` | `\MakeCover` 第 2 步，实际封面渲染 | 各学位模块注册自己的封面实现 |
| `sduthesis/frontmatter/begin` | `\frontmatter` 触发时 | 前置内容页码样式、摘要前置 |
| `sduthesis/mainmatter/begin` | `\mainmatter` 触发时 | 正文页眉切换、计数器重置 |
| `sduthesis/backmatter/begin` | `\backmatter` 触发时 | 参考文献/附录/致谢样式切换 |

### 5.3 Hook 使用示例

```latex
% 模块注册 Hook 代码（以本科为例）
\hook_gput_code:nnn { sduthesis/cover-style } { undergraduate } {
  \sdu_cover_undergraduate:
}

% 用户自定义扩展（在 \SDUSetup 后打印信息）
\hook_gput_code:nnn { sduthesis/after-setup } { my-custom-code } {
  \typeout{* 标题：\GetTitle}
}
```

### 5.4 模块加载流程

```
degree=master  或  module={master,blindreview}
        │
        ▼
写入 \g_@@_module_pending_clist = {degree-master, master, blindreview}
        │
        ▼
\begin{document}  (\AtBeginDocument 钩子)
        │
        ▼
\@@_load_pending_modules:
   ├─ 遍历 pending_clist，调用 \@@_resolve_module:n
   │     ├─ degree-bachelor     → 追加 undergraduate
   │     ├─ degree-master       → 追加 master
   │     ├─ degree-professional → 追加 master（共享同一模块）
   │     ├─ degree-doctor       → 追加 doctor
   │     └─ 其他（如 blindreview）→ 直接追加
   ├─ pending_clist 清空
   ├─ 对已解析的 module_clist 去重
   └─ 逐个调用 \sdu_load_module:n {xxx}
           │
           ├─ \file_if_exist:nTF {sduthesis-xxx.sty}
           │     ├─ 存在：\RequirePackage{sduthesis-xxx}
           │     └─ 不存在：\msg_warning 未知模块
```

### 5.5 组合加载示例

```latex
% 场景 1：学术硕士 + 盲审
\documentclass{sduthesis}
\SDUSetup{
  module = {master, blindreview},
  info = { zh/title = {...}, ... }
}

% 场景 2：专业硕士（通过 degree 选项自动映射）
\documentclass[degree=professional]{sduthesis}
% 等价于 module={master} 且 \g__sdu_professional_bool=true

% 场景 3：本科（默认）
\documentclass[degree=bachelor]{sduthesis}
% 等价于 module={undergraduate}
```

---

## 6. 配置系统

SDUTeX 的配置分为两层：**文档类选项**（`\documentclass[...]` 中设置，类加载时即生效）和 **用户级配置**（`\SDUSetup{...}` 中设置）。

### 6.1 文档类选项

```latex
\documentclass[degree=bachelor, blind=false, twoside=false, lang=zh, math-style=ISO, preset=sdu]{sduthesis}
```

| 选项 | 可选值 | 默认 | 说明 |
|------|-------|------|------|
| `degree` | bachelor / master / professional / doctor | bachelor | 学位类型（内部映射为 module 加载） |
| `blind` | true / false | false | 盲审模式（内部映射为加载 blindreview 模块） |
| `twoside` | true / false | false | 双面打印（传递给 ctexbook） |
| `lang` | zh / en / zh-en / en-zh | zh | 文档语言方向 |
| `math-style` | ISO / GB / french / upright | ISO | 数学排版风格 |
| `preset` | sdu / sjtu / none | sdu | 预设风格包 |
| `module` | 逗号分隔列表 | — | 组合加载模块 |
| `unknown` | — | — | 未知选项透传给 ctexbook |

### 6.2 用户级配置 `\SDUSetup`

支持两种配置风格：**传统星号区分** 和 **info 双语分组**（推荐，对齐 SJTUTeX）。

#### 6.2.1 方式一：info 双语分组（推荐）

```latex
\SDUSetup{
  info = {
    zh/title           = {基于深度学习的图像识别研究},
    en/title           = {Research on Deep Learning based Image Recognition},
    zh/author          = {张三},
    en/author          = {Zhang San},
    zh/student-id      = {2021001234},
    zh/school          = {计算机科学与技术学院},
    zh/major           = {计算机科学与技术},
    en/major           = {Computer Science and Technology},
    zh/supervisor      = {李教授},
    zh/supervisor-title= {教授},
    en/supervisor      = {Prof. Li},
    zh/co-supervisor   = {王副教授},     % 可选
    en/co-supervisor   = {Assoc. Prof. Wang},
    zh/date            = {2025年6月},
    zh/keywords        = {深度学习, 图像识别},
    en/keywords        = {Deep Learning, Image Recognition},
    zh/degree-name     = {工学学士},
    en/degree-name     = {Bachelor of Engineering}
  },
  module      = {master, blindreview},  % 可选：组合加载模块
  lang        = zh,
  math-style  = ISO,
  preset      = sdu,
  header-left = {\GetTitle},            % 自定义页眉左
  header-right= {\leftmark}             % 自定义页眉右
}
```

#### 6.2.2 方式二：传统星号区分（向后兼容）

```latex
\SDUSetup{
  title           = {中文标题},
  title*          = {English Title},
  author          = {作者},
  author*         = {Author},
  student-id      = {2021001234},
  school          = {学院},
  major           = {专业中文},
  major*          = {Major English},
  supervisor      = {导师},
  supervisor-title= {教授},
  supervisor*     = {Supervisor},
  co-supervisor   = {合作导师},
  date            = {2025年6月},
  keywords        = {关键词1, 关键词2},
  keywords*       = {Keyword1, Keyword2}
}
```

#### 6.2.3 sdu/info 键值映射表

| 键 (zh/) | 键 (en/) | 对应变量 |
|----------|----------|---------|
| `zh/title` | `en/title` | `\g_@@_title_tl` / `_en_tl` |
| `zh/author` | `en/author` | `\g_@@_author_tl` / `_en_tl` |
| `zh/student-id` | — | `\g_@@_student_id_tl` |
| `zh/school` | — | `\g_@@_school_tl` |
| `zh/major` | `en/major` | `\g_@@_major_tl` / `_en_tl` |
| `zh/supervisor` | `en/supervisor` | `\g_@@_supervisor_tl` / `_en_tl` |
| `zh/supervisor-title` | — | `\g_@@_supervisor_title_tl` |
| `zh/co-supervisor` | `en/co-supervisor` | `\g_@@_co_supervisor_tl` / `_en_tl` |
| `zh/date` | — | `\g_@@_date_tl` |
| `zh/keywords` | `en/keywords` | `\g_@@_cn_keywords_tl` / `_en_tl` |
| `zh/degree-name` | `en/degree-name` | `\g_@@_degree_name_tl` / `_en_tl` |

---

## 7. 核心变量与命名约定

### 7.1 LaTeX3 命名约定

SDUTeX 严格遵循 LaTeX3 (expl3) 命名规范：

```
\ <scope> _ <namespace> _ <name> : <signature>
│     │            │              │
│     │            │              └─ 参数签名：n / m / o / T / F / TF / V / N / c 等
│     │            └───────────────── 变量/函数的语义名
│     └────────────────────────────── 命名空间前缀（@@ = sdu）
└──────────────────────────────────── 作用域前缀
```

#### 作用域前缀

| 前缀 | 含义 | 示例 |
|------|------|------|
| `g_` | 全局 (global) | `\g_@@_blind_bool` |
| `l_` | 局部 (local) | — |
| `c_` | 常量 (constant) | `\c__sdut_version_tl`（在 sdutex.sty 中） |

> 注：`\g_@@_xxx` 在 DTX 抽取后变为 `\g__sdu_xxx`（双下划线 = 内部命名空间）。

#### 类型后缀

| 后缀 | 含义 | 示例 |
|------|------|------|
| `_tl` | Token List（文本/字符串） | `\g_@@_title_tl` |
| `_int` | 整数 | `\g_@@_type_int` |
| `_dim` | 尺寸/长度 | `\g_@@_cover_label_width_dim` |
| `_bool` | 布尔 | `\g_@@_blind_bool` |
| `_clist` | 逗号分隔列表 | `\g_@@_module_clist` |
| `_seq` | 序列 | — |
| `_prop` | 属性表 | — |
| `_str` | 字符串 | — |

### 7.2 核心全局变量一览

#### 学位与模式控制

| 变量 | 类型 | 取值/说明 |
|------|------|----------|
| `\g_@@_type_int` | int | 1=本科, 2=学硕, 3=专硕, 4=博士 |
| `\g_@@_blind_bool` | bool | 盲审模式开关 |
| `\g_@@_twoside_bool` | bool | 双面打印开关 |
| `\g_@@_professional_bool` | bool | 是否为专业学位（master 模块用） |
| `\g_@@_module_clist` | clist | 已解析待加载的模块列表 |
| `\g_@@_module_pending_clist` | clist | 原始待解析的模块请求（含 degree-xxx 占位） |

#### 用户配置数据

| 变量 | 类型 | 说明 |
|------|------|------|
| `\g_@@_title_tl` / `_en_tl` | tl | 中/英文标题 |
| `\g_@@_author_tl` / `_en_tl` | tl | 中/英文作者 |
| `\g_@@_student_id_tl` | tl | 学号 |
| `\g_@@_school_tl` | tl | 学院 |
| `\g_@@_major_tl` / `_en_tl` | tl | 中/英文专业 |
| `\g_@@_supervisor_tl` / `_en_tl` | tl | 中/英文导师 |
| `\g_@@_supervisor_title_tl` | tl | 导师职称（教授/副教授等） |
| `\g_@@_co_supervisor_tl` / `_en_tl` | tl | 中/英文合作导师（可选） |
| `\g_@@_date_tl` | tl | 提交日期 |
| `\g_@@_cn_keywords_tl` / `_en_tl` | tl | 中/英文关键词 |
| `\g_@@_degree_name_tl` / `_en_tl` | tl | 学位名称（工学学士等） |

#### 扩展选项

| 变量 | 类型 | 说明 |
|------|------|------|
| `\g_@@_lang_tl` | tl | zh / en / zh-en / en-zh |
| `\g_@@_math_style_tl` | tl | ISO / GB / french / upright |
| `\g_@@_preset_tl` | tl | sdu / sjtu / none |
| `\g_@@_has_listoffigures_bool` | bool | 是否有图目录 |
| `\g_@@_has_listoftables_bool` | bool | 是否有表目录 |
| `\g_@@_header_left_tl` | tl | 页眉左侧自定义 |
| `\g_@@_header_right_tl` | tl | 页眉右侧自定义 |

#### 布局尺寸

| 变量 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `\g_@@_cover_label_width_dim` | dim | 2.3cm | 封面信息表"标签列"宽度 |
| `\g_@@_cover_value_width_dim` | dim | 5.5cm | 封面信息表"值列"宽度 |

---

## 8. 关键函数与命令

### 8.1 内核辅助函数

| 函数 | 签名 | 说明 |
|------|------|------|
| `\@@_if_blind:TF` | `{#1}{#2}` | T=盲审分支，F=正常分支 |
| `\@@_secret_circle:n` | `{#1}` | 绘制 #1 个 ███ 方块（盲审脱敏） |
| `\@@_secret_info:n` | `{#1}` | 盲审时用 ███ 替换内容 |
| `\@@_secret_info_fixed:Nn` | `{#1}{#2}` | 对 token list 变量 #1 做固定长度 #2 的脱敏（学号用） |
| `\@@_cover_entry:nn` | `{#1}{#2}` | 共享封面表格条目：标签 #1 + 下划线值 #2 |

### 8.2 Hook 系统

| 函数/命令 | 说明 |
|----------|------|
| `\hook_new:n`（内置） | 内核调用 6 次创建命名 Hook |
| `\sdu_hook_use:n {#1}` | 公共 Hook 触发器封装 |
| `\hook_gput_code:nnn {<hook>} {<label>} {<code>}`（内置） | 模块/用户向 Hook 注册代码 |

### 8.3 模块加载器

| 函数 | 说明 |
|------|------|
| `\sdu_load_module:n {#1}` | 加载 `sduthesis-#1.sty`，不存在则警告 |
| `\sdu_load_module: {#1}` | 用户级命令包装 |
| `\@@_resolve_module:n {#1}` | 解析 `degree-xxx` → 实际模块名 |
| `\@@_load_pending_modules:` | 去重 + 批量加载（AtBeginDocument 时调用） |

### 8.4 用户公开命令

#### 配置与信息获取

| 命令 | 参数 | 说明 |
|------|------|------|
| `\SDUSetup` | `{m}` — 键值列表 | 主配置入口，执行后触发 after-setup Hook |
| `\GetTitle` / `\GetTitleEn` | 无 | 获取中/英文标题 |
| `\GetAuthor` / `\GetAuthorEn` | 无 | 获取中/英文作者 |
| `\GetStudentId` | 无 | 获取学号 |
| `\GetSchool` | 无 | 获取学院 |
| `\GetMajor` / `\GetMajorEn` | 无 | 获取中/英文专业 |
| `\GetSupervisor` / `\GetSupervisorEn` / `\GetSupervisorTitle` | 无 | 获取导师信息 |
| `\GetCoSupervisor` / `\GetCoSupervisorEn` | 无 | 获取合作导师 |
| `\GetDate` | 无 | 获取日期 |
| `\GetCnKeywords` / `\GetEnKeywords` | 无 | 获取关键词 |
| `\GetLang` / `\GetMathStyle` / `\GetPreset` | 无 | 获取扩展选项值 |
| `\GetDegreeName` / `\GetDegreeNameEn` | 无 | 获取学位名称 |

#### 页面生成命令

| 命令 | 说明 |
|------|------|
| `\MakeCover` | 触发 before-cover + cover-style Hook，生成封面 |
| `\makecover` | `\MakeCover` 的小写别名（已弃用，向后兼容） |
| `\MakeDeclaration` | 生成"学位论文独创性声明"页 |
| `\makedeclaration` | 小写别名（已弃用） |
| `\MakeAppendix` | `\appendix` + 公式/图表计数器随章节重置 |
| `\frontmatter` | 重定义，触发 frontmatter/begin Hook |
| `\mainmatter` | 重定义，触发 mainmatter/begin Hook |
| `\backmatter` | 重定义，触发 backmatter/begin Hook |
| `\ListOfFigures` | 图目录（带 PDF 书签） |
| `\ListOfTables` | 表目录（带 PDF 书签） |

#### 文档环境

| 环境 | 可选参数 | 说明 |
|------|---------|------|
| `cnabstract` | `[o]` 自定义标题 | 中文摘要，底部输出关键词；默认标题"摘 要" |
| `enabstract` | `[o]` 自定义标题 | 英文摘要，底部输出 Keywords；默认标题 ABSTRACT |
| `acknowledgement` | 无 | 致谢环境，标题"致 谢" |

#### 定理环境（内核内置）

| 环境 | 编号方式 | 样式 |
|------|---------|------|
| `definition` | 章节编号 | definition 风格 |
| `theorem` | 章节编号 | plain 风格 |
| `lemma` | 章节编号 | plain 风格 |
| `corollary` | 章节编号 | plain 风格 |
| `proposition` | 章节编号 | plain 风格 |
| `assumption` | 章节编号 | plain 风格（补充） |
| `conjecture` | 章节编号 | plain 风格（补充） |
| `remark` | 无编号（*型） | remark 风格（补充） |
| `example` | 章节编号 | definition 风格（补充） |
| `proof` | 无 | 复用 amsthm 内置环境 |

#### 旧式兼容命令（deprecated）

| 旧式命令 | 等价现代化写法 |
|---------|--------------|
| `\title{...}` | `\SDUSetup{title={...}}` |
| `\title*{...}` | `\SDUSetup{title*={...}}` |
| `\author{...}` / `\author*{...}` | `\SDUSetup{author={...}}` / `{author*={...}}` |
| `\degree{...}` | 文档类选项 `degree=...` |
| `\school{...}` | `\SDUSetup{school={...}}` |
| `\major{...}` / `\major*{...}` | `\SDUSetup{major={...}}` / `{major*={...}}` |
| `\supervisor{...}` / `\cosupervisor{...}` | `\SDUSetup{supervisor={...}}` / `{co-supervisor={...}}` |
| `\studentid{...}` | `\SDUSetup{student-id={...}}` |
| `\date{...}` | `\SDUSetup{date={...}}` |
| `\keywords{...}` / `\keywords*{...}` | `\SDUSetup{keywords={...}}` / `{keywords*={...}}` |
| `\language{...}` | 已完全弃用（保留避免编译错误） |

---

## 9. 依赖关系图

### 9.1 宏包依赖

```
sduthesis.cls (内核)
  │
  ├─ 基础类：ctexbook
  │     ├─ ctex（中文支持核心）
  │     └─ book（标准 LaTeX 书籍类）
  │
  ├─ 加载 expl3 / l3keys2e（LaTeX3 基础设施）
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
  └─ 中文下划线（按引擎分流）
        ├─ XeTeX  → xeCJKfntef
        └─ LuaTeX → luatexja（兼容层）

sdutex.sty (工具宏包，可选独立加载)
  ├─ expl3 / l3keys2e
  ├─ amsmath / amssymb
  └─ (按需) xeCJKfntef / graphicx / caption 等

sduthesis-undergraduate.sty / master.sty / doctor.sty
  └─ 通过 \RequirePackage 机制依赖内核（因在内核 \AtBeginDocument 中加载）

sduthesis-blindreview.sty
  └─ 仅翻转内核的 \g__sdu_blind_bool
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
                │                    │                    │
     \AtBeginDocument 时 \RequirePackage 加载各个模块
                │                    │                    │
                ▼                    ▼                    ▼
   ┌────────────────────┐ ┌──────────────────┐ ┌─────────────────────┐
   │undergraduate.sty   │ │ master.sty       │ │ doctor.sty          │
   │(注册 cover-style)  │ │(注册 cover-style)│ │(注册 cover-style)   │
   └─────────┬──────────┘ └────────┬─────────┘ └──────────┬──────────┘
             │                    │                      │
             └────────────────────┼──────────────────────┘
                                  │ 可组合
                                  ▼
                       ┌─────────────────────┐
                       │ blindreview.sty     │
                       │ (翻盲审开关，无 Hook)│
                       └─────────────────────┘
```

### 9.3 字体依赖（按平台回退）

| 平台 | 衬线字体 (main) | 无衬线字体 (sans) | 等宽字体 (mono) |
|------|----------------|------------------|----------------|
| Windows | Times New Roman (AutoFakeBold) | Arial | Consolas |
| Linux / macOS / CI | TeX Gyre Termes | TeX Gyre Heros | TeX Gyre Cursor |

---

## 10. 构建系统

项目采用 **双轨构建体系**：传统 Makefile + l3build（LaTeX 官方标准构建工具）。

### 10.1 Makefile 目标

**文件**：[Makefile](file:///workspace/Makefile)

| 目标 | 说明 | 对应 l3build |
|------|------|-------------|
| `make all` (默认) | = `make test` | — |
| `make unpack` | 解包 DTX 生成 .cls/.sty/.bst，复制到 build/ | `l3build unpack` |
| `make test` | 集成测试：xelatex + lualatex 双引擎遍历所有 test_*.tex | —（自建集成测试） |
| `make test-l3` | l3build 回归测试（.lvt/.tlg） | `l3build check` |
| `make install` | 安装到用户目录 `~/texmf/tex/latex/sdutex/`，运行 texhash | `l3build install` |
| `make ctan` | 生成 CTAN 发布包 sdutex-ctan.zip | `l3build ctan` |
| `make clean` | 删除 build/、test/build/、tlpkg/、src/*.cls、src/*.sty、日志等 | `l3build clean` + 自定义 |
| `make help` | 打印帮助信息 | — |

### 10.2 l3build 配置详解

**文件**：[build.lua](file:///workspace/build.lua)

核心配置项：

```lua
module = "sdutex"                        -- 模块名
sourcefiledir = "src"                    -- 源文件目录
sourcefiles = {"sduthesis.dtx", "sduthesis.ins"}
modulefiledir = "modules"                -- 模块文件目录
modulefiles = { -- 4 个学位模块 .sty }

-- 双引擎回归测试
checkengines = {"xetex", "luatex"}       -- 测试引擎
stdengine   = "xetex"
checkruns   = 3                          -- 每个测试编译 3 轮（toc/bib 等）
checkopts   = "-file-line-error -halt-on-error -interaction=nonstopmode"

-- 回归测试文件（10 组 lvt/tlg）
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

SDUTeX 采用**双层测试架构**：

```
┌────────────────────────────────────────────┐
│  Layer 1：传统集成测试 (.tex)               │
│  · 11 个 .tex 覆盖典型场景                  │
│  · xelatex + lualatex 双引擎                │
│  · 只判断是否编译成功（exit code 0）        │
│  · 命令：make test                          │
├────────────────────────────────────────────┤
│  Layer 2：l3build 回归测试 (.lvt + .tlg)    │
│  · 10 组 lvt 脚本 + 对应的 tlg 基线         │
│  · 每个测试 3 轮编译                        │
│  · xetex + luatex 双引擎（luatex 有独立 .luatex.tlg）│
│  · 对比实际日志与预期基线，逐行比对          │
│  · 命令：make test-l3 / l3build check       │
└────────────────────────────────────────────┘
```

### 11.1 集成测试用例 (.tex)

共 11 个测试文件，位于 [test/](file:///workspace/test/)：

| 测试文件 | 覆盖内容 |
|---------|---------|
| [test_cover.tex](file:///workspace/test/test_cover.tex) | 封面生成（本科） |
| [test_abstract.tex](file:///workspace/test/test_abstract.tex) | 中英文摘要环境 |
| [test_math.tex](file:///workspace/test/test_math.tex) | 数学公式排版 |
| [test_float.tex](file:///workspace/test/test_float.tex) | 图表浮动体 |
| [test_bib.tex](file:///workspace/test/test_bib.tex) | 参考文献（配合 test_bib.bib） |
| [test_full.tex](file:///workspace/test/test_full.tex) | 完整模板全流程 |
| [test_graduate.tex](file:///workspace/test/test_graduate.tex) | 研究生（硕士/博士）封面 |
| [test_blind.tex](file:///workspace/test/test_blind.tex) | 盲审模式（敏感信息脱敏） |
| [test_module.tex](file:///workspace/test/test_module.tex) | module= 组合加载（硕士+盲审等） |
| [test_acknowledgement.tex](file:///workspace/test/test_acknowledgement.tex) | 致谢环境 |
| [test_appendix.tex](file:///workspace/test/test_appendix.tex) | 附录环境 (\MakeAppendix) |

### 11.2 l3build 回归测试 (.lvt/.tlg)

回归测试通过"脚本 + 基线日志"对比，精确捕获任意输出偏差：

| 测试组 | 覆盖内容 | 基线文件 |
|--------|---------|---------|
| test_cover | 封面 + info 分组键值 | `.tlg` + `.luatex.tlg` |
| test_abstract | 摘要环境 + 旧式接口兼容 | `.tlg` + `.luatex.tlg` |
| test_math | 数学风格选项 | `.tlg` + `.luatex.tlg` |
| test_float | 浮动体 | `.tlg` + `.luatex.tlg` |
| test_module | module= 组合加载 | `.tlg` + `.luatex.tlg` |
| test_info | info 完整分组键值 | `.tlg` + `.luatex.tlg` |
| test_lang | lang/preset 选项 | `.tlg` + `.luatex.tlg` |
| test_theorem | 定理环境 | `.tlg` + `.luatex.tlg` |
| test_listoffigures | 图表目录 | `.tlg` + `.luatex.tlg` |
| test_mathstyle | math-style 选项 | `.tlg` + `.luatex.tlg` |

### 11.3 测试执行流程

**Make 集成测试**：
```bash
make test
  → mkdir build/test/
  → 复制 .ins/.dtx/.tex/.bib/.sty/.bst 到 build/test/
  → cd build/test && xelatex sduthesis.ins  (解包)
  → 对 xelatex 和 lualatex 双引擎：
       遍历每个 test_*.tex：
         $engine -interaction=nonstopmode -halt-on-error $f
         非零退出码 → 标记失败
  → 统计通过的 PDF 数量
  → 若失败则 exit 1
```

**l3build 回归测试**：
```bash
l3build check
  → 自动解包 DTX
  → 对 xetex 和 luatex 引擎分别执行：
       对每个测试文件运行 3 轮编译
       收集 .log 输出
       与对应的 .tlg / .luatex.tlg 基线逐行比对
       差异 → FAIL
```

---

## 12. CI/CD 流程

### 12.1 GitHub Actions Workflows

**目录**：[.github/workflows/](file:///workspace/.github/workflows/)

#### 12.1.1 测试流水线 (test.yml)

**触发条件**：push 到 main 分支 / PR 到 main 分支 / workflow_dispatch（路径限定：src/**、test/**、Makefile、build.lua、tl_packages、test.yml）

**执行步骤**：
1. `actions/checkout@v4` — 检出代码
2. `TeX-Live/setup-texlive-action@v4` — 安装 TeX Live，包清单来自 `.github/tl_packages`
3. `make test` — 运行集成测试
4. 失败时上传日志 Artifact：`build/test/*.log`（`actions/upload-artifact@v4`）

#### 12.1.2 发布流水线 (release.yml)

Tag 触发自动发布，构建 CTAN 包并创建 GitHub Release。

#### 12.1.3 CNB 同步流水线 (sync-cnb.yml)

同步 Cloud Native Buildpacks 相关配置。

---

## 13. 项目运行方式

### 13.1 环境要求

| 依赖 | 最低版本 | 推荐版本 | 说明 |
|------|---------|---------|------|
| TeX Live | 2020 | 2024 | 需包含 l3build、ctex、geometry、fancyhdr 等 |
| XeLaTeX / LuaLaTeX | — | 随 TeX Live 2024 | 双引擎均支持；pdfLaTeX 不支持中文 |
| Git | 任意 | 最新 | 版本管理 |
| Make | GNU Make 3.8+ | 4.x | Makefile 驱动构建 |
| Lua | 随 TeX Live | 5.3+ | l3build 运行时 |

### 13.2 安装流程

#### 方式一：从源码安装（推荐）

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

#### 方式二：直接复制使用

将 `src/` 下的 `.cls`、`.sty`、`.bst` 文件和 `modules/*.sty` 复制到用户的论文项目目录中即可使用（无需安装到系统）。

### 13.3 验证安装

```bash
# 运行测试套件
make test         # 集成测试（xelatex + lualatex）
make test-l3      # l3build 回归测试
```

### 13.4 用户论文项目最小示例

```latex
% main.tex
\documentclass[degree=bachelor]{sduthesis}

\SDUSetup{
  info = {
    zh/title      = {基于深度学习的图像识别研究},
    en/title      = {Research on Deep Learning based Image Recognition},
    zh/author     = {张三},
    en/author     = {Zhang San},
    zh/school     = {计算机科学与技术学院},
    zh/major      = {计算机科学与技术},
    en/major      = {Computer Science and Technology},
    zh/supervisor = {李教授},
    zh/supervisor-title = {教授},
    zh/student-id = {2021001234},
    zh/date       = {2025年6月},
    zh/keywords   = {深度学习, 图像识别, 卷积神经网络},
    en/keywords   = {Deep Learning, Image Recognition, CNN}
  }
}

\begin{document}

\MakeCover

\MakeDeclaration

\begin{cnabstract}
本文研究了基于深度学习的图像识别方法...
\end{cnabstract}

\begin{enabstract}
This paper studies image recognition methods based on deep learning...
\end{enabstract}

\tableofcontents
\ListOfFigures
\ListOfTables

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
如式 \SDUT@eqref{eq:cross-entropy} 所示...

\chapter{实验结果}
\begin{figure}[htbp]
  \centering
  \includegraphics[width=0.6\textwidth]{figures/result.png}
  \caption{实验结果对比}
\end{figure}

\backmatter

\begin{acknowledgement}
感谢我的导师...
\end{acknowledgement}

\bibliography{refs}   % refs.bib

\end{document}
```

编译命令：
```bash
xelatex main.tex
biber main          % 或 bibtex main
xelatex main.tex
xelatex main.tex
```

---

## 14. 版本管理与发布

### 14.1 版本号规范

严格遵循 **语义版本号 (Semantic Versioning 2.0.0)**：

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─ 向后兼容的问题修复
  │     └─────── 向后兼容的功能新增
  └───────────── 不兼容的 API 修改
```

### 14.2 变更日志

**文件**：[CHANGELOG.md](file:///workspace/CHANGELOG.md)

采用 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 格式，分节：
- `Unreleased` — 开发中的变更
- `Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security`

### 14.3 发版步骤

1. **更新 `sduthesis.dtx` 版本号**：
   ```tex
   \ProvidesClass{sduthesis}[2025/06/01 1.2.0 Shandong University Thesis Template]
   ```
   `build.lua` 中的 `update_tag` 函数在 `l3build tag` 时会自动做此替换。

2. **更新 `CHANGELOG.md`**：将 `Unreleased` 移至 `[1.2.0] - 2025-06-01`。

3. **打 Git Tag**：
   ```bash
   git tag -a v1.2.0 -m "Version 1.2.0"
   git push origin v1.2.0
   ```

4. **构建 CTAN 包**：
   ```bash
   l3build ctan
   # 生成 sdutex.ctan.zip
   ```

5. **可选：上传至 CTAN**。

6. **GitHub Actions release.yml** 自动创建 Release 并上传产物。

---

## 15. 设计决策与权衡

### 15.1 决策 1：使用 DTX 格式管理核心代码

| 维度 | 选择 | 替代方案 |
|------|------|---------|
| 源代码形式 | DTX（代码 + 文档合一） | 直接维护 .cls / 代码文档分离 |

**理由**：
- LaTeX 社区标准格式，CTAN 发布要求
- 一份源文件同时生成 `.cls` 和 PDF 开发文档
- 通过 `%<!CLASS>` guard 精细控制抽取内容

**代价**：
- 开发时需在 DTX 注释与代码间切换，学习曲线略高
- 需要 DocStrip 解包步骤

### 15.2 决策 2：使用 LaTeX3 (expl3) 语法

**理由**：
- 现代语法、命名规范一致、可读性高
- 原生支持 tl/int/bool/dim/clist/seq/prop 等丰富数据结构
- 强大的键值对系统 (`l3keys`)、Hook 机制（v1.1.0 核心）
- LaTeX 项目官方推荐

### 15.3 决策 3：v1.1.0 插件化架构（内核 + 模块 + Hook）

**问题背景**：v1.0.0 时代码全部集中在 `sduthesis.dtx`，每增加一个学位类型就要在 switch-case 结构中插入分支，维护困难，难以独立定制。

**方案选择**：
```
内核 (sduthesis.cls)
  ├─ 仅保留通用能力
  ├─ 6 个命名 Hook（生命周期）
  └─ 模块加载器 (AtBeginDocument 触发)

模块 (modules/*.sty)
  └─ 通过 Hook 注册学位特定逻辑（如封面）
```

**收益**：
- 核心包"瘦身"为唯一真源，与 sduthesis 示例模板仓库解耦
- 学位类型可独立维护与版本演进
- 支持 `module={master, blindreview}` 组合加载（盲审 + 任意学位）
- 用户可自定义扩展 Hook

### 15.4 决策 4：字体平台回退策略

**问题**：CI 环境（Ubuntu）无 Windows 系统字体（Times New Roman / Arial / Consolas），直接使用会编译失败。

**方案**：
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

**收益**：Windows 用户获得最佳视觉一致性，Linux/macOS/CI 保持编译可通过。

### 15.5 决策 5：双引擎兼容（XeTeX + LuaTeX）

**分流点**：中文下划线/着重号包
- XeTeX → `xeCJKfntef`（原生 xeCJK 配套）
- LuaTeX → `luatexja`（luatexja 兼容层）

---

## 16. 开发指南与最佳实践

### 16.1 添加新选项

在 `sduthesis.dtx` 中找到 `\keys_define:nn { sdu / setup }` 追加：
```latex
my-option .tl_gset:N = \g_@@_my_option_tl,
```

若需在文档类选项层面也支持：
```latex
\keys_define:nn { sdu / option } {
  my-option .tl_gset:N = \g_@@_my_option_tl,
}
```

### 16.2 添加新模块

1. 在 `modules/` 下创建 `sduthesis-mymodule.sty`：
   ```latex
   \NeedsTeXFormat{LaTeX2e}
   \ProvidesExplPackage{sduthesis-mymodule}{2025/06/01}{1.0.0}{My module}

   % 注册到 cover-style Hook（或其他 Hook）
   \hook_gput_code:nnn { sduthesis/cover-style } { mymodule } {
     \typeout{* mymodule loaded}
   }

   \endinput
   ```

2. 在 `build.lua` 的 `modulefiles` 和 `installfiles` / `tdslocations` 中注册该模块。
3. 可选：在 `\@@_resolve_module:n` 中添加 `degree-xxx` → 模块名映射。
4. 在 `\msg_new:nnn { sdutex } { unknown-module }` 可用模块列表中追加。
5. 创建 `test/test_mymodule.tex` + 对应 `.lvt/.tlg`。

### 16.3 添加新测试

**集成测试**（快速验证）：
```latex
% test/test_myfeature.tex
\documentclass[degree=bachelor]{sduthesis}
\SDUSetup{title={测试}, author={作者}}
\begin{document}
\MakeCover
\chapter{Test}
\end{document}
```

**l3build 回归测试**（精确比对）：
```latex
% test/test_myfeature.lvt
\input{regression-test}
\documentclass[degree=bachelor]{showexpl}
\usepackage{sduthesis}
\begin{document}
\START
\TEST{配置并获取标题}{
  \SDUSetup{title={测试标题}}
  \GetTitle
}
\vfil\eject
\end{document}
```
然后运行 `l3build save test_myfeature` 生成 `.tlg` 基线。

### 16.4 常见问题与解决

| 问题 | 解决 |
|------|------|
| 解包失败 "l3build not found" | `tlmgr install l3build` |
| 编译 "File sduthesis.cls not found" | 先 `make unpack` 或 `l3build unpack`，检查文件是否在搜索路径 |
| 测试不通过 | 检查 TeX Live 版本：`texlua -v`；推荐 2024 |
| 字体找不到 (Windows 正常 / Linux 失败) | 检查 TeX Gyre 字体包是否安装：`tlmgr install tex-gyre tex-gyre-math` |
| LuaTeX 编译失败 (xeCJKfntef 缺失) | v1.1.0+ 已按引擎分流；升级至最新版 |

---

## 17. 常见问题 FAQ

**Q1：如何切换到盲审模式？**
```latex
% 方式 1：文档类选项
\documentclass[blind]{sduthesis}

% 方式 2：组合加载模块
\SDUSetup{ module = {master, blindreview} }
```

**Q2：本科、硕士、博士封面如何自动切换？**
通过 `degree=` 选项：
```latex
\documentclass[degree=bachelor]{sduthesis}   % 本科
\documentclass[degree=master]{sduthesis}     % 学硕
\documentclass[degree=professional]{sduthesis} % 专硕
\documentclass[degree=doctor]{sduthesis}     % 博士
```

**Q3：旧式 `\title`、`\author` 命令还能用吗？**
可以，完全向后兼容。但推荐使用 `info` 分组或 `\SDUSetup` 的现代化写法。

**Q4：如何自定义页眉？**
```latex
\SDUSetup{
  header-left = {山东大学学位论文},
  header-right = {第 \thepage 页}
}
\pagestyle{sduthesis}  % 启用自定义页眉页脚样式
```

**Q5：如何加载自定义模块？**
```latex
% 方式 1：通过 module=（推荐，AtBeginDocument 自动加载）
\SDUSetup{ module = {master, blindreview, my-custom-module} }

% 方式 2：随时手动加载
\sdu_load_module: {my-custom-module}
```

**Q6：定理环境如何编号？**
所有定理环境（theorem/definition/lemma/...）按章节编号（1.1, 1.2, 2.1...），通过 `\counterwithin{<env>}{chapter}` 实现。

---

## 附录 A：文件快速索引

| 文件 | 链接 |
|------|------|
| 核心文档类 (DTX) | [sduthesis.dtx](file:///workspace/src/sduthesis.dtx) |
| DocStrip 安装脚本 | [sduthesis.ins](file:///workspace/src/sduthesis.ins) |
| 工具宏包 | [sdutex.sty](file:///workspace/src/sdutex.sty) |
| 参考文献样式 | [sduthesis.bst](file:///workspace/src/sduthesis.bst) |
| 本科模块 | [sduthesis-undergraduate.sty](file:///workspace/modules/sduthesis-undergraduate.sty) |
| 硕士模块 | [sduthesis-master.sty](file:///workspace/modules/sduthesis-master.sty) |
| 博士模块 | [sduthesis-doctor.sty](file:///workspace/modules/sduthesis-doctor.sty) |
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

> **文档版本**：Code Wiki v1.0
> **适用项目版本**：SDUTeX v1.1.0
> **生成日期**：2026-08-16
