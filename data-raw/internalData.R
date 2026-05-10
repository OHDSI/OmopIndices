
hfrs <- readr::read_csv("data-raw/hospital_frailty_risk_score.csv")

hfrsConcepts <- hfrs |>
  dplyr::pull("concept_set")

hfrsFormula <- paste0(hfrs$points, " * .data$", hfrs$concept_set, collapse = " + ")

aersConcepts <- c(
  "activity_limitation", "anemia", "arthritis", "atrial_fibrillation",
  "chronic_kidney_disease", "cerebrovascular_disease", "diabetes", "dizziness",
  "dyspnea", "falls", "foot_problem", "fragility_fracture",
  "hearing_impairment", "heart_failure", "heart_valve_disorder", "housebound",
  "hypertension", "hypotension", "ischemic_heart_disease",
  "memory_cognitive_disorder", "mobility_transfer", "osteoporosis",
  "parkinsonism_tremor", "peptic_ulcer", "peripheral_vascular_disease",
  "care_requirement", "respiratory_disease", "skin_ulcer", "sleep_disturbance",
  "social_vulnerability", "thyroid_disease", "urinary_incontinence",
  "urinary_system_disease", "visual_impairment", "weight_loss_anorexia"
)

aersFormula <- paste0("1/35 * .data$", riskConcepts, collapse = " + ")

charlsonConcepts <- c(
  "myocardial_infarction", "congestive_heart_failure",
  "peripheral_vascular_disease", "cerebrovacular_accident",
  "transient_ischemic_attack", "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
  "severe_liver_disease", "diabetes_mellitus", "end_organ_diabetes_mellitus",
  "hemiplegia", "estimated_glomerular_filtration_rate",
  "severe_chronic_kidney_disease", "localised_solid_tumor",
  "metastatic_solid_tumor", "leukemia", "lymphoma", "aids"
)

charlsonFormula <- "dplyr::case_when(
  .data$age_group == 'g1' ~ 0L,
  .data$age_group == 'g2' ~ 1L,
  .data$age_group == 'g3' ~ 2L,
  .data$age_group == 'g4' ~ 3L,
  .data$age_group == 'g5' ~ 4L
) +
dplyr::case_when(
  .data$end_organ_diabetes_mellitus == 1L ~ 2L,
  .data$diabetes_mellitus == 1L ~ 1L,
  .default = 0L
) +
dplyr::case_when(
  .data$metastatic_solid_tumor == 1L ~ 6L,
  .data$localised_solid_tumor == 1L ~ 2L,
  .default = 0L
) +
data$myocardial_infarction + .data$congestive_heart_failure +
.data$peripheral_vascular_disease + .data$cerebrovacular_accident +
.data$transient_ischemic_attack + .data$dementia +
.data$chronic_pulmonary_disease + .data$connective_tissue_disease +
.data$peptic_ulcer_disease + .data$liver + 2 * .data$hemiplegia +
2 * .data$severe_chronic_kidney_disease + 2 * .data$leukemia +
2 * .data$lymphoma + 6 * .data$aids"

usethis::use_data(
  hfrsConcepts,
  hfrsFormula,
  aersConcepts,
  aersFormula,
  charlsonConcepts,
  charlsonFormula,
  internal = TRUE,
  overwrite = TRUE
)
