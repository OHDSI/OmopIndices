
#' Add the hospital frailty risk score as defined in Gilbert et al:
#' <https://doi.org/10.1016/S0140-6736(18)30668-8>
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("hospital frailty risk score")`
#' @param conceptSet `r documentationConceptSet(frailtyConcepts)`
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
                                        conceptSet = NULL,
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
    name = name
  )
}

#' Hospital Frailty Risk Score data set
#'
#' @format ## `hospitalFrailtyRiskScore`
#' A data frame with 109 rows and 4 columns:
#' \describe{
#'   \item{concept_set}{The name of the concept set to be provided}
#'   \item{points}{Number of points associated with the codelist}
#'   \item{icd10_code}{ICD-10 code used}
#'   \item{icd_description}{Name of the ICD-10 code}
#' }
#' @source <https://doi.org/10.1016/S0140-6736(18)30668-8>
"hospitalFrailtyRiskScore"
