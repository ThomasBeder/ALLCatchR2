#!/usr/bin/env Rscript

cat("=== Installing ALL R dependencies for ALLCatchR2 ===\n\n")

# Get system library path
lib_path <- .Library.site[1]
cat("Installing to:", lib_path, "\n\n")

# All packages including dependencies
all_packages <- c(
  "rlang",
  "ggplot2",
  "ggrepel",        # needed by singscore
  "caret",
  "LiblineaR",
  "kknn",
  "randomForest",
  "ranger",
  "glmnet",
  "caTools",
  "elasticnet"
)

cat("Step 1: Installing CRAN packages...\n")
for (pkg in all_packages) {
  cat("  Installing", pkg, "...\n")
  tryCatch({
    install.packages(pkg, lib = lib_path, repos = "https://cloud.r-project.org", dependencies = TRUE, quiet = TRUE)
  }, error = function(e) {
    cat("    ERROR:", e$message, "\n")
  })
}

# BiocManager and singscore
cat("\nStep 2: Installing BiocManager...\n")
if (!require("BiocManager", quietly = TRUE, lib.loc = lib_path)) {
    install.packages("BiocManager", lib = lib_path, repos = "https://cloud.r-project.org")
}

cat("\nStep 3: Installing singscore from Bioconductor...\n")
library(BiocManager, lib.loc = lib_path)
tryCatch({
  BiocManager::install("singscore", lib = lib_path, update = FALSE, ask = FALSE)
}, error = function(e) {
  cat("ERROR:", e$message, "\n")
})

cat("\n=== Checking installation ===\n")
installed <- installed.packages(lib.loc = lib_path)[, "Package"]
required <- c(all_packages, "singscore")

all_ok <- TRUE
for (pkg in required) {
  if (pkg %in% installed) {
    cat("✓ ", pkg, "\n")
  } else {
    cat("✗ ", pkg, " MISSING!\n")
    all_ok <- FALSE
  }
}

if (all_ok) {
  cat("\n=== SUCCESS: All dependencies installed! ===\n")
  quit(status = 0)
} else {
  cat("\n=== WARNING: Some dependencies missing ===\n")
  quit(status = 1)
}