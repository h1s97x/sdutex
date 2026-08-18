#!/usr/bin/env texlua

-- l3build configuration for SDUTeX
-- 山东大学 LaTeX 核心包构建系统
-- Reference: https://github.com/tuna/thuthesis (build.lua)

module = "sdutex"

-- 测试支持文件目录（放测试用到的公共 .tex 文件）
supportdir = "./test/support"

-- DTX 源码在 src/ 目录下，unpack 时需要指定源码路径
-- l3build 的 sourcefiles 是相对于 build.lua 所在目录
unpackdir = "./build/unpacked"
sourcefiles = {"src/*.dtx", "src/*.ins"}

-- 将模块目录与解包目录加入 TeX 搜索路径（l3build 的 tdsdirs 机制）。
-- testfiles 在 build/test 隔离目录下编译，必须通过 tdsdirs 暴露模板依赖，
-- 否则 xelatex 找不到 sduthesis.cls / modules/*.sty。
tdsdirs = {
  ["./modules"]         = "tex/latex/sdutex",
  ["./build/unpacked"]  = "tex/latex/sdutex",
  ["./figures"]         = "tex/latex/sdutex/figures",
}

-- 安装到 TeX 目录结构（TDS）的文件
-- unpack 产物（sduthesis.cls）直接位于 unpackdir 根目录。
-- 注意：installfiles 路径相对 unpackdir（build/unpacked）解析，
-- "../modules/*.sty" 会指向 build/modules 导致 CTAN/TDS 缺模块，
-- 故模块文件一律并入下方 textfiles（相对 build.lua 所在目录解析）。
installfiles = {"*.cls"}

-- 非解包、直接从源码目录安装的文件（工具宏包 / 模块 / 参考文献样式）
textfiles = {
  "src/sdutex.sty",
  "src/sduthesis.bst",
  "modules/sduthesis-common.sty",
  "modules/sduthesis-master.sty",
  "modules/sduthesis-undergraduate.sty",
  "modules/sduthesis-blindreview.sty",
}

-- 文档文件（随包发布）
docfiles = {
  "README.md",
  "CHANGELOG.md",
  "LICENSE",
  "doc",
}

-- 构建产物打包成 .tds.zip
packtdszip = true

-- 指定文件在 TDS 中的正确位置
tdslocations = {
  "tex/latex/sdutex/*.cls",
  "tex/latex/sdutex/sdutex.sty",
  "tex/latex/sdutex/sduthesis.bst",
  "tex/latex/sdutex/sduthesis-common.sty",
  "tex/latex/sdutex/sduthesis-undergraduate.sty",
  "tex/latex/sdutex/sduthesis-master.sty",
  "tex/latex/sdutex/sduthesis-blindreview.sty",
}

-- 双引擎测试（xetex/luatex），核心包兼容两种编译引擎
checkengines = {"xetex", "luatex"}
stdengine = "xetex"

-- 编译选项
-- 注：不开 -shell-escape（testfiles 与 doc 均未使用 minted 等外部工具），收窄执行面
checkopts = "-file-line-error -halt-on-error -interaction=nonstopmode"

-- 忽略某些测试：
-- smoke.tex 为整篇论文的端到端编译示例，无 .tlg 基线，不参与回归对比；
-- 其覆盖的封面/摘要/目录/附录等能力已由 cover/abstract/toc/appendix 等回归用例覆盖。
-- nested-setup.tex 为 setup-test 的组合支撑文件，二者均非独立回归用例，
-- 若不排除会导致 `l3build check` 因缺基线而失败。
excludetests = {"smoke", "nested-setup"}

-- 测试文件目录
testfiledir = "test"

-- 本项目 testfiles 使用 .tex 扩展名（非 l3build 默认的 .lvt）
-- 测试文件通过 \input{regression-test} + \START/\END 产生可对比的 .tlg 基线
lvtext = ".tex"

-- CTAN 发布设置
ctanpkg = "sdutex"
ctanpath = "latex/sdutex"
