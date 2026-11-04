
#' Add Body Mass Index measurement
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param lookbackDays Nonnegative number of days to look back from `indexDate`,
#' including both endpoints. The default, `Inf`, uses all prior measurements.
#' @param conceptSet `r documentationConceptSet("bmi")`
#' @param categories A named list of numeric vectors, each containing the lower
#' and upper bounds of a BMI interval. An additional column named by appending
#' `_categories` to `nameStyle` is added, and missing BMI values are labelled
#' `missing`.
#' @inheritParams nameStyleDoc
#' @inheritParams inObservationDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column containing the latest eligible BMI
#' value. When several values occur on that day, the maximum is used.
#' @export
#'
#' @examples
#' \donttest{
#' library(omock)
#' library(duckdb)
#' library(OmopIndices)
#' library(dplyr)
#' library(CohortConstructor)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#' cdm$cohort <- conceptCohort(
#'   cdm = cdm,
#'   conceptSet = list(sinusitis = c(257012L, 4283893L, 4294548L, 40481087L)),
#'   name = "cohort"
#' )
#'
#' cdm$cohort |>
#'   addBMI(lookbackDays = 365) |>
#'   select(subject_id, cohort_start_date, bmi) |>
#'   glimpse()
#' }
#'
addBMI <- function(x,
                   conceptSet = getIndexCodelist("body_mass_index"),
                   indexDate = "cohort_start_date",
                   lookbackDays = Inf,
                   nameStyle = "bmi",
                   categories = NULL,
                   inObservation = TRUE,
                   name = tableName(x)) {
  omopgenerics::assertNumeric(lookbackDays, min = 0, length = 1)
  omopgenerics::assertLogical(inObservation, length = 1)

  definition <- list(list(
    type = "measurement",
    concept_set = "bmi",
    follow_up = lookbackDays,
    in_observation = inObservation,
    tie = "max",
    score = "value"
  ))

  addIndex(
    x = x,
    definition = definition,
    indexDate = indexDate,
    window = NULL,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    name = name
  )
}
