addMeasurementInternal <- function(x, indexDate, conceptSet, comp, name) {
  id <- omopgenerics::getPersonIdentifier(x)
  cdm <- omopgenerics::cdmReference(x)
  records <- x |>
    dplyr::select(dplyr::all_of(c(person_id = id, index_date = indexDate))) |>
    dplyr::distinct()

  nm <- omopgenerics::uniqueTableName()
  on.exit(omopgenerics::dropSourceTable(cdm = cdm, name = nm))
  measurements <- getMeasurementRecords(
    cdm, conceptSet[[comp$conceptSet]], records, unlist(comp$window), nm
  )
  if (comp$inObservation) {
    measurements <- measurements |>
      PatientProfiles::filterInObservation(indexDate = "measurement_date")
  }

  # Raw values and scoring bands share the same record selection.
  valueColumn <- "value_as_number"
  if (is.null(comp$measurementGroups)) {
    measurements <- measurements |>
      dplyr::filter(!is.na(.data$value_as_number))
  } else {
    measurements <- measurements |>
      categoriseMeasurements(comp$measurementGroups, conceptSet)
    valueColumn <- "measurement_label"
  }

  # Select the latest date, then resolve same-day ties.
  measurements <- measurements |>
    dplyr::group_by(.data$person_id, .data$index_date) |>
    dplyr::slice_max(.data$measurement_date, n = 1, with_ties = TRUE)
  if (identical(comp$tie, "max")) {
    measurements <- measurements |>
      dplyr::slice_max(.data$value_as_number, n = 1, with_ties = FALSE)
  } else if (identical(comp$tie, "min")) {
    measurements <- measurements |>
      dplyr::slice_min(.data$value_as_number, n = 1, with_ties = FALSE)
  } else {
    labels <- unlist(comp$tie, use.names = FALSE)
    priority <- purrr::imap(labels, \(label, i) {
      rlang::expr(.data$measurement_label == !!label ~ !!i)
    })
    measurements <- measurements |>
      dplyr::mutate(measurement_priority = dplyr::case_when(
        !!!priority, .default = !!length(labels) + 1L
      )) |>
      dplyr::slice_min(.data$measurement_priority, n = 1, with_ties = FALSE)
  }

  columns <- c("person_id", "index_date", valueColumn) |>
    rlang::set_names(c(id, indexDate, comp$nameStyle))
  x |>
    dplyr::left_join(
      measurements |>
        dplyr::ungroup() |>
        dplyr::select(dplyr::all_of(columns)),
      by = c(id, indexDate)
    ) |>
    dplyr::compute(name = name)
}

getMeasurementRecords <- function(cdm, conceptIds, records, window, name) {
  tables <- cdm$concept |>
    dplyr::filter(.data$concept_id %in% .env$conceptIds) |>
    dplyr::distinct(.data$domain_id) |>
    dplyr::pull() |>
    tolower() |>
    purrr::keep(\(x) x %in% c("measurement", "observation"))
  valueColumns <- list(
    value_as_number = NA_real_,
    value_as_concept_id = NA_integer_,
    unit_concept_id = NA_integer_
  )
  if (length(tables) == 0) {
    return(records |>
      dplyr::filter(FALSE) |>
      dplyr::mutate(measurement_date = as.Date(NA_character_), !!!valueColumns) |>
      dplyr::compute(name = name))
  }

  tables |>
    purrr::map(\(table) {
      date <- omopgenerics::omopColumns(table, "start_date")
      concept <- omopgenerics::omopColumns(table, "standard_concept")
      missingColumns <- valueColumns[setdiff(names(valueColumns), colnames(cdm[[table]]))]
      rec <- cdm[[table]] |>
        dplyr::filter(.data[[concept]] %in% .env$conceptIds) |>
        dplyr::mutate(!!!missingColumns) |>
        dplyr::select(dplyr::all_of(c(
          "person_id", measurement_date = date, names(valueColumns)
        ))) |>
        dplyr::inner_join(records, by = "person_id")
      if (!all(is.infinite(window))) {
        rec <- rec |>
          dplyr::mutate(date_diff = clock::date_count_between(
            start = .data$index_date, end = .data$measurement_date, precision = "day"
          )) |>
          filterWindow(diff = "date_diff", window = window) |>
          dplyr::select(-"date_diff")
      }
      rec
    }) |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = name)
}

categoriseMeasurements <- function(x, groups, conceptSet) {
  # Reject units before selecting a date. Bands without units accept any unit.
  if (all(purrr::map_lgl(groups, \(band) !is.null(band$measurement_unit)))) {
    units <- unique(unlist(purrr::map(groups, "measurement_unit")))
    x <- x |>
      dplyr::filter(.data$unit_concept_id %in% .env$units)
  }

  conditions <- purrr::map(groups, \(band) {
    condition <- rlang::expr(TRUE)
    if (!is.null(band$measurement_value)) {
      condition <- rlang::expr(!is.na(.data$value_as_number))
      lower <- band$measurement_value[1]
      upper <- band$measurement_value[2]
      if (is.finite(lower)) {
        bound <- if (identical(band$lower_inclusive, FALSE)) {
          rlang::expr(.data$value_as_number > !!lower)
        } else {
          rlang::expr(.data$value_as_number >= !!lower)
        }
        condition <- rlang::expr(!!condition & !!bound)
      }
      if (is.finite(upper)) {
        bound <- if (identical(band$upper_inclusive, FALSE)) {
          rlang::expr(.data$value_as_number < !!upper)
        } else {
          rlang::expr(.data$value_as_number <= !!upper)
        }
        condition <- rlang::expr(!!condition & !!bound)
      }
    }
    if (!is.null(band$measurement_concept)) {
      concepts <- conceptSet[[band$measurement_concept]]
      condition <- rlang::expr(!!condition & .data$value_as_concept_id %in% !!concepts)
    }
    if (!is.null(band$measurement_unit)) {
      condition <- rlang::expr(!!condition & .data$unit_concept_id %in% !!band$measurement_unit)
    }
    rlang::expr(!!condition ~ !!band$label)
  })

  # Keep unmatched results: a recent normal result must replace an older deficit.
  x |>
    dplyr::mutate(measurement_label = dplyr::case_when(
      !!!conditions, .default = NA_character_
    ))
}
