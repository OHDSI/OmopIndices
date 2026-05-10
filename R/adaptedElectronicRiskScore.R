
#' Add the adapted electronic risk score as defined in Politi et al:
#' <xxx>
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("adapted electronic risk score")`
#' @param conceptSet `r documentationConceptSet(frailtyConcepts)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The `x` table with a new column added with the adapted electronic
#' risk score of the patient.
#'
#' @export
#'
addAdaptedElectronicRiskScore <- function(x,
                                          indexDate = "cohort_start_date",
                                          window = c(-365, 0),
                                          conceptSet = NULL,
                                          categories = list(
                                            "fit" = c(0, 0.12),
                                            "mild" = c(0.12, 0.24),
                                            "moderate" = c(0.24, 0.36),
                                            "severe" = c(0.36, 1)
                                          ),
                                          nameStyle = "aers",
                                          name = tableName(x)) {
  addIndex(
    x = x,
    type = "aers",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    name = name
  )
}
