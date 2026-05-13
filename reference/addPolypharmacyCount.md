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
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0//tmp/RtmpGpMJ1y/file1aaf29efdf6b.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1       236 1990-12-21                            0
#>  2       648 1935-04-20                            0
#>  3       682 1972-10-08                            0
#>  4      1159 1982-03-18                            0
#>  5      1980 1972-10-12                            0
#>  6      2939 1997-12-23                            0
#>  7      3516 2015-11-29                            0
#>  8      3601 2003-05-13                            0
#>  9      4484 2000-05-10                            0
#> 10      4682 1984-01-28                            0
# }
```
