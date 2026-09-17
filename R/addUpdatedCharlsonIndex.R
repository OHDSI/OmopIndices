#' Add Updated Charlson Comorbidity Index (CCI) value based on
#' Quan et al. (2011) (\doi{10.1093/aje/kwq433})
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param ageAdjusted Logical; whether to include age adjustment in the updated
#' Charlson Comorbidity Index.
#' @param conceptSet
#' `r documentationConceptSet(requiredConcepts$updated_charlson)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column containing the updated Charlson
#' Comorbidity Index value.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(omock)
#' library(duckdb)
#' library(OmopIndices)
#' library(dplyr)
#' library(CohortConstructor)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#' cdm$cohort <- conceptCohort(
#'   cdm = cdm,
#'   conceptSet = list(sinusitis = c(257012L, 4283893L, 4294548L, 40481087L)),
#'   name = "cohort"
#' )
#'
#' # Using the internal concept sets:
#' cdm$cohort |>
#'   addUpdatedCharlsonIndex(ageAdjusted = TRUE) |>
#'   select(subject_id, cohort_start_date, updated_charlson) |>
#'   glimpse()
#'
#' # This example uses custom concept sets.
#' customConceptSet <- list(
#'   congestive_heart_failure = 319835L,
#'   dementia = 4182210L,
#'   chronic_pulmonary_disease = 255573L,
#'   connective_tissue_disease = 4134537L,
#'   mild_liver_disease = 194984L,
#'   moderate_or_severe_liver_disease = 4212540L,
#'   diabetes_with_complication = 42538715L,
#'   hemiplegia = 374022L,
#'   severe_chronic_kidney_disease = 46271022L,
#'   any_malignancy = 4180914L,
#'   metastatic_solid_tumor = 432851L,
#'   aids = 4267414L
#' )
#'
#' cdm$cohort |>
#'   addUpdatedCharlsonIndex(
#'     conceptSet = customConceptSet,
#'     nameStyle = "updated_charlson_custom"
#'   ) |>
#'   select(subject_id, cohort_start_date, updated_charlson_custom) |>
#'   glimpse()
#' }
addUpdatedCharlsonIndex <- function(x,
                             indexDate = "cohort_start_date",
                             ageAdjusted = TRUE,
                             conceptSet = getIndexCodelist("updated_charlson"),
                             nameStyle = "updated_charlson",
                             categories = NULL,
                             name = tableName(x)) {
  addIndex(
    x = x,
    type = "updated_charlson",
    indexDate = indexDate,
    window = c(-Inf, 0),
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = ageAdjusted,
    name = name,
  )

}
