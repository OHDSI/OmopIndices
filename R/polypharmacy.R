
addPolypharmacyCount <- function(x,
                                 indexDate = "cohort_start_date",
                                 window = c(0, 0),
                                 nameStyle = "polypharmacy_count",
                                 name = NULL) {
  # input check
  x <- omopgenerics::validateCdmTable(table = x)
  personId <- omopgenerics::getPersonIdentifier(x = x)
  indexDate <- omopgenerics::validateColumn(column = indexDate, x = x, type = "date")
  window <- omopgenerics::validateWindowArgument(window = window)
  if (length(window) > 1) {
    cli::cli_abort(c(x = "Only one window is allowed."))
  }
  omopgenerics::assertCharacter(x = nameStyle, length = 1)
  nameStyle <- omopgenerics::toSnakeCase(x = nameStyle)

  cdm <- omopgenerics::cdmReference(table = x)

  # check drug_era is empty
  if (omopgenerics::isTableEmpty(cdm$drug_era)) {
    cli::cli_warn(c("!" = "{.pkg drug_era} table is empty."))
    q <- "0L" |>
      rlang::set_names(nm = nameStyle) |>
      rlang::parse_exprs()
    x <- x |>
      dplyr::mutate(!!!q) |>
      dplyr::compute(name = name)
    return(x)
  }

  pref <- omopgenerics::tmpPrefix()

  # intersect with drug_era
  ids <- omopgenerics::uniqueId(n = 2, exclude = colnames(x))
  sel <- c("person_id", "drug_era_start_date", "drug_era_end_date") |>
    rlang::set_names(nm = c(personId, ids))
  nm1 <- omopgenerics::uniqueTableName(prefix = pref)
  nm2 <- omopgenerics::uniqueTableName(prefix = pref)
  win1 <- window[[1]][1]
  win2 <- window[[1]][2]

  # useful records
  x_counts <- x |>
    dplyr::distinct(.data[[personId]], .data[[indexDate]]) |>
    dplyr::inner_join(
      cdm$drug_era |>
        dplyr::select(dplyr::all_of(sel)),
      by = personId
    ) |>
    dplyr::filter(
      clock::date_count_between(start = .data[[ids[1]]], end = .data[[indexDate]], precision = "day") >= .env$win1 &
        clock::date_count_between(start = .data[[indexDate]], end = .data[[ids[2]]], precision = "day") >= .env$win2
    ) |>
    dplyr::compute(name = nm1)

  # calculate number ingredients
  q <- "max(.data$flag, na.rm = TRUE)" |>
    rlang::set_names(nm = nameStyle) |>
    rlang::parse_exprs()
  x_counts <- x_counts |>
    dplyr::select(dplyr::all_of(c(personId, indexDate, "date" = ids[1]))) |>
    dplyr::mutate(flag = 1L) |>
    dplyr::union_all(
      x_counts |>
        dplyr::select(dplyr::all_of(c(personId, indexDate, "date" = ids[2]))) |>
        dplyr::mutate(flag = -1L)
    ) |>
    dplyr::group_by(.data[[personId]], .data[[indexDate]]) |>
    dplyr::arrange(.data$date) |>
    dplyr::mutate(flag = cumsum(.data$flag)) |>
    dplyr::summarise(!!!q) |>
    dplyr::compute(name = nm2)

  # add new column
  x <- x |>
    dplyr::left_join(x_counts, by = c(personId, indexDate)) |>
    dplyr::mutate(dplyr::across(
      .cols = dplyr::all_of(nameStyle),
      .fns = \(x) dplyr::coalesce(as.integer(x), 0L)
    )) |>
    dplyr::compute(name = name)

  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  return(x)
}
