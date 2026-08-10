#' Add Electronic Frailty Index 2 (eFI2) value based on Best et al. (2025)
#'
#' The eFI2 is a weighted score for one-year frailty-related outcomes. The
#' supplied concept set must contain the named eFI2 predictors. For BMI,
#' alcohol and smoking, the mutually exclusive categories used by the paper
#' should be represented explicitly (including missing categories where
#' applicable).
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("electronic frailty index 2")`
#' @param conceptSet
#' `r documentationConceptSet(requiredConcepts$electronic_frailty_index_2)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The `x` table with a new eFI2 score column.
#'
#' @export
#'
addElectronicFrailtyIndex2 <- function(x,
                                       indexDate = "cohort_start_date",
                                       window = c(-365, 0),
                                       conceptSet = getIndexCodelist("electronic_frailty_index_2"),
                                       categories = list(
                                         "robust" = c(0, 0.0857),
                                         "mild" = c(0.0857, 0.1624),
                                         "moderate" = c(0.1624, 0.2392),
                                         "severe" = c(0.2392, Inf)
                                       ),
                                       nameStyle = "efi2",
                                       name = tableName(x)) {
  addIndex(
    x = x,
    type = "electronic_frailty_index_2",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = FALSE,
    name = name
  )
}
