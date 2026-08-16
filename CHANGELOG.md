# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **插件化架构重构（v1.1.0）**：`sduthesis.dtx` 内核瘦身，仅保留引擎 + Hook + 基础排版，学位类型相关逻辑（封面/盲审）下沉到 `modules/*.sty`
- 引入 Hook 系统：`sduthesis/after-setup` / `before-cover` / `cover-style` / `frontmatter/begin` / `mainmatter/begin` / `backmatter/begin`
- 新增 `module=` 组合加载接口：`\SDUSetup{ module = {master, blindreview} }`，并在 begindocument 自动加载模块
- 新增 `modules/` 目录与 4 个模块：`undergraduate` / `master` / `doctor` / `blindreview`
- 字体配置增加平台回退：Windows 用系统字体，Linux/macOS 回退到 TeX Gyre，保证 CI 可编译
- 修复 `\language` 覆写 TeX 原语导致的编译错误；修复 `\hei`/`\CJKcircle` 在部分环境未定义的问题

### Added

- `test_module.tex`：新增 `module=` 组合加载测试
- 向后兼容旧式接口命令（`\title` / `\author*` / `\degree` / `\makecover` 等，含带星号别名）
- 定理环境（`definition` / `theorem` / `lemma` / `corollary` / `proposition` / `proof`）

### Fixed

- 定理环境命名统一为小写（`theorem` / `proof`），`proof` 复用 `amsthm` 内置环境
- `\title` / `\author` / `\date` 改用 `\DeclareDocumentCommand` 定义，兼容严格模式
- 修正版本信息笔误（`Updated: 2014` → `2024`）

## [1.0.0] - 2024-12-01

### Added

- Initial release
- `sduthesis.cls` - Main thesis document class
  - Bachelor thesis support
  - Master thesis support
  - Doctor thesis support
  - Blind review mode
  - Chinese and English language support
  - Basic cover page generation
  - Table of contents
  - Abstract environments (Chinese and English)
- `sdutex.sty` - Utility package
  - Math tools
  - Float tools
  - Format tools
- `sduthesis.bst` - Bibliography style (GB/T 7714-2015)
- `build.lua` - l3build configuration
- Test suite
  - `test_cover.tex`
  - `test_abstract.tex`
  - `test_math.tex`
  - `test_float.tex`
  - `test_bib.tex`
- Documentation
  - `doc/README.md`
  - `doc/DEVELOP.md`
  - `doc/ARCHITECTURE.md`
- Makefile for build automation

### Planned for v1.1.0

- More test coverage
- CTAN release
