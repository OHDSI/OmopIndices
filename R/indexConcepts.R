
#' Get the codelists used for a certain index calculation
#'
#' @inheritParams indexDoc
#'
#' @returns A codelist used for the index.
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
  indices <- unique(concepts$index)
  omopgenerics::assertChoice(index, indices, length = 1)

  concepts |>
    dplyr::filter(.data$index == .env$index) |>
    dplyr::select("codelist_name", "concept_id") |>
    omopgenerics::newCodelist()
}
