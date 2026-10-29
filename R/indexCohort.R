
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

  # get individuals of interest
  pref <- omopgenerics::tmpPrefix()
  if (!is.null(subsetCohort)) {
    subset <- cdm[[subsetCohort]] |>
      PatientProfiles::filterCohortId(cohortId = {{subsetCohortId}}) |>
      dplyr::distinct(.data$subject_id) |>
      dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))
  } else {
    subset <- cdm$person |>
      dplyr::select("person_id")
  }

  # get the record per component
  records  <- list()
  for (i in seq_along(component)) {
    comp <- component[[i]]
    if (comp$type == "age_group") {
      record[[i]] <- ageGroupRecords(cdm, ageGroup, pref, subset)
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

ageGroupRecords <- function(cdm, ageGroup, pref, subset) {
  # internal prefix
  ip <- omopgenerics::tmpPrefix()

  # add observation periods
  subset <- subset |>
    dplyr::inner_join(
      cdm$observation_period |>
        dplyr::select(
          "person_id",
          "observation_period_start_date",
          "observation_period_end_date"
        ),
      by = "person_id"
    ) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))

  # get dates of interest
  ageGroup <- ageGroup |>
    purrr::map(\(ag) suppressWarnings(as.integer(ag)))
  birthdays <- ageGroup |>
    purrr::map(\(ag) {ag + c(0L, 1L)}) |>
    unlist(use.names = FALSE) |>
    unique() |>
    purrr::keep(\(x) !is.na(x))
  for (bd in birthdays) {
    subset <- subset |>
      PatientProfiles::addBirthday(
        birthday = bd,
        birthdayName = sprintf("bd_%i", bd),
        name = omopgenerics::uniqueTableName(prefix = ip)
      )
  }

  # filter to contribution of interest
  ageGroupRecords <- ageGroup |>
    purrr::imap(\(ag, nm) {
      if (is.na(ag[1])) {
        q <- ".data$observation_period_start_date"
      } else {
        q <- sprintf(
          "dplyr::if_else(
            .data$observation_period_start_date < .data$bd_%i,
            .data$bd_%i,
            .data$observation_period_start_date
          )", ag[1], ag[1]
        )
      }
      if (is.na(ag[2])) {
        q <- c(q, ".data$observation_period_end_date")
      } else {
        q <- c(q, sprintf(
          "dplyr::if_else(
            .data$observation_period_end_date > as.Date(clock::add_days(.data$bd_%i, -1L)),
            as.Date(clock::add_days(.data$bd_%i, -1L)),
            .data$observation_period_start_date
          )", ag[2] + 1, ag[2] + 1
        ))
      }
      q <- c(q, paste0('"', nm, '"')) |>
        rlang::parse_exprs() |>
        rlang::set_names(c("cohort_start_date", "cohort_end_date", "cohort_name"))

      subset |>
        dplyr::mutate(!!!q) |>
        dplyr::filter(.data$cohort_start_date <= .data$cohort_end_date) |>
        dplyr::select("person_id", "cohort_start_date", "cohort_end_date", "cohort_name") |>
        dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))
    }) |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))

  # drop created tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  return(ageGroupRecords)
}
