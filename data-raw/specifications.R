
# Charlson Index ----
charlsonSpecs <- list(
  list(
    type = "concept_flag",
    conceptSet = c(
      "myocardial_infarction", "congestive_heart_failure",
      "peripheral_vascular_disease", "cerebrovascular_disease",
      "dementia", "chronic_pulmonary_disease",
      "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease",
      "diabetes_without_complication", "hemiplegia",
      "severe_chronic_kidney_disease", "diabetes_with_complication",
      "any_malignancy", "moderate_or_severe_liver_disease",
      "metastatic_solid_tumor", "aids"
    ),
    window = c(-Inf, 0)
  )
)

charlsonAgeAdjustedSpecs <- charlsonSpecs |>
  append(
    list(
      type = "age_group",
      ageGroup = list("g1"= c(0, 49), "g2" = c(50, 59), "g3" = c(60, 69), "g4" = c(70, 79), "g5" = c(80, Inf))
    )
  )

# Updated Charlson Index ----

updatedCharlsonSpecs <- list(
  list(
    type = "concept_flag",
    conceptSet = c(
      "congestive_heart_failure", "dementia", "chronic_pulmonary_disease",
      "connective_tissue_disease", "mild_liver_disease", "hemiplegia",
      "severe_chronic_kidney_disease", "diabetes_with_complication",
      "any_malignancy", "moderate_or_severe_liver_disease",
      "metastatic_solid_tumor", "aids"
    ),
    window = c(-Inf, 0)
  )
)

updatedCharlsonAgeAdjustedSpecs <- charlsonSpecs |>
  append(
    list(
      type = "age_group",
      ageGroup = list("g1"= c(0, 49), "g2" = c(50, 59), "g3" = c(60, 69), "g4" = c(70, 79), "g5" = c(80, Inf))
    )
  )

# Hospital Risk Score ----

hfrsData <- readr::read_csv(
  file = "inst/hospital_frailty_risk_score.csv",
  col_types = c(concept_set = "c", points = "d", icd10_code = "c", icd_description = "c")
)

hfrsSpecs <- list(
  list(
    type = "concept_flag",
    conceptSet = hfrsData$concept_set,
    window = c(-730, 0)
  )
)

# Electronic Frailty Index ----

hf

# internal data ----

specifications <- list(
  charlson = ,
  updated_charlson = ,
  hospital_frailty_risk_score =,
  electronic_frailty_index =,
  electronic_frailty_index_2 =
)
