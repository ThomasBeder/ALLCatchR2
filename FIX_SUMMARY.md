# ALLCatchR2 Debian Package - Issue #1 Fix

## Problem
Users reported that the T-ALL option in the Debian package failed with:
```
Error in data.frame(..., check.names = FALSE): 
  arguments imply differing number of rows: 1, 0
```

The standalone version worked fine, but the Debian package was missing T-ALL lineage data.

## Root Cause
The T-ALL model data files (`TALL_subtype_models.rda`, `models_TALL_BC.rda`) were not correctly embedded in the Debian package during the build process.

## Solution
I created a proper Debian package structure that explicitly includes all data files:

### Key Files Fixed/Added:

1. **`debian/install`** - Explicitly lists all data files to install:
   ```
   data/*.rda usr/lib/R/site-library/ALLCatchR2/data/
   R/*.R usr/lib/R/site-library/ALLCatchR2/R/
   R/sysdata.rda usr/lib/R/site-library/ALLCatchR2/R/
   ```

2. **`debian/control`** - Simplified build dependencies
   - Minimal build-deps to avoid compilation issues
   - Moved problematic packages (ranger, glmnet) to Suggests

3. **`DESCRIPTION`** - Adjusted dependencies:
   ```
   Depends: R (>= 4.0.0), rlang (>= 1.0.0)  # Changed from >= 1.0.6
   Imports: utils, stats, caret, LiblineaR, kknn, randomForest, caTools, elasticnet
   Suggests: singscore, ranger, glmnet  # Made optional
   ```

4. **`debian/rules`**, **`debian/changelog`**, **`debian/copyright`** - Standard Debian packaging files

## How to Use This Fix

### Option 1: Use the Pre-built Package
Simply install the provided `.deb` file:
```bash
sudo dpkg -i r-cran-allcatchr2_1.1-1_all.deb
```

### Option 2: Build It Yourself
1. Copy the `debian/` folder and `DESCRIPTION` to your ALLCatchR2 repository
2. Run the build script:
   ```bash
   ./build-no-sudo.sh
   ```
3. Install the generated package:
   ```bash
   sudo dpkg -i ../r-cran-allcatchr2_1.1-1_all.deb
   ```

## Testing
After installation, test both lineages:

```bash
# Test T-ALL (the fixed issue)
R -e 'library(ALLCatchR2); allcatchr_1.1(Lineage="T-ALL")'

# Test B-ALL
R -e 'library(ALLCatchR2); allcatchr_1.1(Lineage="B-ALL")'
```

## What Changed vs. ALLCatchR v1

| Issue | ALLCatchR v1 | ALLCatchR2 Problem | Fix |
|-------|--------------|-------------------|-----|
| Data files | Auto-detected | T-ALL data not included | Explicit `debian/install` |
| Dependencies | Simple | ranger/glmnet compilation fails | Moved to Suggests |
| rlang version | Compatible | Required >= 1.0.6, system has 1.0.1 | Lowered to >= 1.0.0 |

## Files in This Package

```
allcatchr2-debian-fix.zip contains:
├── debian/                    # Complete Debian package structure
│   ├── control               # Package metadata
│   ├── rules                 # Build rules
│   ├── install              # File installation map (KEY FIX)
│   ├── changelog            # Version history
│   └── copyright            # License info
├── DESCRIPTION               # Updated R package dependencies
├── build-debian-package.sh   # Automated build script (with sudo)
├── build-no-sudo.sh         # Manual build script
├── install-all-deps.R       # R dependency installer
├── README_DEBIAN.md         # Detailed documentation
└── QUICK_BUILD.md           # Quick start guide
```

## To Integrate Into Your Repo

```bash
# Extract the fix
unzip allcatchr2-debian-fix.zip

# Copy to your ALLCatchR2 repo
cp -r debian/ /path/to/ALLCatchR2/
cp DESCRIPTION /path/to/ALLCatchR2/
cp build-*.sh /path/to/ALLCatchR2/
cp *.md /path/to/ALLCatchR2/

# Commit
cd /path/to/ALLCatchR2/
git add debian/ DESCRIPTION build-*.sh *.md
git commit -m "Fix T-ALL data embedding in Debian package (fixes #1)"
git push

# Create release
git tag -a v1.1-1 -m "Debian package - fixes T-ALL issue #1"
git push origin v1.1-1
```

## Verification

The package was successfully tested with:
-  Installation on Ubuntu 22.04
-  T-ALL analysis with test data
-  B-ALL analysis with test data
-  All T-ALL model data files present and loaded correctly

## Package Info

- **Package:** r-cran-allcatchr2_1.1-1_all.deb
- **Size:** 71MB
- **Architecture:** all
- **Tested on:** Ubuntu 22.04, R 4.5.1

