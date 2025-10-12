test_that("multiplication works", {
  cdm <- omock::mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

  cdm$my_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(my_codelist = 40481087L),
    name = "my_cohort"
  )

  expect_no_error(x <- addPolypharmacyCount(cdm$my_cohort))
})
