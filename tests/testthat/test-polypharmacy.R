
test_that("polypharmacy returns zeros for empty drug eras and rejects multiple windows", {
  cdm <- omock::mockCdmReference(vocabularySet = "GiBleed") |>
    omock::mockCdmFromTables(tables = list(
      drug_era = dplyr::tibble(
        drug_era_start_date = as.Date("2000-01-01") + c(0, 100, 60, 111, 0, 100, 60, 110),
        drug_era_end_date = as.Date("2000-01-01") + c(80, 120, 110, 130, 80, 120, 110, 130),
        drug_concept_id = c(1557272L, 1557272L, 708298L, 701322L, 1557272L, 1557272L, 708298L, 701322L),
        person_id = c(rep(1L, 4), rep(2L, 4)),
        drug_era_id = 1:8L,
        drug_exposure_count = c(1L, 2L, 3L, 2L, 1L, 1L, 3L, 3L),
        gap_days = 0L
      )
    )) |>
    copyCdm()
  on.exit(dropCreatedTables(cdm = cdm), add = TRUE)

  cdm <- omopgenerics::insertTable(
    cdm = cdm,
    name = "toy_table",
    table = dplyr::tibble(
      person_id = c(1L, 2L),
      my_date = as.Date(c("2000-01-31", "2000-01-31"))
    )
  )

  cdm <- omopgenerics::insertTable(
    cdm = cdm,
    name = "my_cohort",
    table = dplyr::tibble(
      cohort_definition_id = 1L,
      subject_id = c(1L, 2L),
      cohort_start_date = as.Date(c("2000-01-31", "2000-01-31")),
      cohort_end_date = cohort_start_date
    )
  )
  cdm$my_cohort <- cdm$my_cohort |>
    omopgenerics::newCohortTable()

  expect_no_error(
    cdm$my_cohort2 <- cdm$my_cohort |>
      addPolypharmacy(
        indexDate = "cohort_start_date",
        window = c(0, 0),
        nameStyle = "count",
        name = "my_cohort2"
      )
  )
  expect_identical(tableName(cdm$my_cohort2), "my_cohort2")
  expect_true("count" %in% colnames(cdm$my_cohort2))
  expect_identical(
    cdm$my_cohort2 |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("count"),
    c(1L, 1L)
  )

  cdm$my_cohort_categories <- cdm$my_cohort |>
    addPolypharmacy(
      categories = list(
        low = c(0, 1),
        high = c(2, Inf)
      ),
      name = "my_cohort_categories"
    )
  expect_identical(
    cdm$my_cohort_categories |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("polypharmacy"),
    c(1L, 1L)
  )
  expect_identical(
    cdm$my_cohort_categories |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("polypharmacy_categories"),
    c("low", "low")
  )

  expect_warning(
    cdm$my_cohort2 <- cdm$my_cohort2 |>
      addPolypharmacy(
        indexDate = "cohort_start_date",
        window = c(0, 79),
        nameStyle = "count",
        name = "my_cohort2"
      )
  )
  expect_identical(
    cdm$my_cohort2 |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("count"),
    c(2L, 2L)
  )

  expect_no_error(
    cdm$toy_table <- cdm$toy_table |>
      addPolypharmacy(
        indexDate = "my_date",
        window = c(0, 80),
        nameStyle = "count"
      )
  )
  expect_identical(
    cdm$toy_table |>
      dplyr::collect() |>
      dplyr::arrange(.data$person_id) |>
      dplyr::pull("count"),
    c(2L, 3L)
  )

  expect_no_error(
    cdm$toy_table <- cdm$toy_table |>
      addPolypharmacy(
        indexDate = "my_date",
        window = c(60, 130),
        overlap = FALSE,
        nameStyle = "count_no_overlap"
      )
  )
  expect_identical(
    cdm$toy_table |>
      dplyr::collect() |>
      dplyr::arrange(.data$person_id) |>
      dplyr::pull("count_no_overlap"),
    c(3L, 3L)
  )

  expect_no_error(
    cdm$toy_table <- cdm$toy_table |>
      addPolypharmacy(
        indexDate = "my_date",
        window = c(-Inf, 0),
        overlap = FALSE,
        nameStyle = "count_left_open"
      )
  )
  expect_identical(
    cdm$toy_table |>
      dplyr::collect() |>
      dplyr::arrange(.data$person_id) |>
      dplyr::pull("count_left_open"),
    c(1L, 1L)
  )

  expect_no_error(
    cdm$toy_table <- cdm$toy_table |>
      addPolypharmacy(
        indexDate = "my_date",
        window = c(0, Inf),
        nameStyle = "count_right_open"
      )
  )
  expect_identical(
    cdm$toy_table |>
      dplyr::collect() |>
      dplyr::arrange(.data$person_id) |>
      dplyr::pull("count_right_open"),
    c(2L, 3L)
  )

  expect_no_error(
    cdm$toy_table <- cdm$toy_table |>
      addPolypharmacy(
        indexDate = "my_date",
        window = c(-Inf, Inf),
        nameStyle = "count_unbounded"
      )
  )
  expect_identical(
    cdm$toy_table |>
      dplyr::collect() |>
      dplyr::arrange(.data$person_id) |>
      dplyr::pull("count_unbounded"),
    c(2L, 3L)
  )

  expect_error(
    addPolypharmacy(cdm$my_cohort, window = list(c(0, 0), c(0, 90))),
    "Only one window is allowed"
  )

  # empty drug era
  cdm$drug_era <- cdm$drug_era |>
    dplyr::filter(.data$person_id == 0)
  expect_warning(
    result <- cdm$my_cohort |>
      addPolypharmacy(),
    "table is empty"
  )
  expect_true("my_cohort" %in% tableName(result))
  expect_warning(
    result <- result |>
      dplyr::compute() |>
      addPolypharmacy()
  )
  expect_true(is.na(tableName(result)))

  dropCreatedTables(cdm = cdm)
})
