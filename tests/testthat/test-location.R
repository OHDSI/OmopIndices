test_that("check addLocation", {
  cdm <- omock::mockCdmFromTables(tables = list(
    cohort = dplyr::tibble(
      cohort_definition_id = 1L,
      subject_id = 1:8L,
      cohort_start_date = as.Date("2020-01-01"),
      cohort_end_date = cohort_start_date
    )
  ))

  # location
  location <- dplyr::tibble(
    location_id = 1:4L,
    address_1 = NA_character_,
    address_2 = NA_character_,
    city = NA_character_,
    state = NA_character_,
    zip = NA_character_,
    county = NA_character_,
    location_source_value = c("location1", "zone", "UK", "Catalunya")
  )
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "location", table = location)

  # care site
  careSite <- dplyr::tibble(
    care_site_id = 1:5L,
    care_site_name = NA_character_,
    place_of_service_concept_id = 0L,
    location_id = c(1L, 1L, 4L, 4L, 4L),
    care_site_source_value = NA_character_,
    place_of_service_source_value = NA_character_
  )
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "care_site", table = careSite)

  cdm <- copyCdm(cdm)

  # expect all missing
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addLocation()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("location") |>
      unique(),
    "Missing"
  )

  # add location via location_id
  cdm$person <- cdm$person |>
    dplyr::mutate(location_id = dplyr::case_when(
      person_id %in% 1:4 ~ 2L,
      person_id %in% 5:6 ~ 1L,
      person_id == 7 ~ 7L,
      person_id == 8 ~ 3L
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
