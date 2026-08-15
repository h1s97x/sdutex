# SDUTeX 项目概述

## 什么是 SDUTeX？

SDUTeX 是山东大学 LaTeX 论文模板的核心包，提供：
- 学位论文文档类 (`sduthesis.cls`)
- 工具宏包 (`sdutex.sty`)
- 参考文献样式 (`sduthesis.bst`)

## 仓库结构

```
sdutex/
├── src/                    # 源代码
│   ├── sduthesis.dtx       # 论文文档类（DTX格式）
│   ├── sduthesis.ins       # 安装脚本
│   ├── sdutex.sty         # 工具宏包
│   └── sduthesis.bst       # 参考文献样式
├── test/                   # 测试用例
│   ├── test_cover.tex      # 封面测试
│   ├── test_abstract.tex   # 摘要测试
│   ├── test_math.tex       # 数学公式测试
│   ├── test_float.tex      # 图表浮动体测试
│   └── test_bib.tex       # 参考文献测试
├── doc/                    # 开发者文档
├── Makefile               # 构建脚本
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

**方式二：直接复制**

将 `src/` 目录下的 `.cls`、`.sty`、`.bst` 文件复制到你的项目目录。

### 使用

```latex
\documentclass[degree=bachelor]{sduthesis}

\SDUSetup{
  title = {你的论文题目},
  author = {你的姓名},
  school = {你的学院},
  major = {你的专业},
  student-id = {你的学号},
  supervisor = {你的导师},
  date = {2025年6月}
}

\begin{document}

\MakeCover

\begin{cnabstract}
摘要内容...
\end{cnabstract}

\tableofcontents

\chapter{第一章}
...

\end{document}
```

## 核心功能

| 功能 | 说明 |
|------|------|
| 多学位支持 | 本科、硕士、博士 |
| 中英文支持 | 中文论文、英文论文 |
| 盲审模式 | 隐藏作者信息 |
| 图表目录 | 自动生成图表目录 |
| 参考文献 | GB/T 7714-2015 样式 |

## 相关仓库

| 仓库 | 说明 |
|------|------|
| [sduthesis](https://github.com/h1s97x/sduthesis) | 示例模板仓库 |
| [sdubeamer](https://github.com/h1s97x/sdubeamer) | Beamer 幻灯片模板 |

## 参与贡献

欢迎提交 Issue 和 Pull Request！

详细开发指南请参考 [DEVELOP.md](DEVELOP.md)。

## 许可证

本项目采用 LaTeX Project Public License (LPPL) 许可证。
