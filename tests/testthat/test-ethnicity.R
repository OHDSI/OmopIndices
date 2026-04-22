test_that("ethnicity works", {
  cdm <- omock::mockCdmFromTables(tables = list(
    cohort = dplyr::tibble(
      cohort_definition_id = 1L,
      subject_id = 1:8L,
      cohort_start_date = as.Date("2020-01-01"),
      cohort_end_date = cohort_start_date
    )
  ))

  # ethnicity
  cdm$person <- cdm$person |>
    dplyr::mutate(
      race_concept_id = NA_integer_,
      race_source_concept_id = NA_integer_,
      race_source_value = NA_character_,
      ethnicity_concept_id = NA_integer_,
      ethnicity_source_concept_id = NA_integer_,
      ethnicity_source_value = NA_character_
    )

  cdm <- copyCdm(cdm)

  # expect all missing
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addEthnicity()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("ethnicity") |>
      unique(),
    "Missing"
  )

  # add ethnicity via ethnicity_source_concept_id
  cdm$person <- cdm$person |>
    dplyr::mutate(location_id = dplyr::case_when(
      person_id %in% 1:4 ~ 8515L,
      person_id %in% 5:6 ~ 8522L,
      person_id == 7 ~ 8527L,
      person_id == 8 ~ 8557L
    ))
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addEthnicity()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("location") |>
      unique(),
    c("zone", "location1", "Missing", "UK")
  )

  # add care_site results should not change
  cdm$person <- cdm$person |>
    dplyr::mutate(care_site_id = dplyr::case_when(
      person_id %in% 1:2 ~ 1L,
      person_id %in% 3:4 ~ 2L,
      person_id %in% 5:6 ~ 3L,
      person_id %in% 7:8 ~ 4L,
      person_id %in% 9:10 ~ 5L
    ))
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addLocation()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("location") |>
      unique(),
    c("zone", "location1", "Missing", "UK")
  )

  # force location via care_site
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addLocation(from = "care_site_id")
  )
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("location") |>
      unique(),
    c("location1", "Catalunya")
  )

  # remove location_id
  cdm$person <- cdm$person |>
    dplyr::mutate(location_id = NA_integer_)
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addLocation()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("location") |>
      unique(),
    c("location1", "Catalunya")
  )

  # expect all missing if no from is supplied
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addLocation(from = character())
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("location") |>
      unique(),
    "Missing"
  )

  dropCreatedTables(cdm = cdm)
})
