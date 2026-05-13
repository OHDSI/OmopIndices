
addIndex <- function(x,
                     type,
                     indexDate,
                     window,
                     conceptSet,
                     categories,
                     nameStyle,
                     name,
                     call = parent.frame()) {
  # initial checks
  x <- validateX(x, call = call)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- omopgenerics::validateColumn(indexDate, x, "date", call = call)
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE, call = call)[[1]]
  if (type == "aers") {
    reqConcepts <- aersConcepts
    formula <- aersFormula
  } else if (type == "hfrs") {
    reqConcepts <- hfrsConcepts
    formula <- hfrsFormula
  } else if (type == "charlson") {
    reqConcepts <- charlsonConcepts
    formula <- charlsonFormula
  }
  conceptSet <- validateConceptSet(conceptSet, reqConcepts, cdm, call = call)
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

  if (type == "charlson") {
    index <- index |>
      PatientProfiles::addAge(
        indexDate = indexDate,
        ageGroup = list("g1"= c(0, 49), "g2" = c(50, 59), "g3" = c(60, 69), "g4" = c(70, 79), "g5" = c(80, Inf)),
        name = nm
      )
  } else if (type == "aers") {
    # TODO use internal functions to skip validation
    index <- index |>
      addPolypharmacyCount(
        indexDate = indexDate,
        window = window,
        nameStyle = "polypharmacy_count"
      )
  }

  index <- index |>
    dplyr::mutate(!!!q)

  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(nameStyle) |>
      rlang::parse_exprs()
    index <- index |>
      dplyr::mutate(!!!qc)
  }

  index <- index |>
    dplyr::select(dplyr::all_of(c(id, indexDate, nameStyle))) |>
    dplyr::compute(name = nm)

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
    purrr::imap(\(win, nm) {
      paste0(windowCondition(win), " ~ '", nm, "'")
    }) |>
    paste0(", ")
  paste0("dplyr::case_when(", q, ")")
}
windowCondition <- function(window) {
  if (is.infinite(window[2])) {
    paste0(window[1], " <= .data[[nameStyle]]")
  } else {
    paste0(window[1], " <= .data[[nameStyle]] & .data[[nameStyle]] <= ", window[2])
  }
}
