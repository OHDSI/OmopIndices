
addIndexFromKey <- function(x,
                            key,
                            indexDate,
                            window,
                            conceptSet,
                            categories,
                            nameStyle,
                            name,
                            call = parent.frame()) {
  addIndexInternal(
    x = x,
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    name = name,
    formula = fomulas[[key]],
    component = components[[key]],
    call = call
  )
}

addIndexInternal <- function(x,
                             indexDate,
                             window,
                             conceptSet,
                             categories,
                             nameStyle,
                             name,
                             formula,
                             component,
                             call) {
  # input validation
  x <- validateX(x, call = call)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- omopgenerics::validateColumn(indexDate, x, "date", call = call)
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE, call = call, empty = TRUE)
  component <- overwriteWindow(component, window, call)
  neededConcepts <- neededConceptSet(component)
  conceptSet <- validateConceptSet(conceptSet, neededConcepts, cdm, call = call)
  nameStyle <- validateNameStyle(nameStyle, x, call = call)
  x <- omopgenerics::validateNewColumn(x, nameStyle, call = call)
  name <- validateName(name, call = call)
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", null = TRUE, call = call)

  id <- omopgenerics::getPersonIdentifier(x)
  q <- formula |>
    rlang::set_names(nameStyle) |>
    rlang::parse_exprs()

  # distinct entries
  nm <- omopgenerics::uniqueTableName()
  index <- x |>
    dplyr::select(dplyr::any_of(c(id, indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm)
  on.exit(omopgenerics::dropSourceTable(cdm = cdm, name = nm))

  # check if index needs to be a cohort
  types <- purrr::map_chr(component, "type")
  if (any(c("cohort_flag", "measurement_flag") %in% types)) {
    indexCohort <- omopgenerics::uniqueTableName()
    cdm[[indexCohort]] <- index |>
      dplyr::rename(all_of(c("subject_id" = id, "cohort_start_date" = indexDate))) |>
      dplyr::mutate(
        cohort_definition_id = 1L,
        cohort_end_date = .data$cohort_start_date
      ) |>
      dplyr::compute(name = indexCohort) |>
      omopgenerics::newCohortTable(
        cohortSetRef = NULL,
        cohortAttritionRef = NULL,
        cohortCodelistRef = NULL,
        .softValidation = TRUE
      )
    on.exit(omopgenerics::dropSourceTable(cdm = cdm, name = indexCohort), add = TRUE)
  }

  # instantiate components
  for (comp in component) {
    if (comp$type == "age_group") {
      index <- index |>
        PatientProfiles::addDemographics(
          indexDate = indexDate,
          ageGroup = comp$ageGroup,
          age = FALSE,
          sex = FALSE,
          priorObservation = FALSE,
          futureObservation = FALSE,
          dateOfBirth = FALSE,
          name = nm
        )
    } else if (comp$type == "polypharmacy") {
      index <- index |>
        addPolypharmacy(
          indexDate = indexDate,
          window = comp$window,
          overlap = comp$overlap,
          name = nm
        )
    } else if (comp$type == "concept_flag") {
      index <- index |>
        PatientProfiles::addConceptIntersectFlag(
          indexDate = indexDate,
          conceptSet = conceptSet[comp$conceptSet],
          window = comp$window,
          name = nm
        )
    } else if (comp$type %in% c("measurement_flag", "cohort_flag")) {
      # instantiate cohort
      tmpCohort <- omopgenerics::uniqueTableName()

      if (comp$type == "measurement_flag") {
        cdm[[tmpCohort]] <- CohortConstructor::measurementCohort(
          cdm = cdm,
          conceptSet = comp$conceptSet,
          name = tmpCohort,
          valueAsConcept = comp$valueAsConcept,
          valueAsNumber = comp$valueAsNumber,
          subsetCohort = indexCohort
        )
      } else {
        cdm[[tmpCohort]] <- CohortConstructor::conceptCohort(
          cdm = cdm,
          conceptSet = comp$conceptSet,
          name = tmpCohort,
          exit = "event_start_date",
          subsetCohort = indexCohort
        )
        # apply requirements
        req <- comp$requirements
        if (!is.null(req$ageRange)) {
          cdm[[tmpCohort]] <- cdm[[tmpCohort]] |>
            CohortConstructor::requireAge(ageRange = req$ageRange)
        }
      }

      # join with index
      index <- index |>
        PatientProfiles::addCohortIntersectFlag(
          indexDate = indexDate,
          targetCohortTable = tmpCohort,
          window = comp$window,
          name = nm
        )

      # drop tmp cohorts
      omopgenerics::dropSourceTable(cdm = cdm, name = tmpCohort)
    }
  }

  # apply formula
  index <- index |>
    dplyr::mutate(!!nameStyle := !!!formula) |>
    dplyr::select(dplyr::all_of(c(id, indexDate, nameStyle))) |>
    dplyr::compute(name = nm)

  # apply categories
  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(paste0(nameStyle, "_categories")) |>
      rlang::parse_exprs()
    index <- index |>
      dplyr::mutate(!!!qc) |>
      dplyr::compute(name = nm)
  }

  # left join back to original table
  x <- x |>
    dplyr::inner_join(index, by = c(id, indexDate)) |>
    dplyr::compute(name = name)

  return(x)
}

overwriteWindow <- function(component, window, call) {
  if (length(window) == 1) {
    cli::cli_inform(c("!" = "Overwritting window settings."))
    component <- component |>
      purrr::map(\(x) {
        if ("window" %in% names(x)) {
          x$window <- window
        }
        return(x)
      })
  } else if (length(window) > 1) {
    cli::cli_abort(c(x = "Only one window can be supplied."), call = call)
  }
  return(component)
}
neededConceptSet <- function(component) {
  component |>
    purrr::map(\(x) {
      if ("conceptSet" %in% names(x)) {
        x$conceptSet
      } else {
        NULL
      }
    }) |>
    purrr::flatten_chr()
}

addIndex <- function(x,
                     type,
                     indexDate,
                     window,
                     conceptSet,
                     categories,
                     nameStyle,
                     ageAdjusted,
                     name,
                     call = parent.frame()) {
  # initial checks
  x <- validateX(x, call = call)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- omopgenerics::validateColumn(indexDate, x, "date", call = call)
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE, call = call)[[1]]
  formulaKey <- paste0(type, ifelse(ageAdjusted, "_age_adjusted", ""))
  formula <- formulas[[formulaKey]]

  conceptSet <- validateConceptSet(conceptSet, type, cdm, call = call)
  nameStyle <- validateNameStyle(nameStyle, x, call = call)
  x <- omopgenerics::validateNewColumn(x, nameStyle, call = call)
  name <- validateName(name, call = call)
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", null = TRUE, call = call)

  id <- omopgenerics::getPersonIdentifier(x)
  q <- formula |>
    rlang::set_names(nameStyle) |>
    rlang::parse_exprs()

  # calculate score
  nm <- omopgenerics::uniqueTableName()
  index <- x |>
    dplyr::select(dplyr::any_of(c(id, indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm) |>
    PatientProfiles::addConceptIntersectFlag(
      conceptSet = conceptSet,
      indexDate = indexDate,
      window = window,
      name = nm,
      nameStyle = "{concept_name}"
    )

  if (type %in% c("updated_charlson", "charlson") & isTRUE(ageAdjusted)) {
    index <- index |>
      PatientProfiles::addAge(
        indexDate = indexDate,
        ageGroup = list("g1"= c(0, 49), "g2" = c(50, 59), "g3" = c(60, 69), "g4" = c(70, 79), "g5" = c(80, Inf)),
        name = nm
      )
  } else if (type %in% c("electronic_frailty_index", "electronic_frailty_index_2")) {
    # TODO use internal functions to skip validation
    index <- index |>
      addPolypharmacy(
        indexDate = indexDate,
        window = c(-365, 0),
        nameStyle = "polypharmacy",
        name = nm
      )
  }
  if (type == "electronic_frailty_index_2") {
    index <- index |>
      addBMI(
        indexDate = indexDate,
        conceptSet = conceptSet,
        window = window,
        nameStyle = "bmi",
        name = nm
      )
  }

  index <- index |>
    dplyr::mutate(!!!q) |>
    dplyr::select(dplyr::all_of(c(id, indexDate, nameStyle))) |>
    dplyr::compute(name = nm)

  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(paste0(nameStyle, "_categories")) |>
      rlang::parse_exprs()
    index <- index |>
      dplyr::mutate(!!!qc) |>
      dplyr::compute(name = nm)
  }

  # add index to x
  x <- x |>
    dplyr::inner_join(index, by = c(id, indexDate)) |>
    dplyr::compute(name = name)

  # drop intermediate table
  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  return(x)
}
qCategories <- function(categories) {
  q <- categories |>
    purrr::imap_chr(\(win, nm) {
      paste0(windowCondition(win), " ~ '", nm, "'")
    }) |>
    paste0(collapse = ", ")
  paste0(
    "dplyr::case_when(",
    "is.na(.data[[nameStyle]]) ~ 'missing',",
    q,
    ")"
  )
}
windowCondition <- function(window) {
  if (is.infinite(window[2])) {
    paste0(window[1], " <= .data[[nameStyle]]")
  } else {
    paste0(window[1], " <= .data[[nameStyle]] & .data[[nameStyle]] <= ", window[2])
  }
}
