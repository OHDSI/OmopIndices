
documentationWindow <- function(fun) {
  paste0(
    "Window to asses `", fun, "` in, it must be a vector of two numeric",
    " values `c(min, max)`. Window times refer to days since `indexDate`."
  )
}


#' Helper for consistent documentation of x argument
#'
#' @param x A `cdm_table` object, it mus contain `person_id` or `subject_id` as
#' columns.
#'
#' @name xDoc
#' @keywords internal
NULL
