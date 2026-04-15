
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

The goal of **OmopIndices** is to … *clearly state the main goal of the
package*

## Tested sources

| Source                      | Driver | CDM reference                   | Status                                                                                                                            |
|-----------------------------|--------|---------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| Local R dataframe           | N/A    | `omopgenerics::cdmFromTables()` | ![](https://img.shields.io/github/actions/workflow/status/OHDSI/OmopIndices/test-weekly.yaml?branch=main&job=local-omopgenerics)  |
| In-memory duckdb datatabase | duckdb | `CDMConnector::cdmFromCon()`    | ![](https://img.shields.io/github/actions/workflow/status/OHDSI/OmopIndices/test-weekly.yaml?branch=main&job=duckdb-CDMConnector) |

## Installation

You can install the development version of OmopIndices from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pkg_install("OHDSI/OmopIndices")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(OmopIndices)
```
