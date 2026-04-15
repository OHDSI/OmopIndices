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

  A \`cdm_table\` object.

- indexDate:

  Name of a 'date' column that indicates the index date.

- window:

  Window of interest.

- nameStyle:

  Name of the new column.

- name:

  Name of the new table.

## Value

The table \`x\` with a new column column with the number of ingredients
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
#> # Source:   table<og_011_1776280783> [?? x 3]
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3//tmp/Rtmptx4SBk/file1b32290f67c4.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1       486 1987-10-28                            0
#>  2      1004 1997-05-27                            0
#>  3       654 2001-10-12                            0
#>  4      1328 2008-02-17                            0
#>  5      2012 1971-05-10                            0
#>  6      2603 1975-05-07                            0
#>  7      3686 2008-08-06                            0
#>  8      3570 2004-06-29                            0
#>  9      4040 2015-03-12                            0
#> 10      3803 2016-09-04                            0
# }
```
