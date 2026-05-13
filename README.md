
<!-- README.md is generated from README.Rmd. Please edit that file -->

# OmopIndices

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![CRAN
status](https://www.r-pkg.org/badges/version/OmopIndices)](https://CRAN.R-project.org/package=OmopIndices)
[![R-CMD-check](https://github.com/OHDSI/OmopIndices/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/OHDSI/OmopIndices/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/OHDSI/OmopIndices/graph/badge.svg)](https://app.codecov.io/gh/OHDSI/OmopIndices)
<!-- badges: end -->

The goal of **OmopIndices** is to enable standardised and reproducible
derivation of clinically and epidemiologically relevant patient-level
indexes and covariates directly from OMOP CDM databases instances.

## Ecosystem

*OmopIndices* is part of the ecosystem of packages defined by
[omopgenerics](https://darwin-eu.github.io/omopgenerics/). For more
details on the ecosystem you can read the [Tidy R programming with the
OMOP Common Data
Model](https://ohdsi.github.io/Tidy-R-programming-with-OMOP/) book.

## Tested sources

| Source | Driver | CDM reference | Status |
|----|----|----|----|
| Local R dataframe | N/A | `omopgenerics::cdmFromTables()` | ![](https://img.shields.io/github/actions/workflow/status/OHDSI/OmopIndices/test-weekly.yaml?branch=main&job=local-omopgenerics) |
| In-memory duckdb datatabase | duckdb | `CDMConnector::cdmFromCon()` | ![](https://img.shields.io/github/actions/workflow/status/OHDSI/OmopIndices/test-weekly.yaml?branch=main&job=duckdb-CDMConnector) |

## Installation

You can install the CRAN version of OmopIndices as:

``` r
install.packages("OmopIndices")
```

Or you can install the development version of OmopIndices from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pkg_install("OHDSI/OmopIndices")
```

## Main functionality

## Examples

### Mock data

For the purpose to illustrate the functionality of OmopIndices we will
use the *GiBleed* database contained by the
[omock](https://ohdsi.github.io/omock/) package.

``` r
library(omock)
library(duckdb)
#> Warning: package 'duckdb' was built under R version 4.4.3
#> Loading required package: DBI
#> Warning: package 'DBI' was built under R version 4.4.3
library(OmopIndices)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> ℹ Inserting <cdm_reference> into duckdb.
```

### `addLocation()`
