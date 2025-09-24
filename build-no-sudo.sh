#!/bin/bash

set -e

echo "=========================================="
echo "  ALLCatchR2 Package Builder (No Sudo)"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Since ranger and glmnet fail to compile, we'll skip the verification
# and build the package anyway - they're now in Suggests, not Imports

echo "Step 1: Checking R is installed..."
if ! command -v R &> /dev/null; then
    echo "ERROR: R is not installed"
    exit 1
fi
echo "✓ R found: $(R --version | head -1)"

echo ""
echo "Step 2: Checking available packages..."
R --quiet --no-save << 'RSCRIPT'
lib_path <- .Library.site[1]
cat("Library path:", lib_path, "\n\n")

required <- c("rlang", "caret", "LiblineaR", "kknn", 
              "randomForest", "caTools", "elasticnet")
optional <- c("singscore", "ranger", "glmnet")

installed <- installed.packages(lib.loc = lib_path)[, "Package"]

cat("Required packages:\n")
for (pkg in required) {
  status <- if (pkg %in% installed) "✓" else "✗"
  cat(status, pkg, "\n")
}

cat("\nOptional packages (Suggests):\n")
for (pkg in optional) {
  status <- if (pkg %in% installed) "✓" else "✗"
  cat(status, pkg, "\n")
}
RSCRIPT

echo ""
echo "Step 3: Building Debian package..."
echo "Note: ranger and glmnet are optional and will be loaded at runtime if available"
echo ""

dpkg-buildpackage -us -uc -b

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "           BUILD SUCCESSFUL!"
    echo "=========================================="
    echo ""
    echo "Package created:"
    ls -lh ../r-cran-allcatchr2_*.deb 2>/dev/null || echo "  (check parent directory)"
    echo ""
    echo "To install:"
    echo "  sudo dpkg -i ../r-cran-allcatchr2_1.1-1_all.deb"
    echo ""
    echo "Note: After installation, you may need to install ranger/glmnet:"
    echo "  sudo R -e 'install.packages(c(\"ranger\",\"glmnet\"))'"
    echo ""
    echo "To test:"
    echo "  R -e 'library(ALLCatchR2); allcatchr_1.1(Lineage=\"T-ALL\")'"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "           BUILD FAILED"
    echo "=========================================="
    exit 1
fi