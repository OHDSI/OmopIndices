test_that("test addObesity", {
  skip_on_cran()
  cdm <- omock::mockCdmFromDataset("GiBleed")

  cdm$my_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(xx = 40481087),
    name = "my_cohort"
  )

  expect_no_error(
    cdm$my_cohort <- cdm$my_cohort |>
      addObesity()
  )

})
