
#' Add obesity flag
#'
#' @inheritParams xDoc
#' @param indexDate indexDate
#' @param window `r documentationWindow("obesity")`
#' @param conceptSet conceptSet
#' @param bmiThreshold bmiThreshold
#' @param nameStyle nameStyle
#' @param name name
#'
#' @returns The table `x` with a new column
#' @export
#'
#' @examples
#' library(OmopIndexes)
#'
#'
#'
addObesity <- function(x,
                       indexDate = "cohort_start_date",
                       window = c(-Inf, 0),
                       conceptSet = NULL,
                       bmiThreshold = NULL,
                       nameStyle = "obesity",
                       name = tableName(x)) {

}

#' Title
#'
#' @param x
#' @param indexDate
#' @param window
#' @param conceptSet
#' @param nameStyle
#' @param name
#'
#' @returns
#' @export
#'
#' @examples
addBMI <- function(x,
                   indexDate = "cohort_start_date",
                   window = c(-Inf, 0),
                   conceptSet = NULL,
                   nameStyle = "bmi",
                   name = tableName(x)) {
  # input check
  x <- validateX(x)
  indexDate <- validateIndexDate(indexDate, x)
  window <- validateWindow(window)
  conceptSet <- validateConceptSet(conceptSet, "bmi")
  nameStyle <- validateNameStyle(nameStyle, x)

  # add measurement
  x |>
    PatientProfiles::addConceptIntersectField(
      conceptSet = conceptSet,
      field = "value_as_number",
      indexDate = indexDate,
      window = window,
      order = "last",
      allowDuplicates = FALSE,
      nameStyle = nameStyle,
      name = name
    )
}
