# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **中英双语字段分组化**：对齐 SJTUTeX，新增 `\SDUSetup{ info = { zh/title = {...}, en/title = {...} } }` 分组键值方式，替代传统的 `title` / `title*` 星号区分（旧式写法仍向后兼容）
- **扩展选项面**：新增 `lang`（zh/en/zh-en/en-zh）、`math-style`（ISO/GB/french/upright）、`preset`（sdu/sjtu/none）选项
- **页眉样式增强**：新增 `header-left` / `header-right` 页眉配置项，新增 `sduthesis` 页眉样式
- **插件化架构重构（v1.1.0）**：`sduthesis.dtx` 内核瘦身，仅保留引擎 + Hook + 基础排版，学位类型相关逻辑（封面/盲审）下沉到 `modules/*.sty`
- 引入 Hook 系统：`sduthesis/after-setup` / `before-cover` / `cover-style` / `frontmatter/begin` / `mainmatter/begin` / `backmatter/begin`
- 新增 `module=` 组合加载接口：`\SDUSetup{ module = {master, blindreview} }`，并在 begindocument 自动加载模块
- 新增 `modules/` 目录与 4 个模块：`undergraduate` / `master` / `doctor` / `blindreview`
- 字体配置增加平台回退：Windows 用系统字体，Linux/macOS 回退到 TeX Gyre，保证 CI 可编译
- 修复 `\language` 覆写 TeX 原语导致的编译错误；修复 `\hei`/`\CJKcircle` 在部分环境未定义的问题
- LuaTeX 兼容：`xeCJKfntef` 仅在 XeTeX 下加载，LuaTeX 使用 `luatexja` 兼容层

### Added

- **info 分组键值**：`\SDUSetup{ info = { zh/title = {...}, en/title = {...}, zh/author = {...}, ... } }` 中英双语同块配置
- **图表目录**：`\ListOfFigures` / `\ListOfTables` 命令
- **增强定理环境**：新增 `assumption`（假设）、`conjecture`（猜想）、`remark`（注）、`example`（例），并为所有定理环境添加章节编号
- **l3build 回归测试**：新增 `.lvt/.tlg` 测试体系，覆盖双语分组、选项配置、定理环境等核心功能
- **双引擎测试**：l3build 配置支持 xetex/luatex 双引擎测试
- `test_module.tex`：新增 `module=` 组合加载测试
- 向后兼容旧式接口命令（`\title` / `\author*` / `\degree` / `\makecover` 等，含带星号别名）
- 定理环境（`definition` / `theorem` / `lemma` / `corollary` / `proposition` / `proof`）
- 新增 Getter 命令：`\GetLang` / `\GetMathStyle` / `\GetPreset` / `\GetDegreeName` / `\GetDegreeNameEn` / `\GetSupervisorEn` / `\GetCoSupervisorEn`

### Fixed

- **`header-left` / `header-right` 配置项真正生效**：`sduthesis` 页眉样式不再硬编码居中标题，改为默认左侧标题、右侧章节名，并实际消费两个配置项
- **`cnabstract` 支持可选参数自定义标题**：与 `enabstract` 行为对齐，默认仍为“摘要”
- 修正 `info` 分组注释中未实现的点分式写法的误导说明
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
