# SDUTeX 内部实现文档

本文档详细描述 SDUTeX 的内部实现细节，供开发者参考。当前实现与示例模板仓库 **sduthesis v2.2.0** 完全对齐。

## 代码结构

`src/sduthesis.dtx`（内核）结构：

```
sduthesis.dtx
├── 存储层：变量声明（tl / dim / bool）
├── 定义层：l3keys 键注册（sdu/info、sdu/option、sdu 顶层）
├── 命令层：\SDUSetup
├── 导出层：Getter 命令
├── 模块加载器：\sdu_load_module:
├── Hook 系统：6 个命名钩子
├── 宏包加载
├── 字体引擎
├── 页面 / 章节 / 交叉引用 / 图表标题 / 数学 / 代码排版引擎
├── 占位命令与环境（模块可覆盖）
└── 通用环境定义（printbib / myacknowledgement / myappendix / maketable）
```

## 命名约定

### 命名空间

- 模块前缀：`sdu`
- 内部变量使用 `\l__sdu_<名称>_tl`（`l` 局部、`__sdu` 模块前缀）
- 使用 `\ExplSyntaxOn` 启用 LaTeX3 语法（内核核心逻辑）；模块采用 `\AddToHook` + 传统命令混合风格

### 变量命名

| 类型 | 前缀 | 示例 |
|------|------|------|
| token list | `\l__sdu_..._tl` | `\l__sdu_title_tl` |
| dimension | `\l__sdu_..._dim` | `\l__sdu_line_spread_dim` |
| bool | `\l__sdu_..._bool` | `\l__sdu_blindreview_bool` |
| seq | `\l__sdu_..._seq` | `\l__sdu_module_seq` |

## 存储变量

### 论文信息（info 组）

```latex
\l__sdu_title_tl        % 标题
\l__sdu_author_tl       % 作者
\l__sdu_studentid_tl    % 学号
\l__sdu_school_tl       % 学院
\l__sdu_major_tl        % 专业
\l__sdu_supervisor_tl   % 指导教师
\l__sdu_year_tl         % 年份
\l__sdu_month_tl        % 月份
```

### 学位信息（master 模块）

```latex
\l__sdu_degree_tl               % 学位类型（默认“硕士”）
\l__sdu_committee_chair_tl      % 答辩委员会主席
\l__sdu_committee_members_tl    % 答辩委员会委员
\l__sdu_defense_date_tl         % 答辩日期
\l__sdu_defense_place_tl        % 答辩地点
```

### 样式（option 组）

```latex
\l__sdu_line_spread_dim     % 行距倍数（默认 1.5）
\l__sdu_page_left_tl        % 左边距（默认 3cm）
\l__sdu_page_right_tl       % 右边距（默认 3cm）
\l__sdu_page_top_tl         % 上边距（默认 2.5cm）
\l__sdu_page_bottom_tl      % 下边距（默认 2.5cm）
```

### 模块与盲审

```latex
\l__sdu_module_tl                % module 键原始值
\l__sdu_module_seq               % 拆分后的模块序列
\l__sdu_blindreview_bool         % 盲审标志
\l__sdu_has_blindreview_bool     % 是否含盲审模块
\l__sdu_has_base_module_bool     % 是否含基础模块
```

## 配置系统

`\SDUSetup{...}` 通过 `\keys_set:nn { sdu } { ... }` 解析，支持：

- **嵌套分组**：`info={...}` → `\keys_set:nn { sdu/info }`；`option={...}` → `\keys_set:nn { sdu/option }`
- **顶层平铺**：旧写法兼容（`title` / `author` 等直接写在顶层）

## 模块加载器

`\sdu_load_module:` 在 `\begin{document}` 时执行（由 `\AddToHook { begindocument }` 触发）：

1. 分割 `module` 列表（逗号分隔），去空白、跳空项
2. 预扫描判断是否含 `blindreview`、是否已有基础模块
3. `blindreview` 单独使用时前置加载本科模块
4. 按用户顺序加载各模块：`\RequirePackage{sduthesis-<name>}`

## 盲审标志

`blindreview` 模块加载时置 `\l__sdu_blindreview_bool` 为真。基础模块通过 `\IfBlindReviewTF` / `\IfBlindReviewF` 决定封面个人信息行是否输出、答辩委员会页是否跳过。

## 核心命令与环境

| 命令/环境 | 说明 | 定义位置 |
|-----------|------|----------|
| `\makecoverpage` | 封面（模块覆盖） | 内核占位，模块 `\renewcommand` |
| `\makestatement` | 声明页（盲审可跳过） | 内核占位 |
| `\makecommittee` | 答辩委员会页（master 模块） | 内核占位 |
| `cnabstract` / `enabstract` | 中英文摘要 | 内核占位，模块覆盖 |
| `\cnkeywords` / `\enkeywords` | 关键词 | 内核占位 |
| `\printbib` | 参考文献（biblatex/biber） | 内核 |
| `myacknowledgement` | 致谢环境 | 内核 |
| `myappendix` | 附录环境 | 内核 |
| `\maketable` | 目录 | 内核 |

## 依赖宏包

| 宏包 | 用途 |
|------|------|
| `ctexbook` | 中文支持（基础类） |
| `expl3` / `l3keys2e` | LaTeX3 编程与键值解析 |
| `geometry` | 页面布局 |
| `fancyhdr` | 页眉页脚 |
| `graphicx` | 图形 |
| `amsmath` / `amsthm` / `amsfonts` / `amssymb` | 数学与定理环境 |
| `unicode-math` / `xeCJK` | 数学与中文 |
| `biblatex`（biber, gb7714-2015） | 参考文献 |
| `bookmark` / `hyperref` | 书签与超链接 |
| `algorithm` / `algorithmicx` / `algpseudocode` | 算法环境 |

## 测试体系

采用 l3build `.tex/.tlg` 回归测试（`test/` 目录），支持 xetex/luatex 双引擎。测试文件通过 `\input{regression-test}` + `\START/\END` 产生基线。
