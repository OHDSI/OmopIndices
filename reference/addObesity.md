# Add obesity flag

Add obesity flag

## Usage

``` r
addObesity(
  x,
  indexDate = "cohort_start_date",
  window = c(-Inf, 0),
  conceptSet = NULL,
  bmiThreshold = NULL,
  nameStyle = "obesity",
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

  Window to asses `bmi` in, it must be a vector of two numeric values
  `c(min, max)`. Window times refer to days since `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain `bmi` as concepts.
  If `NULL` concepts will be retrieved using the OmopConcepts package.

- bmiThreshold:

  Argument to indicate the thresholds for the obesity using BMI
  measurements. It can be:

  - A single number, any BMI measurement above the threshold will be
    consider as an obesity record.

  - A tibble with the columns `bmi_threshold`, `sex`, `age_min` and
    `age_max`, to use age and sex specific thresholds.

  - NULL the table
    [`OmopIndices::bmiThreshold`](https://OHDSI.github.io/OmopIndices/reference/bmiThreshold.md)
    will be used.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The table `x` with a new column column indicating if subjects have an
obesity record in the window of interest.

## Examples

``` r
library(OmopIndices)


```
