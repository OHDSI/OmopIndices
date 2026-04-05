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

  A \`cdm_table\` object, it mus contain \`person_id\` or \`subject_id\`
  as columns.

- indexDate:

  A character string that points to a \`Date\` column in the \`x\`
  table.

- window:

  \`r documentationWindow("obesity")\`

- conceptSet:

  \`r documentationConceptSet(c("obesity", "bmi"))\`

- bmiThreshold:

  Argument to indicate the thresholds for the obesity using BMI
  measurements. It can be:

  \- A single number, any BMI measurement above the threshold will be
  consider as an obesity record. - A tibble with the columns
  \`bmi_threshold\`, \`sex\`, \`age_min\` and \`age_max\`, to use age
  and sex specific thresholds. - NULL the table
  \`OmopIndexes::bmiThreshold\` will be used.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If \`NULL\` a
  temporary table will be created.

## Value

The table \`x\` with a new column column indicating if subjects have an
obesity record in the window of interest.

## Examples

``` r
library(OmopIndexes)


```
