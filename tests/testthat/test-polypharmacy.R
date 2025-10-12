test_that("polypharmacy works", {
  cdm <- omock::mockCdmFromDataset(datasetName = "GiBleed", source = "local") |>
    copyCdm()

  cdm$my_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(my_codelist = 40481087L),
    name = "my_cohort"
  )

  expect_no_error(x <- addPolypharmacyCount(cdm$my_cohort))
  expect_warning(x <- addPolypharmacyCount(x))
  expect_error(addPolypharmacyCount(cdm$my_cohort, window = list(c(0, 0), c(0, 90))))

  cdm$drug_era <- cdm$drug_era |>
    dplyr::filter(.data$drug_concept_id == 0L)

  expect_warning(x <- addPolypharmacyCount(cdm$my_cohort))
  expect_warning(x <- addPolypharmacyCount(x))

  dropCreatedTables(cdm = cdm)
})
