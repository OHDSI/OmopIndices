# Get the codelists used for a certain index calculation

Get the codelists used for a certain index calculation

## Usage

``` r
getIndexCodelist(index)
```

## Arguments

- index:

  A choice between the different indexes: `"body_mass_index"`,
  `"charlson"`, `"electronic_frailty_index"`,
  `"electronic_frailty_index_2"`, `"hospital_frailty_risk_score"`, and
  `"updated_charlson"`.

## Value

A codelist used for the index.

## Examples

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
