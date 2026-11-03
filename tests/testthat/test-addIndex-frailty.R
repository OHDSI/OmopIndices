test_that("hospital frailty risk score uses addIndex", {
  cdm <- omock::mockCdmFromDataset() |>
    omock::mockCohort()

  expect_warning(
    result <- cdm$cohort |>
      addHospitalFrailtyRiskScore(),
    "unique codelist concept IDs are not present"
  )
  expect_true("hfrs" %in% names(result))

  CDMConnector::cdmDisconnect(cdm)
})

test_that("electronic frailty index 2 uses addIndex", {
  cdm <- omock::mockCdmFromDataset() |>
    omock::mockCohort()
  conceptSet <- getIndexCodelist("electronic_frailty_index_2")
  missing <- setdiff(
    getNeededConcepts(indexDefinitions$electronic_frailty_index_2),
    names(conceptSet)
  )
  conceptSet[missing] <- 0L

  expect_warning(
    result <- cdm$cohort |>
      addElectronicFrailtyIndex2(conceptSet = conceptSet),
    "unique codelist concept IDs are not present"
  )
  expect_true("efi2" %in% names(result))

  CDMConnector::cdmDisconnect(cdm)
})
