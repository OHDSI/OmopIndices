test_that("check it works", {
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
    "condition_start_date" = c(as.Date("2015-01-01"), rep(as.Date("2020-01-01"), 21)),
    "condition_end_date" = c(as.Date("2015-01-01"), rep(as.Date("2020-01-01"), 21)),
    "condition_type_concept_id" = NA_integer_)

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
                                     "cdmName" = "mock")

  categories <- list("low" = c(0,2),
                     "moderate" = c(3, 5),
                     "high" = c(5, Inf))

  cdm[["new_cohort"]] <- updatedCharlsonCohort(cdm = cdm,
                                               categories = categories,
                                               name = "new_cohort", ageAdjusted = FALSE,
                                               conceptSet = conceptSet)

  expect_identical(cdm[["new_cohort"]] |>
                     settings() |>
                     dplyr::pull("cohort_name"),
                   names(categories))

  expect_true(cdm[["new_cohort"]] |>
    dplyr::filter(subject_id == 1L) |>
    nrow() == 2)

  expect_equal(
    cdm[["new_cohort"]] |>
      dplyr::filter(subject_id == 1L) |>
      dplyr::collect() |>
      dplyr::select("cohort_start_date", "cohort_end_date") |>
      unlist(use.names = FALSE) |>
      as.Date(origin = "1970-01-01"),
    as.Date(c("2001-01-01", "2020-01-01", "2019-12-31", "2025-01-01"))
  )

  # edge case (change groups on 2020-12-21, 2020-12-22, 2020-12-23) ----
  categories <- list("low" = c(0,0),
                     "moderate" = c(1, 2),
                     "high" = c(3, Inf))
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
    "condition_start_date" = c(as.Date("2020-12-21"), as.Date("2020-12-22"), as.Date("2020-12-23"), rep(as.Date("2020-01-01"), 19)),
    "condition_end_date" = c(as.Date("2020-12-21"), as.Date("2020-12-22"), as.Date("2020-12-23"), rep(as.Date("2020-01-01"), 19)),
    "condition_type_concept_id" = NA_integer_)
  cdm <- omopgenerics::cdmFromTables("tables" = list("person" = person,
                                                     "observation_period" = observation_period,
                                                     "condition_occurrence" = condition_occurrence,
                                                     "concept" = concept),
                                     "cohort" = list("cohort" = cohort),
                                     "cdmName" = "mock")

  cdm[["new_cohort"]] <- updatedCharlsonCohort(cdm = cdm,
                                           categories = categories,
                                           name = "new_cohort",
                                           ageAdjusted = FALSE,
                                           conceptSet = conceptSet)

  expect_equal(
    cdm[["new_cohort"]] |>
      dplyr::filter(subject_id == 1L) |>
      dplyr::collect() |>
      dplyr::arrange(cohort_definition_id) |>
      dplyr::pull("cohort_start_date"),
    as.Date(c("2001-01-01", "2020-12-21", "2020-12-22"))
  )

  expect_equal(
    cdm[["new_cohort"]] |>
      dplyr::filter(subject_id == 1L) |>
      dplyr::collect() |>
      dplyr::arrange(cohort_definition_id) |>
      dplyr::pull("cohort_end_date"),
    as.Date(c("2020-12-20", "2020-12-21", "2025-01-01"))
  )

})
