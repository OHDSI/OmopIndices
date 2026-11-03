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

  cohort <- dplyr::tibble(
    "cohort_definition_id" = rep(1L, 2),
    "subject_id" = c(1L, 2L),
    "cohort_start_date" = c(rep(as.Date("2024-01-01"), 1), as.Date("2019-01-01")),
    "cohort_end_date" = c(rep(as.Date("2024-01-01"), 1), as.Date("2019-01-01"))
  )

  # Subset to a cohort functionality ----
  cdm <- omopgenerics::cdmFromTables("tables" = list("person" = person,
                                                     "observation_period" = observation_period,
                                                     "condition_occurrence" = condition_occurrence,
                                                     "concept" = concept),
                                     "cohortTables" = list("cohort" = cohort),
                                     "cdmName" = "mock")

  cdm[["new_cohort"]] <- updatedCharlsonCohort(cdm = cdm,
                                               categories = categories,
                                               name = "new_cohort",
                                               ageAdjusted = FALSE,
                                               subsetCohort = "cohort",
                                               conceptSet = conceptSet)

  expect_identical(cdm[["new_cohort"]] |>
                     dplyr::distinct(subject_id) |>
                     dplyr::pull("subject_id"),
                   c(1L, 2L))

})

test_that("polypharmacy cohort intervals stay within observation periods", {
  start <- as.Date("2000-01-01")
  cdm <- omopgenerics::cdmFromTables(
    tables = list(
      person = dplyr::tibble(
        person_id = 1:5, gender_concept_id = 0L, year_of_birth = 1970L,
        race_concept_id = 0L, ethnicity_concept_id = 0L
      ),
      observation_period = dplyr::tibble(
        observation_period_id = 1:6, person_id = c(1L, 2L, 2L, 3L, 4L, 5L),
        observation_period_start_date = start + c(0, 0, 20, 0, 0, 0),
        observation_period_end_date = start + c(10, 10, 30, 10, 10, 10),
        period_type_concept_id = 0L
      ),
      drug_era = dplyr::tibble(
        drug_era_id = 1:20, person_id = rep(1:4, each = 5),
        drug_concept_id = rep(1:5, times = 4),
        drug_era_start_date = start + rep(c(5, -5, 20, -370), each = 5),
        drug_era_end_date = start + rep(c(7, 3, 25, -366), each = 5),
        drug_exposure_count = 1L, gap_days = 0L
      )
    ),
    cdmName = "polypharmacy_observation"
  ) |>
    copyCdm()
  on.exit(dropCreatedTables(cdm), add = TRUE)

  # Use the eFI polypharmacy definition, including its 365-day follow-up.
  definition <- purrr::keep(
    indexDefinitions$electronic_frailty_index, \(x) x$type == "polypharmacy"
  )
  expected <- dplyr::tibble(
    subject_id = c(1L, 1L, 2L, 2L, 3L, 4L, 5L),
    cohort_definition_id = c(1L, 2L, 2L, 2L, 1L, 1L, 1L),
    cohort_start_date = start + c(0, 5, 0, 20, 0, 0, 0),
    cohort_end_date = start + c(4, 10, 10, 30, 10, 10, 10)
  )

  for (overlap in c(TRUE, FALSE)) {
    definition[[1]]$overlap <- overlap
    result <- indexCohort(
      cdm = cdm, definition = definition,
      categories = list(none = c(0, 0), polypharmacy = c(0.01, 1)),
      name = "polypharmacy_cohort", conceptSet = list(),
      subsetCohort = NULL, subsetCohortId = NULL
    ) |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id, .data$cohort_start_date) |>
      dplyr::select(dplyr::all_of(names(expected)))

    for (column in names(expected)) {
      expect_equal(result[[column]], expected[[column]])
    }
  }
})
