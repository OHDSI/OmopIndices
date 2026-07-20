#' Add Updated Charlson Comorbidity Index (CCI) value based on Quan et al. (2011)
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param ageAdjusted Whether to calculate the Age-Adjusted Comorbidity Index (TRUE) or not (FALSE)
#' @param window `r documentationWindow("Charlson index")`
#' @param conceptSet `r documentationConceptSet(updatedCharlsonConcepts)`
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
#'  "congestive_heart_failure" = 319835L,,
#'  "dementia" = 4182210L,
#'  "chronic_pulmonary_disease" = 255573L,
#'  "connective_tissue_disease" = 4134537L,
#'  "mild_liver_disease" = 194984L,
#'  "moderate_or_severe_liver_disease" = 4212540L,
#'  "diabetes_with_complication" = 42538715L,
#'  "hemiplegia" = 374022L,
#'  "severe_chronic_kidney_disease" = 46271022L,
#'  "any_malignancy" = 4180914L,
#'  "metastatic_solid_tumor" = 432851L,
#'  "aids" = 4267414L)
#'
#' cdm$cohort |>
#'   addUpdatedCharlsonIndex(conceptSet = conceptSet)
#'}
addUpdatedCharlsonIndex <- function(x,
                             indexDate = "cohort_start_date",
                             ageAdjusted = TRUE,
                             window = c(-Inf, 0),
                             conceptSet = NULL,
                             nameStyle = "charlson_index",
                             categories = NULL,
                             name = tableName(x)) {
  addIndex(
    x = x,
    type = "updatedCharlson",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = ageAdjusted,
    name = name,
  )

}

