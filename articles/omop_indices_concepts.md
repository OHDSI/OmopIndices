# OmopIndices default concepts

The core functions in **OmopIndices** add indexes to a table:

- [`addCharlsonIndex()`](https://OHDSI.github.io/OmopIndices/reference/addCharlsonIndex.md)
- [`addUpdatedCharlsonIndex()`](https://OHDSI.github.io/OmopIndices/reference/addUpdatedCharlsonIndex.md)
- [`addHospitalFrailtyRiskScore()`](https://OHDSI.github.io/OmopIndices/reference/addHospitalFrailtyRiskScore.md)
- [`addElectronicFrailtyIndex()`](https://OHDSI.github.io/OmopIndices/reference/addElectronicFrailtyIndex.md)
- [`addElectronicFrailtyIndex2()`](https://OHDSI.github.io/OmopIndices/reference/addElectronicFrailtyIndex2.md)

These indices depend on a set of codelists, these codelist can be
provided by the user using the `conceptSet` argument. If not provided
the package contain its own definition for each one of the codelist.

You can get the default codelists of a given index with
[`getIndexCodelist()`](https://OHDSI.github.io/OmopIndices/reference/getIndexCodelist.md):

``` r

library(OmopIndices)

getIndexCodelist("charlson")
#> 
#> ── 17 codelists ────────────────────────────────────────────────────────────────
#> 
#> - aids (11 codes)
#> - any_malignancy (716 codes)
#> - cerebrovascular_disease (129 codes)
#> - chronic_pulmonary_disease (92 codes)
#> - congestive_heart_failure (41 codes)
#> - connective_tissue_disease (60 codes)
#> along with 11 more codelists
```

You can explore the different codelists here:

## Overview of codelists

- Charlson Index
- Updated Charlson Index
- Electronic Frailty Index
- Electronic Frailty Index 2
- Hospital Frailty Risk Score

## 

## Diagnostics of codelists

You might want to perform diagnostics on the mapping of your source data
and assess how well the involved codelists are recorded you can easily
do that using **CodelistGenerator** or **PhenotypeR**.

- CodelistGenerator
- PhenotypeR

``` r

library(CodelistGenerator)
library(OmopIndices)
library(omock)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

codelist <- getIndexCodelist("charlson")

codeUse <- summariseCodeUse(x = codelist, cdm = cdm)

tableCodeUse(result = codeUse)
```

``` r

library(PhenotypeR)
library(CohortConstructor)
library(OmopIndices)
library(omock)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

codelist <- getIndexCodelist("charlson")

cdm$my_cohort <- conceptCohort(cdm = cdm, conceptSet = codelist, name = "my_cohort")

results <- phenotypeDiagnostics(cohort = cdm$my_cohort)

shinyDiagnostics(result = results, directory = getwd())
```

## 

## Codelists generation

As mentioned above the package contains default codelists these were
obtained from other papers and projects:

- **Charlson Index** and **Updated Charlson Index** codelists were
  obtained from [Fortin et al
  2022](https://doi.org/10.1186/s12911-022-02006-1).

- **Hospital Frailty Risk Score** /@martaalcalde to explain

- **Electronic Frailty Index** codelists were obtained from …

- **Electronic Frailty Index 2** codelists were obtained from …
