
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
  cdm[[name]] <- records |>
    OmopConstructor::collapseRecords(
      startDate = "cohort_start_date",
      endDate = "cohort_end_date",
      by = c("cohort_name"),
      gap = 1L,
      name = name
    )

  # create settings
  set <- dplyr::tibble(
    cohort_definition_id = as.integer(seq_along(categories)),
    cohort_name = names(categories)
  )
  q <- set |>
    purrr::pmap_chr(\(cohort_definition_id, cohort_name) {
      paste0(".data$cohort_name == '", cohort_name, "' ~ ", cohort_definition_id, "L")
    }) |>
    paste(collapse = ",") |>
    (\(x) paste0("dplyr::case_when(", x, ")"))() |>
    rlang::parse_exprs() |>
    rlang::set_names("cohort_definition_id")
  cdm[[name]] <- cdm[[name]] |>
    dplyr::mutate(!!!q) |>
    dplyr::select(!"cohort_name") |>
    dplyr::compute(name = name) |>
    omopgenerics::newCohortTable(
      cohortSetRef = set,
      cohortAttritionRef = NULL,
      cohortCodelistRef = NULL # TODO add codelists??
    )

  return(cdm[[name]])
}
