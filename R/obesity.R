
#' Add obesity flag
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("obesity")`
#' @param conceptSet `r documentationConceptSet(c("obesity", "bmi"))`
#' @param bmiThreshold Argument to indicate the thresholds for the obesity using
#' BMI measurements. It can be:
#'
#' - A single number, any BMI measurement above the threshold will be consider
#' as an obesity record.
#' - A tibble with the columns `bmi_threshold`, `sex`, `age_min` and `age_max`,
#' to use age and sex specific thresholds.
#' - NULL the table `OmopIndexes::bmiThreshold` will be used.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column column indicating if subjects have
#' an obesity record in the window of interest.
#'
#' @export
#'
#' @examples
#' library(OmopIndexes)
#'
#'
#'
addObesity <- function(x,
                       indexDate = "cohort_start_date",
                       window = c(-Inf, 0),
                       conceptSet = NULL,
                       bmiThreshold = NULL,
                       nameStyle = "obesity",
                       name = tableName(x)) {
  # initial checks
  x <- validateX(x)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- validateIndexDate(indexDate, x)
  window <- validateWindow(window)
  conceptSet <- validateConceptSet(conceptSet, c("bmi", "obesity"), cdm)
  bmiThreshold <- validateBmiThreshold(bmiThreshold)
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)

  id <- omopgenerics::getPersonIdentifier(x = x)

  pref <- omopgenerics::tmpPrefix()
  nm1 <- omopgenerics::uniqueTableName(prefix = pref)
  nm2 <- omopgenerics::uniqueTableName(prefix = pref)

  # add flag for obesity
  flag <- x |>
    dplyr::select(dplyr::all_of(c("person_id" = id, "index_date" = indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm1) |>
    PatientProfiles::addConceptIntersectFlag(
      conceptSet = conceptSet["obesity"],
      indexDate = "index_date",
      window = window,
      nameStyle = "obesity",
      name = nm1
    )

  bmi <- flag |>
    dplyr::filter(.data$obesity == 0)

  # if we have a tibble we need age and sex as columns
  if (!is.numeric(bmiThreshold)) {
    bmi <- bmi |>
      PatientProfiles::addDemographics(
        indexDate = "index_date",
        priorObservation = FALSE,
        futureObservation = FALSE,
        name = nm1
      )
  }

  # retrieve bmi measurements
  bmi <- bmi |>
    dplyr::inner_join(
      cdm$measurement |>
        dplyr::filter(.data$measurement_concept_id %in% !!conceptSet[["bmi"]]) |>
        dplyr::select("person_id", "measurement_date", bmi = "value_as_number"),
      by = "person_id"
    ) |>
    filterWindow("index_date", "measurement_date", window) |>
    dplyr::filter(!is.na(.data$bmi)) |>
    dplyr::select("person_id", "index_date", "bmi", dplyr::any_of(c("age", "sex"))) |>
    dplyr::compute(name = nm2)
  if (is.numeric(bmiThreshold)) {
    bmi <- bmi |>
      dplyr::filter(.data$bmi >= .env$bmiThreshold) |>
      dplyr::distinct(.data$person_id, .data$index_date) |>
      dplyr::compute(name = nm2)
  } else {
    nm3 <- omopgenerics::uniqueTableName(prefix = pref)
    cdm <- omopgenerics::insertTable(cdm = cdm, name = nm3, table = bmiThreshold)
    bmi <- bmi |>
      dplyr::inner_join(cdm[[nm3]], by = c("age", "sex")) |>
      dplyr::filter(.data$bmi >= .data$bmi_threshold) |>
      dplyr::distinct(.data$person_id, .data$index_date) |>
      dplyr::compute(name = nm2)
  }

  # combine bmi and obesity flag
  sel <- c("person_id", "index_date") |>
    rlang::set_names(c(id, indexDate))
  q <- "dplyr::if_else(.data$bmi == 1 | .data$obesity == 1, 1L, 0L)" |>
    rlang::parse_exprs() |>
    rlang::set_names(nm = nameStyle)
  flag <- flag |>
    dplyr::left_join(
      bmi |>
        dplyr::mutate(bmi = 1L),
      by = c("person_id", "index_date")
    ) |>
    dplyr::mutate(!!!q) |>
    dplyr::select(dplyr::all_of(c(sel, nameStyle))) |>
    dplyr::compute(name = nm2)

  # add flag to main
  q <- "dplyr::coalesce(.data[[nameStyle]], 0L)" |>
    rlang::parse_exprs() |>
    rlang::set_names(nm = nameStyle)
  x <- x |>
    dplyr::left_join(flag, by = c(id, indexDate)) |>
    dplyr::mutate(!!!q) |>
    dplyr::compute(name = name)

  # drop intermediate tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  return(x)
}
filterWindow <- function(x, index, date, window) {
  if (is.infinite(window[1])) {
    if (!is.infinite(window[2])) {
      x <- x |>
        dplyr::filter(
          clock::date_count_between(start = .data[[index]], end = .data[[date]]) <= !!window[2]
        )
    }
  } else {
    if (is.infinite(window[2])) {
      x <- x |>
        dplyr::filter(
          clock::date_count_between(start = .data[[index]], end = .data[[date]]) >= !!window[1] &
            clock::date_count_between(start = .data[[index]], end = .data[[date]]) <= !!window[2]
        )
    } else {
      x <- x |>
        dplyr::filter(
          clock::date_count_between(start = .data[[index]], end = .data[[date]]) >= !!window[1]
        )
    }
  }
  return(x)
}
