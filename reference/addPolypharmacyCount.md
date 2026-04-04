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

## Examples

``` r
# \donttest{
library(OmopIndexes)
library(omock)
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> ℹ Inserting <cdm_reference> into duckdb.

cdm$condition_occurrence |>
  slice_sample(n = 10) |>
  select("person_id", "condition_start_date") |>
  addPolypharmacyCount(indexDate = "condition_start_date")
#> # Source:   table<og_003_1775335765> [?? x 3]
#> # Database: DuckDB 1.5.1 [unknown@Linux 6.17.0-1008-azure:R 4.5.3//tmp/RtmpOSqaQk/file1d0c5b85e4bd.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1      1761 1962-12-04                            0
#>  2      2786 1965-04-17                            0
#>  3      2540 2003-08-27                            0
#>  4      2736 1981-09-07                            0
#>  5      3022 1978-11-05                            0
#>  6      3984 1956-08-28                            0
#>  7      4732 1964-07-06                            0
#>  8      4077 1976-12-03                            0
#>  9      4241 1972-12-15                            0
#> 10      5063 1981-09-11                            0
# }
```
