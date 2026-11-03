test_that("measurement definitions select and score eligible records", {
  start <- as.Date("2000-01-01")
  cdm <- omopgenerics::cdmFromTables(
    tables = list(
      person = dplyr::tibble(
        person_id = 1:9, gender_concept_id = 0L, year_of_birth = 1990L,
        race_concept_id = 0L, ethnicity_concept_id = 0L
      ),
      observation_period = dplyr::tibble(
        observation_period_id = 1:9, person_id = 1:9,
        observation_period_start_date = start - 10,
        observation_period_end_date = start + 100,
        period_type_concept_id = 0L
      ),
      measurement = dplyr::tibble(
        measurement_id = 1:11,
        person_id = c(1L, 1L, 2L, 2L, 3L, 4L, 5L, 5L, 6L, 7L, 8L),
        measurement_concept_id = 1L,
        measurement_date = start + c(0, 9, 5, 9, 10, 9, 9, 9, -1, 2, 11),
        value_as_number = c(20, 100, 30, 10, 25, 18.5, 22, 28, 30, 20, 30),
        value_as_concept_id = c(100L, 200L, 200L, 200L, 200L, 100L,
                                100L, 200L, 200L, 100L, 200L),
        unit_concept_id = c(1L, 2L, rep(1L, 9)),
        measurement_type_concept_id = 0L
      ),
      observation = dplyr::tibble(
        observation_id = 1L, person_id = 7L, observation_concept_id = 2L,
        observation_date = start + 10, value_as_number = 27,
        value_as_concept_id = 200L, unit_concept_id = 1L,
        observation_type_concept_id = 0L
      ),
      concept = dplyr::tibble(
        concept_id = c(1L, 2L, 100L, 200L),
        concept_name = c("Measurement", "Observation", "Normal", "Raised"),
        domain_id = c("Measurement", "Observation", "Meas Value", "Meas Value"),
        vocabulary_id = "SNOMED", concept_class_id = "Clinical Finding",
        standard_concept = "S", concept_code = as.character(concept_id),
        valid_start_date = start - 100, valid_end_date = start + 100,
        invalid_reason = NA_character_
      )
    ),
    cohortTables = list(cohort = dplyr::tibble(
      cohort_definition_id = 1L, subject_id = 1:9,
      cohort_start_date = start + 10, cohort_end_date = start + 10
    )),
    cdmName = "measurement_test"
  ) |>
    copyCdm()
  on.exit(dropCreatedTables(cdm), add = TRUE)
  originalTables <- omopgenerics::listSourceTables(cdm)

  conceptSet <- list(measure = c(1L, 2L), normal = 100L, raised = 200L)
  definition <- list(list(
    type = "measurement", concept_set = "measure", follow_up = 10,
    measurement_groups = list(
      list(label = "normal", measurement_value = c(18.5, 25),
           lower_inclusive = FALSE, upper_inclusive = FALSE,
           measurement_unit = 1L, score = 1),
      list(label = "raised", measurement_value = c(25, Inf),
           measurement_unit = 1L, score = 2)
    )
  ))
  scores <- function(definition) {
    addIndex(cdm$cohort, definition, "cohort_start_date", NULL, conceptSet,
             NULL, "score", "measurement_score") |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("score")
  }

  # Reject invalid units before choosing the latest date; retain unmatched values
  # as zero. Both lookback endpoints count, but expired/future records do not.
  expect_equal(scores(definition), c(1, 0, 2, 0, 2, 0, 2, 0, 0))
  definition[[1]]$tie <- "min"
  expect_equal(scores(definition), c(1, 0, 2, 0, 1, 0, 2, 0, 0))

  # Without a unit restriction, person 1's more recent value is eligible.
  definition[[1]]$measurement_groups <- purrr::map(
    definition[[1]]$measurement_groups,
    \(band) { band$measurement_unit <- NULL; band }
  )
  expect_equal(scores(definition), c(2, 0, 2, 0, 1, 0, 2, 0, 0))

  definition[[1]]$tie <- list("normal", "raised")
  definition[[1]]$measurement_groups <- list(
    list(label = "normal", measurement_concept = "normal", measurement_unit = 1L, score = 1),
    list(label = "raised", measurement_concept = "raised", measurement_unit = 1L, score = 2)
  )
  expect_equal(scores(definition), c(1, 2, 2, 1, 1, 0, 2, 0, 0))

  # A band specifying both constraints requires both to match.
  definition[[1]]$measurement_groups[[2]]$measurement_value <- c(25, Inf)
  expect_equal(scores(definition), c(1, 0, 2, 1, 1, 0, 2, 0, 0))

  # Source concepts with no measurement/observation domain give missing raw values.
  definition <- list(list(
    type = "measurement", concept_set = "normal", follow_up = Inf, score = "value"
  ))
  expect_equal(scores(definition), rep(NA_real_, 9))

  addedTables <- setdiff(omopgenerics::listSourceTables(cdm), originalTables)
  expect_true(all(grepl("measurement_score$", addedTables)))
})
