# SDUTeX Makefile
# 山东大学 LaTeX 论文模板核心包

.PHONY: all test unpack clean install ctan help

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

# 运行所有测试
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
	@cd build/test && FAILED=0; \
	for f in test_*.tex; do \
		name=$$(basename $$f .tex); \
		echo "=== 测试: $$name ==="; \
		if xelatex -interaction=nonstopmode -halt-on-error -output-directory=. $$f > /dev/null 2>&1; then \
			echo "  OK: $$name"; \
		else \
			echo "  失败: $$name"; \
			FAILED=1; \
		fi; \
	done; \
	if [ $$FAILED -ne 0 ]; then \
		echo "存在编译失败，测试未通过"; \
		exit 1; \
	fi
	@echo "测试完成"
	@ls -la build/test/*.pdf 2>/dev/null | wc -l | xargs -I {} echo "生成 {} 个 PDF"

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
	@echo "  make test      运行所有测试"
	@echo "  make install   安装到用户 TeX 目录"
	@echo "  make ctan      生成 CTAN 发布包"
	@echo "  make clean     清理生成的文件"
	@echo ""
