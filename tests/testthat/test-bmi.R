test_that("test BMI index", {
  cdm <- omopgenerics::cdmFromTables(
    tables = list(
      person = dplyr::tibble(
        person_id = c(1L, 2L),
        gender_concept_id = 0L,
        year_of_birth = 1990L,
        race_concept_id = 0L,
        ethnicity_concept_id = 0L
      ),
      observation_period = dplyr::tibble(
        observation_period_id = 1:2L,
        person_id = 1:2L,
        observation_period_start_date = as.Date("2000-01-01"),
        observation_period_end_date = as.Date("2020-01-01"),
        period_type_concept_id = 0L
      ),
      measurement = dplyr::tibble(
        measurement_id = 1:6L,
        person_id = c(1L, 1L, 2L, 2L, 2L, 2L),
        measurement_concept_id = 4245997L,
        measurement_date = as.Date("2000-01-01") + c(-100, 400, 10, 10, 3000, 4000),
        value_as_number = c(20, 25, 22, 21, 20, 30),
        measurement_type_concept_id = 0L
      ),
      concept = dplyr::tibble(
        concept_id = 4245997L,
        concept_name = "Body mass index",
        domain_id = "Measurement",
        vocabulary_id = "SNOMED",
        concept_class_id = "Observable Entity",
        standard_concept = "S",
        concept_code = "60621009",
        valid_start_date = as.Date("2002-01-31"),
        valid_end_date = as.Date("2099-12-31"),
        invalid_reason = NA_character_
      )
    ),
    cdmName = "test",
    cohortTables = list(
      cohort1 = dplyr::tibble(
        cohort_definition_id = 1L,
        subject_id = c(1L, 2L, 2L),
        cohort_start_date = as.Date("2000-01-01") + c(100, 5, 5000),
        cohort_end_date = cohort_start_date,
        extra_column = "a"
      )
    )
  ) |>
    copyCdm()

  bmi <- list(bmi = 4245997L)

  expect_no_error(
    cdm$cohort1 |>
      addBMI(conceptSet = bmi)
  )

  dropCreatedTables(cdm = cdm)
})
