# SDUTeX 测试

本项目采用 **l3build 回归测试体系**（`.tex/.tlg`），测试文件位于 `test/` 目录，
通过 `\input{regression-test}` + `\START/\END` 产生可对比的 `.tlg` 基线。

## 测试用例

| 文件 | 测试内容 |
|------|----------|
| `cover.tex` | 封面生成 |
| `abstract.tex` | 摘要环境 |
| `appendix.tex` | 附录环境 |
| `bib.tex` | 参考文献（biblatex/biber） |
| `blindreview.tex` | 盲审模式 |
| `master.tex` | 硕士学位论文模块 |
| `master-blindreview.tex` | 硕士 + 盲审组合加载 |
| `nested-setup.tex` | SDUSetup info/option 嵌套分组 |
| `toc.tex` | 目录 |

公共配置位于 `test/support/setup-test.tex`。

## 运行测试

```bash
# 运行所有测试（xetex/luatex 双引擎）
make test

# 仅 xetex 引擎
l3build check -e xetex

# 仅 luatex 引擎
l3build check -e luatex

# 更新 .tlg 基线（当模板输出有意变更时）
l3build save
```
