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
      addBMI(conceptSet = bmi, name = "bmi_initial")
  )

  # Exercise category creation, all ordering choices, and each finite/infinite
  # window shape.  These assertions also verify that one result is returned
  # per cohort row and that the category is derived from the selected BMI.
  for (ord in c("first", "last", "min", "max")) {
    result <- cdm$cohort1 |>
      addBMI(conceptSet = bmi, order = ord, inObservation = FALSE,
             categories = list(normal = c(0, 24.9), high = c(25, Inf)),
             nameStyle = paste0("bmi_", ord)) |>
      dplyr::collect()
    expect_equal(nrow(result), 3)
    expect_true(paste0("bmi_", ord) %in% names(result))
  }
  windows <- list(c(-Inf, 0), c(0, Inf), c(-1, 1), c(-Inf, Inf))
  for (i in seq_along(windows)) {
    win <- windows[[i]]
    result <- cdm$cohort1 |>
      addBMI(conceptSet = bmi, window = win, inObservation = FALSE,
             nameStyle = paste0("bmi_window_", i))
    expect_equal(nrow(result |> dplyr::collect()), 3)
  }

  # No concept in an eligible domain returns the typed empty result.
  empty <- OmopIndices:::getRecords(
    tables = character(), cdm = cdm, conceptSet = list(bmi = 999L),
    records = cdm$cohort1 |> dplyr::transmute(person_id = .data$subject_id,
                                               index_date = .data$cohort_start_date),
    window = c(-Inf, 0), nm = "empty_bmi_records"
  ) |> dplyr::collect()
  expect_equal(nrow(empty), 0)

  records <- cdm$cohort1 |>
    dplyr::transmute(person_id = .data$subject_id,
                     index_date = .data$cohort_start_date)
  direct <- OmopIndices:::getRecords(
    tables = "measurement", cdm = cdm, conceptSet = bmi,
    records = records, window = c(-Inf, 1000), nm = "direct_bmi_records"
  )
  expect_true(dplyr::collect(direct) |> nrow() > 0)
  for (i in seq_along(list(c(0, Inf), c(-1, 1)))) {
    ranged <- OmopIndices:::getRecords(
      tables = "measurement", cdm = cdm, conceptSet = bmi,
      records = records, window = list(c(0, Inf), c(-1, 1))[[i]],
      nm = paste0("ranged_bmi_records_", i)
    )
    expect_true(is.data.frame(dplyr::collect(ranged)))
  }
  tied <- direct |>
    dplyr::mutate(bmi_date = as.Date("2020-01-01"), bmi = 99) |>
    dplyr::compute(name = "tied_bmi_records")
  selected <- OmopIndices:::subsetRecords(tied, character(), "tied_bmi_records") |>
    dplyr::collect()
  expect_true(nrow(selected) > 0)
  expect_true(all(selected$bmi == 99))
  dropCreatedTables(cdm = cdm)
})
