# Add the maximum number of ingredients an individual is exposed simultaneously in a certain window.

Add the maximum number of ingredients an individual is exposed
simultaneously in a certain window.

## Usage

``` r
addPolypharmacyCount(
  x,
  indexDate = "cohort_start_date",
  window = c(0, 0),
  nameStyle = "polypharmacy_count",
  name = tableName(x)
)
```

## Arguments

- x:

  A `cdm_table` object.

- indexDate:

  Name of a 'date' column that indicates the index date.

- window:

  Window of interest.

- nameStyle:

  Name of the new column.

- name:

  Name of the new table.

## Value

The table `x` with a new column column with the number of ingredients
used in the window of interest.

## Examples

``` r
# \donttest{
library(OmopIndices)
library(omock)
library(dplyr)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> ℹ Inserting <cdm_reference> into duckdb.

cdm$condition_occurrence |>
  slice_sample(n = 10) |>
  select("person_id", "condition_start_date") |>
  addPolypharmacyCount(indexDate = "condition_start_date")
#> # Source:   table<results.test_condition_occurrence> [?? x 3]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0//tmp/RtmpOJGoHp/file1a6e4a56aff4.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1       902 1990-12-15                            0
#>  2       673 2014-08-05                            0
#>  3      1508 1944-10-15                            0
#>  4      1903 1962-07-26                            0
#>  5      3263 1978-09-12                            0
#>  6      3059 1972-07-07                            0
#>  7      3440 2009-07-11                            0
#>  8      3773 1979-12-23                            0
#>  9      4707 1977-03-19                            0
#> 10      5058 2001-10-16                            0
# }
```
