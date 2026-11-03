# Index definitions ----
# One definition supplies the components, scoring and temporal rules used by
# both addIndex() and indexCohort(). The four component types below cover the
# current indices.
#
# An index is defined by a list of components (elements). Each component/element
# has a type, and the settings for that type. *marks a required field.
#
# SHARED RULES
# - Components contribute independently and their scores are summed. Within
#   each group = "name", only the FIRST ACTIVE component in definition order
#   contributes. Earlier components take precedence regardless of their score;
#   this is list order, not the order in which events occurred. If no component
#   in a group is active, the group contributes zero. An active component with
#   score zero still takes precedence over later components in its group.
#   For example, define diabetes with complications before diabetes without
#   complications to select its score when both are active. Put the preferred
#   liver and cancer components first in their respective groups as well.
# - Scored components use finite, nonnegative numeric scores. Numeric sources
#   can instead use score = "value" to return the selected value/count, as in
#   standalone BMI and polypharmacy. In this mode, omit the scoring bands.
# - Bands are lists of named fields, not positional vectors. Each band has a
#   label, a range and a score. Ranges include both endpoints by default;
#   lower_inclusive / upper_inclusive = FALSE makes an endpoint exclusive.
#   Use nonoverlapping bands; unmatched values contribute zero in scored mode.
#
# **concept**
# type* = "concept"
# concept_set* = name of the codelist identifying qualifying events.
# score* = numeric contribution, e.g. "1L" or "0.15".
# follow_up* = nonnegative days, or Inf.
# group = optional scoring group; the first active component in the group wins.
# require_age_range = c(5, Inf), optional inclusive age range AT THE EVENT.
#   For example, a diagnosis recorded before age 5 never becomes eligible just
#   because the person later turns 5.
# Each qualifying event contributes once while active; repeated diagnoses do
# not add points. With follow_up = 730, an event on day d is active through
# d + 730 inclusive. With Inf, the component persists without expiry.
#
# **age_group**
# type* = "age_group"
# age_groups* = list of bands, each with:
#   label* = unique band name, e.g. "50 to 59".
#   age_range* = inclusive range of completed years, e.g. c(50, 59).
#   score* = numeric contribution.
# Age is evaluated on the scoring date, not on a diagnosis date. A person is
# in c(50, 59) from their 50th birthday until the day before their 60th birthday.
# Unlisted ages contribute zero.
#
# **polypharmacy**
# type* = "polypharmacy"
# overlap* = TRUE/FALSE:
#   TRUE: maximum number of distinct drug groups simultaneously active at any
#   time; FALSE: number of distinct drug groups with exposure
#   intersecting the window, even if they were never simultaneous.
# follow_up* = nonnegative days. This defines the rolling assessment.
# drug_group* = grouping for the drug concept, e.g. "ingredient drug_era",
#   "ingredient drug_exposure", "concept_id", or an ATC level.
# drug_groups* = scoring bands (omit when score = "value"), each with:
#   label* = unique band name.
#   drug_range* = inclusive count range, e.g. c(5, 9) or c(10, Inf).
#   score* = numeric contribution.
# drug_group controls how drugs are counted; drug_groups maps the resulting
# count to points.
#
# **measurement**
# type* = "measurement"
# concept_set* = codelist identifying measurement/observation records, e.g. BMI.
# follow_up* = nonnegative days, or Inf.
# Select the latest eligible record in c(-follow_up, 0) relative to the index
# date, including both endpoints. addBMI exposes follow_up as lookbackDays.
# in_observation = TRUE (default); restrict records to observation periods.
# tie = "max" (default) or "min": resolves same-day ties. An explicit list of
#   band labels can instead define priority for categorical measurements.
#   Ties are resolved on the latest eligible date; the first listed label wins.
# measurement_groups* = scoring bands (omit when score = "value"), each with:
#   label* = unique band name.
#   measurement_value = numeric range, with optional endpoint exclusions.
#   measurement_concept = codelist name for categorical value_as_concept_id.
#   measurement_unit = optional accepted unit concept ID(s), applied before
#   selecting a record. Omission preserves the current BMI behaviour of no
#   unit restriction. Different units are not automatically converted.
#   score* = numeric contribution.
#   Supply at least one of measurement_value and measurement_concept per band.
#   If both are supplied, both must match. Unmatched values contribute zero.
#
# Utility functions:
#   getFormula(definition)          -- score expression for addIndex
#   getAddComponents(definition)    -- input extraction for addIndex
#   getPointsMatrix(definition)     -- fixed points and scoring groups
#   getCohortComponents(definition) -- time intervals for indexCohort
#   getNeededConcepts(definition)   -- required codelist names
#
# TODO: adapt and validate these contracts before exposing general addIndex /
# indexCohort functions or public constructors for index definitions.

indexDefinitions <- list()

## Charlson ----
indexDefinitions$charlson <- list(
  list(
    type = "concept",
    concept_set = "myocardial_infarction",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "congestive_heart_failure",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "peripheral_vascular_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "cerebrovascular_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "dementia",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "chronic_pulmonary_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "connective_tissue_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "peptic_ulcer_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "moderate_or_severe_liver_disease",
    follow_up = Inf,
    score = 3L,
    group = "liver"
  ),
  list(
    type = "concept",
    concept_set = "mild_liver_disease",
    follow_up = Inf,
    score = 1L,
    group = "liver"
  ),
  list(
    type = "concept",
    concept_set = "diabetes_with_complication",
    follow_up = Inf,
    score = 2L,
    group = "diabetes"
  ),
  list(
    type = "concept",
    concept_set = "diabetes_without_complication",
    follow_up = Inf,
    score = 1L,
    group = "diabetes"
  ),
  list(
    type = "concept",
    concept_set = "hemiplegia",
    follow_up = Inf,
    score = 2L
  ),
  list(
    type = "concept",
    concept_set = "severe_chronic_kidney_disease",
    follow_up = Inf,
    score = 2L
  ),
  list(
    type = "concept",
    concept_set = "metastatic_solid_tumor",
    follow_up = Inf,
    score = 6L,
    group = "cancer"
  ),
  list(
    type = "concept",
    concept_set = "any_malignancy",
    follow_up = Inf,
    score = 2L,
    group = "cancer"
  ),
  list(
    type = "concept",
    concept_set = "aids",
    follow_up = Inf,
    score = 6L
  )
)

## Age adjusted Charlson ----
indexDefinitions$charlson_age_adjusted <- c(
  indexDefinitions$charlson,
  list(
    list(
      type = "age_group",
      name_style = "age_group",
      age_groups = list(
        list(
          label = "50 to 59",
          age_range = c(50, 59),
          score = 1L
        ),
        list(
          label = "60 to 69",
          age_range = c(60, 69),
          score = 2L
        ),
        list(
          label = "70 to 79",
          age_range = c(70, 79),
          score = 3L
        ),
        list(
          label = "80 or over",
          age_range = c(80, Inf),
          score = 4L
        )
      )
    )
  )
)

## Updated Charlson ----
indexDefinitions$updated_charlson <- list(
  list(
    type = "concept",
    concept_set = "congestive_heart_failure",
    follow_up = Inf,
    score = 2L
  ),
  list(
    type = "concept",
    concept_set = "dementia",
    follow_up = Inf,
    score = 2L
  ),
  list(
    type = "concept",
    concept_set = "chronic_pulmonary_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "connective_tissue_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "moderate_or_severe_liver_disease",
    follow_up = Inf,
    score = 4L,
    group = "liver"
  ),
  list(
    type = "concept",
    concept_set = "mild_liver_disease",
    follow_up = Inf,
    score = 2L,
    group = "liver"
  ),
  list(
    type = "concept",
    concept_set = "diabetes_with_complication",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "hemiplegia",
    follow_up = Inf,
    score = 2L
  ),
  list(
    type = "concept",
    concept_set = "severe_chronic_kidney_disease",
    follow_up = Inf,
    score = 1L
  ),
  list(
    type = "concept",
    concept_set = "metastatic_solid_tumor",
    follow_up = Inf,
    score = 6L,
    group = "cancer"
  ),
  list(
    type = "concept",
    concept_set = "any_malignancy",
    follow_up = Inf,
    score = 2L,
    group = "cancer"
  ),
  list(
    type = "concept",
    concept_set = "aids",
    follow_up = Inf,
    score = 4L
  )
)

## Age adjusted updated Charlson ----
indexDefinitions$updated_charlson_age_adjusted <- c(
  indexDefinitions$updated_charlson,
  list(
    list(
      type = "age_group",
      name_style = "age_group",
      age_groups = list(
        list(
          label = "50 to 59",
          age_range = c(50, 59),
          score = 1L
        ),
        list(
          label = "60 to 69",
          age_range = c(60, 69),
          score = 2L
        ),
        list(
          label = "70 to 79",
          age_range = c(70, 79),
          score = 3L
        ),
        list(
          label = "80 or over",
          age_range = c(80, Inf),
          score = 4L
        )
      )
    )
  )
)

## Hospital Frailty Risk Score ----
hfrsData <- readr::read_csv(
  "inst/hospital_frailty_risk_score.csv",
  col_types = c(concept_set = "c", points = "d", icd10_code = "c", icd_description = "c")
)
indexDefinitions$hospital_frailty_risk_score <- hfrsData |>
  purrr::pmap(\(concept_set, points, ...) {
    list(
      type = "concept",
      concept_set = concept_set,
      follow_up = 730,
      score = points
    )
  })

## Electronic Frailty Index ----
indexDefinitions$electronic_frailty_index <- c(
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
) |>
  purrr::map(\(x) {
    list(
      type = "concept",
      concept_set = x,
      follow_up = Inf,
      score = 1/36
    )
  }) |>
  c(list(list(
    type = "polypharmacy",
    name_style = "polypharmacy_categories",
    overlap = TRUE,
    follow_up = 365,
    drug_group = "ingredient drug_era",
    drug_groups = list(
      list(
        label = "5 or more",
        drug_range = c(5, Inf),
        score = 1/36
      )
    )
  )))

## Electronic Frailty Index 2 ----
# efi2 <- c(
#   activity_limitation = 0.15284 / 8.429,
#   alcohol_harmful_intake = 0.23107 / 8.429,
#   alcohol_missing = 0.13175 / 8.429,
#   alcohol_previous_harmful_higher = 1.36434 / 8.429,
#   atrial_fibrillation = 0.13025 / 8.429,
#   cancer = 0.2406 / 8.429,
#   cognitive_impairment = 0.10985 / 8.429,
#   copd = 0.11683 / 8.429,
#   dementia = 0.41715 / 8.429,
#   dressing_grooming_problems = 0.05422 / 8.429,
#   environment_problems = 0.11886 / 8.429,
#   falls = 0.62743 / 8.429,
#   fracture = 0.07353 / 8.429,
#   fragility_fracture = 0.17425 / 8.429,
#   heart_failure = 0.11086 / 8.429,
#   housebound = 0.33254 / 8.429,
#   hypotension_syncope = 0.18253 / 8.429,
#   liver_problems = 0.23787 / 8.429,
#   medication_management_problems = 0.32125 / 8.429,
#   memory_concerns = 0.11915 / 8.429,
#   mobility_problems = 0.46836 / 8.429,
#   motor_neuron_disease = 0.35347 / 8.429,
#   palliative_care = 0.5145 / 8.429,
#   parkinsonism_tremor = 0.03537 / 8.429,
#   peptic_ulcer = 0.05427 / 8.429,
#   peripheral_vascular_disease = 0.02672 / 8.429,
#   care_requirement = 0.21428 / 8.429,
#   respiratory_disease = 0.01049 / 8.429,
#   seizures = 0.02885 / 8.429,
#   self_harm = 0.009 / 8.429,
#   skin_ulcer = 0.21935 / 8.429,
#   smoker_current = 0.10291 / 8.429,
#   social_vulnerability = 0.23585 / 8.429,
#   stroke = 0.10565 / 8.429,
#   transient_ischemic_attack = 0.02305 / 8.429,
#   weight_loss_anorexia = 0.19256 / 8.429
# )
#
# indexDefinitions$electronic_frailty_index_2 <- list(
#   components = c(
#     conceptComponents(as.list(efi2)),
#     list(
#       bmi = list(
#         type = "bmi", window = c(-Inf, 0), order = "last",
#         score = list(
#           missing = list(missing = TRUE, score = 0.25318 / 8.429),
#           underweight = list(range = c(-Inf, 18.5), upperInclusive = FALSE,
#                              score = 0.4417 / 8.429)
#         )
#       ),
#       polypharmacy = list(
#         type = "polypharmacy", window = c(-365, 0), overlap = TRUE,
#         drugGroup = "ingredient drug_era",
#         score = list(
#           ten_or_more = list(range = c(10, Inf), score = 0.50801 / 8.429),
#           five_to_nine = list(range = c(5, 9), score = 0.32301 / 8.429)
#         )
#       )
#     )
#   ),
#   groupRule = "maximum",
#   ageAdjustment = NULL
# )

requiredConcepts <- purrr::map(indexDefinitions, getNeededConcepts)

# Internal concepts ----
cdm <- omock::mockCdmFromDataset(datasetName = "delphi-100k")
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

# Save canonical definitions and internal concepts
usethis::use_data(
  indexDefinitions, internalConcepts, internal = TRUE, overwrite = TRUE
)
