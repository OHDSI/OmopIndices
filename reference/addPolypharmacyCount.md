# Add the maximum number of ingredients an individual is exposed simultaneouly in a certain window.

Add the maximum number of ingredients an individual is exposed
simultaneouly in a certain window.

## Usage

``` r
addPolypharmacyCount(
  x,
  indexDate = "cohort_start_date",
  window = c(0, 0),
  nameStyle = "polypharmacy_count",
  name = NULL
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
#> # Source:   table<og_011_1776298218> [?? x 3]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3//tmp/RtmpOo3zyj/file1ad81495a79.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1       245 2007-01-13                            0
#>  2      1231 1990-12-28                            0
#>  3      1162 1931-08-01                            0
#>  4      2445 1933-02-22                            0
#>  5      2555 1959-10-23                            0
#>  6      3070 1978-06-08                            0
#>  7      4127 2018-10-27                            0
#>  8      4977 1971-08-26                            0
#>  9      4755 2013-11-04                            0
#> 10      4852 1990-01-02                            0
# }
```
