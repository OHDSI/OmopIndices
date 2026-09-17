
#' Helper for consistent documentation of `x` argument
#'
#' @param x A `cdm_table` containing a person identifier column named
#' `person_id` or `subject_id`.
#'
#' @name xDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `indexDate` argument
#'
#' @param indexDate A character string naming the `Date` column in `x` that
#' defines the index date.
#'
#' @name indexDateDoc
#' @keywords internal
NULL

documentationWindow <- function(fun) {
  paste0(
    "A numeric vector of length two, `c(min, max)`, defining the window for `",
    fun, "` in days relative to `indexDate`. Use `-Inf` or `Inf` for an ",
    "unbounded lower or upper limit."
  )
}

documentationConceptSet <- function(cs) {
  paste0(
    "A named concept set supplied as a `codelist`, `codelist_with_details`, ",
    "`concept_set_expression`, or named list of concept IDs. It must contain `",
    paste0(cs, collapse = "`, `"), "` as concepts. By default, internal ",
    "codelists are used."
  )
}

#' Helper for consistent documentation of `nameStyle` argument
#'
#' @param nameStyle A character string specifying the name of the new column.
#'
#' @name nameStyleDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `name` argument
#'
#' @param name A character string specifying the name of the output table. If
#' `NULL`, a temporary table is created.
#'
#' @name nameDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `categories` argument
#'
#' @param categories A named list of numeric vectors, each containing the lower
#' and upper bounds of a score interval. An additional column with the suffix
#' `_categories` is added. Intervals are
#' evaluated in the order supplied, and missing scores are labelled `missing`.
#'
#' @name categoriesDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `inObservation` argument
#'
#' @param inObservation Logical; whether to restrict records to the person's
#' observation period.
#'
#' @name inObservationDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `index` argument
#'
#' @param index A character string identifying the index for which to retrieve
#' internal codelists. Supported values are `r indexOptions()`.
#'
#' @name indexDoc
#' @keywords internal
NULL

indexOptions <- function() {
  # eFI2 is retained internally while its implementation is being developed.
  indices <- unique(internalConcepts$index)
  indices <- indices[indices != "electronic_frailty_index_2"]
  indices <- paste0("`\"", indices, "\"`")
  indices[length(indices)] <- paste0("and ", indices[length(indices)])
  paste0(indices, collapse = ", ")
}
