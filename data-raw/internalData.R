
hfrs <- readr::read_csv("data-raw/hospital_frailty_risk_score.csv")

hfrsConcepts <- hfrs |>
  dplyr::pull("concept_set")

hfrsFormula <- paste0(hfrs$points, " * .data$", hfrs$concept_set, collapse = " + ")

efiConcepts <- c(
  "activity_limitation", "anemia", "arthritis", "atrial_fibrillation",
  "cerebrovascular_disease", "chronic_kidney_disease",  "diabetes", "dizziness",
  "dyspnea", "falls", "foot_problems", "fragility_fracture",
  "hearing_impairment", "heart_failure", "heart_valve_disorder", "housebound",
  "hypertension", "hypotension", "ischemic_heart_disease",
  "memory_cognitive_disorder", "mobility_transfer", "osteoporosis",
  "parkinsonism_tremor", "peptic_ulcer", "peripheral_vascular_disease",
  "care_requirement", "respiratory_disease", "skin_ulcer", "sleep_disturbance",
  "social_vulnerability", "thyroid_disease", "urinary_incontinence",
  "urinary_system_disease", "visual_impairment", "weight_loss_anorexia"
)

efiFormula <- paste0(
  paste0("1/36 * .data$", efiConcepts, collapse = " + "),
  " + dplyr::if_else(.data$polypharmacy_count >= 5, 1/36, 0)"
)

efi2Concepts <- c(
  "activity_limitation", "alcohol_harmful_intake", "alcohol_missing",
  "alcohol_previous_harmful_higher", "atrial_fibrillation", "cancer",
  "cognitive_impairment", "copd", "dementia", "dressing_grooming_problems",
  "environment_problems", "falls", "fracture", "fragility_fracture",
  "heart_failure", "housebound", "hypotension_syncope", "liver_problems",
  "medication_management_problems", "memory_concerns", "mobility_problems",
  "motor_neuron_disease", "bmi_missing", "bmi_underweight", "palliative_care",
  "parkinsonism_tremor", "peptic_ulcer_disease", "peripheral_vascular_disease",
  "requirement_for_care", "respiratory_disease", "seizures", "self_harm",
  "skin_ulcer", "smoker_current", "social_vulnerability", "stroke",
  "transient_ischemic_attack", "weight_loss"
)

efi2Weights <- c(
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
  peptic_ulcer_disease = "0.05427 / 8.429",
  peripheral_vascular_disease = "0.02672 / 8.429",
  requirement_for_care = "0.21428 / 8.429",
  respiratory_disease = "0.01049 / 8.429",
  seizures = "0.02885 / 8.429",
  self_harm = "0.009 / 8.429",
  skin_ulcer = "0.21935 / 8.429",
  smoker_current = "0.10291 / 8.429",
  social_vulnerability = "0.23585 / 8.429",
  stroke = "0.10565 / 8.429",
  transient_ischemic_attack = "0.02305 / 8.429",
  weight_loss = "0.19256 / 8.429"
)

efi2Formula <- paste0(
  paste0(efi2Weights[efi2Concepts], " * .data$", efi2Concepts, collapse = " + "),
  " + dplyr::case_when(
    .data$polypharmacy_count >= 10 ~ 0.50801 / 8.429,
    .data$polypharmacy_count >= 5 ~ 0.32301 / 8.429,
    .default = 0
  )"
)

charlsonConcepts <- c(
  "myocardial_infarction", "congestive_heart_failure",
  "peripheral_vascular_disease", "cerebrovascular_disease",
  "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
  "diabetes_without_complication", "hemiplegia",
  "severe_chronic_kidney_disease",   "diabetes_with_complication",
  "any_malignancy", "moderate_or_severe_liver_disease",
  "metastatic_solid_tumor", "aids"
)

updatedCharlsonConcepts <- c(
  "congestive_heart_failure", "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "mild_liver_disease", "hemiplegia",
  "severe_chronic_kidney_disease", "diabetes_with_complication",
  "any_malignancy", "moderate_or_severe_liver_disease",
  "metastatic_solid_tumor", "aids"
)

charlsonFormula <- "dplyr::case_when(
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

charlsonFormulaAgeAdjusted <- paste0(
 "dplyr::case_when(
    .data$age_group == 'g1' ~ 0L,
    .data$age_group == 'g2' ~ 1L,
    .data$age_group == 'g3' ~ 2L,
    .data$age_group == 'g4' ~ 3L,
    .data$age_group == 'g5' ~ 4L
  ) +",
 charlsonFormula
)

updatedCharlsonFormula <- "dplyr::case_when(
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

updatedCharlsonFormulaAgeAdjusted <- paste0(
  "dplyr::case_when(
    .data$age_group == 'g1' ~ 0L,
    .data$age_group == 'g2' ~ 1L,
    .data$age_group == 'g3' ~ 2L,
    .data$age_group == 'g4' ~ 3L,
    .data$age_group == 'g5' ~ 4L
  ) +",
  updatedCharlsonFormula
)

usethis::use_data(
  hfrsConcepts,
  hfrsFormula,
  efiConcepts,
  efiFormula,
  efi2Concepts,
  efi2Formula,
  charlsonConcepts,
  updatedCharlsonConcepts,
  charlsonFormulaAgeAdjusted,
  charlsonFormula,
  updatedCharlsonFormula,
  updatedCharlsonFormulaAgeAdjusted,
  internal = TRUE,
  overwrite = TRUE
)
