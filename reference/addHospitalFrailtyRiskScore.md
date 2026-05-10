# Add the hospital frailty risk score as defined in Gilbert et al: <https://doi.org/10.1016/S0140-6736(18)30668-8>

Add the hospital frailty risk score as defined in Gilbert et al:
<https://doi.org/10.1016/S0140-6736(18)30668-8>

## Usage

``` r
addHospitalFrailtyRiskScore(
  x,
  indexDate = "cohort_start_date",
  window = c(-365, 0),
  conceptSet = NULL,
  categories = list(low = c(0, 5), intermediate = c(5, 15), high = c(15, Inf)),
  nameStyle = "hfrs",
  name = tableName(x)
)
```

## Arguments

- x:

  A `cdm_table` object, it mus contain `person_id` or `subject_id` as
  columns.

- indexDate:

  A character string that points to a `Date` column in the `x` table.

- window:

  Window to asses `hospital frailty risk score` in, it must be a vector
  of two numeric values `c(min, max)`. Window times refer to days since
  `indexDate`.

- conceptSet:

  It can either be a , \<codelist_with_details\> or
  \<concept_set_expression\> object. It must contain
  `abnormal_results_of_function_studies`,
  `abnormalities_of_gait_and_mobility`, `abnormalities_of_heart_beat`,
  `acute_renal_failure`,
  `agent_resistant_to_penicillin_and_related_antibiotics`,
  `alzheimers_disease`, `artificial_opening_status`,
  `blindness_and_low_vision`, `calculus_of_kidney_and_ureter`,
  `care_involving_use_of_rehabilitation_procedures`,
  `carrier_of_infectious_disease`, `cellulitis`, `cerebral_infarction`,
  `cerebral_ischaemic_attacks`, `chronic_renal_failure`,
  `cognitive_functions_and_awareness`,
  `convulsions_not_elsewhere_classified`, `decubitus_ulcer`,
  `deficiency_of_other_b_group_vitamins`,
  `degenerative_diseases_of_nervous_system`, `delirium`,
  `dementia_in_alzheimers_disease`,
  `dependence_on_enabling_machines_and_devices`, `depressive_episode`,
  `diarrhoea_and_gastroenteritis`, `disorders_of_kidney_and_ureter`,
  `disorders_of_mineral_metabolism`, `duodenal_ulcer`, `dysphagia`,
  `epilepsy`, `exposure_to_unspecified_factor`, `fall`,
  `fall_involving_bed`, `fall_on_and_from_stairs_and_steps`,
  `fever_of_unknown_origin`, `fluid_electrolyte_and_acid_base_balance`,
  `fracture_of_femur`, `fracture_of_lumbar_spine_and_pelvis`,
  `fracture_of_ribs_sternum_and_thoracic_spine`,
  `fracture_of_shoulder_and_upper_arm`,
  `gangrene_not_elsewhere_classified`,
  `general_sensations_and_perceptions`, `hemiplegia`, `hypotension`,
  `infections_of_skin`, `intracranial_injury`,
  `mental_and_behavioural_disorders_due_to_use_of_alcohol`,
  `nausea_and_vomiting`,
  `nervous_and_musculoskeletal_systems_r_29_6_tendency_to_fall`,
  `nosocomial_condition`, `open_wound_of_forearm`, `open_wound_of_head`,
  `osteoporosis_with_pathological_fracture`,
  `osteoporosis_without_pathological_fracture`,
  `other_abnormal_findings_of_blood_chemistry`, `other_anaemias`,
  `other_and_unspecified_injuries_of_head`, `other_arthrosis`,
  `other_bacterial_agents`, `other_bacterial_intestinal_infections`,
  `other_cerebrovascular_diseases`,
  `other_diseases_of_digestive_system`,
  `other_disorders_of_pancreatic_internal_secretion`,
  `other_disorders_of_urinary_system`, `other_fall_on_same_level`,
  `other_functional_intestinal_disorders`, `other_hearing_loss`,
  `other_joint_disorders_not_elsewhere_classified`,
  `other_medical_procedures`,
  `other_noninfective_gastroenteritis_and_colitis`, `other_septicaemia`,
  `other_soft_tissue_disorders_not_elsewhere_classified`,
  `parkinsons_disease`,
  `personal_history_of_other_diseases_and_conditions`,
  `personal_history_of_risk_factors`, `pneumonia_organism_unspecified`,
  `pneumonitis_due_to_solids_and_liquids`, `polyarthrosis`,
  `problems_related_to_care_provider_dependency`,
  `problems_related_to_life_management_difficulty`,
  `problems_related_to_medical_facilities_and_other_health_care`,
  `problems_related_to_social_environment`,
  `prosthetic_devices_implants`,
  `respiratory_failure_not_elsewhere_classified`, `retention_of_urine`,
  `scoliosis`, `senility`, `sequelae_of_cerebrovascular_disease`,
  `somnolence_stupor_and_coma`,
  `speech_disturbances_not_elsewhere_classified`,
  `spinal_stenosis_secondary_code_only`,
  `streptococcus_and_staphylococcus`, `superficial_injury_of_head`,
  `superficial_injury_of_lower_leg`,
  `symptoms_and_signs_concerning_food_and_fluid_intake`,
  `symptoms_and_signs_involving_emotional_state`,
  `syncope_and_collapse`, `thyrotoxicosis_hyperthyroidism`,
  `ulcer_of_lower_limb_not_elsewhere_classified`,
  `unknown_and_unspecified_causes_of_morbidity`,
  `unspecified_acute_lower_respiratory_infection`,
  `unspecified_dementia`, `unspecified_fall`, `unspecified_haematuria`,
  `unspecified_renal_failure`, `unspecified_urinary_incontinence`,
  `vascular_dementia`, `vitamin_d_deficiency`, `volume_depletion` as
  concepts. If `NULL` concepts will be retrieved using the OmopConcepts
  package.

- categories:

  Named list of categories to group the values. If NULL the risk score
  is returned as numeric.

- nameStyle:

  A character string with the name of the new column.

- name:

  A character string with the name of the new table. If `NULL` a
  temporary table will be created.

## Value

The `x` table with a new column added with the hospital frailty risk
score of the patient.
