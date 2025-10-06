#!/bin/bash

set -e

echo "=========================================="
echo "  ALLCatchR2 Dependency Installer"  
echo "=========================================="
echo ""

cd "$(dirname "$0")"

echo "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    debhelper \
    dh-r \
    r-base-dev \
    build-essential \
    r-cran-rlang \
    r-cran-caret \
    r-cran-randomforest \
    r-cran-catools

echo ""
echo "Installing R packages..."
R --quiet --no-save << 'RSCRIPT'
# CRAN packages
cran_packages <- c("LiblineaR", "kknn", "elasticnet")

for (pkg in cran_packages) {
  if (!require(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "from CRAN...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    cat("✓", pkg, "already installed\n")
  }
}

# Install BiocManager if needed
if (!require("BiocManager", quietly = TRUE)) {
  cat("Installing BiocManager...\n")
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

# Install singscore from Bioconductor
if (!require("singscore", quietly = TRUE)) {
  cat("Installing singscore from Bioconductor...\n")
  BiocManager::install("singscore", update = FALSE, ask = FALSE)
} else {
  cat("✓ singscore already installed\n")
}

cat("\n✓ All dependencies installed!\n")
RSCRIPT

echo ""
echo "=========================================="
echo "     DEPENDENCIES INSTALLED!"
echo "=========================================="
echo ""
echo "Now you can build the package:"
echo "  ./build-no-sudo.sh"
echo ""