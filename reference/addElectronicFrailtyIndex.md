# Add Electronic Frailty Index (eFI) value based Clegg et al. (2016) definition

Add Electronic Frailty Index (eFI) value based Clegg et al. (2016)
definition

## Usage

``` r
addElectronicFrailtyIndex(
  x,
  indexDate = "cohort_start_date",
  window = c(-365, 0),
  conceptSet = getIndexCodelist("electronic_frailty_index"),
  categories = list(fit = c(0, 0.12), mild = c(0.12, 0.24), moderate = c(0.24, 0.36),
    severe = c(0.36, 1)),
  nameStyle = "efi",
  name = tableName(x)
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- indexDate:

  A character string that points to a `Date` column in the `x` table.

- window:

  Window to asses `electronic frailty index` in, it must be a vector of
  two numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `activity_limitation`, `anemia`, `arthritis`, `atrial_fibrillation`,
  `cerebrovascular_disease`, `chronic_kidney_disease`, `diabetes`,
  `dizziness`, `dyspnea`, `falls`, `foot_problem`, `fragility_fracture`,
  `hearing_impairment`, `heart_failure`, `heart_valve_disorder`,
  `housebound`, `hypertension`, `hypotension_syncope`,
  `ischemic_heart_disease`, `memory_cognitive_disorder`,
  `mobility_problems`, `osteoporosis`, `parkinsonism_tremor`,
  `peptic_ulcer`, `peripheral_vascular_disease`, `care_requirement`,
  `respiratory_disease`, `skin_ulcer`, `sleep_disturbance`,
  `social_vulnerability`, `thyroid_disease`, `urinary_incontinence`,
  `urinary_system_disease`, `visual_impairment`, `weight_loss_anorexia`
  as concepts. By default internal concepts are used.

- categories:

  Named list of categories to group the values. If NULL the risk score
  is returned as numeric.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The `x` table with a new column added with the eFI of the patient.

## Examples

``` r
{
library(OmopIndices)
library(omock)

cdm <- mockCdmFromDataset() |>
  mockCohort()

conceptSet <- list(
  "activity_limitation" = 763723L,
  "anemia" = 439777L,
  "arthritis" = 4291025L,
  "atrial_fibrillation" = 313217L,
  "chronic_kidney_disease" = 46271022L,
  "cerebrovascular_disease" = 381591L,
  "dizziness" = 4223938L,
  "dyspnea" = 312437L,
  "falls" = 4059015L,
  "foot_problem" = 4101512L,
  "fragility_fracture" = 3170964L,
  "hearing_impairment" = 4234647L,
  "heart_failure" = 316139L,
  "heart_valve_disorder" = 4281749L,
  "housebound" = 4052962L,
  "hypertension" = 319826L,
  "hypotension_syncope" = 316447L,
  "ischemic_heart_disease" = 4185932L,
  "memory_cognitive_disorder" = 4304008L,
  "mobility_problems" =  4053076L,
  "osteoporosis" = 80502L,
  "parkinsonism_tremor" = 4140090L,
  "peptic_ulcer" = 4027663L,
  "peripheral_vascular_disease" = 321052L,
  "care_requirement" = 3661927L,
  "respiratory_disease" = 317009L,
  "skin_ulcer" = 4262920L,
  "sleep_disturbance" = 435524L,
  "social_vulnerability" = 4026161L,
  "diabetes" = 201820L,
  "thyroid_disease" = 4017052L,
  "urinary_incontinence" = 197672L,
  "urinary_system_disease" = 75865L,
  "visual_impairment" = 4265433L,
  "weight_loss_anorexia" = 436675L
)

# Polypharmacy is calculated internally using the function
# `addPolypharmacyCount()`, and is defined as individuals taking 5 or more
# medicines

cdm$cohort |>
  addElectronicFrailtyIndex(conceptSet = conceptSet)
}
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> Warning: 30 unique codelist concept IDs are not present in `cdm$concept`.
#> Warning: 30 unique codelist concept IDs are not present in `cdm$concept`.
#> ! 30 concept(s) from domain NA eliminated as it is not supported.
#> ℹ Supported domains are: device, specimen, measurement, drug, condition,
#>   observation, procedure, episode, and visit.
#> # A tibble: 2,694 × 5
#>    cohort_definition_id subject_id cohort_start_date cohort_end_date efi  
#>  *                <int>      <int> <date>            <date>          <chr>
#>  1                    1          1 1960-05-13        1974-01-19      fit  
#>  2                    1          2 1947-09-19        1949-07-27      fit  
#>  3                    1          2 1949-07-28        2003-08-10      fit  
#>  4                    1          3 1934-12-13        1954-08-16      fit  
#>  5                    1          3 1954-08-17        1983-03-31      fit  
#>  6                    1          7 1968-12-28        1974-04-18      fit  
#>  7                    1          7 1974-04-19        1987-12-19      fit  
#>  8                    1          7 2013-05-11        2014-05-07      fit  
#>  9                    1         12 1977-08-23        1992-12-22      fit  
#> 10                    1         12 2007-07-23        2010-01-24      fit  
#> # ℹ 2,684 more rows
```
