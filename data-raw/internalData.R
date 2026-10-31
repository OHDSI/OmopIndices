
# Create cdm for descendants and concept names ----
cdm <- omock::mockCdmFromDataset(datasetName = "delphi-100k")

# Indices definitions ----
## Empty objects to save  -----
formulas <- list()
components <- list()
requiredConcepts <- list()
points <- list()
cohortComponents <- list()

## Charlson Index ----
requiredConcepts$charlson <- c(
  "myocardial_infarction", "congestive_heart_failure",
  "peripheral_vascular_disease", "cerebrovascular_disease",
  "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
  "diabetes_without_complication", "hemiplegia",
  "severe_chronic_kidney_disease", "diabetes_with_complication",
  "any_malignancy", "moderate_or_severe_liver_disease",
  "metastatic_solid_tumor", "aids"
)
formulas$charlson <- "dplyr::case_when(
  .data$diabetes_with_complication == 1L ~ 2L,
  .data$diabetes_without_complication == 1L ~ 1L,
  .default = 0L
) +
dplyr::case_when(
  .data$metastatic_solid_tumor == 1L ~ 6L,
  .data$any_malignancy == 1L ~ 2L,
  .default = 0L
) +
dplyr::case_when(
  .data$moderate_or_severe_liver_disease == 1L ~ 3L,
  .data$mild_liver_disease == 1L ~ 1L,
  .default = 0L
) +
.data$myocardial_infarction + .data$congestive_heart_failure +
.data$peripheral_vascular_disease + .data$cerebrovascular_disease +
.data$dementia + .data$chronic_pulmonary_disease + .data$connective_tissue_disease +
.data$peptic_ulcer_disease +
2 * .data$hemiplegia + 2 * .data$severe_chronic_kidney_disease + 6 * .data$aids"
formulas$charlson_age_adjusted <- paste0(
  "dplyr::case_when(
    .data$age_group == '0 to 49' ~ 0L,
    .data$age_group == '50 to 59' ~ 1L,
    .data$age_group == '60 to 69' ~ 2L,
    .data$age_group == '70 to 79' ~ 3L,
    .data$age_group == '80 or over' ~ 4L
  ) + ",
  formulas$charlson
)
points$charlson <- list(
  diabetes_with_complication = 2L,
  diabetes_without_complication = 1L,
  metastatic_solid_tumor = 6L,
  any_malignancy = 2L,
  moderate_or_severe_liver_disease = 3L,
  mild_liver_disease = 1L,
  myocardial_infarction = 1L,
  congestive_heart_failure = 1L,
  peripheral_vascular_disease = 1L,
  cerebrovascular_disease = 1L,
  dementia = 1L,
  chronic_pulmonary_disease = 1L,
  connective_tissue_disease = 1L,
  peptic_ulcer_disease = 1L,
  hemiplegia = 2L,
  severe_chronic_kidney_disease = 2L,
  aids = 6L
)
points$charlson_age_adjusted <- c(
  points$charlson,
  list(
    '50 to 59' = 1L,
    '60 to 69' = 2L,
    '70 to 79' = 3L,
    '80 or over' = 4L
  )
)
cohortComponents$charlson <- list(
  list(
    type = "concept",
    conceptSet = c(
      "diabetes_with_complication", "metastatic_solid_tumor",
      "moderate_or_severe_liver_disease", "myocardial_infarction",
      "congestive_heart_failure", "peripheral_vascular_disease",
      "cerebrovascular_disease", "dementia", "chronic_pulmonary_disease",
      "connective_tissue_disease", "peptic_ulcer_disease", "hemiplegia",
      "severe_chronic_kidney_disease", "aids"
    ),
    followUp = Inf
  ),
  list(
    type = "concept",
    conceptSet = "diabetes_without_complication",
    followUp = Inf,
    censor = "diabetes_with_complication"
  ),
  list(
    type = "concept",
    conceptSet = "any_malignancy",
    followUp = Inf,
    censor = "metastatic_solid_tumor"
  ),
  list(
    type = "concept",
    conceptSet = "mild_liver_disease",
    followUp = Inf,
    censor = "moderate_or_severe_liver_disease"
  )
)
cohortComponents$charlson_age_adjusted <- c(
  cohortComponents$charlson,
  list(list(
    type = "age_group",
    ageGroup = list(
     "50 to 59" = c(50, 59),
     "60 to 69" = c(60, 69),
     "70 to 79" = c(70, 79),
     "80 or over" = c(80, Inf)
    )
  ))
)
components$charlson <- list(
  list(
    type = "concept_flag",
    conceptSet = requiredConcepts$charlson,
    window = c(-Inf, 0)
  )
)
components$charlson_age_adjusted <- c(
  components$charlson,
  list(list(
    type = "age_group",
    ageGroup = list(
      "0 to 49" = c(0, 49), "50 to 59" = c(50, 59),
      "60 to 69" = c(60, 69), "70 to 79" = c(70, 79),
      "80 or over" = c(80, Inf)
    )
  ))
)

## Updated Charlson Index ----
requiredConcepts$updated_charlson <- c(
  "congestive_heart_failure", "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "mild_liver_disease", "hemiplegia",
  "severe_chronic_kidney_disease", "diabetes_with_complication",
  "any_malignancy", "moderate_or_severe_liver_disease",
  "metastatic_solid_tumor", "aids"
)
formulas$updated_charlson <- "dplyr::case_when(
  .data$metastatic_solid_tumor == 1L ~ 6L,
  .data$any_malignancy == 1L ~ 2L,
  .default = 0L
) +
dplyr::case_when(
  .data$moderate_or_severe_liver_disease == 1L ~ 4L,
  .data$mild_liver_disease == 1L ~ 2L,
  .default = 0L
) +
2 * .data$congestive_heart_failure + 2 * .data$dementia +
.data$chronic_pulmonary_disease + .data$connective_tissue_disease +
.data$diabetes_with_complication + 2 * .data$hemiplegia +
.data$severe_chronic_kidney_disease + 4 * .data$aids"
formulas$updated_charlson_age_adjusted <- paste0(
  "dplyr::case_when(
    .data$age_group == '0 to 49' ~ 0L,
    .data$age_group == '50 to 59' ~ 1L,
    .data$age_group == '60 to 69' ~ 2L,
    .data$age_group == '70 to 79' ~ 3L,
    .data$age_group == '80 or over' ~ 4L
  ) +",
  formulas$updated_charlson
)
components$updated_charlson <- list(
  list(
    type = "concept_flag",
    conceptSet = requiredConcepts$updated_charlson,
    window = c(-Inf, 0)
  )
)
components$updated_charlson_age_adjusted <- c(
  components$updated_charlson,
  components$charlson_age_adjusted[length(components$charlson_age_adjusted)]
)

## Hospital Frailty Risk Score ----
hfrsData <- readr::read_csv(
  file = "inst/hospital_frailty_risk_score.csv",
  col_types = c(concept_set = "c", points = "d", icd10_code = "c", icd_description = "c")
)
requiredConcepts$hospital_frailty_risk_score <- hfrsData$concept_set
formulas$hospital_frailty_risk_score <- paste0(hfrsData$points, " * .data$", hfrsData$concept_set, collapse = " + ")
components$hospital_frailty_risk_score <- list(
  list(
    type = "concept_flag",
    conceptSet = requiredConcepts$hospital_frailty_risk_score,
    window = c(-730, 0)
  )
)

## Electronic Frailty Index ----
requiredConcepts$electronic_frailty_index <- c(
  "activity_limitation", "anemia", "arthritis", "atrial_fibrillation",
  "cerebrovascular_disease", "chronic_kidney_disease",  "diabetes", "dizziness",
  "dyspnea", "falls", "foot_problem", "fragility_fracture",
  "hearing_impairment", "heart_failure", "heart_valve_disorder", "housebound",
  "hypertension", "hypotension_syncope", "ischemic_heart_disease",
  "memory_cognitive_disorder", "mobility_problems", "osteoporosis",
  "parkinsonism_tremor", "peptic_ulcer", "peripheral_vascular_disease",
  "care_requirement", "respiratory_disease", "skin_ulcer", "sleep_disturbance",
  "social_vulnerability", "thyroid_disease", "urinary_incontinence",
  "urinary_system_disease", "visual_impairment", "weight_loss_anorexia"
)
formulas$electronic_frailty_index <- paste0(
  paste0("1/36 * .data$", requiredConcepts$electronic_frailty_index, collapse = " + "),
  " + dplyr::if_else(.data$polypharmacy >= 5, 1/36, 0)"
)
components$electronic_frailty_index <- list(
  list(
    type = "concept_flag",
    conceptSet = requiredConcepts$electronic_frailty_index,
    window = c(-Inf, 0)
  ),
  list(
    type = "polypharmacy",
    window = c(-365, 0),
    overlap = TRUE
  )
)

## Electronic Frailty Index 2 ----
efi2 <- c(
  activity_limitation = "0.15284 / 8.429",
  alcohol_harmful_intake = "0.23107 / 8.429",
  alcohol_missing = "0.13175 / 8.429",
  alcohol_previous_harmful_higher = "1.36434 / 8.429",
  atrial_fibrillation = "0.13025 / 8.429",
  cancer = "0.2406 / 8.429",
  cognitive_impairment = "0.10985 / 8.429",
  copd = "0.11683 / 8.429",
  dementia = "0.41715 / 8.429",
  dressing_grooming_problems = "0.05422 / 8.429",
  environment_problems = "0.11886 / 8.429",
  falls = "0.62743 / 8.429",
  fracture = "0.07353 / 8.429",
  fragility_fracture = "0.17425 / 8.429",
  heart_failure = "0.11086 / 8.429",
  housebound = "0.33254 / 8.429",
  hypotension_syncope = "0.18253 / 8.429",
  liver_problems = "0.23787 / 8.429",
  medication_management_problems = "0.32125 / 8.429",
  memory_concerns = "0.11915 / 8.429",
  mobility_problems = "0.46836 / 8.429",
  motor_neuron_disease = "0.35347 / 8.429",
  palliative_care = "0.5145 / 8.429",
  parkinsonism_tremor = "0.03537 / 8.429",
  peptic_ulcer = "0.05427 / 8.429",
  peripheral_vascular_disease = "0.02672 / 8.429",
  care_requirement = "0.21428 / 8.429",
  respiratory_disease = "0.01049 / 8.429",
  seizures = "0.02885 / 8.429",
  self_harm = "0.009 / 8.429",
  skin_ulcer = "0.21935 / 8.429",
  smoker_current = "0.10291 / 8.429",
  social_vulnerability = "0.23585 / 8.429",
  stroke = "0.10565 / 8.429",
  transient_ischemic_attack = "0.02305 / 8.429",
  weight_loss_anorexia = "0.19256 / 8.429"
)
requiredConcepts$electronic_frailty_index_2 <- c(names(efi2), "bmi")
formulas$electronic_frailty_index_2 <- paste0(
  paste0(unname(efi2), " * .data$", names(efi2), collapse = " + "),
  " + dplyr::case_when(
    is.na(.data$bmi) ~ 0.25318 / 8.429,
    .data$bmi < 18.5  ~ 0.4417 / 8.429,
    .default = 0
  ) + dplyr::case_when(
    .data$polypharmacy >= 10 ~ 0.50801 / 8.429,
    .data$polypharmacy >= 5 ~ 0.32301 / 8.429,
    .default = 0
  )"
)
components$electronic_frailty_index_2 <- list(
  list(
    type = "concept_flag",
    conceptSet = names(efi2),
    window = c(-Inf, 0)
  ),
  list(
    type = "bmi",
    conceptSet = "bmi",
    window = c(-Inf, 0),
    order = "last"
  ),
  list(
    type = "polypharmacy",
    window = c(-365, 0),
    overlap = TRUE
  )
)

## Body Mass Index ----
requiredConcepts$body_mass_index <- "bmi"
formulas$body_mass_index <- ".data$bmi"
components$body_mass_index <- list(
  list(
    type = "bmi",
    conceptSet = "bmi",
    window = c(-Inf, 0),
    order = "last",
    inObservation = TRUE
  )
)

# Internal concepts ----
internalConcepts <- list()

## Charlson Index concepts ----
internalConcepts$charlson <- readr::read_csv(
  file = here::here("data-raw", "concepts", "charlson.csv"),
  col_types = c(concept_id = "i", codelist_name = "c", concept_name = "c", vocabulary_id = "c")
) |>
  dplyr::select("codelist_name", "concept_id")

## Updated Charlson Index concepts ----
internalConcepts$updated_charlson <- internalConcepts$charlson |>
  dplyr::filter(.data$codelist_name %in% .env$requiredConcepts$updated_charlson)

## Hospital Frailty Risk Score ----
internalConcepts$hospital_frailty_risk_score <- list.files(
  path = here::here("data-raw", "concepts"),
  pattern = "^hfrs_",
  full.names = TRUE
) |>
  rlang::set_names() |>
  purrr::map(\(x) readr::read_csv(file = x, col_types = c(concept_id = "i"))) |>
  dplyr::bind_rows(.id = "icd10_code") |>
  dplyr::mutate(icd10_code = toupper(substr(basename(.data$icd10_code), 6, 8))) |>
  dplyr::left_join(
    hfrsData |>
      dplyr::select("codelist_name" = "concept_set", "icd10_code"),
    by = "icd10_code"
  ) |>
  dplyr::select("codelist_name", "concept_id")

## Body Mass Index ----
internalConcepts$body_mass_index <- here::here("data-raw", "concepts", "bmi.csv") |>
  omopgenerics::importCodelist() |>
  dplyr::as_tibble()

## Electronic Frailty Index ----
internalConcepts$electronic_frailty_index <- list.files(
  path = here::here("data-raw", "concepts"),
  pattern = "^efi_",
  full.names = TRUE
) |>
  omopgenerics::importConceptSetExpression() |>
  # there is a warning because we do not use SNOMED veterinary
  CodelistGenerator::asCodelist(cdm = cdm) |>
  dplyr::as_tibble() |>
  dplyr::mutate(codelist_name = stringr::str_remove(string = .data$codelist_name, pattern = "^efi_")) |>
  # eliminating the SNOMED veterinary concepts
  dplyr::filter(!.data$concept_id %in% c(42593547, 42598600, 42600089, 42600293, 42600389))

## Electronic Frailty Index 2 ----
internalConcepts$electronic_frailty_index_2 <- list.files(
  path = here::here("data-raw", "concepts"),
  pattern = "^efi2_",
  full.names = TRUE
) |>
  omopgenerics::importConceptSetExpression() |>
  # there is a warning because we do not use SNOMED veterinary
  CodelistGenerator::asCodelist(cdm = cdm) |>
  dplyr::as_tibble() |>
  dplyr::mutate(codelist_name = stringr::str_remove(string = .data$codelist_name, pattern = "^efi2_")) |>
  dplyr::union_all(
    internalConcepts$electronic_frailty_index |>
      dplyr::filter(.data$codelist_name %in% .env$requiredConcepts$electronic_frailty_index_2)
  ) |>
  dplyr::union_all(internalConcepts$body_mass_index)

## Prepare points dataframe ----
points <- points |>
  purrr::map(\(x) dplyr::tibble(cohort_name = names(x), points = unlist(x)))

## Prepare internal concepts ----
internalConcepts <- internalConcepts |>
  dplyr::bind_rows(.id = "index") |>
  dplyr::select("index", "codelist_name", "concept_id") |>
  dplyr::arrange(.data$index, .data$codelist_name, .data$concept_id) |>
  dplyr::left_join(
    cdm$concept |>
      dplyr::select(
        "concept_id", "concept_name", "domain_id", "vocabulary_id",
        "concept_code"
      ),
    by = "concept_id"
  )
# check if any name is not present
x <- internalConcepts |>
  dplyr::filter(is.na(.data$concept_name))
if (nrow(x) > 0) {
  cli::cli_abort(c(x = "There are concepts that are not present in cdm."))
}
# check missing definitions
# check extra definitions

# Save internal data ----
usethis::use_data(
  requiredConcepts,
  formulas,
  components,
  points,
  cohortComponents,
  internalConcepts,
  internal = TRUE,
  overwrite = TRUE
)
