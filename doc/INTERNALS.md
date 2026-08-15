# SDUTeX 内部实现文档

本文档详细描述 SDUTeX 的内部实现细节，供开发者参考。

## 代码结构

```
sduthesis.dtx
├── 全局变量定义
├── 辅助函数
├── 选项解析
├── 基础类加载
├── 宏包加载
├── 页面布局
├── 样式配置
├── 用户配置接口
├── 封面生成
├── 摘要环境
├── 声明
├── 致谢
├── 附录
└── 章节样式
```

## 命名约定

### 命名空间

- `@@` = `sdu`（内部前缀）
- 使用 `\ExplSyntaxOn` 启用现代语法

### 变量命名

| 类型 | 前缀 | 示例 |
|------|------|------|
| 整数 | `\g_@@_type_int` | 论文类型 |
| 布尔 | `\g_@@_blind_bool` | 盲审模式 |
| 文本 | `\g_@@_title_tl` | 论文标题 |
| 长度 | `\g_@@_cover_label_width_dim` | 封面标签宽度 |

### 函数命名

| 类型 | 模式 | 示例 |
|------|------|------|
| 条件函数 | `\@@_if_xxx:TF` | `\@@_if_type_bachelor:TF` |
| 内部函数 | `\@@_xxx:` | `\@@_make_cover_bachelor:` |
| 用户命令 | `\MakeCover` | 封面命令 |

## 全局变量

### 论文类型 (`\g_@@_type_int`)

```latex
1 = bachelor  (本科生)
2 = master   (学术型硕士)
3 = professional (专业型硕士)
4 = doctor   (博士)
```

### 模式开关

```latex
\g_@@_blind_bool     % 盲审模式
\g_@@_twoside_bool   % 双面打印
```

### 用户配置变量

```latex
\g_@@_title_tl          % 中文标题
\g_@@_title_en_tl       % 英文标题
\g_@@_author_tl          % 作者
\g_@@_author_en_tl       % 英文作者
\g_@@_student_id_tl     % 学号
\g_@@_school_tl          % 学院
\g_@@_major_tl           % 专业
\g_@@_major_en_tl        % 英文专业
\g_@@_supervisor_tl      % 导师
\g_@@_supervisor_title_tl % 导师职称
\g_@@_supervisor_en_tl   % 英文导师
\g_@@_co_supervisor_tl  % 合作导师
\g_@@_co_supervisor_en_tl % 英文合作导师
\g_@@_date_tl            % 日期
\g_@@_cn_keywords_tl     % 中文关键词
\g_@@_en_keywords_tl     % 英文关键词
```

## 辅助函数

### 类型判断

```latex
\@@_if_type_bachelor:TF {true} {false}
\@@_if_type_master:TF {true} {false}
\@@_if_type_doctor:TF {true} {false}
\@@_if_type_professional:TF {true} {false}
```

### 盲审处理

```latex
\@@_secret_info:n {张三}
% 正常模式：张三
% 盲审模式：███

\@@_secret_info_fixed:Nn \g_@@_student_id_tl {10}
% 正常模式：2021001234
% 盲审模式：██████████
```

## 选项系统

### 文档类选项

```latex
\documentclass[degree=bachelor]{sduthesis}
\documentclass[degree=master,blind]{sduthesis}
```

可选值：
- `degree`: `bachelor`, `master`, `professional`, `doctor`
- `blind`: `true`, `false`
- `twoside`: `true`, `false`

### 用户配置

```latex
\SDUSetup{
  title = {论文标题},
  author = {作者姓名},
  student-id = {学号},
  school = {学院名称},
  major = {专业名称},
  supervisor = {导师姓名},
  supervisor-title = {导师职称},
  date = {2025}年6月
}
```

## 核心命令

### 封面

```latex
\MakeCover  % 生成封面
```

会根据论文类型自动选择：
- 本科生：本科生封面
- 研究生：硕士/博士封面

### 摘要环境

```latex
\begin{cnabstract}
  中文摘要内容
\end{cnabstract}

\begin{enabstract}
  English abstract content
\end{enabstract}
```

### 致谢

```latex
\begin{acknowledgement}
  感谢内容
\end{acknowledgement}
```

### 附录

```latex
\MakeAppendix
% 之后的内容将作为附录
```

## 样式配置

### 页面布局

```latex
\geometry{
  top = 3.0cm,
  bottom = 2.5cm,
  left = 3.0cm,
  right = 2.5cm
}
```

### 章节标题

| 级别 | 字体 | 字号 |
|------|------|------|
| chapter | 黑体 | 三号 |
| section | 黑体 | 四号 |
| subsection | 楷体 | 小四号 |

## 依赖宏包

| 宏包 | 用途 |
|------|------|
| `ctexbook` | 中文支持（基础类） |
| `geometry` | 页面布局 |
| `fancyhdr` | 页眉页脚 |
| `graphicx` | 图形 |
| `amsmath` | 数学公式 |
| `amssymb` | 数学符号 |
| `amsthm` | 定理环境 |
| `hyperref` | 超链接 |
| `xeCJKfntef` | 中文字形标注 |
| `sduthesis.bst` | 参考文献样式（自定义） |

## 版本历史

### v1.0.0 (2024-12-01)

- 初始版本
- 支持本科生/研究生论文
- 支持盲审模式
- 包含封面、摘要、致谢等环境
