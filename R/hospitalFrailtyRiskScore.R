
#' Add the hospital frailty risk score as defined in
#' [Gilbert et al. (2018)](https://doi.org/10.1016/S0140-6736(18)30668-8)
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("hospital frailty risk score")`
#' @param conceptSet
#' `r documentationConceptSet(requiredConcepts$hospital_frailty_risk_score)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The `x` table with a new column added with the hospital
#' frailty risk score of the patient.
#'
#' @export
#'
addHospitalFrailtyRiskScore <- function(x,
                                        indexDate = "cohort_start_date",
                                        window = c(-365, 0),
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
    type = "hfrs",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = FALSE,
    name = name
  )
}
