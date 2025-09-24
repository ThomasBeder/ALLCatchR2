#!/bin/bash

set -e

echo "=========================================="
echo "  ALLCatchR2 Debian Package Builder"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Install system dependencies"
echo "2. Install R packages" 
echo "3. Build the Debian package"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo privileges."
    echo "Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

# Step 1: Install Debian/System dependencies
echo "Step 1: Installing system build dependencies..."
apt-get update -qq
apt-get install -y -qq \
    debhelper \
    dh-r \
    r-base-dev \
    build-essential \
    gfortran \
    r-cran-rlang \
    r-cran-ggplot2 \
    r-cran-ggrepel \
    r-cran-caret \
    r-cran-randomforest \
    r-cran-catools

echo "✓ System dependencies installed"

# Step 2: Install R packages that aren't in apt
echo ""
echo "Step 2: Installing additional R packages..."

R --quiet --no-save << 'RSCRIPT'
lib_path <- .Library.site[1]
cat("Installing to:", lib_path, "\n")

# Packages not in apt repos (or apt install failed)
r_packages <- c(
  "LiblineaR",
  "kknn", 
  "elasticnet",
  "ranger",
  "glmnet"
)

for (pkg in r_packages) {
  if (!require(pkg, quietly = TRUE, lib.loc = lib_path)) {
    cat("  Installing", pkg, "...\n")
    tryCatch({
      install.packages(pkg, lib = lib_path, repos = "https://cloud.r-project.org", quiet = FALSE)
    }, error = function(e) {
      cat("    WARNING: Failed to install", pkg, "-", e$message, "\n")
    })
  }
}

# Install BiocManager and singscore
if (!require("BiocManager", quietly = TRUE, lib.loc = lib_path)) {
  cat("  Installing BiocManager...\n")
  install.packages("BiocManager", lib = lib_path, repos = "https://cloud.r-project.org", quiet = TRUE)
}

library(BiocManager, lib.loc = lib_path)
if (!require("singscore", quietly = TRUE, lib.loc = lib_path)) {
  cat("  Installing singscore from Bioconductor...\n")
  BiocManager::install("singscore", lib = lib_path, update = FALSE, ask = FALSE, quiet = TRUE)
}

cat("\n✓ R packages installed\n")
RSCRIPT

# Step 3: Verify core dependencies (not optional ones)
echo ""
echo "Step 3: Verifying core dependencies..."

R --quiet --no-save << 'RSCRIPT'
lib_path <- .Library.site[1]
# Only check packages in Imports (not Suggests)
required <- c("rlang", "caret", "LiblineaR", "kknn", 
              "randomForest", "caTools", "elasticnet")
optional <- c("singscore", "ranger", "glmnet")

installed <- installed.packages(lib.loc = lib_path)[, "Package"]
missing <- setdiff(required, installed)
missing_optional <- setdiff(optional, installed)

if (length(missing) > 0) {
  cat("ERROR: Missing required packages:", paste(missing, collapse=", "), "\n")
  quit(status = 1)
}

cat("✓ Core dependencies verified\n")
if (length(missing_optional) > 0) {
  cat("⚠ Optional packages not installed:", paste(missing_optional, collapse=", "), "\n")
  cat("  (These will be loaded at runtime if needed)\n")
}
RSCRIPT

# Step 4: Build the package
echo ""
echo "Step 4: Building Debian package..."
echo ""

# Change to package directory if needed
cd "$(dirname "$0")"

# Build as the original user, not root
ORIGINAL_USER="${SUDO_USER:-$USER}"
su - "$ORIGINAL_USER" -c "cd '$(pwd)' && dpkg-buildpackage -us -uc -b"

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