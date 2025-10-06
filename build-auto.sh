#!/bin/bash

set -e

echo "=========================================="
echo "  ALLCatchR2 Auto Package Builder"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Install system dependencies (with sudo)"
echo "2. Install R packages"
echo "3. Build the Debian package (without sudo)" 
echo ""

cd "$(dirname "$0")"

# Step 1: Install system dependencies
echo "Step 1: Installing system dependencies..."
echo "This requires sudo privileges."

# Detect OS
if command -v lsb_release &> /dev/null; then
    OS=$(lsb_release -si)
    CODENAME=$(lsb_release -sc)
    echo "Detected OS: $OS $CODENAME"
else
    echo "Cannot detect OS, assuming Ubuntu/Debian"
    OS="Ubuntu"
fi

# Install system packages
echo "Installing system packages..."
sudo apt-get update -qq

# Core build dependencies
sudo apt-get install -y -qq \
    debhelper \
    dh-r \
    r-base-dev \
    build-essential \
    gfortran

# Try to install R packages from apt (faster than CRAN)
echo "Installing R packages from apt repositories..."
sudo apt-get install -y -qq \
    r-cran-rlang \
    r-cran-caret \
    r-cran-randomforest \
    r-cran-catools \
    || echo "Some apt packages failed, will install from CRAN"

echo "✓ System dependencies installed"

# Step 2: Install missing R packages from CRAN
echo ""
echo "Step 2: Installing R packages from CRAN..."

R --quiet --no-save << 'RSCRIPT'
# CRAN packages
cran_packages <- c(
  "LiblineaR",
  "kknn", 
  "elasticnet"
)

# Optional packages (don't fail if they don't install)
optional_packages <- c("ranger", "glmnet")

# Install CRAN packages
for (pkg in cran_packages) {
  if (!require(pkg, quietly = TRUE)) {
    cat("  Installing", pkg, "from CRAN...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = FALSE)
  } else {
    cat("  ✓", pkg, "already installed\n")
  }
}

# Install BiocManager if needed
if (!require("BiocManager", quietly = TRUE)) {
  cat("  Installing BiocManager...\n")
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

# Install singscore from Bioconductor
if (!require("singscore", quietly = TRUE)) {
  cat("  Installing singscore from Bioconductor...\n")
  BiocManager::install("singscore", update = FALSE, ask = FALSE)
} else {
  cat("  ✓ singscore already installed\n")
}

# Try to install optional packages
for (pkg in optional_packages) {
  if (!require(pkg, quietly = TRUE)) {
    cat("  Trying to install optional package", pkg, "...\n")
    tryCatch({
      install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
      cat("  ✓", pkg, "installed\n")
    }, error = function(e) {
      cat("  ⚠", pkg, "failed to install (optional)\n")
    })
  } else {
    cat("  ✓", pkg, "already installed\n")
  }
}

cat("\n✓ R packages installation completed\n")
RSCRIPT

# Step 3: Verify core dependencies
echo ""
echo "Step 3: Verifying core dependencies..."

R --quiet --no-save << 'RSCRIPT'
required <- c("rlang", "caret", "LiblineaR", "kknn", 
              "randomForest", "caTools", "elasticnet", "singscore")

installed <- installed.packages()[, "Package"]
missing <- setdiff(required, installed)

if (length(missing) > 0) {
  cat("❌ ERROR: Missing required packages:", paste(missing, collapse=", "), "\n")
  cat("Please install manually:\n")
  cat("  R -e \"install.packages(c('", paste(missing, collapse="', '"), "'))\"\n", sep="")
  quit(status = 1)
}

cat("✓ All required dependencies verified\n")
RSCRIPT

# Step 4: Build the package
echo ""
echo "Step 4: Building Debian package..."
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
    echo "To install and test:"
    echo "  sudo dpkg -i ../r-cran-allcatchr2_1.1-1_all.deb"
    echo "  R -e 'library(ALLCatchR2); allcatchr_1.1(Lineage=\"T-ALL\")'"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "           BUILD FAILED"
    echo "=========================================="
    echo ""
    echo "If dependencies are missing, install them manually:"
    echo "  sudo apt install debhelper dh-r r-base-dev r-cran-rlang r-cran-caret r-cran-randomforest r-cran-catools"
    echo "  R -e \"install.packages(c('LiblineaR', 'kknn', 'elasticnet', 'singscore'))\""
    echo ""
    exit 1
fi