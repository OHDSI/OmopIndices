# Add the location to a table

Add the location to a table

## Usage

``` r
addLocation(
  x,
  from = c("location_id", "care_site_id"),
  nameStyle = "location",
  name = tableName(x),
  missingLocationValue = "Missing"
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- from:

  Character to indicate how to retrieve location, if multiple values are
  provided different sources will be tried sequentially.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

- missingLocationValue:

  Character to coaslesce missing values.

## Value

The `x` table with a new column added with the location of the patient.

## Examples

``` r
library(OmopIndices)
library(omock)
library(dplyr)

cdm <- mockCdmFromDataset(source = "duckdb")
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> ℹ Inserting <cdm_reference> into duckdb.

cdm$condition_occurrence |>
  addLocation() |>
  glimpse()
#> ℹ Trying to get location from: location_id.
#> ✖ Location could not be added from location_id.
#> ℹ Trying to get location from: care_site_id.
#> ✖ Location could not be added from care_site_id.
#> ! No location found, variable will be filled with `Missing`.
#> Rows: ??
#> Columns: 17
#> Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.5.3//tmp/RtmpTNwoen/file1aa5f4be88e.duckdb]
#> $ condition_occurrence_id       <int> 4483, 4657, 4815, 4981, 5153, 5313, 5513…
#> $ person_id                     <int> 263, 273, 283, 293, 304, 312, 326, 334, …
#> $ condition_concept_id          <int> 4112343, 192671, 28060, 378001, 257012, …
#> $ condition_start_date          <date> 2015-10-02, 2011-10-10, 1984-02-15, 200…
#> $ condition_start_datetime      <dttm> 2015-10-02, 2011-10-10, 1984-02-15, 200…
#> $ condition_end_date            <date> 2015-10-14, NA, 1984-02-25, 2005-12-07,…
#> $ condition_end_datetime        <dttm> 2015-10-14, NA, 1984-02-25, 2005-12-07,…
#> $ condition_type_concept_id     <int> 32020, 32020, 32020, 32020, 32020, 32020…
#> $ condition_status_concept_id   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ stop_reason                   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ provider_id                   <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ visit_occurrence_id           <int> 17479, 18192, 18859, 19515, 20239, 20658…
#> $ visit_detail_id               <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ condition_source_value        <chr> "195662009", "K92.2", "43878008", "62106…
#> $ condition_source_concept_id   <int> 4112343, 35208414, 28060, 378001, 257012…
#> $ condition_status_source_value <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ location                      <chr> "Missing", "Missing", "Missing", "Missin…
```
