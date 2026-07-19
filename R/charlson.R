
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
#' @examples{
#' library(OmopIndices)
#' library(omock)
#'
#' cdm <- mockCdmFromDataset()
#' cdm <- cdm |>
#'  mockCohort()
#'
#'conceptSet <- list(
#'  "myocardial_infarction" = 4116491L,
#'  "congestive_heart_failure" = 4113008L,
#'  "peripheral_vascular_disease" = 4156265L,
#'  "cerebrovascular_disease" = 4155034L,
#'  "dementia" = 4094814L,
#'  "chronic_pulmonary_disease" = 4048695L,
#'  "connective_tissue_disease" = 40486433L,
#'  "peptic_ulcer_disease" = 4051466L,
#'  "mild_liver_disease" = 4142905L,
#'  "moderate_or_severe_liver_disease" = 4144583L,
#'  "diabetes_without_complication" = 4144583L,
#'  "diabetes_with_complication" = 4144583L,
#'  "hemiplegia" = 4144583L,
#'  "severe_chronic_kidney_disease" = 4144583L,
#'  "any_malignancy" = 4144583L,
#'   "metastatic_solid_tumor" = 4144583L,
#'  "aids" = 4144583L)
#'
#' cdm$cohort |>
#'   addCharlsonIndex(conceptSet = conceptSet)
#'}
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

conceptSet <- list(
     "myocardial_infarction" = 4116491L,
     "congestive_heart_failure" = 4113008L,
     "peripheral_vascular_disease" = 4156265L,
     "cerebrovascular_disease" = 4155034L,
     "dementia" = 4094814L,
     "chronic_pulmonary_disease" = 4048695L,
     "connective_tissue_disease" = 40486433L,
     "peptic_ulcer_disease" = 4051466L,
     "mild_liver_disease" = 4142905L,
     "moderate_or_severe_liver_disease" = 4144583L,
     "diabetes_without_complication" = 4144583L,
     "diabetes_with_complication" = 4144583L,
     "hemiplegia" = 4144583L,
     "severe_chronic_kidney_disease" = 4144583L,
     "any_malignancy" = 4144583L,
     "metastatic_solid_tumor" = 4144583L,
     "aids" = 4144583L)
