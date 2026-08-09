
#' Add Electronic Frailty Index (eFI) value based Clegg et al. (2016) definition
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("electronic frailty index")`
#' @param conceptSet
#' `r documentationConceptSet(requiredConcepts$electronic_frailty_index)`
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The `x` table with a new column added with the eFI of the patient.
#'
#' @export
#' @examples{
#' library(OmopIndices)
#' library(omock)
#'
#' cdm <- mockCdmFromDataset()
#' cdm <- cdm |>
#'  mockCohort()
#'
#' conceptSet <- list(
#'    "activity_limitation" = 763723L,
#'    "anemia" = 439777L,
#'    "arthritis" = 4291025L,
#'    "atrial_fibrillation" = 313217L,
#'    "chronic_kidney_disease" = 46271022L,
#'    "cerebrovascular_disease" = 381591L,
#'    "dizziness" = 4223938L,
#'    "dyspnea" = 312437L,
#'    "falls" = 4059015L,
#'    "foot_problem" = 4101512L,
#'    "fragility_fracture" = 3170964L,
#'    "hearing_impairment" = 4234647L,
#'    "heart_failure" = 316139L,
#'    "heart_valve_disorder"  = 4281749L,
#'    "housebound" = 4052962L,
#'    "hypertension" = 319826L,
#'    "hypotension_syncope" = 316447L,
#'    "ischemic_heart_disease"  = 4185932L,
#'    "memory_cognitive_disorder" = 4304008L,
#'    "mobility_problems" =  4053076L,
#'    "osteoporosis" = 80502L,
#'    "parkinsonism_tremor" = 4140090L,
#'    "peptic_ulcer" = 4027663L,
#'    "peripheral_vascular_disease" = 321052L,
#'    "care_requirement" = 3661927L,
#'    "respiratory_disease" = 317009L,
#'    "skin_ulcer" = 4262920L,
#'    "sleep_disturbance" = 435524L,
#'    "social_vulnerability" = 4026161L,
#'    "diabetes" = 201820L,
#'    "thyroid_disease" = 4017052L,
#'    "urinary_incontinence" = 197672L,
#'    "urinary_system_disease" = 75865L,
#'    "visual_impairment" = 4265433L,
#'    "weight_loss_anorexia" = 436675L)
#'
#'# Polypharmacy is calculated internally using the function `addPolypharmacyCount()`,
#'# and is defined as individuals taking 5 or more medicines
#'
#' cdm$cohort |>
#'   addElectronicFrailtyIndex(conceptSet = conceptSet)
#'    }
addElectronicFrailtyIndex <- function(x,
                                      indexDate = "cohort_start_date",
                                      window = c(-365, 0),
                                      conceptSet = getIndexCodelist("electronic_frailty_index"),
                                      categories = list(
                                        "fit" = c(0, 0.12),
                                        "mild" = c(0.12, 0.24),
                                        "moderate" = c(0.24, 0.36),
                                        "severe" = c(0.36, 1)
                                      ),
                                      nameStyle = "efi",
                                      name = tableName(x)) {
  addIndex(
    x = x,
    type = "efi",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    ageAdjusted = FALSE,
    name = name
  )
}
