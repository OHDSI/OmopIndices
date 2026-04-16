test_that("check addLocation", {
  cdm <- omock::mockPerson() |>
    omock::mockObservationPeriod() |>
    omock::mockCohort()

  # location
  location <- dplyr::tibble(

  )
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "location", table = location)

  # care site
  careSite <- dplyr::tibble(

  )
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "care_site", table = careSite)

  cdm <- copyCdm(cdm)

  dropCreatedTables(cdm = cdm)
})
