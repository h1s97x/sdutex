#!/usr/bin/env texlua

--
-- SDUTeX l3build configuration
-- 山东大学 LaTeX 核心包构建系统
--

module = "sdutex"

-- 源代码目录
sourcefiledir = "src"
sourcefiles = {"sduthesis.dtx", "sduthesis.ins"}

-- 模块目录
modulefiledir = "modules"
modulefiles = {
  "sduthesis-undergraduate.sty",
  "sduthesis-master.sty",
  "sduthesis-doctor.sty",
  "sduthesis-blindreview.sty"
}

-- 安装文件
installfiles = {"*.cls", "*.sty", "*.def", "*.bst",
  "../modules/sduthesis-undergraduate.sty",
  "../modules/sduthesis-master.sty",
  "../modules/sduthesis-doctor.sty",
  "../modules/sduthesis-blindreview.sty"}

-- 文档生成
typesetexe = "xelatex"
typesetfiles = {"src/sduthesis.dtx"}
typesetsuppfiles = {"support/ctxdoc.cls"}

-- BibTeX/Biber 设置
bibtexexe = "bibtex"
biberexe = "biber"
biberopts = "--quiet"

-- 解包设置
unpackexe = "luatex"
unpackfiles = {"src/sduthesis.dtx"}

-- 测试设置
checkruns = 3
-- 双引擎测试（luatex/xetex），对齐 l3build 最佳实践
checkengines = {"xetex", "luatex"}
checkopts = "-file-line-error -halt-on-error -interaction=nonstopmode"
stdengine = "xetex"
recordstatus = true

-- 测试文件目录
-- 使用 l3build 的 .lvt/.tlg 回归测试体系
-- 保留原有 .tex 集成测试作为补充
unpacksearch = true
testfiledir = "test"
testfiles = {
  "test_cover",
  "test_abstract",
  "test_math",
  "test_float",
  "test_module",
  "test_info",
  "test_lang",
  "test_theorem",
  "test_listoffigures",
  "test_mathstyle"
}

-- CTAN 发布设置
packtdszip = true
ctanpkg = "sdutex"
ctanpath = "latex/sdutex"

-- TDS 目录结构
tdslocations = {
  "tex/latex/sdutex/sduthesis.cls",
  "tex/latex/sdutex/sdutex.sty",
  "tex/latex/sdutex/sduthesis.bst",
  "tex/latex/sdutex/sduthesis-*.def",
  "tex/latex/sdutex/sduthesis-undergraduate.sty",
  "tex/latex/sdutex/sduthesis-master.sty",
  "tex/latex/sdutex/sduthesis-doctor.sty",
  "tex/latex/sdutex/sduthesis-blindreview.sty"
}

-- Git 版本信息
gitverfiles = {"src/sduthesis.dtx"}

-- Windows shell escape
shellescape = os.type == "windows"
  and function(s) return s end
  or function(s)
    s = s:gsub([[\]], [[\\]])
    s = s:gsub([[%$]], [[\$]])
    return s
  end

-- Git 版本提取函数
function extract_git_version()
  mkdir(supportdir)
  for _, i in ipairs(gitverfiles) do
    for _, j in ipairs({sourcefiledir}) do
      for _, k in ipairs(filelist(j, i)) do
        local idfile = normalize_path(supportdir .. "/" .. jobname(k) .. ".id")
        local file = normalize_path(j .. "/" .. k)
        local cmdline = shellescape(
          [[git log -1 --pretty=format:"$Id: ]] .. k .. [[ %h %ai %an <%ae> $" ]] .. file
        )
        local f = assert(io.popen(cmdline, "r"))
        local id = f:read("*all")
        f:close()
        git_id_info[k] = id
        f = assert(io.open(idfile, "wb"))
        f:write(id, "\n")
        f:close()
      end
    end
  end
end

-- 替换 Git 版本
function expand_git_version()
  local sourcedir = tdsdir .. "/source/" .. moduledir
  for _, i in ipairs(gitverfiles) do
    for _, j in ipairs({sourcedir}) do
      for _, k in ipairs(filelist(j, i)) do
        replace_git_id(j, k)
      end
    end
  end
end

function replace_git_id(path, file)
  local f = assert(io.open(path .. "/" .. file, "rb"))
  local s = f:read("*all")
  f:close()
  local id = assert(git_id_info[file])
  local s, n = s:gsub([[(\GetIdInfo)%b$$]], "%1" .. id)
  if n > 0 then
    f = assert(io.open(path .. "/" .. file, "wb"))
    f:write(s)
    f:close()
    cp(file, path, ctandir .. "/" .. ctanpkg)
  end
end

-- 版本标签更新
function update_tag(file, content, tagname, tagdate)
  local content, date = content, tagdate:gsub("%-", "/")
  if file:match("%.dtx$") then
    content = content:gsub("({\\ExplFileDate})%b{}", "%1{" .. tagname .. "}")
    content = content:gsub("{%d%d%d%d/%d%d/%d%d v%S+", "{" .. date .. " v" .. tagname)
    content = content:gsub("(\\changes){unreleased}", "%1{v" .. tagname .. "}")
  end
  return content
end

-- 创建符号链接支持目录
function copy_support_files()
  mkdir(supportdir)
end

-- 自定义任务：清理生成的文件
function clean()
  os.execute("rm -f *.cls *.sty *.def *.aux *.log *.out *.toc *.bbl *.blg *.xdv")
  os.execute("rm -rf tlpkg/build")
end

-- 自定义任务：仅解包不测试
function unpackonly()
  run(unpackexe, unpackopts .. " " .. getunpackfiles())
end
