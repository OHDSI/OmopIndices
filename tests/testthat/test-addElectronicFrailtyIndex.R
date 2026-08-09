test_that("efi works", {

  conceptSet <- list(
    "activity_limitation" = 763723L,
    "anemia" = 439777L,
    "arthritis" = 4291025L,
    "atrial_fibrillation" = 313217L,
    "chronic_kidney_disease" = 46271022L,
    "cerebrovascular_disease" = 381591L,
    "dizziness" = 4223938L,
    "dyspnea" = 312437L,
    "falls" = 4059015L,
    "foot_problems" = 4101512L,
    "fragility_fracture" = 3170964L,
    "hearing_impairment" = 4234647L,
    "heart_failure" = 316139L,
    "heart_valve_disorder"  = 4281749L,
    "housebound" = 4052962L,
    "hypertension" = 319826L,
    "hypotension_syncope" = 316447L,
    "ischemic_heart_disease"  = 4185932L,
    "memory_cognitive_disorder" = 4304008L,
    "mobility_problems" =  4053076L,
    "osteoporosis" = 80502L,
    "parkinsonism_tremor" = 4140090L,
    "peptic_ulcer" = 4027663L,
    "peripheral_vascular_disease" = 321052L,
    "care_requirement" = 3661927L,
    "respiratory_disease" = 317009L,
    "skin_ulcer" = 4262920L,
    "sleep_disturbance" = 435524L,
    "social_vulnerability" = 4026161L,
    "diabetes" = 201820L,
    "thyroid_disease" = 4017052L,
    "urinary_incontinence" = 197672L,
    "urinary_system_disease" = 75865L,
    "visual_impairment" = 4265433L,
    "weight_loss_anorexia" = 436675L)

  person <- dplyr::tibble(
    "person_id" = c(1L, 2L, 3L, 4L),
    "gender_concept_id" = rep(8532L, 4),
    "year_of_birth" = c(1963L, 1973L, 1993L, 2000L),
    "month_of_birth" = rep(1L, 4),
    "day_of_birth" = rep(1L, 4),
    "race_concept_id" = NA_integer_,
    "ethnicity_concept_id" = NA_integer_
  )

  condition_occurrence <- dplyr::tibble(
    "condition_occurrence_id" = seq(1L, 46L, 1L),
    "person_id" = c(rep(1L, 3), rep(2L, 35), rep(3L, 7), rep(4L, 1)),
    "condition_concept_id" = c(unlist(conceptSet[c("foot_problems",
                                                   "mobility_problems",
                                                   "urinary_incontinence")]),
                               unlist(conceptSet),
                               unlist(conceptSet[c("weight_loss_anorexia",
                                                   "diabetes",
                                                   "urinary_incontinence",
                                                   "social_vulnerability",
                                                   "care_requirement",
                                                   "hypertension",
                                                   "hypotension_syncope")]),
                               unlist(conceptSet[c("skin_ulcer")])),
    "condition_start_date" = rep(as.Date("2020-01-01"), 46),
    "condition_end_date" = rep(as.Date("2020-01-01"), 46),
    "condition_type_concept_id" = NA_integer_)

  cohort <- dplyr::tibble(
    "cohort_definition_id" = rep(1L, 4),
    "subject_id" = c(1L, 2L, 3L, 4L),
    "cohort_start_date" = c(rep(as.Date("2024-01-01"), 3), as.Date("2019-01-01")),
    "cohort_end_date" = c(rep(as.Date("2024-01-01"), 3), as.Date("2019-01-01"))
  )

  observation_period = dplyr::tibble(
    "observation_period_id" = c(1L, 2L, 3L, 4L),
    "person_id" = c(1L, 2L, 3L, 4L),
    "observation_period_start_date" = rep(as.Date("2001-01-01"),4),
    "observation_period_end_date" = rep(as.Date("2025-01-01"),4),
    "period_type_concept_id" = NA_integer_
  )

  concept <- dplyr::tibble(
    "concept_id" = unlist(conceptSet),
    "concept_name" = names(conceptSet),
    "domain_id" = "Condition",
    "vocabulary_id" = "SNOMED",
    "concept_class_id" = "Clinical Finding",
    "standard_concept" = "S",
    "concept_code" = NA_character_,
    "valid_start_date" = as.Date("1950-01-01"),
    "valid_end_date" = as.Date("2099-01-01")
  )

  drug_era <- dplyr::tibble(
    "drug_era_id" = as.integer(),
    "person_id" = as.integer(),
    "drug_concept_id" = as.integer(),
    "drug_era_start_date" = as.Date(character()),
    "drug_era_end_date" = as.Date(character())
  )

  cdm <- omopgenerics::cdmFromTables("tables" = list("person" = person,
                                                     "observation_period" = observation_period,
                                                     "condition_occurrence" = condition_occurrence,
                                                     "concept" = concept,
                                                     "drug_era" = drug_era),
                                     "cohort" = list("cohort" = cohort),
                                     cdmName = "mock")


  expect_no_error(cdm[["cohort"]] <- cdm[["cohort"]] |>
                    addElectronicFrailtyIndex(indexDate = "cohort_start_date",
                                              window = c(-Inf, 0),
                                              conceptSet = conceptSet,
                                              nameStyle = "efi",
                                              categories = NULL))

  expect_equal(cdm[["cohort"]] |>
                 dplyr::pull("efi"),
               c(3/36, 35/36, 7/36, 0))

  expect_no_error(cdm[["cohort"]] <- cdm[["cohort"]] |>
                    addElectronicFrailtyIndex(indexDate = "cohort_start_date",
                                              window = c(0, Inf),
                                              conceptSet = conceptSet,
                                              nameStyle = "efi_w",
                                              categories = NULL))
  expect_identical(cdm[["cohort"]] |>
                     dplyr::pull("efi_w"),
                   c(0, 0, 0, 1/36))

  CDMConnector::cdmDisconnect(cdm)

})
