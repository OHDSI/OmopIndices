
#' Add the adapted electronic risk score as defined in Politi et al:
#' <xxx>
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("adapted electronic risk score")`
#' @param conceptSet `r documentationConceptSet(frailtyConcepts)`
#' @param categories Named list of categories to group the values. If NULL the
#' risk score is returned as numeric.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The `x` table with a new column added with the adapted electronic
#' risk score of the patient.
#'
#' @export
#'
addAdaptedElectronicRiskScore <- function(x,
                                          indexDate = "cohort_start_date",
                                          window = c(-365, 0),
                                          conceptSet = NULL,
                                          categories = list(
                                            "fit" = c(0, 0.12),
                                            "mild" = c(0.12, 0.24),
                                            "moderate" = c(0.24, 0.36),
                                            "severe" = c(0.36, 1)
                                          ),
                                          nameStyle = "aers",
                                          name = tableName(x)) {
  addIndex(
    x = x,
    type = "aers",
    indexDate = indexDate,
    window = window,
    conceptSet = conceptSet,
    categories = categories,
    nameStyle = nameStyle,
    name = name
  )
}

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
  rs <- x |>
    dplyr::select(dplyr::any_of(c(id, indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm) |>
    PatientProfiles::addConceptIntersectFlag(
      conceptSet = conceptSet,
      indexDate = indexDate,
      window = window,
      name = nm,
      nameStyle = "{concept_name}"
    ) |>
    dplyr::mutate(!!!q)

  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(nameStyle) |>
      rlang::parse_exprs()
    rs <- rs |>
      dplyr::mutate(!!!qc)
  }

  rs <- rs |>
    dplyr::select(dplyr::all_of(c(id, indexDate, nameStyle))) |>
    dplyr::compute(name = nm)

  # add rs to x
  x <- x |>
    dplyr::inner_join(rs, by = c(id, indexDate)) |>
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

