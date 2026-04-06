
#' Add Charlson index value
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("Charlson index")`
#' @param conceptSet `r documentationConceptSet(charlsonConcepts)`
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column column with the corresponding
#' Charlson index value.
#'
#' @export
#'
#' @examples
#' library(OmopIndexes)
#'
#'
#'
addCharlsonIndex <- function(x,
                             indexDate = "cohort_start_date",
                             window = c(-Inf, 0),
                             conceptSet = NULL,
                             nameStyle = "charlson_index",
                             name = tableName(x)) {
  # initial checks
  x <- validateX(x)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- validateIndexDate(indexDate, x)
  window <- validateWindow(window)
  conceptSet <- validateConceptSet(conceptSet, charlsonConcepts, cdm)
  bmiThreshold <- validateBmiThreshold(bmiThreshold)
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)

  id <- omopgenerics::getPersonIdentifier(x)

  nm <- omopgenerics::uniqueTableName()
  ind <- x |>
    dplyr::select(dplyr::any_of(c(id, "index_date" = indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm) |>
    PatientProfiles::addConceptIntersectFlag(
      conceptSet = conceptSet,
      indexDate = "index_date",
      window = window,
      name = nm,
      nameStyle = "{concept_name}"
    ) |>
    PatientProfiles::addAge(
      indexDate = "index_date",
      ageGroup = list("g1"= c(0, 49), "g2" = c(50, 59), "g3" = c(60, 69), "g4" = c(70, 79), "g5" = c(80, Inf)),
      name = nm
    )

  # check ckd measurements
  # TODO

  # complex decisions
  ind <- ind |>
    dplyr::mutate(
      age_group = dplyr::case_when(
        .data$age_group == "g1" ~ 0L,
        .data$age_group == "g2" ~ 1L,
        .data$age_group == "g3" ~ 2L,
        .data$age_group == "g4" ~ 3L,
        .data$age_group == "g5" ~ 4L
      ),
      liver = dplyr::case_when(
        .data$severe_liver_disease == 1L ~ 3L,
        .data$mild_liver_disease == 1L ~ 1L,
        .default = 0L
      ),
      diabetes = dplyr::case_when(
        .data$end_organ_diabetes_mellitus == 1L ~ 2L,
        .data$diabetes_mellitus == 1L ~ 1L,
        .default = 0L
      ),
      tumor = dplyr::case_when(
        .data$metastatic_solid_tumor == 1L ~ 6L,
        .data$localised_solid_tumor == 1L ~ 2L,
        .default = 0L
      ),
      !!nameStyle := .data$age_group + .data$myocardial_infarction +
        .data$congestive_heart_failure + .data$peripheral_vascular_disease +
        .data$cerebrovacular_accident + .data$transient_ischemic_attack +
        .data$dementia + .data$chronic_pulmonary_disease +
        .data$connective_tissue_disease + .data$peptic_ulcer_disease +
        .data$liver + .data$diabetes + 2 * .data$hemiplegia +
        2 * .data$severe_chronic_kidney_disease + .data$tumor +
        2 * .data$leukemia + 2 * .data$lymphoma + 6 * .data$aids
    ) |>
    dplyr::select(dplyr::all_of(c(id, !!indexDate := "index_date", nameStyle))) |>
    dplyr::compute(name = nm)

  # add charlson to x
  x <- x |>
    dplyr::inner_join(ind, by = c(id, indexDate)) |>
    dplyr::compute(name = name)

  # drop intermediate table
  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  return(x)
}

charlsonConcepts <- c(
  "myocardial_infarction", "congestive_heart_failure",
  "peripheral_vascular_disease", "cerebrovacular_accident",
  "transient_ischemic_attack", "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
  "severe_liver_disease", "diabetes_mellitus", "end_organ_diabetes_mellitus",
  "hemiplegia", "estimated_glomerular_filtration_rate",
  "severe_chronic_kidney_disease", "localised_solid_tumor",
  "metastatic_solid_tumor", "leukemia", "lymphoma", "aids"
)
