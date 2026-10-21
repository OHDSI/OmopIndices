
formulas <- list()
components <- list()

# Charlson Index ----
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

components$charlson <- c(
  "myocardial_infarction", "congestive_heart_failure",
  "peripheral_vascular_disease", "cerebrovascular_disease",
  "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
  "diabetes_without_complication", "hemiplegia",
  "severe_chronic_kidney_disease", "diabetes_with_complication",
  "any_malignancy", "moderate_or_severe_liver_disease",
  "metastatic_solid_tumor", "aids"
) |>
  purrr::map(\(x) {
    list(type = "concept_flag", conceptSet = x, window = c(-Inf, 0))
  })

# Charlson Index Age Adjusted ----
formulas$charlson_age_adjusted <- paste0(
  formulas$charlson,
  "+ dplyr::case_when(
    .data$age_group == '0 to 49' ~ 0L,
    .data$age_group == '50 to 59' ~ 1L,
    .data$age_group == '60 to 69' ~ 2L,
    .data$age_group == '70 to 79' ~ 3L,
    .data$age_group == '80 or over' ~ 4L
  )"
)

components$charlson_age_adjusted <- c(
  components$charlson,
  list(
    type = "age_group",
    ageGroup = list(
      "0 to 49"= c(0, 49),
      "50 to 59" = c(50, 59),
      "60 to 69" = c(60, 69),
      "70 to 79" = c(70, 79),
      "80 or over" = c(80, Inf)
    )
  )
)

# Updated Charlson Index ----
formulas$charlson <- "dplyr::case_when(
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

components$updated_charlson <- c(
  "congestive_heart_failure", "dementia", "chronic_pulmonary_disease",
  "connective_tissue_disease", "mild_liver_disease", "hemiplegia",
  "severe_chronic_kidney_disease", "diabetes_with_complication",
  "any_malignancy", "moderate_or_severe_liver_disease",
  "metastatic_solid_tumor", "aids"
) |>
  purrr::map(\(x) {
    list(type = "concept_flag", conceptSet = x, window = c(-Inf, 0))
  })

# Updated Charlson Index Age Adjusted ----
formulas$updated_charlson_age_adjusted <- paste0(
  formulas$updated_charlson,
  "+ dplyr::case_when(
    .data$age_group == '0 to 49' ~ 0L,
    .data$age_group == '50 to 59' ~ 1L,
    .data$age_group == '60 to 69' ~ 2L,
    .data$age_group == '70 to 79' ~ 3L,
    .data$age_group == '80 or over' ~ 4L
  )"
)

components$updated_charlson_age_adjusted <- c(
  components$updated_charlson,
  list(
    type = "age_group",
    ageGroup = list(
      "0 to 49"= c(0, 49),
      "50 to 59" = c(50, 59),
      "60 to 69" = c(60, 69),
      "70 to 79" = c(70, 79),
      "80 or over" = c(80, Inf)
    )
  )
)

# Hospital Risk Score ----
hfrsData <- readr::read_csv(
  file = "inst/hospital_frailty_risk_score.csv",
  col_types = c(concept_set = "c", points = "d", icd10_code = "c", icd_description = "c")
)

formulas$hospital_risk_score <- paste0(
  sprintf("%.1f * .data$%s", hfrsData$points, hfrsData$concept_set),
  collapse = " + "
)

components$hospital_risk_score <- hfrsData$concept_set |>
  purrr::map(\(x) {
    list(type = "concept_flag", conceptSet = x, window = c(-730, 0))
  })

# Electronic Frailty Index ----

# internal data ----
