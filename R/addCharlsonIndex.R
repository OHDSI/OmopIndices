#' Add Charlson Comorbidity Index (CCI) value based on
#' Charlson et al. (1987) (\doi{10.1016/0021-9681(87)90171-8}) and
#' Charlson et al. (1994) (\doi{10.1016/0895-4356(94)90129-5})
#' (age-adjusted) version.
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param ageAdjusted Logical; whether to include age adjustment in the
#' Charlson Comorbidity Index.
#' @param conceptSet `r documentationConceptSet(requiredConcepts$charlson)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column containing the Charlson Comorbidity
#' Index value.
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
#'   addCharlsonIndex(ageAdjusted = TRUE) |>
#'   select(subject_id, cohort_start_date, charlson) |>
#'   glimpse()
#'
#' # This example uses custom concept sets.
#' customConceptSet <- list(
#'   myocardial_infarction = 329847L,
#'   congestive_heart_failure = 319835L,
#'   peripheral_vascular_disease = 321052L,
#'   cerebrovascular_disease = 381591L,
#'   dementia = 4182210L,
#'   chronic_pulmonary_disease = 255573L,
#'   connective_tissue_disease = 4134537L,
#'   peptic_ulcer_disease = 4027663L,
#'   mild_liver_disease = 194984L,
#'   moderate_or_severe_liver_disease = 4212540L,
#'   diabetes_without_complication = 201820L,
#'   diabetes_with_complication = 42538715L,
#'   hemiplegia = 374022L,
#'   severe_chronic_kidney_disease = 46271022L,
#'   any_malignancy = 4180914L,
#'   metastatic_solid_tumor = 432851L,
#'   aids = 4267414L
#' )
#'
#' cdm$cohort |>
#'   addCharlsonIndex(
#'     conceptSet = customConceptSet,
#'     nameStyle = "charlson_custom"
#'   ) |>
#'   select(subject_id, cohort_start_date, charlson_custom) |>
#'   glimpse()
#' }
addCharlsonIndex <- function(x,
                             indexDate = "cohort_start_date",
                             ageAdjusted = TRUE,
                             conceptSet = getIndexCodelist("charlson"),
                             nameStyle = "charlson",
                             categories = NULL,
                             name = tableName(x)) {
  addIndex(
    x = x,
    type = "charlson",
    indexDate = indexDate,
    window = c(-Inf, 0),
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = ageAdjusted,
    name = name,
  )

}
