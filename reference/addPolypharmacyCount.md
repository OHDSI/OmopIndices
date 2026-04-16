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
#> # Source:   table<og_011_1776298344> [?? x 3]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3//tmp/RtmpTNwoen/file1aa51f1e650b.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1      1057 2007-03-13                            0
#>  2       844 1993-10-01                            0
#>  3      2237 2005-10-29                            0
#>  4      1967 1993-04-22                            0
#>  5      2233 1973-11-30                            0
#>  6      3968 1954-01-03                            0
#>  7      3901 2010-10-12                            0
#>  8      4586 2003-08-14                            0
#>  9      4113 1997-01-17                            0
#> 10      5290 1955-11-13                            0
# }
```
