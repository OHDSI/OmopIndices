
#' Add Charlson index value
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("Charlson index")`
#' @param conceptSet `r documentationConceptSet(charlsonConcepts)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column column with the corresponding
#' Charlson index value.
#'
#' @export
#'
#' @examples
#' library(OmopIndices)
#'
#'
#'
addCharlsonIndex <- function(x,
                             indexDate = "cohort_start_date",
                             window = c(-Inf, 0),
                             conceptSet = NULL,
                             nameStyle = "charlson_index",
                             categories = NULL,
                             name = tableName(x)) {
  addIndex(
    x = x,
    type = "charlson",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    name = name
  )
}
