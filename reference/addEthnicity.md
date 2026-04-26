# Add the ethnicity of a person to a table

Add the ethnicity of a person to a table

## Usage

``` r
addEthnicity(
  x,
  from = c("ethnicity_concept_id", "ethnicity_source_concept_id", "race_concept_id",
    "race_source_concept_id"),
  nameStyle = "ethnicity",
  name = tableName(x),
  missingEthnicityValue = "Missing"
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- from:

  Character to indicate how to retrieve ethnicity, if multiple values
  are provided different sources will be tried sequentially. Available
  options are:

  - **ethnicity_concept_id** to assign ethnicity using the
    `concept_name` associated with the `ethnicity_concept_id` column of
    person table.

  - **ethnicity_source_concept_id** to assign ethnicity using the
    `concept_name` associated with the `ethnicity_source_concept_id`
    column of person table.

  - **race_concept_id** to assign ethnicity using the `concept_name`
    associated with the `race_concept_id` column of person table.

  - **race_source_concept_id** to assign ethnicity using the
    `concept_name` associated with the `race_source_concept_id` column
    of person table.

  - **ethnicity_source_value** to assign ethnicity using the value of
    the column `ethnicity_source_value` in the person table.

  - **race_source_value** to assign ethnicity using the value of the
    column `race_source_value` in the person table.

  - **nhs-categories** to assign ethnicity using [NHS Ethnic
    Category](https://athena.ohdsi.org/search-terms/terms?vocabulary=NHS+Ethnic+Category).

  - **nhs-groups** to assign ethnicity using the broad groups of [NHS
    Ethnic
    Category](https://athena.ohdsi.org/search-terms/terms?vocabulary=NHS+Ethnic+Category)
    as described in <https://doi.org/10.1038/s41597-024-02958-1>.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

- missingEthnicityValue:

  Character to coaslesce missing values.

## Value

The `x` table with a new column added with the ethnicity of the patient.

## Examples

``` r
library(OmopIndices)
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

cdm <- mockCdmFromDataset(source = "duckdb")
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> ℹ Inserting <cdm_reference> into duckdb.

cdm$condition_occurrence |>
  addEthnicity() |>
  glimpse()
#> ℹ Trying to get ethnicity from: ethnicity_concept_id.
#> ✖ Ethnicity could not be added from ethnicity_concept_id.
#> ℹ Trying to get ethnicity from: ethnicity_source_concept_id.
#> ✖ Ethnicity could not be added from ethnicity_source_concept_id.
#> ℹ Trying to get ethnicity from: race_concept_id.
#> ✖ Ethnicity could not be added from race_concept_id.
#> ℹ Trying to get ethnicity from: race_source_concept_id.
#> ✖ Ethnicity could not be added from race_source_concept_id.
#> ! No ethnicity found, variable will be filled with `Missing`.
#> Rows: ??
#> Columns: 17
#> Database: DuckDB 1.5.2 [unknown@Linux 6.17.0-1010-azure:R 4.6.0//tmp/RtmpfnAWS3/file1a2010f6386b.duckdb]
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
#> $ ethnicity                     <chr> "Missing", "Missing", "Missing", "Missin…
```
