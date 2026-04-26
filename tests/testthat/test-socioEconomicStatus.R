test_that("test addSocioEconomicStatus", {
  collectCohortSes <- function(x, col) {
    x |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id, .data$cohort_start_date) |>
      dplyr::pull(dplyr::all_of(col))
  }

  cdm <- omock::mockCdmFromTables(tables = list(
    observation_period = dplyr::tibble(
      observation_period_id = 1:5L,
      person_id = 1:5L,
      observation_period_start_date = as.Date("2000-01-01"),
      observation_period_end_date = as.Date("2020-01-01")
    ),
    cohort = dplyr::tibble(
      cohort_definition_id = 1L,
      subject_id = c(1L, 1L, 1L, 2L, 3L, 4L, 5L),
      cohort_start_date = as.Date("2010-01-01") + c(0, 100, 200, 0, 0, 0, 0),
      cohort_end_date = cohort_start_date
    )
  )) |>
    omopgenerics::emptyOmopTable(name = "measurement") |>
    omopgenerics::emptyOmopTable(name = "observation") |>
    copyCdm()

  # no records
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addSocioEconomicStatus()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("socio_economic_status") |>
      unique(),
    "Missing"
  )
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addIndexOfMultipleDeprivation()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("socio_economic_status") |>
      unique(),
    "Missing"
  )
  expect_no_warning(
    cdm$cohort <- cdm$cohort |>
      dplyr::select(!"socio_economic_status") |>
      addTownsend()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("socio_economic_status") |>
      unique(),
    "Missing"
  )

  # add townsend
  meas <- dplyr::tibble(
    measurement_id = c(1:6L),
    person_id = c(1:5L, 1L),
    measurement_date = as.Date("2010-01-01") + c(-50, 50, -50, 50, -50, 50),
    measurement_concept_id = 715996L,
    value_as_number = c(1, 2, 3, 4, 5, 6)
  )
  meas <- dplyr::bind_rows(meas, dplyr::collect(cdm$measurement))
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "measurement", table = meas)
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addSocioEconomicStatus(nameStyle = "ses1")
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses1"),
    c("Q3", "Q3", "Q3", "Q1", "Q2", "Q2", "Q3")
  )
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addIndexOfMultipleDeprivation(nameStyle = "ses2")
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("ses2") |>
      unique(),
    "Missing"
  )
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addTownsend(nameStyle = "ses3")
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses3"),
    c("Q3", "Q3", "Q3", "Q1", "Q2", "Q2", "Q3")
  )

  # window
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addTownsend(
        window = c(0, Inf),
        nameStyle = "ses4",
        missingSocioEconomicStatusValue = "m"
      )
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses4"),
    c("Q3", "m", "m", "Q1", "m", "Q2", "m")
  )
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addTownsend(
        window = c(-Inf, 0),
        nameStyle = "ses5",
        missingSocioEconomicStatusValue = "m"
      )
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses5"),
    c("Q1", "Q3", "Q3", "m", "Q2", "m", "Q3")
  )
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addTownsend(
        window = c(-100, 100),
        nameStyle = "ses6",
        missingSocioEconomicStatusValue = "m"
      )
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses6"),
    c("Q3", "Q3", "m", "Q1", "Q2", "Q2", "Q3")
  )

  # order
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addTownsend(order = "first", nameStyle = "ses7")
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses7"),
    c("Q1", "Q1", "Q1", "Q1", "Q2", "Q2", "Q3")
  )

  # add imd
  obs <- dplyr::tibble(
    observation_id = 1:3L,
    person_id = c(3L, 2L, 5L),
    observation_date = as.Date("2010-01-01") + c(-50, 50, -50),
    observation_concept_id = 35812882L,
    value_as_number = c(1, 2, 3)
  )
  obs <- dplyr::bind_rows(obs, dplyr::collect(cdm$observation))
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "observation", table = obs)
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addIndexOfMultipleDeprivation(nameStyle = "ses8")
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses8"),
    c("Missing", "Missing", "Missing", "Q2", "Q1", "Missing", "Q3")
  )

  # townsed still works
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addTownsend(nameStyle = "ses9")
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses9"),
    collectCohortSes(cdm$cohort, "ses3")
  )

  # order matters
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addSocioEconomicStatus(
        from = c("imd", "townsend"),
        nameStyle = "ses10"
      )
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses10"),
    collectCohortSes(cdm$cohort, "ses8")
  )
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addSocioEconomicStatus(
        from = c("townsend", "imd"),
        nameStyle = "ses11"
      )
  )
  expect_identical(
    collectCohortSes(cdm$cohort, "ses11"),
    collectCohortSes(cdm$cohort, "ses3")
  )

  # empty from
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addSocioEconomicStatus(
        from = character(),
        nameStyle = "ses12"
      )
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("ses12") |>
      unique(),
    "Missing"
  )

  dropCreatedTables(cdm = cdm)
})
