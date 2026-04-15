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

  A \`cdm_table\` object, it mus contain \`person_id\` or \`subject_id\`
  as columns.

- indexDate:

  A character string that points to a \`Date\` column in the \`x\`
  table.

- window:

  \`r documentationWindow("Charlson index")\`

- conceptSet:

  \`r documentationConceptSet(charlsonConcepts)\`

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If \`NULL\` a
  temporary table will be created.

## Value

The table \`x\` with a new column column with the corresponding Charlson
index value.

## Examples

``` r
library(OmopIndices)


```
