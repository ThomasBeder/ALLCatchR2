# ALLCatchR2
This is a test version for ALLCatchR2. The tool is an update of the gene expression based BCP-ALL subtype classifier **ALLCatchR** (https://github.com/ThomasBeder/ALLCatchR) including subtype predictions for T-ALL. T-ALL subtypes were identified based on an analysis of 2049 samples from 13 cohorts.

# links to References
- T-ALL subtype classification https://library.ehaweb.org/eha/2025/eha2025-congress/4159185/thomas.beder.a.gene.expression.based.machine.learning.classifier.robustly.html?f=listing%3D4%2Abrowseby%3D8%2Asortby%3D2%2Amedia%3D3%2Aspeaker%3D1045302 

_ALLCatchR2_ was developed to predict:
- 20 T-ALL gene expression subtypes and a driver overarching definition of immature T-ALL / ETP-like
- 21 BCP-ALL molecular subtypes (_BCL2/MYC_, _CDX2/UBTF_, _CEBP_, _DUX4_, _ETV6::RUNX1_, _ETV6::RUNX1-like_, _HLF_, Hyperdiploid, iAMP21, _IKZF1 N159Y_, _KMT2A_, Low hypodiploid, _MEF2D_, Near haploid, _NUTM1_, _PAX5 P80R_, _PAX5alt_, _Ph-like_, _Ph-pos_, _TCF3::PBX1_, _ZNF384_)
- Two _BCR::ABL1_ main gene expression clusters (multilineage and lymphoid)
- Four _BCR::ABL1_ gene expression subcluster enriched for genomic aberrations (delHBS1L, del7, IKZF1, CDKN2A/PAX5)
- Hyperdiploidy in _BCR::ABL1_
- Associations to B and T lymphopoiesis stages based on gene set enrichment analyses 
- Blast Count percentage
- Immunophenotype in B-ALL
- Patient's sex

# ALLCatchR2
![image](Github_abstract.png)
# _BCR::ABL1_ gene expression subclusters
<img src="https://github.com/ThomasBeder/ALLCatchR_bcrabl1/blob/main/ALLCatchRbcrabl1.png" width=100% height=100%>


## Publications
- Beder T, Wolgast N, Walter W et al. A gene expression based machine learnning classifier robustly identifies 20 T-ALL subtypes across cohorts and age groups (https://library.ehaweb.org/eha/2025/eha2025-congress/4159185/thomas.beder.a.gene.expression.based.machine.learning.classifier.robustly.html?f=listing%3D4%2Abrowseby%3D8%2Asortby%3D2%2Amedia%3D3%2Aspeaker%3D1045302).
- Bastian L, Beder T, Barz M, et al. Developmental trajectories and cooperating genomic events define molecular subtypes of _BCR::ABL1_-positive ALL  _Blood_ (2024) 143 (14): 1391–1398. (https://doi.org/10.1097/HS9.0000000000000939)
- Beder T, Hansen BT, Hartmann AM, et al. A The Gene Expression Classifier ALLCatchR Identifies B-cell Precursor ALL Subtypes and Underlying Developmental Trajectories Across Age _HemaSphere_.  7(9):p e939, September 2023. (https://doi.org/10.1182/blood.2023021752)

## Installation
open RStudio
install devtools and follow the installion guide https://github.com/r-lib/devtools
```
if (!require("devtools", quietly = TRUE))
  install.packages("devtools")
```
install ALLCatchR2
```
devtools::install_github("ThomasBeder/ALLCatchR2")
```

## Quickstart
If Counts.file is left ```NA``` ten test samples are predicted
```
library(ALLCatchR2)
out <- allcatchr_1.1()
```

Usage

Arguments


Counts.file	
count data

ID_class	
gene ids used; c("symbol","ensemble_ID","entrez_ID")

sep	
file seperator

out.file	
output file path

## Run ALLCatchR2
As input ALLCatchR2 requires a single text file in which the first column represent the genes and the other columns the count data for each sample
```
library(ALLCatchR2)
out <- allcatchr_1.1(Lineage = "B-ALL", Counts.file = NA, ID_class = "symbol", sep = "\t", out.file = "predictions.tsv")
# out a list including T-ALL subtype predicitons, ssGSEA results to healthy T cell developmental stages and expression of T-ALL marker and driver genes with expression statistic in T-ALL 
# Lineage: disease Lineage c("B-ALL","T-ALL")
# Counts.file: /path/to/your/count/data, if left empty a test
# ID_class: gene names can be either "symbol", "ensemble_ID" or	"entrez_ID"
# sep: seperator of the text file usually "\t", "," or ";"
# out.file: name of the output file
```

## output T-ALL
ALLCatchR2 writes a ```out.file``` file to your current working directory (or the path defined by ```out.file``` parameter) with the following columns:
- sample: Sample ID
- 2-24 Scores: T-ALL subtype main- and sub-cluster predicitons scores
- 25-30 Predicitons: high-confidence and candidate level predictions for main-, sub-cluser and immature T-ALL / ETP-like
- Prediction: Predicted subtype
- BC_pred: Blast count predictions score
- 32-57: ssGSEA to T-cell developmental stages 
## output B-ALL
ALLCatchR2 writes a ```out.file``` file to your current working directory (or the path defined by ```out.file``` parameter) with the following columns:
- sample: Sample ID
- Score: BCP-ALL subtype prediction score
- Prediction: Predicted subtype
- Confidence: Confidence of subtype predictions, **IMPORTANT** predictions of samples labeled as unclassified here should be considered unclassified
- BCR_ABL1_maincluster_pred: _BCR::ABL1_ main gene expression cluster predictions for samples predicted to be Ph-pos
- BCR_ABL1_maincluster_score: corresponding prediciton score
- BCR_ABL1_subcluster_pred: _BCR::ABL1_ subcluster (delHBS1L, del7, IKZF1 and CDKN2A/PAX5) predictions for samples predicted to be Ph-pos
- BCR_ABL1_subcluster_score: corresponding prediciton score
- BCR_ABL1_hyperdiploidy_pred: _BCR::ABL1_ hyperdiploidy predictions for samples predicted to be Ph-pos
- BCR_ABL1_hyperdiploidy_score: corresponding prediciton score
- BlastCounts: Predicted Blast Count percentage
- Sex: Patient's sex predition
- Score_sex: Sex prediciton probability
- Immuno: Immunophenotype prediction
- ScoreImmuno: Immunophenotype prediciton probability
- 16-22: Enrichment analysis results (singscore, https://github.com/DavisLaboratory/singscore) to gene sets defined for B-cell progenitors
- 23-43: SVM linear predictions for individual subtypes
- 44-65: Results from gene set based nearest neighbor analysis
- 66-73: _BCR::ABL1_ gene expression cluster probability scores for each sample
