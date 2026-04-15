# Add Body Mass Index measurement

Add Body Mass Index measurement

## Usage

``` r
addBMI(
  x,
  conceptSet = NULL,
  indexDate = "cohort_start_date",
  window = c(-Inf, 0),
  order = "last",
  nameStyle = "bmi",
  categories = NULL,
  name = tableName(x)
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain `obesity`, `bmi` as
  concepts. If `NULL` concepts will be retrieved using the OmopConcepts
  package.

- indexDate:

  A character string that points to a `Date` column in the `x` table.

- window:

  Window to asses `obesity` in, it must be a vector of two numeric
  values `c(min, max)`. Window times refer to days since `indexDate`.

- order:

  A character vector with the options to deal with multiple values per
  person:

  - `last`: Latest value within the window.

  - `first`: First value within the window.

  - `max`: Maximum value within the window.

  - `min`: Minimum value within the window.

- nameStyle:

  A character string with the name of the new column.

- categories:

  List to group the `bmi` records into categories.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

A new table with the new column.

## Examples

``` r
library(OmopIndices)
```
