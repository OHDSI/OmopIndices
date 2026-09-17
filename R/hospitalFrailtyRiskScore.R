
#' Add the hospital frailty risk score as defined in
#' Gilbert et al. (2018) (\doi{10.1016/S0140-6736(18)30668-8})
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param conceptSet
#' `r documentationConceptSet(requiredConcepts$hospital_frailty_risk_score)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column containing the Hospital Frailty Risk
#' Score value.
#'
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
#'   addHospitalFrailtyRiskScore() |>
#'   select(subject_id, cohort_start_date, hfrs, hfrs_categories) |>
#'   glimpse()
#' }
#'
addHospitalFrailtyRiskScore <- function(x,
                                        indexDate = "cohort_start_date",
                                        conceptSet = getIndexCodelist("hospital_frailty_risk_score"),
                                        categories = list(
                                          "low" = c(0, 5),
                                          "intermediate" = c(5, 15),
                                          "high" = c(15, Inf)
                                        ),
                                        nameStyle = "hfrs",
                                        name = tableName(x)) {
  addIndex(
    x = x,
    type = "hospital_frailty_risk_score",
    indexDate = indexDate,
    window = c(-730, 0),
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = FALSE,
    name = name
  )
}
