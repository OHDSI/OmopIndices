
# Create cdm for descendants and concept names ----
cdm <- omock::mockCdmFromDataset(datasetName = "delphi-100k")

# Indices data ----
## Empty objects to save  -----
formulas <- list()
requiredConcepts <- list()

## Charlson Index ----
requiredConcepts$charlson <- c(
  "myocardial_infarction", "congestive_heart_failure",
  "peripheral_vascular_disease", "cerebrovascular_disease",
  "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
  "diabetes_without_complication", "hemiplegia",
  "severe_chronic_kidney_disease",   "diabetes_with_complication",
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
    .data$age_group == 'g1' ~ 0L,
    .data$age_group == 'g2' ~ 1L,
    .data$age_group == 'g3' ~ 2L,
    .data$age_group == 'g4' ~ 3L,
    .data$age_group == 'g5' ~ 4L
  ) + ",
  formulas$charlson
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
    .data$age_group == 'g1' ~ 0L,
    .data$age_group == 'g2' ~ 1L,
    .data$age_group == 'g3' ~ 2L,
    .data$age_group == 'g4' ~ 3L,
    .data$age_group == 'g5' ~ 4L
  ) +",
  formulas$updated_charlson
)

## Hospital Frailty Risk Score ----
hfrsData <- readr::read_csv(
  file = "inst/hospital_frailty_risk_score.csv",
  col_types = c(concept_set = "c", points = "d", icd10_code = "c", icd_description = "c")
)
requiredConcepts$hospital_frailty_risk_score <- hfrsData$concept_set
formulas$hospital_frailty_risk_score <- paste0(hfrsData$points, " * .data$", hfrsData$concept_set, collapse = " + ")

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
  " + dplyr::if_else(.data$polypharmacy_count >= 5, 1/36, 0)"
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
  bmi_missing = "0.25318 / 8.429",
  bmi_underweight = "0.4417 / 8.429",
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
requiredConcepts$electronic_frailty_index_2 <- names(efi2)
formulas$electronic_frailty_index_2 <- paste0(
  paste0(unname(efi2), " * .data$", names(efi2), collapse = " + "),
  " + dplyr::case_when(
    .data$polypharmacy_count >= 10 ~ 0.50801 / 8.429,
    .data$polypharmacy_count >= 5 ~ 0.32301 / 8.429,
    .default = 0
  )"
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
  pattern = "^hfrs",
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
  pattern = "^efi",
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

## Prepare intenal concepts ----
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

# Save internal data ----
usethis::use_data(
  requiredConcepts,
  formulas,
  internalConcepts,
  internal = TRUE,
  overwrite = TRUE
)
