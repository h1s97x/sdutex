# SDUTeX Makefile
# 山东大学 LaTeX 论文模板核心包

.PHONY: all test unpack clean install ctan manual help

# 默认目标
all: test

# 解包 .dtx 文件生成 .cls
unpack:
	@echo "解包 DTX 文件..."
	@mkdir -p build
	cd src && latex sduthesis.ins
	@mv src/sduthesis.cls build/ 2>/dev/null || true
	@echo "解包完成"

# CI 门禁测试：运行 l3build 回归测试套件（.tex/.tlg，XeTeX 引擎，对齐 sduthesis），
# 对齐 sduthesis 的设计。l3build 负责解包、TDS 布局与测试编译，
# 无需手工维护解包/拷贝步骤，避免反复修补缺失宏包的脆弱逻辑。
test:
	@echo "=== 运行 l3build 回归测试 (XeTeX 引擎) ==="
	@if command -v l3build > /dev/null 2>&1; then \
		l3build check; \
	else \
		echo "l3build 不可用，请安装 TeX Live 或 l3build"; \
		exit 1; \
	fi
	@echo "测试通过"

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
	@rm -rf build/ tlpkg/
	@rm -f src/*.cls
	@rm -f test/*.log test/*.aux test/*.out test/*.synctex.gz
	@echo "清理完成"

# 帮助信息
help:
	@echo "SDUTeX Makefile"
	@echo ""
	@echo "用法:"
	@echo "  make unpack    解包 DTX 文件生成 .cls"
	@echo "  make test      运行 l3build 回归测试（CI 门禁，XeTeX 引擎）"
	@echo "  make install   安装到用户 TeX 目录"
	@echo "  make ctan      生成 CTAN 发布包"
	@echo "  make clean     清理生成的文件"
	@echo ""
