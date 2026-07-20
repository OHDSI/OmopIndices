test_that("updated CCI works", {

  conceptSet <- list(
    "congestive_heart_failure" = 81151L,
    "dementia" = 4182210L,
    "chronic_pulmonary_disease" = 255573L,
    "connective_tissue_disease" = 4134537L,
    "mild_liver_disease" = 194984L,
    "moderate_or_severe_liver_disease" = 4212540L,
    "diabetes_with_complication" = 40481087L,
    "hemiplegia" = 374022L,
    "severe_chronic_kidney_disease" = 46271022L,
    "any_malignancy" = 80180L,
    "metastatic_solid_tumor" = 28060L,
    "aids" = 4267414L)

  person <- dplyr::tibble(
    "person_id" = c(1L, 2L, 3L, 4L),
    "gender_concept_id" = rep(8532L, 4),
    "year_of_birth" = c(1963L, 1973L, 1993L, 2000L),
    "month_of_birth" = rep(1L, 4),
    "day_of_birth" = rep(1L, 4),
    "race_concept_id" = NA_integer_,
    "ethnicity_concept_id" = NA_integer_
  )

  condition_occurrence <- dplyr::tibble(
    "condition_occurrence_id" = seq(1L, 22L, 1L),
    "person_id" = c(rep(1L, 3), rep(2L, 12), rep(3L, 6), rep(4L, 1)),
    "condition_concept_id" = c(unlist(conceptSet[c("chronic_pulmonary_disease",
                                                   "congestive_heart_failure",
                                                   "dementia")]),
                               unlist(conceptSet),
                               unlist(conceptSet[c("diabetes_with_complication",
                                                   "any_malignancy",
                                                   "metastatic_solid_tumor",
                                                   "mild_liver_disease",
                                                   "moderate_or_severe_liver_disease",
                                                   "hemiplegia")]),
                               unlist(conceptSet[c("aids")])),
    "condition_start_date" = rep(as.Date("2020-01-01"), 22),
    "condition_end_date" = rep(as.Date("2020-01-01"), 22),
    "condition_type_concept_id" = NA_integer_)

  cohort <- dplyr::tibble(
    "cohort_definition_id" = rep(1L, 4),
    "subject_id" = c(1L, 2L, 3L, 4L),
    "cohort_start_date" = c(rep(as.Date("2024-01-01"), 3), as.Date("2019-01-01")),
    "cohort_end_date" = c(rep(as.Date("2024-01-01"), 3), as.Date("2019-01-01"))
  )

  observation_period = dplyr::tibble(
    "observation_period_id" = c(1L, 2L, 3L, 4L),
    "person_id" = c(1L, 2L, 3L, 4L),
    "observation_period_start_date" = rep(as.Date("2001-01-01"),4),
    "observation_period_end_date" = rep(as.Date("2025-01-01"),4),
    "period_type_concept_id" = NA_integer_
  )

  concept <- dplyr::tibble(
    "concept_id" = unlist(conceptSet),
    "concept_name" = names(conceptSet),
    "domain_id" = "Condition",
    "vocabulary_id" = "SNOMED",
    "concept_class_id" = "Clinical Finding",
    "standard_concept" = "S",
    "concept_code" = NA_character_,
    "valid_start_date" = as.Date("1950-01-01"),
    "valid_end_date" = as.Date("2099-01-01")
  )

  cdm <- omopgenerics::cdmFromTables("tables" = list("person" = person,
                                                     "observation_period" = observation_period,
                                                     "condition_occurrence" = condition_occurrence,
                                                     "concept" = concept),
                                     "cohort" = list("cohort" = cohort),
                                     cdmName = "mock")


  expect_no_error(cdm[["cohort"]] <- cdm[["cohort"]] |>
                    addUpdatedCharlsonIndex(indexDate = "cohort_start_date",
                                            ageAdjusted = FALSE,
                                            window = c(-Inf, 0),
                                            conceptSet = conceptSet,
                                            nameStyle = "cci",
                                            categories = NULL))

  expect_identical(cdm[["cohort"]] |>
                     dplyr::pull("cci"),
                   c(5, 24, 13, 0))

  expect_no_error(cdm[["cohort"]] <- cdm[["cohort"]] |>
                    addUpdatedCharlsonIndex(indexDate = "cohort_start_date",
                                            ageAdjusted = TRUE,
                                            window = c(-Inf, 0),
                                            conceptSet = conceptSet,
                                            nameStyle = "cci_aa",
                                            categories = NULL))

  expect_identical(cdm[["cohort"]] |>
                     dplyr::pull("cci_aa"),
                   c(7, 25, 13, 0))

  expect_no_error(cdm[["cohort"]] <- cdm[["cohort"]] |>
                    addUpdatedCharlsonIndex(indexDate = "cohort_start_date",
                                            ageAdjusted = FALSE,
                                            window = c(0, Inf),
                                            conceptSet = conceptSet,
                                            nameStyle = "cci_w",
                                            categories = NULL))
  expect_identical(cdm[["cohort"]] |>
                     dplyr::pull("cci_w"),
                   c(0, 0, 0, 4))

  CDMConnector::cdmDisconnect(cdm)
})
