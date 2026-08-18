# SDUTeX 架构设计文档

## 设计目标

1. **内核 + 模块 + Hook 插件化**：核心只负责引擎与基础排版，学位类型逻辑由模块承载
2. **可扩展性**：通过 `\SDUSetup` 集中配置 + 命名 Hook 支持扩展
3. **兼容性**：兼容主流 TeX 发行版（TeX Live, MiKTeX），双引擎（xetex/luatex）
4. **标准化**：遵循 LaTeX3 编程规范与 l3keys 机制

> 本架构与示例模板仓库 **sduthesis** 完全对齐（v2.2.0），二者为"核心包 / 示例模板"的单一真源关系。

## 整体架构

```
┌─────────────────────────────────────────────┐
│           用户层 (User Layer)                │
│   \documentclass{sduthesis} + \SDUSetup{}   │
├─────────────────────────────────────────────┤
│         模块层 (Module Layer)                │
│   undergraduate / master / blindreview .sty  │
├─────────────────────────────────────────────┤
│           内核 (Core Engine)                 │
│   sduthesis.cls（src/sduthesis.dtx）         │
│   ├── SDUSetup 引擎 (l3keys)                │
│   ├── Hook 系统（6 个文档阶段钩子）           │
│   └── 基础排版引擎                           │
└─────────────────────────────────────────────┘
```

## 核心模块

### 1. 存储层：变量声明

所有配置值通过 `tl`（token list）/ `dim` / `bool` 变量存储，命名规范为 `\l__sdu_<名称>_tl`（`l` 局部变量，`__sdu` 模块前缀）：

- **论文信息组**：`\l__sdu_title_tl` `\l__sdu_author_tl` `\l__sdu_studentid_tl` `\l__sdu_school_tl` `\l__sdu_major_tl` `\l__sdu_supervisor_tl` `\l__sdu_year_tl` `\l__sdu_month_tl`
- **学位信息组**（master 模块）：`\l__sdu_degree_tl` `\l__sdu_committee_chair_tl` `\l__sdu_committee_members_tl` `\l__sdu_defense_date_tl` `\l__sdu_defense_place_tl`
- **样式组**：`\l__sdu_line_spread_dim` `\l__sdu_page_left_tl` `\l__sdu_page_right_tl` `\l__sdu_page_top_tl` `\l__sdu_page_bottom_tl`
- **模块组**：`\l__sdu_module_tl` `\l__sdu_module_seq` `\l__sdu_module_item_tl` `\l__sdu_module_pkg_tl`
- **盲审标志**：`\l__sdu_blindreview_bool` `\l__sdu_has_blindreview_bool` `\l__sdu_has_base_module_bool`

### 2. 配置系统

使用 `l3keys` 实现键值对配置，`\SDUSetup` 统一入口，支持 `info` / `option` 嵌套分组与顶层平铺两种写法：

```
用户代码
    ↓
\SDUSetup{ module={...}, info={...}, option={...} }
    ↓
\keys_set:nn { sdu } { ... }          # info/option 代理键
    ↓
\keys_set:nn { sdu/info } / sdu/option
    ↓
存储到 \l__sdu_* 变量
```

### 3. 模块加载器

`module` 键支持逗号分隔列表，`\sdu_load_module:` 在 `\begin{document}` 时执行：

1. 分割模块列表，去空白、跳空项
2. 预扫描：判断是否含 `blindreview`、是否已有基础模块（undergraduate/master）
3. 若 `blindreview` 单独使用，自动前置加载本科模块
4. 按用户顺序正式加载各模块（`\RequirePackage{sduthesis-<name>}`）

### 4. Hook 系统

内核声明 6 个命名 Hook，模块通过 `\AddToHook` 注入行为：

| Hook | 触发时机 |
|------|----------|
| `sduthesis/after-setup` | `\SDUSetup` 处理完后、begindocument |
| `sduthesis/before-cover` | 封面生成前 |
| `sduthesis/cover-style` | 封面样式注入 |
| `sduthesis/frontmatter/begin` | 前言开始 |
| `sduthesis/mainmatter/begin` | 正文开始 |
| `sduthesis/backmatter/begin` | 后记开始 |

### 5. Getter 命令

内核导出 Getter 命令供模块与用户读取配置值：
`\GetTitle` `\GetAuthor` `\GetStudentId` `\GetSchool` `\GetMajor` `\GetSupervisor` `\GetYear` `\GetMonth` `\GetDegree` `\GetCommitteeChair` `\GetCommitteeMembers` `\GetDefenseDate` `\GetDefensePlace`

### 6. 盲审标志

`blindreview` 模块加载时置 `\l__sdu_blindreview_bool` 为真。基础模块通过 `\IfBlindReviewTF` / `\IfBlindReviewF` 决定是否隐藏作者、学号、导师等个人信息（盲审时隐藏）。

## 模块划分

| 模块文件 | 职责 |
|----------|------|
| `sduthesis-undergraduate.sty` | 本科封面、中英摘要、关键词、页眉页脚 |
| `sduthesis-master.sty` | 硕博封面、答辩委员会页、中英摘要、页眉页脚 |
| `sduthesis-blindreview.sty` | 盲审标志、声明页跳过 |

## 参考文献

- **biblatex/biber**（GB/T 7714-2015）：内核默认，`\printbib` 命令输出
- **sduthesis.bst**（传统 LaTeX 工程）：保留作兜底

## 测试体系

采用 l3build `.tex/.tlg` 回归测试，覆盖 cover / abstract / appendix / bib / blindreview / master / master-blindreview / nested-setup / toc，支持 xetex/luatex 双引擎。
