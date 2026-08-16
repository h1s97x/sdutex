% test_index.md - 测试索引
% 用于记录所有测试用例及其用途

# SDUTeX 测试用例索引

## 基础测试

| 文件 | 测试内容 | 状态 |
|------|----------|------|
| `test_cover.tex` | 封面生成 | ✅ |
| `test_abstract.tex` | 中英文摘要 | ✅ |
| `test_math.tex` | 数学公式 | ✅ |
| `test_float.tex` | 图表浮动体 | ✅ |
| `test_bib.tex` | 参考文献 | ✅ |
| `test_full.tex` | 完整模板 | ✅ |

## 扩展测试

| 文件 | 测试内容 | 状态 |
|------|----------|------|
| `test_appendix.tex` | 附录环境 | ✅ |
| `test_acknowledgement.tex` | 致谢环境 | ✅ |
| `test_graduate.tex` | 研究生封面 | ✅ |
| `test_blind.tex` | 盲审模式 | ✅ |

## 运行测试

```bash
# 解包 DTX
make unpack

# 运行所有测试
make test

# 运行单个测试
xelatex test_cover.tex

# l3build 回归测试（.lvt/.tlg）
l3build check
```

## l3build 回归测试

项目采用 l3build 的 `.lvt/.tlg` 回归测试体系，测试文件位于 `test/test-l3/`：

| 文件 | 测试内容 |
|------|----------|
| `test_cover.lvt` | 封面 + info 分组键值 |
| `test_abstract.lvt` | 摘要环境 + 旧式接口兼容 |
| `test_math.lvt` | 数学风格选项 |
| `test_float.lvt` | 浮动体 |
| `test_module.lvt` | module= 组合加载 |
| `test_info.lvt` | info 完整分组键值 |
| `test_lang.lvt` | lang/preset 选项 |
| `test_theorem.lvt` | 定理环境 |
| `test_listoffigures.lvt` | 图表目录 |
| `test_mathstyle.lvt` | math-style 选项 |

支持 xetex/luatex 双引擎测试：

```bash
l3build check -e xetex
l3build check -e luatex
l3build check  # 同时运行双引擎
```
