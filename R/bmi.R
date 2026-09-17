
#' Add Body Mass Index measurement
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("BMI")`
#' @param conceptSet `r documentationConceptSet("bmi")`
#' @param order A character string specifying how to select among multiple BMI
#' measurements within the window: `last` (latest), `first` (earliest), `max`
#' (highest), or `min` (lowest).
#' @param categories A named list of numeric vectors, each containing the lower
#' and upper bounds of a BMI interval. An additional column named by appending
#' `_categories` to `nameStyle` is added, and missing BMI values are labelled
#' `missing`.
#' @inheritParams nameStyleDoc
#' @inheritParams inObservationDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column containing the selected BMI value.
#' @export
#'
#' @examples
#' \donttest{
#' library(omock)
#' library(duckdb)
#' library(OmopIndices)
#' library(dplyr)
#' library(CohortConstructor)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#' cdm$cohort <- conceptCohort(
#'   cdm = cdm,
#'   conceptSet = list(sinusitis = c(257012L, 4283893L, 4294548L, 40481087L)),
#'   name = "cohort"
#' )
#'
#' cdm$cohort |>
#'   addBMI(window = c(-365, 0), order = "last") |>
#'   select(subject_id, cohort_start_date, bmi) |>
#'   glimpse()
#' }
#'
addBMI <- function(x,
                   conceptSet = getIndexCodelist("body_mass_index"),
                   indexDate = "cohort_start_date",
                   window = c(-Inf, 0),
                   order = "last",
                   nameStyle = "bmi",
                   categories = NULL,
                   inObservation = TRUE,
                   name = tableName(x)) {
  # initial checks
  x <- validateX(x)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- validateIndexDate(indexDate, x)
  window <- validateWindow(window)
  window <- unlist(window)
  conceptSet <- validateConceptSet(conceptSet, "body_mass_index", cdm)
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)
  categories <- validateCategories(categories)
  omopgenerics::assertChoice(order, c("first", "last", "min", "max"))

  # person id
  id <- omopgenerics::getPersonIdentifier(x)

  # get records
  records <- x |>
    dplyr::select(dplyr::all_of(c(person_id = id, index_date = indexDate))) |>
    dplyr::distinct()

  # get bmi
  nm <- omopgenerics::uniqueTableName()
  bmiRecords <- tablesToSubset(conceptSet, cdm) |>
    getRecords(cdm, conceptSet, records, window, nm) |>
    subsetInObservation(inObservation, nm) |>
    subsetRecords(order, nm)

  # add bmi
  sel <- c("person_id", "index_date", "bmi") |>
    rlang::set_names(c(id, indexDate, nameStyle))
  x <- x |>
    dplyr::left_join(
      bmiRecords |>
        dplyr::select(dplyr::all_of(sel)),
      by = c(id, indexDate)
    ) |>
    dplyr::compute(name = name)

  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  # add categories
  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(paste0(nameStyle, "_categories")) |>
      rlang::parse_exprs()
    x <- x |>
      dplyr::mutate(!!!qc) |>
      dplyr::compute(name = name)
  }

  return(x)
}
tablesToSubset <- function(conceptSet, cdm) {
  cdm$concept |>
    dplyr::filter(.data$concept_id %in% .env$conceptSet$bmi) |>
    dplyr::distinct(.data$domain_id) |>
    dplyr::pull() |>
    tolower() |>
    purrr::keep(\(x) x %in% c("measurement", "observation"))
}
getRecords <- function(tables, cdm, conceptSet, records, window, nm) {
  if (length(tables) == 0) {
    cdm[[nm]] <- cdm$person |>
      dplyr::select("person_id") |>
      dplyr::filter(.data$person_id < 0) |>
      dplyr::mutate(
        index_date = as.Date(NA_character_),
        bmi_date = as.Date(NA_character_),
        bmi = NA_real_
      ) |>
      dplyr::compute(name = nm)
    return(cdm[[nm]])
  }
  tables |>
    purrr::map(\(x) {
      date <- omopgenerics::omopColumns(table = x, field = "start_date")
      concept <- omopgenerics::omopColumns(table = x, field = "standard_concept")
      rec <- cdm[[x]] |>
        dplyr::filter(
          .data[[concept]] %in% .env$conceptSet$bmi & !is.na(.data$value_as_number)
        ) |>
        dplyr::select(dplyr::all_of(c(
          "person_id", bmi_date = date, bmi = "value_as_number"
        ))) |>
        dplyr::inner_join(records, by = "person_id")
      if (!all(is.infinite(window))) {
        rec <- rec |>
          dplyr::mutate(date_diff = clock::date_count_between(
            start = .data$index_date, end = .data$bmi_date, precision = "day"
          )) |>
          filterWindow(diff = "date_diff", window = window)
      }
      return(rec)
    }) |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = nm)
}
subsetRecords <- function(x, order, nm) {
  for (ord in order) {
    q <- switch (
      order,
      "first" = ".data$bmi_date == min(.data$bmi_date, na.rm = TRUE)",
      "last" = ".data$bmi_date == max(.data$bmi_date, na.rm = TRUE)",
      "min" = ".data$bmi == min(.data$bmi, na.rm = TRUE)",
      "max" = ".data$bmi == max(.data$bmi, na.rm = TRUE)"
    ) |>
      rlang::parse_expr()
    x <- x |>
      dplyr::group_by(.data$person_id, .data$index_date) |>
      dplyr::filter(!!q) |>
      dplyr::distinct() |>
      dplyr::compute(name = nm)
  }

  # check multiple records
  multiple <- x |>
    dplyr::group_by(.data$person_id, .data$index_date) |>
    dplyr::summarise(n = dplyr::n(), .groups = "drop") |>
    dplyr::filter(.data$n > 1) |>
    dplyr::tally() |>
    dplyr::pull()

  if (multiple > 0) {
    mes <- "Multiple records observed despite the `order` argument, maximum value will be keept to ensure 1 record per `person` and `indexDate`"
    cli::cli_inform(c("!" = mes))
    cli::cli_warn(c("!" = mes))
    x <- x |>
      dplyr::group_by(.data$person_id, .data$index_date) |>
      dplyr::filter(.data$bmi == max(.data$bmi, na.rm = TRUE)) |>
      dplyr::distinct() |>
      dplyr::compute(name = nm)
  }

  return(x)
}
subsetInObservation <- function(x, inObservation, nm) {
  if (inObservation) {
    x <- x |>
      PatientProfiles::filterInObservation(indexDate = "bmi_date") |>
      dplyr::compute(name = nm)
  }
  return(x)
}
