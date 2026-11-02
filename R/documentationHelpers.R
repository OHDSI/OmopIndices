
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

#' Helper for consistent documentation of `window` argument
#'
#' @param window `NULL` to use the windows defined by the index components, or
#' a numeric vector of length two, `c(min, max)`, to override the component
#' windows in days relative to `indexDate`. Use `-Inf` or `Inf` for an
#' unbounded lower or upper limit.
#'
#' @name windowDoc
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

#' Helper for consistent documentation for cohort functions
#'
#' @param cdm A `cdm_reference` object.
#' @param categories A named list of numeric vectors, each containing the lower
#' and upper bounds of a score interval. Upper and lower bounds are both
#' included. The name will be used to name the resultant cohort.
#' @param name Name of the new cohort table created in the cdm object.
#' @param subsetCohort A character refering to a cohort table containing
#' individuals for whom cohorts will be generated. Only individuals in this
#' table will appear in the generated cohort. If `NULL` no subsetting will be
#' performed.
#' @param subsetCohortId Specifies cohort IDs from the `subsetCohort` table to
#' include. If none are provided, all cohorts from the subsetCohort are
#' included.
#'
#' @name cohortDoc
#' @keywords internal
NULL
