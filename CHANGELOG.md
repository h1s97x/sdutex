# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-08-18

### Changed

- **架构反向同步（以 sduthesis 为准）**：将 sduthesis 示例模板仓库已验证成熟的 `src/sduthesis.dtx` + `modules/*.sty` + `build.lua` + 回归测试体系同步回核心包 sdutex，消除"双仓库漂移"，恢复"核心包 → 示例模板"的单一真源
- **内核接口对齐 sduthesis v2.2.0**：`sduthesis.cls` 采用 ctexbook + Hook 插件化架构，`\SDUSetup` 支持 `info={...}` / `option={...}` 嵌套分组（也保留顶层平铺写法向后兼容）
- **模块体系对齐**：`module=` 键支持逗号分隔多模块组合（如 `{master, blindreview}`），盲审单独使用时自动前置加载本科模块
- **Hook 系统**：6 个文档阶段钩子（`after-setup` / `before-cover` / `cover-style` / `frontmatter/begin` / `mainmatter/begin` / `backmatter/begin`），模块通过 `\AddToHook` 注入行为
- **博士学位论文**：由 `master` 模块的 `degree={博士}` 键覆盖（不再需要独立的 doctor 模块）
- **参考文献**：改用 biblatex/biber（GB/T 7714-2015），`sduthesis.bst` 保留作为传统 LaTeX 工程兜底

### Added

- **回归测试体系**：采用 l3build `.tex/.tlg` 回归测试，覆盖 cover / abstract / appendix / bib / blindreview / master / master-blindreview / nested-setup / toc，支持 xetex/luatex 双引擎
- **master 模块**：硕博封面 + 答辩委员会页（`\makecommittee`），新增 `degree` / `committeeChair` / `committeeMembers` / `defenseDate` / `defensePlace` 配置键与对应 Getter
- **盲审模块**：`\IfBlindReviewTF` / `\IfBlindReviewF` 标志命令，封面个人信息行隐藏、答辩委员会页整页跳过

### Removed

- 移除独立的 `doctor` 模块（博士学位论文统一由 `module={master}` + `degree={博士}` 覆盖）
- 移除旧式集成测试（`test_*.tex`），替换为 l3build 回归测试

## [1.1.0] - 2026-08-18

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
