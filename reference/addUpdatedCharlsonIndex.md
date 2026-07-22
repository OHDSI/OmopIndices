# Add Updated Charlson Comorbidity Index (CCI) value based on Quan et al. (2011)

Add Updated Charlson Comorbidity Index (CCI) value based on Quan et al.
(2011)

## Usage

``` r
addUpdatedCharlsonIndex(
  x,
  indexDate = "cohort_start_date",
  ageAdjusted = TRUE,
  window = c(-Inf, 0),
  conceptSet = NULL,
  nameStyle = "charlson_index",
  categories = NULL,
  name = tableName(x)
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- indexDate:

  A character string that points to a `Date` column in the `x` table.

- ageAdjusted:

  Whether to calculate the Age-Adjusted Comorbidity Index (TRUE) or not
  (FALSE)

- window:

  Window to asses `Charlson index` in, it must be a vector of two
  numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `congestive_heart_failure`, `dementia`, `chronic_pulmonary_disease`,
  `connective_tissue_disease`, `mild_liver_disease`, `hemiplegia`,
  `severe_chronic_kidney_disease`, `diabetes_with_complication`,
  `any_malignancy`, `moderate_or_severe_liver_disease`,
  `metastatic_solid_tumor`, `aids` as concepts. If `NULL` concepts will
  be retrieved using the OmopConcepts package.

- nameStyle:

  A character string with the name of the new column.

- categories:

  Named list of categories to group the values. If NULL the risk score
  is returned as numeric.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The table `x` with a new column column with the corresponding Charlson
index value.

## Examples

``` r
{
library(OmopIndices)
library(omock)

cdm <- mockCdmFromDataset()
cdm <- cdm |>
 mockCohort()

conceptSet <- list(
 "congestive_heart_failure" = 319835L,
 "dementia" = 4182210L,
 "chronic_pulmonary_disease" = 255573L,
 "connective_tissue_disease" = 4134537L,
 "mild_liver_disease" = 194984L,
 "moderate_or_severe_liver_disease" = 4212540L,
 "diabetes_with_complication" = 42538715L,
 "hemiplegia" = 374022L,
 "severe_chronic_kidney_disease" = 46271022L,
 "any_malignancy" = 4180914L,
 "metastatic_solid_tumor" = 432851L,
 "aids" = 4267414L)

cdm$cohort |>
  addUpdatedCharlsonIndex(conceptSet = conceptSet)
}
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> Warning: 12 unique codelist concept IDs are not present in `cdm$concept`.
#> Warning: 12 unique codelist concept IDs are not present in `cdm$concept`.
#> ! 12 concept(s) from domain NA eliminated as it is not supported.
#> ℹ Supported domains are: device, specimen, measurement, drug, condition,
#>   observation, procedure, episode, and visit.
#> # A tibble: 2,694 × 5
#>    cohort_definition_id subject_id cohort_start_date cohort_end_date
#>  *                <int>      <int> <date>            <date>         
#>  1                    1          1 1992-09-10        1999-11-07     
#>  2                    1          5 1979-12-31        2010-02-08     
#>  3                    1          6 2003-03-02        2005-04-21     
#>  4                    1         16 1975-01-07        1997-08-24     
#>  5                    1         16 2006-09-12        2010-04-03     
#>  6                    1         16 2010-04-04        2016-03-08     
#>  7                    1         17 2011-12-22        2014-12-13     
#>  8                    1         18 1983-06-19        1984-10-24     
#>  9                    1         18 1984-10-25        2003-05-21     
#> 10                    1         18 2004-11-04        2010-08-07     
#> # ℹ 2,684 more rows
#> # ℹ 1 more variable: charlson_index <dbl>
```
