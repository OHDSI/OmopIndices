# OmopIndices

The goal of **OmopIndices** is to … *clearly state the main goal of the
package*

## Tested sources

| Source                      | Driver | CDM reference                                                                                            | Status                                                                                                                            |
|-----------------------------|--------|----------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| Local R dataframe           | N/A    | [`omopgenerics::cdmFromTables()`](https://darwin-eu.github.io/omopgenerics/reference/cdmFromTables.html) | ![](https://img.shields.io/github/actions/workflow/status/OHDSI/OmopIndices/test-weekly.yaml?branch=main&job=local-omopgenerics)  |
| In-memory duckdb datatabase | duckdb | [`CDMConnector::cdmFromCon()`](https://darwin-eu.github.io/CDMConnector/reference/cdmFromCon.html)       | ![](https://img.shields.io/github/actions/workflow/status/OHDSI/OmopIndices/test-weekly.yaml?branch=main&job=duckdb-CDMConnector) |

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
