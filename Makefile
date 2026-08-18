# SDUTeX Makefile
# 山东大学 LaTeX 论文模板核心包

.PHONY: all test test-l3 unpack clean install ctan manual help

# 默认目标
all: test

# 解包 .dtx 文件生成 .cls 和 .sty
unpack:
	@echo "解包 DTX 文件..."
	@mkdir -p build
	cd src && latex sduthesis.ins
	@mv src/sduthesis.cls build/ 2>/dev/null || true
	@mv src/sdutex.sty build/ 2>/dev/null || true
	@mv src/sduthesis.bst build/ 2>/dev/null || true
	@cp modules/*.sty build/ 2>/dev/null || true
	@echo "解包完成"

# 运行所有测试（xelatex + lualatex 双引擎）
test:
	@echo "运行测试..."
	@mkdir -p build/test
	@cp src/sduthesis.ins build/test/
	@cp src/sduthesis.dtx build/test/
	@cp test/test_*.tex build/test/
	@cp test/test_*.bib build/test/ 2>/dev/null || true
	@cp src/sdutex.sty build/test/ 2>/dev/null || true
	@cp src/sduthesis.bst build/test/ 2>/dev/null || true
	@cp modules/*.sty build/test/ 2>/dev/null || true
	@cd build/test && xelatex sduthesis.ins > /dev/null 2>&1
	@echo "=== 传统集成测试（xelatex + lualatex 双引擎） ==="
	@cd build/test && FAILED=0; \
	for eng in xelatex lualatex; do \
		echo "--- 引擎: $$eng ---"; \
		for f in test_*.tex; do \
			name=$$(basename $$f .tex); \
			echo "  测试: $$name"; \
			if $$eng -interaction=nonstopmode -halt-on-error -output-directory=. $$f > /dev/null 2>&1; then \
				echo "    OK: $$name"; \
			else \
				echo "    失败: $$name ($$eng)"; \
				FAILED=1; \
			fi; \
		done; \
	done; \
	if [ $$FAILED -ne 0 ]; then \
		echo "存在编译失败，测试未通过"; \
		exit 1; \
	fi
	@echo "传统测试完成"
	@ls -la build/test/*.pdf 2>/dev/null | wc -l | xargs -I {} echo "生成 {} 个 PDF"

# l3build 回归测试（.lvt/.tlg，xetex/luatex 双引擎）
test-l3:
	@echo "运行 l3build 回归测试..."
	@if command -v l3build > /dev/null 2>&1; then \
		l3build check 2>&1 | tail -40; \
	else \
		echo "l3build 不可用，请安装 TeX Live 或 l3build"; \
		exit 1; \
	fi

# 安装到用户目录
install:
	@echo "安装到用户目录..."
	@mkdir -p ~/texmf/tex/latex/sdutex
	cp -r src/*.sty src/*.cls src/*.bst ~/texmf/tex/latex/sdutex/
	cp -r modules/*.sty ~/texmf/tex/latex/sdutex/
	texhash ~/texmf
	@echo "安装完成"

# 生成 CTAN 发布包
ctan:
	@echo "生成 CTAN 发布包..."
	@mkdir -p tlpkg
	cd src && latex sduthesis.ins
	@mkdir -p tlpkg/sdutex/tex/latex/sdutex
	cp src/sduthesis.dtx src/sduthesis.ins src/sdutex.sty src/sduthesis.bst tlpkg/sdutex/tex/latex/sdutex/
	cp modules/*.sty tlpkg/sdutex/tex/latex/sdutex/
	cd tlpkg && zip -r ../sdutex-ctan.zip sdutex
	@echo "CTAN 包已生成: sdutex-ctan.zip"

# 编译中文使用手册（由 dtx 文档化内容生成）
manual:
	@echo "编译中文使用手册（由 sduthesis.dtx 文档化内容生成）..."
	@mkdir -p build
	cd build && pdflatex -interaction=nonstopmode -halt-on-error ../src/sduthesis.dtx
	cd build && makeindex -s gind.ist -o sduthesis.ind sduthesis.idx 2>/dev/null || true
	cd build && makeindex -s gglo.ist -o sduthesis.gls sduthesis.glo 2>/dev/null || true
	cd build && pdflatex -interaction=nonstopmode -halt-on-error ../src/sduthesis.dtx
	@ls -la build/sduthesis.pdf
	@echo "使用手册已生成: build/sduthesis.pdf"

# 清理所有生成文件
clean:
	@echo "清理..."
	@rm -rf build/ test/build/ tlpkg/
	@rm -f src/*.cls src/*.sty
	@rm -f test/*.log test/*.aux test/*.out test/*.synctex.gz
	@echo "清理完成"

# 帮助信息
help:
	@echo "SDUTeX Makefile"
	@echo ""
	@echo "用法:"
	@echo "  make unpack    解包 DTX 文件生成 .cls/.sty"
	@echo "  make test      运行集成测试（xelatex + lualatex）"
	@echo "  make test-l3   运行 l3build 回归测试（.lvt/.tlg）"
	@echo "  make install   安装到用户 TeX 目录"
	@echo "  make ctan      生成 CTAN 发布包"
	@echo "  make clean     清理生成的文件"
	@echo ""
