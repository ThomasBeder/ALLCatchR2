#!/bin/bash

set -e

echo "=========================================="
echo "  ALLCatchR2 Builder (Linux Mint Fix)"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Step 1: Install system dependencies WITHOUT problematic CRAN repos
echo "Step 1: Installing system dependencies (skipping problematic CRAN repos)..."

# Temporarily disable CRAN repos during apt operations
echo "Temporarily disabling CRAN repositories..."
sudo mkdir -p /etc/apt/sources.list.d.bak
sudo mv /etc/apt/sources.list.d/*cran* /etc/apt/sources.list.d.bak/ 2>/dev/null || true

# Update and install
sudo apt-get update -qq
sudo apt-get install -y -qq \
    debhelper \
    dh-r \
    r-base-dev \
    build-essential \
    gfortran

echo "✓ System dependencies installed"

# Step 2: Install ALL R packages from CRAN (bypass apt entirely)
echo ""
echo "Step 2: Installing ALL R packages from CRAN..."

R --quiet --no-save << 'RSCRIPT'
# All required packages from CRAN/Bioconductor
packages <- list(
  cran = c("rlang", "caret", "LiblineaR", "kknn", "randomForest", "caTools", "elasticnet"),
  optional = c("ranger", "glmnet")
)

# Install all CRAN packages
all_cran <- c(packages$cran, packages$optional)
for (pkg in all_cran) {
  if (!require(pkg, quietly = TRUE)) {
    cat("  Installing", pkg, "from CRAN...\n")
    tryCatch({
      install.packages(pkg, repos = "https://cloud.r-project.org", quiet = FALSE)
      cat("  ✓", pkg, "installed\n")
    }, error = function(e) {
      cat("  ⚠", pkg, "failed:", e$message, "\n")
    })
  } else {
    cat("  ✓", pkg, "already installed\n")
  }
}

# Install BiocManager and singscore
if (!require("BiocManager", quietly = TRUE)) {
  cat("  Installing BiocManager...\n")
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

if (!require("singscore", quietly = TRUE)) {
  cat("  Installing singscore from Bioconductor...\n")
  BiocManager::install("singscore", update = FALSE, ask = FALSE)
} else {
  cat("  ✓ singscore already installed\n")
}

cat("\n✓ R packages installation completed\n")
RSCRIPT

# Step 3: Verify dependencies
echo ""
echo "Step 3: Verifying dependencies..."

R --quiet --no-save << 'RSCRIPT'
required <- c("rlang", "caret", "LiblineaR", "kknn", "randomForest", "caTools", "elasticnet", "singscore")
installed <- installed.packages()[, "Package"]
missing <- setdiff(required, installed)

if (length(missing) > 0) {
  cat("❌ Missing packages:", paste(missing, collapse=", "), "\n")
  quit(status = 1)
}

cat("✓ All required dependencies verified\n")
RSCRIPT

# Step 4: Build package
echo ""
echo "Step 4: Building Debian package..."
dpkg-buildpackage -us -uc -b

# Step 5: Restore CRAN repos
echo ""
echo "Restoring CRAN repositories..."
sudo mv /etc/apt/sources.list.d.bak/*cran* /etc/apt/sources.list.d/ 2>/dev/null || true
sudo rmdir /etc/apt/sources.list.d.bak 2>/dev/null || true

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "           BUILD SUCCESSFUL!"
    echo "=========================================="
    echo ""
    echo "Package created:"
    ls -lh ../r-cran-allcatchr2_*.deb 2>/dev/null
    echo ""
    echo "To install and test:"
    echo "  sudo dpkg -i ../r-cran-allcatchr2_1.1-1_all.deb"
    echo "  R -e 'library(ALLCatchR2); allcatchr_1.1(Lineage=\"T-ALL\")'"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "           BUILD FAILED"
    echo "=========================================="
    exit 1
fi