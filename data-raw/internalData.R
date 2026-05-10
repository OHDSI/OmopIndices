
hfrs <- readr::read_csv("data-raw/hospital_frailty_risk_score.csv")

hfrsConcepts <- hfrs |>
  dplyr::pull("concept_set")

hfrsFormula <- paste0(hfrs$points, " * ", hfrs$concept_set, collapse = " + ")

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

aersFormula <- paste0("1/35 * ", riskConcepts, collapse = " + ")

usethis::use_data(
  hfrsConcepts,
  hfrsFormula,
  aersConcepts,
  aersFormula,
  internal = TRUE,
  overwrite = TRUE
)
