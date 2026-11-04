test_that("addBMI selects and categorises BMI measurements", {
  bmi_concept_ids <- c(
    607520L, 3038553L, 4087497L, 4245997L, 37398925L,
    44783982L, 44807883L, 44809197L, 44809198L
  )

  cdm <- omopgenerics::cdmFromTables(
    tables = list(
      person = dplyr::tibble(
        person_id = 1:3,
        gender_concept_id = 0L,
        year_of_birth = 1990L,
        race_concept_id = 0L,
        ethnicity_concept_id = 0L
      ),
      observation_period = dplyr::tibble(
        observation_period_id = 1:3,
        person_id = 1:3,
        observation_period_start_date = as.Date("2000-01-01"),
        observation_period_end_date = as.Date("2020-01-01"),
        period_type_concept_id = 0L
      ),
      measurement = dplyr::tibble(
        measurement_id = 1:4,
        person_id = c(1L, 1L, 1L, 2L),
        measurement_concept_id = 4245997L,
        measurement_date = as.Date("2000-01-01") + c(1, 10, 20, -1),
        value_as_number = c(30, 20, 25, 27),
        measurement_type_concept_id = 0L
      ),
      concept = dplyr::tibble(
        concept_id = bmi_concept_ids,
        concept_name = rep("Body mass index", length(bmi_concept_ids)),
        domain_id = rep("Measurement", length(bmi_concept_ids)),
        vocabulary_id = rep("SNOMED", length(bmi_concept_ids)),
        concept_class_id = rep("Observable Entity", length(bmi_concept_ids)),
        standard_concept = rep("S", length(bmi_concept_ids)),
        concept_code = rep("60621009", length(bmi_concept_ids)),
        valid_start_date = rep(as.Date("2002-01-31"), length(bmi_concept_ids)),
        valid_end_date = rep(as.Date("2099-12-31"), length(bmi_concept_ids)),
        invalid_reason = rep(NA_character_, length(bmi_concept_ids))
      )
    ),
    cdmName = "test",
    cohortTables = list(
      cohort1 = dplyr::tibble(
        cohort_definition_id = 1L,
        subject_id = 1:3,
        cohort_start_date = as.Date("2000-01-01") + 20,
        cohort_end_date = cohort_start_date
      )
    )
  ) |>
    copyCdm()
  on.exit(dropCreatedTables(cdm = cdm), add = TRUE)

  bmi <- list(bmi = 4245997L)
  collect_bmi <- function(x, variable) {
    x |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull(dplyr::all_of(variable))
  }

  # The default uses the internal BMI codelist.
  cdm$cohort_bmi_default <- cdm$cohort1 |>
    addBMI(nameStyle = "bmi_default", name = "cohort_bmi_default")
  expect_equal(
    collect_bmi(cdm$cohort_bmi_default, "bmi_default"),
    c(25, NA_real_, NA_real_)
  )

  # A custom concept set is also accepted.
  cdm$cohort_bmi_custom <- cdm$cohort1 |>
    addBMI(conceptSet = bmi, nameStyle = "bmi_custom", name = "cohort_bmi_custom")
  expect_equal(
    collect_bmi(cdm$cohort_bmi_custom, "bmi_custom"),
    c(25, NA_real_, NA_real_)
  )

  cdm$cohort_bmi_lookback <- cdm$cohort1 |>
    addBMI(
      conceptSet = bmi,
      lookbackDays = 5,
      nameStyle = "bmi_lookback",
      name = "cohort_bmi_lookback"
    )
  expect_equal(
    collect_bmi(cdm$cohort_bmi_lookback, "bmi_lookback"),
    c(25, NA_real_, NA_real_)
  )

  cdm$cohort_bmi_today <- cdm$cohort1 |>
    addBMI(conceptSet = bmi, lookbackDays = 0, name = "cohort_bmi_today")
  expect_equal(
    collect_bmi(cdm$cohort_bmi_today, "bmi"),
    c(25, NA_real_, NA_real_)
  )
  expect_error(addBMI(cdm$cohort1, lookbackDays = -1), "lookbackDays")

  cdm$cohort_bmi_outside_observation <- cdm$cohort1 |>
    addBMI(
      conceptSet = bmi,
      inObservation = FALSE,
      nameStyle = "bmi_outside_observation",
      name = "cohort_bmi_outside_observation"
    )
  expect_equal(
    collect_bmi(
      cdm$cohort_bmi_outside_observation,
      "bmi_outside_observation"
    ),
    c(25, 27, NA_real_)
  )

  cdm$cohort_bmi_categories <- cdm$cohort1 |>
    addBMI(
      conceptSet = bmi,
      categories = list(
        underweight = c(0, 18.5),
        normal = c(18.5, 24.9),
        overweight = c(25, 29.9),
        obese = c(30, Inf)
      ),
      name = "cohort_bmi_categories"
    )
  expect_equal(
    collect_bmi(cdm$cohort_bmi_categories, "bmi"),
    c(25, NA_real_, NA_real_)
  )
  expect_equal(
    collect_bmi(cdm$cohort_bmi_categories, "bmi_categories"),
    c("overweight", "missing", "missing")
  )

  # If multiple records fall on the selected day, addBMI keeps the
  # maximum value so the result remains one row per person and index date.
  cdm$measurement <- cdm$measurement |>
    dplyr::mutate(
      measurement_date = dplyr::if_else(
        .data$measurement_id == 2L,
        as.Date("2000-01-21"),
        .data$measurement_date
      ),
      value_as_number = dplyr::if_else(
        .data$measurement_id == 2L,
        26,
        .data$value_as_number
      )
    )
  cdm$cohort_bmi_same_day <- cdm$cohort1 |>
    addBMI(
      conceptSet = bmi,
      nameStyle = "bmi_same_day",
      name = "cohort_bmi_same_day"
    )
  expect_equal(
    collect_bmi(cdm$cohort_bmi_same_day, "bmi_same_day"),
    c(26, NA_real_, NA_real_)
  )
})
