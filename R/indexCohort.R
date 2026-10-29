
indexCohort <- function(cdm,
                        formula,
                        component,
                        categories,
                        name,
                        conceptSet,
                        subsetCohort,
                        subsetCohortId,
                        call = parent.frame()) {
  # input check
  cdm <- omopgenerics::validateCdmArgument(cdm = cdm, call = call)
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", call = call)
  name <- omopgenerics::validateNameArgument(name = name, cdm = cdm, call = call)
  neededConcepts <- neededConceptSet(component)
  conceptSet <- validateConceptSet(conceptSet, neededConcepts, cdm, call = call)
  omopgenerics::assertCharacter(subsetCohort, null = TRUE, call = call)
  if (!is.null(subsetCohort)) {
    subsetCohortId <- omopgenerics::validateCohortIdArgument(
      cohortId = {{subsetCohortId}},
      cohort = cdm[[subsetCohort]],
      call = call
    )
  }

  # get the record per component
  pref <- omopgenerics::tmpPrefix()
  records  <- list()
  for (comp in component) {
    if (comp$type == "age_group") {

    } else if (comp$type == "polypharmacy") {

    } else if (comp$type == "bmi") {

    } else if (comp$type == "concept_flag") {

    } else if (comp$type %in% c("measurement_flag", "cohort_flag")) {
      if (comp$type == "measurement_flag") {

      } else {

      }
    }
  }

  # join all records
  nm <- omopgenerics::uniqueTableName()
  records <- records |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = nm)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  # apply formula and categories

  # erafy

  return(cdm[[name]])
}
