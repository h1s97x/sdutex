# SDUTeX 项目概述

## 什么是 SDUTeX？

SDUTeX 是山东大学 LaTeX 论文模板的**核心包**，采用「内核 + 模块 + Hook」插件化架构，提供：
- 学位论文文档类 (`sduthesis.cls`，由 `sduthesis.dtx` 解包生成)
- 工具宏包 (`sdutex.sty`)
- 参考文献样式 (`sduthesis.bst`，传统 LaTeX 工程兜底)

配套的 **sduthesis** 是示例模板仓库（用户使用入口），本仓库是"引擎"，二者共同构成完整生态，且核心代码完全对齐（v2.2.0）。

## 仓库结构

```
sdutex/
├── src/                    # 源代码
│   ├── sduthesis.dtx       # 论文文档类（内核，DTX 格式）
│   ├── sduthesis.ins       # 安装脚本
│   ├── sdutex.sty          # 工具宏包
│   └── sduthesis.bst       # 参考文献样式
├── modules/                # 插件模块
│   ├── sduthesis-undergraduate.sty   # 本科
│   ├── sduthesis-master.sty          # 硕士（含博士）
│   └── sduthesis-blindreview.sty     # 盲审
├── test/                   # l3build 回归测试（.tex/.tlg）
├── doc/                    # 开发者文档
├── Makefile                # 构建脚本
├── build.lua              # l3build 配置
└── README.md
```

## 快速开始

### 安装

**方式一：从源码安装**

```bash
# 解包 DTX 文件
l3build unpack

# 安装到本地 TeX 目录
l3build install
```

**方式二：直接使用示例模板**

克隆配套的 [sduthesis](https://github.com/h1s97x/sduthesis) 示例模板仓库，开箱即用。

### 使用

```latex
\documentclass{sduthesis}

\SDUSetup{
  module = {undergraduate},
  info = {
    title      = {你的论文题目},
    author     = {你的姓名},
    studentId  = {你的学号},
    school     = {你的学院},
    major      = {你的专业},
    supervisor = {你的导师},
    year       = {2025},
    month      = {6},
  },
}

\begin{document}

\frontmatter
\makecoverpage

\begin{cnabstract}
摘要内容...
\end{cnabstract}

\maketable

\mainmatter
\chapter{第一章}
...

\printbib

\end{document}
```

## 核心功能

| 功能 | 说明 |
|------|------|
| 多学位支持 | 本科、硕士（博士通过 `degree={博士}`） |
| 中英文支持 | 中文论文、英文论文 |
| 盲审模式 | 隐藏作者信息、跳过答辩委员会页 |
| 模块组合 | `module = {master, blindreview}` |
| 参考文献 | biblatex/biber（GB/T 7714-2015） |

## 相关仓库

| 仓库 | 说明 |
|------|------|
| [sduthesis](https://github.com/h1s97x/sduthesis) | 示例模板仓库（用户使用入口） |
| [sdubeamer](https://github.com/h1s97x/sdubeamer) | Beamer 幻灯片模板 |

## 参与贡献

欢迎提交 Issue 和 Pull Request！

详细开发指南请参考 [DEVELOP.md](DEVELOP.md)。

## 许可证

本项目采用 LaTeX Project Public License (LPPL) 许可证。
