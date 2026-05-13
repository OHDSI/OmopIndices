# Add the adapted electronic risk score as defined in Politi et al:

Add the adapted electronic risk score as defined in Politi et al:

## Usage

``` r
addAdaptedElectronicRiskScore(
  x,
  indexDate = "cohort_start_date",
  window = c(-365, 0),
  conceptSet = NULL,
  categories = list(fit = c(0, 0.12), mild = c(0.12, 0.24), moderate = c(0.24, 0.36),
    severe = c(0.36, 1)),
  nameStyle = "aers",
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

  Window to asses `adapted electronic risk score` in, it must be a
  vector of two numeric values `c(min, max)`. Window times refer to days
  since `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `activity_limitation`, `anemia`, `arthritis`, `atrial_fibrillation`,
  `chronic_kidney_disease`, `cerebrovascular_disease`, `diabetes`,
  `dizziness`, `dyspnea`, `falls`, `foot_problem`, `fragility_fracture`,
  `hearing_impairment`, `heart_failure`, `heart_valve_disorder`,
  `housebound`, `hypertension`, `hypotension`, `ischemic_heart_disease`,
  `memory_cognitive_disorder`, `mobility_transfer`, `osteoporosis`,
  `parkinsonism_tremor`, `peptic_ulcer`, `peripheral_vascular_disease`,
  `care_requirement`, `respiratory_disease`, `skin_ulcer`,
  `sleep_disturbance`, `social_vulnerability`, `thyroid_disease`,
  `urinary_incontinence`, `urinary_system_disease`, `visual_impairment`,
  `weight_loss_anorexia` as concepts. If `NULL` concepts will be
  retrieved using the OmopConcepts package.

- categories:

  Named list of categories to group the values. If NULL the risk score
  is returned as numeric.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The `x` table with a new column added with the adapted electronic risk
score of the patient.
