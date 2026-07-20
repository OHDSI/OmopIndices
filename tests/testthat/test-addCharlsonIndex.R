test_that("CCI works", {
  cdm <- omock::mockCdmFromDataset(datasetName = "GiBleed")
  cdm <- cdm |>
    omock::mockCohort(seed = 1)

  conceptSet <- list(
    "myocardial_infarction" = 134438L,
    "congestive_heart_failure" = 81151L,
    "peripheral_vascular_disease" = 321052L,
    "cerebrovascular_disease" = 381591L,
    "dementia" = 4182210L,
    "chronic_pulmonary_disease" = 255573L,
    "connective_tissue_disease" = 4134537L,
    "peptic_ulcer_disease" = 4027663L,
    "mild_liver_disease" = 194984L,
    "moderate_or_severe_liver_disease" = 4212540L,
    "diabetes_without_complication" = 28060L,
    "diabetes_with_complication" = 40481087L,
    "hemiplegia" = 374022L,
    "severe_chronic_kidney_disease" = 46271022L,
    "any_malignancy" = 80180L,
    "metastatic_solid_tumor" = 28060L,
    "aids" = 4267414L)

  expect_no_error(cdm[["cohort"]] <- cdm[["cohort"]] |>
                    addCharlsonIndex(indexDate = "cohort_start_date",
                                     ageAdjusted = FALSE,
                                     window = c(-Inf, 0),
                                     conceptSet = conceptSet,
                                     nameStyle = "cci",
                                     categories = NULL))

  cdm[["cohort"]] <- cdm[["cohort"]] |>
    PatientProfiles::addConceptIntersectFlag(conceptSet = conceptSet,
                                             nameStyle = "com_sum_{concept_name}",
                                             window = c(-Inf, 0))  |>
    dplyr::mutate("total_val" = rowSums(dplyr::across(dplyr::starts_with("com_sum_")), na.rm = TRUE)) |>
    PatientProfiles::addAge() |>
    dplyr::compute(temporary = FALSE, name = "cohort")

  expect_identical(cdm[["cohort"]] |>
                     dplyr::filter(subject_id == 1 & cohort_start_date == as.Date("1980-09-25")) |>
                     dplyr::pull("cci"), 10)

  expect_identical(cdm[["cohort"]] |>
                     dplyr::filter(subject_id == 6) |>
                     dplyr::pull("cci"), 5)

  expect_identical(cdm[["cohort"]] |>
                     dplyr::filter(subject_id == 160) |>
                     dplyr::pull("cci"), 9)


  CDMConnector::cdmDisconnect(cdm)
})
