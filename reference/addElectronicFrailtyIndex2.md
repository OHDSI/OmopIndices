# Add Electronic Frailty Index 2 (eFI2) value based on Best et al. (2025)

The eFI2 is a weighted score for one-year frailty-related outcomes. The
supplied concept set must contain the named eFI2 predictors. For BMI,
alcohol and smoking, the mutually exclusive categories used by the paper
should be represented explicitly (including missing categories where
applicable).

## Usage

``` r
addElectronicFrailtyIndex2(
  x,
  indexDate = "cohort_start_date",
  window = c(-365, 0),
  conceptSet = getIndexCodelist("electronic_frailty_index_2"),
  categories = list(robust = c(0, 0.0857), mild = c(0.0857, 0.1624), moderate = c(0.1624,
    0.2392), severe = c(0.2392, Inf)),
  nameStyle = "efi2",
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

  Window to asses `electronic frailty index 2` in, it must be a vector
  of two numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `activity_limitation`, `alcohol_harmful_intake`, `alcohol_missing`,
  `alcohol_previous_harmful_higher`, `atrial_fibrillation`, `cancer`,
  `cognitive_impairment`, `copd`, `dementia`,
  `dressing_grooming_problems`, `environment_problems`, `falls`,
  `fracture`, `fragility_fracture`, `heart_failure`, `housebound`,
  `hypotension_syncope`, `liver_problems`,
  `medication_management_problems`, `memory_concerns`,
  `mobility_problems`, `motor_neuron_disease`, `palliative_care`,
  `parkinsonism_tremor`, `peptic_ulcer`, `peripheral_vascular_disease`,
  `care_requirement`, `respiratory_disease`, `seizures`, `self_harm`,
  `skin_ulcer`, `smoker_current`, `social_vulnerability`, `stroke`,
  `transient_ischemic_attack`, `weight_loss_anorexia`, `bmi` as
  concepts. By default internal concepts are used.

- categories:

  Named list of categories to group the values. If NULL the risk score
  is returned as numeric.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The `x` table with a new eFI2 score column.
