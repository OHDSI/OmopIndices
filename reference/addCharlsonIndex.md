# Add Charlson index value

Add Charlson index value

## Usage

``` r
addCharlsonIndex(
  x,
  indexDate = "cohort_start_date",
  window = c(-Inf, 0),
  conceptSet = NULL,
  nameStyle = "charlson_index",
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

  Window to asses `Charlson index` in, it must be a vector of two
  numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `myocardial_infarction`, `congestive_heart_failure`,
  `peripheral_vascular_disease`, `cerebrovacular_accident`,
  `transient_ischemic_attack`, `dementia`, `chronic_pulmonary_disease`,
  `connective_tissue_disease`, `peptic_ulcer_disease`,
  `mild_liver_disease`, `severe_liver_disease`, `diabetes_mellitus`,
  `end_organ_diabetes_mellitus`, `hemiplegia`,
  `estimated_glomerular_filtration_rate`,
  `severe_chronic_kidney_disease`, `localised_solid_tumor`,
  `metastatic_solid_tumor`, `leukemia`, `lymphoma`, `aids` as concepts.
  If `NULL` concepts will be retrieved using the OmopConcepts package.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The table `x` with a new column column with the corresponding Charlson
index value.

## Examples

``` r
library(OmopIndices)


```
