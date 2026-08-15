# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- 统一用户接口为 `\SDUSetup` + getter 的现代化方案
- 测试文件全部改用大写命令 `\MakeCover` / `\MakeDeclaration`
- 修复测试文件中的旧式命令和错误的 `\usepackage{test_bib}`
- `test_blind.tex` 改用 `degree=` 选项
- 封面 logo 支持可缺失降级（文件不存在时使用文字占位）
- `make test` 编译失败时正确返回退出码 1
- CI 使用 `TeX-Live/setup-texlive-action` 安装依赖

### Added

- 向后兼容旧式接口命令（`\title` / `\author*` / `\degree` / `\makecover` 等，含带星号别名）
- 定理环境（`definition` / `theorem` / `lemma` / `corollary` / `proposition` / `proof`）

### Fixed

- 定理环境命名统一为小写（`theorem` / `proof`），`proof` 复用 `amsthm` 内置环境
- `\title` / `\author` / `\date` 改用 `\DeclareDocumentCommand` 定义，兼容严格模式

## [0.1.0] - 2024-01-01

### Added

- Initial release
- `sduthesis.cls` - Main thesis document class
  - Bachelor thesis support
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

### Planned for v0.2.0

- Master thesis support
- Doctor thesis support
- Blind review mode
- More test coverage

### Planned for v1.0.0

- CTAN release
- Complete documentation
- Full compatibility with SDU thesis guidelines
