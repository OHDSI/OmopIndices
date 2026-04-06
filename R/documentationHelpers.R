
#' Helper for consistent documentation of `x` argument
#'
#' @param x A `cdm_table` object, it mus contain `person_id` or `subject_id` as
#' columns.
#'
#' @name xDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `indexDate` argument
#'
#' @param indexDate A character string that points to a `Date` column in the `x`
#' table.
#'
#' @name indexDateDoc
#' @keywords internal
NULL

documentationWindow <- function(fun) {
  paste0(
    "Window to asses `", fun, "` in, it must be a vector of two numeric ",
    "values `c(min, max)`. Window times refer to days since `indexDate`."
  )
}

documentationConceptSet <- function(cs) {
  paste0(
    "It can either be a <codelist>, <codelist_with_details> or ",
    "<concept_set_expression> object. It must contain `",
    paste0(cs, collapse = "`, `"), "` as concepts. If `NULL` concepts will be ",
    "retrieved using the OmopConcepts package."
  )
}

#' Helper for consistent documentation of `nameStyle` argument
#'
#' @param nameStyle A character string with the name of the new column.
#'
#' @name nameStyleDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `name` argument
#'
#' @param name A character string with the name of the new table. If `NULL` a
#' temporary table will be created.
#'
#' @name nameDoc
#' @keywords internal
NULL
