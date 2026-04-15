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
#> # Source:   table<og_011_1776292325> [?? x 3]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3//tmp/RtmpM2Bprb/file1a6e60a2d5b5.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1       582 1996-11-05                            0
#>  2      1173 1993-02-01                            0
#>  3      1310 2010-04-01                            0
#>  4      1576 2015-05-13                            0
#>  5      1565 1998-07-02                            0
#>  6      3428 1970-06-05                            0
#>  7      3689 1971-09-23                            0
#>  8      3179 1939-10-11                            0
#>  9      4395 2010-07-11                            0
#> 10      5253 2011-01-18                            0
# }
```
