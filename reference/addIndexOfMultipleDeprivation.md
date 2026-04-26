# Add Socio-economic status as a column to a table using the [Index of Multiple Deprivation](https://athena.ohdsi.org/search-terms/terms/35812882)

Add Socio-economic status as a column to a table using the [Index of
Multiple
Deprivation](https://athena.ohdsi.org/search-terms/terms/35812882)

## Usage

``` r
addIndexOfMultipleDeprivation(
  x,
  indexDate = "cohort_start_date",
  window = c(-Inf, Inf),
  order = "last",
  nameStyle = "socio_economic_status",
  name = tableName(x),
  missingSocioEconomicStatusValue = "Missing"
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- indexDate:

  A character string that points to a `Date` column in the `x` table.

- window:

  Window to asses `socio_economic_status` in, it must be a vector of two
  numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- order:

  Character to indicate which of the records to select if multiple
  records are found.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

- missingSocioEconomicStatusValue:

  Character to assign missing values.

## Value

The `x` table with a new column added with the socio-economic status
(index of multiple deprivation) of the patient.
