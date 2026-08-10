# Add Charlson Comorbidity Index (CCI) value based on [Charlson et al. (1987)](https://doi.org/10.1016/0021-9681(87)90171-8) and [Charlson et al. (1994)](https://doi.org/10.1016/0895-4356(94)90129-5) (age-adjusted) version.

Add Charlson Comorbidity Index (CCI) value based on [Charlson et al.
(1987)](https://doi.org/10.1016/0021-9681(87)90171-8) and [Charlson et
al. (1994)](https://doi.org/10.1016/0895-4356(94)90129-5) (age-adjusted)
version.

## Usage

``` r
addCharlsonIndex(
  x,
  indexDate = "cohort_start_date",
  ageAdjusted = TRUE,
  window = c(-Inf, 0),
  conceptSet = getIndexCodelist("charlson"),
  nameStyle = "charlson_index",
  categories = NULL,
  name = tableName(x)
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- indexDate:

  A character string that points to a `Date` column in the `x` table.

- ageAdjusted:

  Whether to calculate the Age-Adjusted Comorbidity Index (TRUE) or not
  (FALSE)

- window:

  Window to asses `Charlson index` in, it must be a vector of two
  numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `c("myocardial_infarction", "congestive_heart_failure", "peripheral_vascular_disease", "cerebrovascular_disease", "dementia", "chronic_pulmonary_disease", "connective_tissue_disease", "peptic_ulcer_disease", "mild_liver_disease", "diabetes_without_complication", "hemiplegia", "severe_chronic_kidney_disease", "diabetes_with_complication", "any_malignancy", "moderate_or_severe_liver_disease", "metastatic_solid_tumor", "aids")`,
  `c("congestive_heart_failure", "dementia", "chronic_pulmonary_disease", "connective_tissue_disease", "mild_liver_disease", "hemiplegia", "severe_chronic_kidney_disease", "diabetes_with_complication", "any_malignancy", "moderate_or_severe_liver_disease", "metastatic_solid_tumor", "aids")`,
  `c("abnormal_results_of_function_studies", "abnormalities_of_gait_and_mobility", "abnormalities_of_heart_beat", "acute_renal_failure", "agent_resistant_to_penicillin_and_related_antibiotics", "alzheimers_disease", "artificial_opening_status", "blindness_and_low_vision", "calculus_of_kidney_and_ureter", "care_involving_use_of_rehabilitation_procedures", "carrier_of_infectious_disease", "cellulitis", "cerebral_infarction", "cerebral_ischaemic_attacks", "chronic_renal_failure", "cognitive_functions_and_awareness", "convulsions_not_elsewhere_classified", "decubitus_ulcer", "deficiency_of_other_b_group_vitamins", "degenerative_diseases_of_nervous_system", "delirium", "dementia_in_alzheimers_disease", "dependence_on_enabling_machines_and_devices", "depressive_episode", "diarrhoea_and_gastroenteritis", "disorders_of_kidney_and_ureter", "disorders_of_mineral_metabolism", "duodenal_ulcer", "dysphagia", "epilepsy", "exposure_to_unspecified_factor", "fall", "fall_involving_bed", "fall_on_and_from_stairs_and_steps", "fever_of_unknown_origin", "fluid_electrolyte_and_acid_base_balance", "fracture_of_femur", "fracture_of_lumbar_spine_and_pelvis", "fracture_of_ribs_sternum_and_thoracic_spine", "fracture_of_shoulder_and_upper_arm", "gangrene_not_elsewhere_classified", "general_sensations_and_perceptions", "hemiplegia", "hypotension", "infections_of_skin", "intracranial_injury", "mental_and_behavioural_disorders_due_to_use_of_alcohol", "nausea_and_vomiting", "nervous_and_musculoskeletal_systems_r_29_6_tendency_to_fall", "nosocomial_condition", "open_wound_of_forearm", "open_wound_of_head", "osteoporosis_with_pathological_fracture", "osteoporosis_without_pathological_fracture", "other_abnormal_findings_of_blood_chemistry", "other_anaemias", "other_and_unspecified_injuries_of_head", "other_arthrosis", "other_bacterial_agents", "other_bacterial_intestinal_infections", "other_cerebrovascular_diseases", "other_diseases_of_digestive_system", "other_disorders_of_pancreatic_internal_secretion", "other_disorders_of_urinary_system", "other_fall_on_same_level", "other_functional_intestinal_disorders", "other_hearing_loss", "other_joint_disorders_not_elsewhere_classified", "other_medical_procedures", "other_noninfective_gastroenteritis_and_colitis", "other_septicaemia", "other_soft_tissue_disorders_not_elsewhere_classified", "parkinsons_disease", "personal_history_of_other_diseases_and_conditions", "personal_history_of_risk_factors", "pneumonia_organism_unspecified", "pneumonitis_due_to_solids_and_liquids", "polyarthrosis", "problems_related_to_care_provider_dependency", "problems_related_to_life_management_difficulty", "problems_related_to_medical_facilities_and_other_health_care", "problems_related_to_social_environment", "prosthetic_devices_implants", "respiratory_failure_not_elsewhere_classified", "retention_of_urine", "scoliosis", "senility", "sequelae_of_cerebrovascular_disease", "somnolence_stupor_and_coma", "speech_disturbances_not_elsewhere_classified", "spinal_stenosis_secondary_code_only", "streptococcus_and_staphylococcus", "superficial_injury_of_head", "superficial_injury_of_lower_leg", "symptoms_and_signs_concerning_food_and_fluid_intake", "symptoms_and_signs_involving_emotional_state", "syncope_and_collapse", "thyrotoxicosis_hyperthyroidism", "ulcer_of_lower_limb_not_elsewhere_classified", "unknown_and_unspecified_causes_of_morbidity", "unspecified_acute_lower_respiratory_infection", "unspecified_dementia", "unspecified_fall", "unspecified_haematuria", "unspecified_renal_failure", "unspecified_urinary_incontinence", "vascular_dementia", "vitamin_d_deficiency", "volume_depletion")`,
  `c("activity_limitation", "anemia", "arthritis", "atrial_fibrillation", "cerebrovascular_disease", "chronic_kidney_disease", "diabetes", "dizziness", "dyspnea", "falls", "foot_problem", "fragility_fracture", "hearing_impairment", "heart_failure", "heart_valve_disorder", "housebound", "hypertension", "hypotension_syncope", "ischemic_heart_disease", "memory_cognitive_disorder", "mobility_problems", "osteoporosis", "parkinsonism_tremor", "peptic_ulcer", "peripheral_vascular_disease", "care_requirement", "respiratory_disease", "skin_ulcer", "sleep_disturbance", "social_vulnerability", "thyroid_disease", "urinary_incontinence", "urinary_system_disease", "visual_impairment", "weight_loss_anorexia")`,
  `c("activity_limitation", "alcohol_harmful_intake", "alcohol_missing", "alcohol_previous_harmful_higher", "atrial_fibrillation", "cancer", "cognitive_impairment", "copd", "dementia", "dressing_grooming_problems", "environment_problems", "falls", "fracture", "fragility_fracture", "heart_failure", "housebound", "hypotension_syncope", "liver_problems", "medication_management_problems", "memory_concerns", "mobility_problems", "motor_neuron_disease", "palliative_care", "parkinsonism_tremor", "peptic_ulcer", "peripheral_vascular_disease", "care_requirement", "respiratory_disease", "seizures", "self_harm", "skin_ulcer", "smoker_current", "social_vulnerability", "stroke", "transient_ischemic_attack", "weight_loss_anorexia", "bmi")`
  as concepts. By default internal concepts are used.

- nameStyle:

  A character string with the name of the new column.

- categories:

  Named list of categories to group the values. If NULL the risk score
  is returned as numeric.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The table `x` with a new column column with the corresponding Charlson
index value.

## Examples

``` r
{
library(OmopIndices)
library(omock)

cdm <- mockCdmFromDataset()
cdm <- cdm |>
 mockCohort()

conceptSet <- list(
 "myocardial_infarction" = 329847L,
 "congestive_heart_failure" = 319835L,
 "peripheral_vascular_disease" = 321052L,
 "cerebrovascular_disease" = 381591L,
 "dementia" = 4182210L,
 "chronic_pulmonary_disease" = 255573L,
 "connective_tissue_disease" = 4134537L,
 "peptic_ulcer_disease" = 4027663L,
 "mild_liver_disease" = 194984L,
 "moderate_or_severe_liver_disease" = 4212540L,
 "diabetes_without_complication" = 201820L,
 "diabetes_with_complication" = 42538715L,
 "hemiplegia" = 374022L,
 "severe_chronic_kidney_disease" = 46271022L,
 "any_malignancy" = 4180914L,
 "metastatic_solid_tumor" = 432851L,
 "aids" = 4267414L)

cdm$cohort |>
  addCharlsonIndex(conceptSet = conceptSet)
}
#> ℹ Loading bundled GiBleed tables from package data.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> Warning: 16 unique codelist concept IDs are not present in `cdm$concept`.
#> Warning: 16 unique codelist concept IDs are not present in `cdm$concept`.
#> ! 16 concept(s) from domain NA eliminated as it is not supported.
#> ℹ Supported domains are: device, specimen, measurement, drug, condition,
#>   observation, procedure, episode, and visit.
#> # A tibble: 2,694 × 5
#>    cohort_definition_id subject_id cohort_start_date cohort_end_date
#>  *                <int>      <int> <date>            <date>         
#>  1                    1          1 1992-08-21        2001-11-26     
#>  2                    1          2 1986-05-10        2000-03-13     
#>  3                    1          7 1971-04-25        1977-08-27     
#>  4                    1          9 1991-08-07        2003-06-27     
#>  5                    1          9 2009-09-14        2010-09-07     
#>  6                    1         11 1993-11-14        1999-06-12     
#>  7                    1         11 1999-06-13        2012-03-19     
#>  8                    1         12 2007-06-30        2010-06-05     
#>  9                    1         12 2010-06-06        2010-08-27     
#> 10                    1         16 1990-08-22        1994-07-07     
#> # ℹ 2,684 more rows
#> # ℹ 1 more variable: charlson_index <dbl>
```
