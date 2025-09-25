# ALLCatchR2 Debian Package

## Problem behoben

Dieses Debian-Paket behebt das Problem aus [Issue #1](https://github.com/ThomasBeder/ALLCatchR2/issues/1), bei dem die T-ALL Lineage-Daten nicht korrekt in das Debian-Paket eingebettet wurden.

### Was wurde geändert:

1. **Komplette Debian-Paketstruktur erstellt** mit allen notwendigen Dateien:
   - `debian/control` - Paketmetadaten und Abhängigkeiten
   - `debian/rules` - Build-Regeln
   - `debian/install` - Explizite Installation aller Datendateien
   - `debian/changelog` - Versionsinformationen
   - `debian/copyright` - Lizenzinformationen
   - `debian/compat` - Debhelper-Kompatibilität

2. **Alle Datendateien werden explizit eingebunden**:
   - `TALL_subtype_models.rda` - T-ALL Subtyp-Modelle
   - `models_TALL_BC.rda` - T-ALL Blast Count-Modelle
   - Alle B-ALL Modelle
   - Test-Daten

3. **Build-Skripte** (`build-no-sudo.sh` und `build-debian-package.sh`) automatisieren den Prozess

## Paket bauen

### Voraussetzungen

Das Paket benötigt folgende R-Pakete:
- rlang (>= 1.0.6)
- singscore
- caret
- LiblineaR
- kknn
- randomForest
- ranger
- glmnet
- caTools
- elasticnet

### Build-Prozess

#### Option 1: Schnelles Build-Skript (empfohlen)

```bash
cd ALLCatchR2
./build-no-sudo.sh
```

Das Skript ist schneller und benötigt kein sudo. Es prüft vorhandene R-Pakete und baut das Debian-Paket.

#### Option 2: Vollständiges Build-Skript

```bash
cd ALLCatchR2
./build-debian-package.sh
```

Das Skript installiert alle Dependencies, kann aber bei fehlenden Paketen länger dauern.

#### Option 3: Manueller Build

```bash
# Abhängigkeiten installieren
sudo apt-get install debhelper dh-r r-base-dev r-cran-rlang r-cran-caret

# R-Pakete installieren
R -e 'install.packages(c("singscore", "LiblineaR", "kknn", "ranger", "glmnet", "caTools", "elasticnet"))'

# Paket bauen
dpkg-buildpackage -us -uc -b
```

## Installation

Nach erfolgreichem Build:

```bash
sudo dpkg -i ../r-cran-allcatchr2_1.1-1_all.deb
```

Falls Abhängigkeitsfehler auftreten:

```bash
sudo apt-get install -f
```

## Testen

Nach der Installation können Sie das Paket in R testen:

```r
library(ALLCatchR2)

# Test mit B-ALL Daten
out_b <- allcatchr_1.1(Lineage = "B-ALL")

# Test mit T-ALL Daten (behebt das Problem aus Issue #1)
out_t <- allcatchr_1.1(Lineage = "T-ALL")
```

## Unterschied zur vorherigen Version

Das Problem in Issue #1 war, dass beim Debian-Package-Build die T-ALL-Daten nicht korrekt eingebettet wurden, was zu folgendem Fehler führte:

```
Error in data.frame(..., check.names = FALSE): arguments imply differing number of rows: 1, 0
```

Dieses Problem wurde durch explizite Definition der zu installierenden Dateien in `debian/install` behoben. Alle `.rda` Dateien im `data/` Verzeichnis werden jetzt garantiert in das Paket aufgenommen.

## Paket-Inhalt

Das fertige Paket enthält:

```
/usr/lib/R/site-library/ALLCatchR2/
├── data/
│   ├── TALL_subtype_models.rda      # T-ALL Modelle
│   ├── models_TALL_BC.rda           # T-ALL BC Modelle  
│   ├── bcrabl1_models.rda           # BCR::ABL1 Modelle
│   ├── models_L.rda                 # B-ALL Hauptmodelle
│   ├── models_L_BC.rda              # B-ALL BC Modelle
│   ├── models_L_immuno.rda          # Immunophänotyp
│   ├── models_L_sex.rda             # Geschlecht
│   └── test_data.rda                # Testdaten
├── R/
│   ├── allcatchr_1.1.R
│   ├── data.R
│   └── sysdata.rda
├── DESCRIPTION
├── NAMESPACE
└── man/
```

## Support

Bei Problemen bitte ein Issue auf GitHub öffnen:
https://github.com/ThomasBeder/ALLCatchR2/issues