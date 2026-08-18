# SDUTeX 开发者指南

## 环境搭建

### 必要工具

- TeX Live 2020+ (推荐 2024)
- Git
- LuaTeX (用于 l3build)

### 安装依赖

```bash
# macOS
brew install --cask mactex

# Ubuntu/Debian
sudo apt install texlive-full

# Windows
# 下载 TeX Live Installer: https://tug.org/texlive/
```

### 克隆仓库

```bash
git clone https://github.com/h1s97x/sdutex.git
cd sdutex
```

## 构建命令

### 基本命令

| 命令 | 说明 |
|------|------|
| `make` | 解包并生成所有文件 |
| `make install` | 安装到本地 TeX 目录 |
| `make clean` | 清理生成的文件 |
| `make test` | 运行测试 |
| `make doc` | 生成文档 |

### 使用 l3build

```bash
# 解包 DTX 文件
l3build unpack

# 运行测试
l3build check

# 生成文档
l3build doc

# 打包 CTAN
l3build ctan

# 打包 TDS
l3build tds
```

## 代码结构

### 源代码组织

```
src/
├── sduthesis.dtx       # 主文档类
│   ├── 模块注释         # %<*cls> ... %</cls>
│   ├── 变量定义         # 全局变量和开关
│   ├── 配置系统         # l3keys 键值对
│   ├── 宏包加载         # 依赖的宏包
│   ├── 页面布局         # geometry 设置
│   ├── 字体设置         # ctex 字体配置
│   ├── 章节标题         # ctexset 样式
│   ├── 封面生成         # 封面渲染函数
│   ├── 目录生成         # 目录配置
│   └── 浮动体样式       # 图表公式样式
└── sduthesis.ins       # DocStrip 安装脚本
```

### 变量命名规范

使用 LaTeX3 命名约定：

| 前缀 | 含义 |
|------|------|
| `c_` | 常量 (constant) |
| `g_` | 全局 (global) |
| `l_` | 局部 (local) |
| `l__sdu_` | SDUTeX 局部变量（模块前缀 `sdu`） |

内核配置变量统一使用 `\l__sdu_<名称>_tl`（局部变量），配合 l3keys 存储论文信息、学位信息、样式与模块状态。

### 类型后缀

| 后缀 | 含义 |
|------|------|
| `_tl` | Token List |
| `_int` | Integer |
| `_dim` | Dimension |
| `_bool` | Boolean |
| `_str` | String |
| `_seq` | Sequence |
| `_clist` | Comma List |
| `_prop` | Property List |

## 添加新功能

### 1. 添加新选项

在 `sduthesis.dtx` 中找到选项定义部分：

```latex
% 添加新选项
\keys_define:nn { sdut / option } {
  newoption .meta:nn = { sdut / newoption } {#1},
}

% 添加新选项的处理
\keys_define:nn { sdut / newoption } {
  value .code:n = {
    % 处理逻辑
  }
}
```

### 2. 添加新环境

```latex
% 新环境定义
\NewDocumentEnvironment { newenv } { o }
  {
    \begin{trivlist}
    \item[\hskip\labelsep {\bfseries 新环境}]
    \IfValueT{#1}{（#1）}
  }
  {
    \end{trivlist}
  }
```

### 3. 添加新命令

```latex
% 新命令定义
\NewDocumentCommand \NewCommand { s o m }
  {
    % 命令实现
    % #1: starred variant
    % #2: optional argument
    % #3: mandatory argument
  }
```

## 测试指南

### 编写测试

本项目采用 l3build `.tex/.tlg` 回归测试，在 `test/` 目录下创建测试文件，通过 `\input{regression-test}` + `\START/\END` 产生可对比的基线：

```latex
\documentclass{sduthesis}
\input{setup-test}
\input{regression-test}

\begin{document}
\START
\makecoverpage
\END
\end{document}
```

### 运行测试

```bash
# 单个测试
xelatex test_cover.tex

# 所有测试
make test

# 使用 l3build
l3build check
```

### 预期结果

每个测试文件应该：
1. 能成功编译（无错误）
2. 生成预期的 PDF
3. 在日志中无警告（除已知警告外）

## 发布流程

### 版本号规范

使用语义版本号 (SemVer)：
- 主版本号：不兼容的 API 修改
- 次版本号：向后兼容的功能新增
- 修订号：向后兼容的问题修复

### 发布步骤

1. 更新版本号：
   ```bash
   # 在 src/sduthesis.dtx 中更新（含 dtx 头部 \date 与 \ProvidesClass）
   \ProvidesClass{sduthesis}[2026/08/18 v2.2.0 Thesis template for Shandong University]
   ```

2. 更新 CHANGELOG.md

3. 创建 Git Tag：
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```

4. 构建 CTAN 包：
   ```bash
   l3build ctan
   ```

5. 上传到 CTAN (可选)

## 常见问题

### Q: 解包失败

**A**: 确保已安装 l3build：
```bash
tlmgr install l3build
```

### Q: 编译报错 "File not found"

**A**: 重新安装：
```bash
l3build install
```

### Q: 测试不通过

**A**: 检查 TeX Live 版本：
```bash
texlua -v
```

推荐使用 TeX Live 2024。

## 参考资料

- [LaTeX3 文档](https://www.latex-project.org/help/documentation/)
- [l3build 文档](https://ctan.org/pkg/l3build)
- [DTX 格式说明](https://www.latex-project.org/help/documentation/docmod.pdf)
