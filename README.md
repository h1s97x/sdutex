# SDUTeX

山东大学 LaTeX 论文模板核心包 | Shandong University LaTeX Thesis Template Core Package

[![License](https://img.shields.io/badge/license-LPPL-blue.svg)](https://www.latex-project.org/lppl/)
[![GitHub stars](https://img.shields.io/github/stars/h1s97x/sdutex)](https://github.com/h1s97x/sdutex/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/h1s97x/sdutex)](https://github.com/h1s97x/sdutex/issues)

## 简介

SDUTeX 是山东大学学位论文 LaTeX 模板的**核心代码仓库**，提供：
- `sduthesis.cls` - 学位论文文档类（内核 + 模块 + Hook 插件化架构）
- `sdutex.sty` - 工具宏包
- `sduthesis.bst` - 参考文献样式 (GB/T 7714-2015，传统 LaTeX 工程兜底)

配套的 **sduthesis** 是示例模板仓库，供用户开箱即用；本仓库是"引擎"，两者共同构成完整生态。

## 特性

- 支持本科、硕士学位论文（博士学位论文通过 `degree={博士}` 覆盖）
- 支持盲审模式（隐藏个人信息、跳过答辩委员会页）
- 支持多模块组合加载：`module = {master, blindreview}`
- 遵循山东大学论文格式规范
- 基于 `\SDUSetup` 集中配置 + LaTeX3 l3keys 机制
- 基于 ctexbook 原生中文排版，兼容 Overleaf
- 完整的 l3build 回归测试（xetex/luatex 双引擎）

## 安装

### 方式一：从源码安装

```bash
# 解包
l3build unpack

# 安装到本地 TeX 目录
l3build install
```

### 方式二：直接使用

将 `src/` 目录解包生成的 `sduthesis.cls` 与 `modules/` 下的模块 `.sty` 复制到你的项目目录（或使用配套示例模板仓库 sduthesis）。

## 快速开始

通过 `\SDUSetup` 集中配置论文信息，支持 `info` / `option` 嵌套分组：

```latex
\documentclass{sduthesis}

\SDUSetup{
  module = {undergraduate},        % 论文类型：undergraduate / master，可叠加 blindreview
  info = {
    title      = {基于深度学习的图像识别研究},
    author     = {张三},
    studentId  = {2021001234},
    school     = {计算机科学与技术学院},
    major      = {计算机科学与技术},
    supervisor = {李四 教授},
    year       = {2025},
    month      = {6},
  },
  option = {
    lineSpread = 1.5,              % 行距
    pageLeft   = 3cm,              % 页边距
  },
}

\begin{document}

\frontmatter
\makecoverpage                     % 封面（由模块提供）

\begin{cnabstract}                 % 中文摘要
本文研究了基于深度学习的图像识别方法...
\cnkeywords{深度学习, 图像识别}
\end{cnabstract}

\maketable                         % 目录

\mainmatter
\chapter{引言}
...

% 参考文献（biblatex/biber）
\printbib

\end{document}
```

## 配置选项

### `\SDUSetup` 键值

`module` 键指定论文模块，`info` 组收纳论文元数据，`option` 组收纳排版参数。也支持顶层平铺写法（向后兼容）。

| 分组 | 键 | 说明 |
|------|-----|------|
| `module` | `module` | 模块列表，逗号分隔（`undergraduate` / `master` / `blindreview`） |
| `info` | `title` / `author` / `studentId` / `school` / `major` / `supervisor` / `year` / `month` | 论文基本信息 |
| `info` | `degree` / `committeeChair` / `committeeMembers` / `defenseDate` / `defensePlace` | 学位信息（master 模块） |
| `option` | `lineSpread` / `pageLeft` / `pageRight` / `pageTop` / `pageBottom` | 排版参数 |

### Getter 命令

内核导出若干 Getter 命令，供模块与用户读取配置值：

`\GetTitle` `\GetAuthor` `\GetStudentId` `\GetSchool` `\GetMajor` `\GetSupervisor` `\GetYear` `\GetMonth` `\GetDegree` `\GetCommitteeChair` `\GetCommitteeMembers` `\GetDefenseDate` `\GetDefensePlace`

## 插件化架构（内核 + 模块 + Hook）

SDUTeX 采用「内核 + 模块 + Hook」插件化架构。核心 `sduthesis.cls` 只负责引擎、Hook 与基础排版，学位类型相关逻辑（封面 / 摘要 / 页眉页脚）由独立模块承载：

| 模块文件 | 用途 |
|----------|------|
| `sduthesis-undergraduate.sty` | 本科论文模块 |
| `sduthesis-master.sty` | 硕士学位论文模块（硕博封面 + 答辩委员会页） |
| `sduthesis-blindreview.sty` | 盲审模块 |

### 组合加载 `module=`

通过 `\SDUSetup{ module = {...} }` 自由组合模块，模块在 `\begin{document}` 时自动加载：

```latex
\SDUSetup{
  module = {master, blindreview},   % 硕士 + 盲审
  info = {...},
}
```

> 盲审模块单独使用时，内核会自动前置加载本科模块。

### 内置 Hook

内核提供 6 个命名 Hook 供模块/用户扩展：
`sduthesis/after-setup`、`sduthesis/before-cover`、`sduthesis/cover-style`、`sduthesis/frontmatter/begin`、`sduthesis/mainmatter/begin`、`sduthesis/backmatter/begin`。

模块通过 `\AddToHook{...}{...}` 注入行为。

## 目录结构

```
sdutex/
├── src/                    # 源代码
│   ├── sduthesis.dtx       # 论文文档类（内核）
│   ├── sduthesis.ins       # 安装脚本
│   ├── sdutex.sty          # 工具宏包
│   └── sduthesis.bst       # 参考文献样式
├── modules/                # 插件模块
│   ├── sduthesis-undergraduate.sty
│   ├── sduthesis-master.sty
│   └── sduthesis-blindreview.sty
├── test/                   # l3build 回归测试（.tex/.tlg）
├── doc/                    # 开发者文档
├── Makefile
├── build.lua               # l3build 配置
└── README.md
```

## 构建命令

| 命令 | 说明 |
|------|------|
| `make` | 运行 l3build 回归测试 |
| `make test` | 运行测试（xetex + lualatex 双引擎） |
| `make install` | 安装到本地 |
| `make ctan` | 生成 CTAN 发布包 |
| `make clean` | 清理生成的文件 |

使用 l3build：

```bash
l3build unpack    # 解包
l3build check     # 测试
l3build doc       # 生成文档
l3build ctan      # 打包 CTAN
```

## 相关项目

| 项目 | 说明 |
|------|------|
| [sduthesis](https://github.com/h1s97x/sduthesis) | 示例模板仓库（用户使用入口） |
| [sdubeamer](https://github.com/h1s97x/sdubeamer) | Beamer 幻灯片模板 |

## 文档

- [开发者指南](doc/DEVELOP.md)
- [架构设计](doc/ARCHITECTURE.md)
- [项目概述](doc/README.md)

## 参与贡献

欢迎提交 Issue 和 Pull Request！

详情请参考 [DEVELOP.md](doc/DEVELOP.md)。

## 许可证

本项目采用 [LaTeX Project Public License (LPPL)](https://www.latex-project.org/lppl/) 许可证。

## 致谢

本项目参考了以下优秀的 LaTeX 模板：
- [SJTUThesis](https://github.com/sjtug/SJTUThesis)
- [THUThesis](https://github.com/tuna/thuthesis)
- [zjuthesis](https://github.com/TheNetAdmin/zjuthesis)

## 联系方式

- GitHub Issues: [h1s97x/sdutex](https://github.com/h1s97x/sdutex/issues)
