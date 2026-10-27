
#' Add the maximum number of ingredients to which an individual is simultaneously
#' exposed within a specified window
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("polypharmacy")`
#' @param overlap Logical; if `TRUE`, count drug records that overlap in time.
#' If `FALSE`, count drug records that occur within the window without
#' requiring them to overlap one another.
#' @param group Group at which drug records will be considered, it must be a
#' choice between:
#'   - "concept_id" Records are not grouped, each drug_concept_id counts as 1.
#'   - "ingredient drug_era" Records are grouped using the drug_era table.
#'   - "ingredient drug_exposure" Records are grouped at ingredient level using
#'   the drug_exposure table.
#'   - "ATC 1st", "ATC 2nd", "ATC 3rd", "ATC 4th", "ATC 5th" Records are grouped
#'   using different ATC groups levels. ATC codelists are retrieved using
#'   `CodelistGenerator::getATCCodes()`.
#'   - Custom `conceptSet` a custom `codelist`, `codelist_with_details` or
#'   `concept_set_expression` concept set definition, `drug_concept_ids` not
#'   included in the conceptSet will be omitted.
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The table `x` with a new column containing the maximum number of
#' simultaneous ingredients in the window of interest.
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
#'   addPolypharmacy(window = c(-30, 0)) |>
#'   select(subject_id, cohort_start_date, polypharmacy) |>
#'   glimpse()
#' }
#'
addPolypharmacy <- function(x,
                            indexDate = "cohort_start_date",
                            window = c(0, 0),
                            overlap = TRUE,
                            group = "ingredient drug_era",
                            categories = NULL,
                            nameStyle = "polypharmacy",
                            name = tableName(x)) {
  # input check
  x <- omopgenerics::validateCdmTable(table = x)
  personId <- omopgenerics::getPersonIdentifier(x = x)
  indexDate <- omopgenerics::validateColumn(column = indexDate, x = x, type = "date")
  window <- omopgenerics::validateWindowArgument(window = window)
  omopgenerics::assertLogical(overlap, length = 1)
  if (length(window) > 1) {
    cli::cli_abort(c(x = "Only one window is allowed."))
  }
  omopgenerics::assertCharacter(x = nameStyle, length = 1)
  nameStyle <- omopgenerics::toSnakeCase(x = nameStyle)
  if (is.na(name)) {
    name <- NULL
  }
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", null = TRUE)

  if (nameStyle %in% colnames(x)) {
    cli::cli_warn(c("!" = "column {.var {nameStyle}} will be overwritten."))
    x <- x |>
      dplyr::select(!dplyr::all_of(nameStyle))
  }

  cdm <- omopgenerics::cdmReference(table = x)

  table <- ifelse(group == "ingredient drug_era", "drug_era", "drug_exposure")
  join <- validateGroup(group, cdm)

  # check table is empty
  if (omopgenerics::isTableEmpty(cdm[[table]])) {
    cli::cli_warn(c("!" = "{.pkg {table}} table is empty."))
    q <- "0L" |>
      rlang::set_names(nm = nameStyle) |>
      rlang::parse_exprs()
    x <- x |>
      dplyr::mutate(!!!q) |>
      dplyr::compute(name = name)
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

  pref <- omopgenerics::tmpPrefix()

  # intersect with table
  ids <- omopgenerics::uniqueId(n = 3, exclude = colnames(x))
  sel <- c(
    "person_id",
    omopgenerics::omopColumns(table = table, field = "start_date"),
    omopgenerics::omopColumns(table = table, field = "end_date"),
    ifelse(is.character(join), "drug_concept_id", "group")
  ) |>
    rlang::set_names(nm = c(personId, ids))
  nm1 <- omopgenerics::uniqueTableName(prefix = pref)
  nm2 <- omopgenerics::uniqueTableName(prefix = pref)
  win1 <- window[[1]][1]
  win2 <- window[[1]][2]

  # join by groups
  records <- cdm[[table]]
  if (!is.character(join)) {
    records <- records |>
      dplyr::inner_join(join, by = "drug_concept_id")
  }

  # useful records
  x_counts <- x |>
    dplyr::distinct(.data[[personId]], .data[[indexDate]]) |>
    dplyr::inner_join(
      records |>
        dplyr::select(dplyr::all_of(sel)),
      by = personId
    )

  if (is.infinite(win1)) {
    if (!is.infinite(win2)) {
      x_counts <- x_counts |>
        dplyr::filter(
          clock::date_count_between(start = .data[[indexDate]], end = .data[[ids[1]]], precision = "day") <= .env$win2
        )
    }
  } else {
    if (is.infinite(win2)) {
      x_counts <- x_counts |>
        dplyr::filter(
          clock::date_count_between(start = .data[[indexDate]], end = .data[[ids[2]]], precision = "day") >= .env$win1
        )
    } else {
      x_counts <- x_counts |>
        dplyr::filter(
          clock::date_count_between(start = .data[[indexDate]], end = .data[[ids[2]]], precision = "day") >= .env$win1 &
            clock::date_count_between(start = .data[[indexDate]], end = .data[[ids[1]]], precision = "day") <= .env$win2
        )
    }
  }

  x_counts <- x_counts |>
    dplyr::compute(name = nm1)

  # calculate number exposures
  if (overlap) {
    q <- "-min(.data$flag, na.rm = TRUE)" |>
      rlang::set_names(nm = nameStyle) |>
      rlang::parse_exprs()
    x_counts <- x_counts |>
      dplyr::select(dplyr::all_of(c(personId, indexDate, "date" = ids[1]))) |>
      dplyr::mutate(flag = -1L) |>
      dplyr::union_all(
        x_counts |>
          dplyr::select(dplyr::all_of(c(personId, indexDate, "date" = ids[2]))) |>
          dplyr::mutate(flag = 1L)
      ) |>
      dplyr::group_by(.data[[personId]], .data[[indexDate]]) |>
      dplyr::arrange(.data$date, .data$flag) |>
      dplyr::mutate(flag = cumsum(.data$flag)) |>
      dplyr::summarise(!!!q) |>
      dplyr::compute(name = nm2)
  } else {
    q <- "dplyr::n_distinct(.data$drug)" |>
      rlang::set_names(nm = nameStyle) |>
      rlang::parse_exprs()
    x_counts <- x_counts |>
      dplyr::select(dplyr::all_of(c(personId, indexDate, "drug" = ids[3]))) |>
      dplyr::group_by(.data[[personId]], .data[[indexDate]]) |>
      dplyr::summarise(!!!q) |>
      dplyr::compute(name = nm2)
  }

  # add new column
  x <- x |>
    dplyr::left_join(x_counts, by = c(personId, indexDate)) |>
    dplyr::mutate(dplyr::across(
      .cols = dplyr::all_of(nameStyle),
      .fns = \(x) dplyr::coalesce(as.integer(x), 0L)
    )) |>
    dplyr::compute(name = name)

  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(paste0(nameStyle, "_categories")) |>
      rlang::parse_exprs()
    x <- x |>
      dplyr::mutate(!!!qc) |>
      dplyr::compute(name = name)
  }

  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  return(x)
}

#' Add the maximum number of ingredients to which an individual is simultaneously
#' exposed within a specified window
#'
#' `r lifecycle::badge("deprecated")`
#'
#' The function was renamed to `addPolypharmacy()`
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("polypharmacy")`
#' @param overlap Logical; if `TRUE`, count drug eras that overlap in time. If
#' `FALSE`, count drug eras that occur within the window without requiring them
#' to overlap one another.
#' @inheritParams categoriesDoc
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @export
#'
#' @returns The table `x` with a new column containing the maximum number of
#' simultaneous ingredients in the window of interest.
#'
addPolypharmacyCount <- function(x,
                                 indexDate = "cohort_start_date",
                                 window = c(0, 0),
                                 overlap = TRUE,
                                 categories = NULL,
                                 nameStyle = "polypharmacy",
                                 name = tableName(x)) {
  lifecycle::deprecate_soft(when = "0.1.0", "addPolypharmacyCount()", "addPolypharmacy()")
  addPolypharmacy(
    x = x,
    indexDate = indexDate,
    window = window,
    overlap = overlap,
    categories = categories,
    nameStyle = nameStyle,
    name = name
  )
}
