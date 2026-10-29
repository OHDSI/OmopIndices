
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

  # apply formula and categories

  # erafy

}
