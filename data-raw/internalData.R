
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
  .data$diabetes_without_complication == 1L & .data$diabetes_with_complication == 0L ~ 1L,
  .default = 0L
) +
dplyr::case_when(
  .data$metastatic_solid_tumor == 1L ~ 6L,
  .data$any_malignancy == 1L & .data$metastatic_solid_tumor == 0L ~ 2L,
  .default = 0L
) +
dplyr::case_when(
  .data$moderate_or_severe_liver_disease == 1L ~ 3L,
  .data$mild_liver_disease == 1L & .data$moderate_or_severe_liver_disease == 0L ~ 1L,
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
  .data$any_malignancy == 1L & .data$metastatic_solid_tumor == 0L ~ 2L,
  .default = 0L
) +
dplyr::case_when(
  .data$moderate_or_severe_liver_disease == 1L ~ 4L,
  .data$mild_liver_disease == 1L & .data$moderate_or_severe_liver_disease == 0L ~ 2L,
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
  charlsonConcepts,
  updatedCharlsonConcepts,
  charlsonFormulaAgeAdjusted,
  charlsonFormula,
  updatedCharlsonFormula,
  updatedCharlsonFormulaAgeAdjusted,
  internal = TRUE,
  overwrite = TRUE
)
