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
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0//tmp/RtmpfnAWS3/file1a2053478613.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1       430 1948-06-27                            0
#>  2       388 1966-08-03                            0
#>  3       670 2015-09-19                            0
#>  4      1854 1993-05-07                            0
#>  5      1137 1956-11-18                            0
#>  6      3363 1964-05-27                            0
#>  7      3483 2018-07-22                            0
#>  8      4560 1999-08-30                            0
#>  9      4852 1990-09-17                            0
#> 10      5315 1957-07-05                            0
# }
```
