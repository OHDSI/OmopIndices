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
#> # Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0//tmp/RtmpowgbkK/file1a351812f83c.duckdb]
#>    person_id condition_start_date polypharmacy_count
#>        <int> <date>                            <int>
#>  1      2054 1974-06-30                            0
#>  2      2777 2014-12-10                            0
#>  3      2834 1945-06-17                            0
#>  4      3246 2016-12-31                            0
#>  5      3668 2013-12-04                            0
#>  6      3788 1997-11-24                            0
#>  7      4413 1975-09-25                            0
#>  8      4799 1998-08-06                            0
#>  9      4010 2015-10-21                            0
#> 10      5325 1948-11-21                            0
# }
```
