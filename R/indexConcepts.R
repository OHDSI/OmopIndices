
#' Get the codelists used for a specified index calculation
#'
#' @inheritParams indexDoc
#'
#' @returns A codelist containing the concepts used for the selected index.
#'
#' @export
#'
#' @examples
#' library(OmopIndices)
#'
#' getIndexCodelist("charlson")
#'
getIndexCodelist <- function(index) {
  # input check
  indices <- unique(internalConcepts$index)
  omopgenerics::assertChoice(index, indices, length = 1)

  internalConcepts |>
    dplyr::filter(.data$index == .env$index) |>
    dplyr::select("codelist_name", "concept_id") |>
    omopgenerics::newCodelist()
}
