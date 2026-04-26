
#' Add Socio-economic status as a column to a table
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("socio_economic_status")`
#' @param order Character to indicate which of the records to select if multiple
#' records are found.
#' @param from Character indicating where to extract Socio-economic status from:
#' - **townsed** to use records from the [Townsend deprivation index](https://athena.ohdsi.org/search-terms/terms/715996)
#' - **imd** to use records from the [Index of Multiple Deprivation](https://athena.ohdsi.org/search-terms/terms/35812882)
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#' @param missingSocioEconomicStatusValue Character to assign missing values.
#'
#' @returns The `x` table with a new column added with the socio-economic status
#' of the patient.
#'
#' @export
#'
addSocioEconomicStatus <- function(x,
                                   indexDate = "cohort_start_date",
                                   window = c(-Inf, Inf),
                                   order = "last",
                                   from = c("imd", "townsend"),
                                   nameStyle = "socio_economic_status",
                                   name = tableName(x),
                                   missingSocioEconomicStatusValue = "Missing") {
  addSocioEconomicStatusFrom(
    x = x,
    indexDate = indexDate,
    window = window,
    order = order,
    from = from,
    nameStyle = nameStyle,
    name = name,
    missingSocioEconomicStatusValue = missingSocioEconomicStatusValue
  )
}

#' Add Socio-economic status as a column to a table using the
#' [Townsend deprivation index](https://athena.ohdsi.org/search-terms/terms/715996)
#'
#' @inheritParams addSocioEconomicStatus
#'
#' @returns The `x` table with a new column added with the socio-economic status
#' (townsend index) of the patient.
#'
#' @export
#'
addTownsend <- function(x,
                        indexDate = "cohort_start_date",
                        window = c(-Inf, Inf),
                        order = "last",
                        nameStyle = "socio_economic_status",
                        name = tableName(x),
                        missingSocioEconomicStatusValue = "Missing") {
  addSocioEconomicStatusFrom(
    x = x,
    indexDate = indexDate,
    window = window,
    order = order,
    from = "townsend",
    nameStyle = nameStyle,
    name = name,
    missingSocioEconomicStatusValue = missingSocioEconomicStatusValue
  )
}

#' Add Socio-economic status as a column to a table using the
#' [Index of Multiple Deprivation](https://athena.ohdsi.org/search-terms/terms/35812882)
#'
#' @inheritParams addSocioEconomicStatus
#'
#' @returns The `x` table with a new column added with the socio-economic status
#' (index of multiple deprivation) of the patient.
#'
#' @export
#'
addIndexOfMultipleDeprivation <- function(x,
                                          indexDate = "cohort_start_date",
                                          window = c(-Inf, Inf),
                                          order = "last", # first, last, last-before, first-after
                                          nameStyle = "socio_economic_status",
                                          name = tableName(x),
                                          missingSocioEconomicStatusValue = "Missing") {
  addSocioEconomicStatusFrom(
    x = x,
    indexDate = indexDate,
    window = window,
    order = order,
    from = "imd",
    nameStyle = nameStyle,
    name = name,
    missingSocioEconomicStatusValue = missingSocioEconomicStatusValue
  )
}

addSocioEconomicStatusFrom <- function(x,
                                       indexDate,
                                       window,
                                       order,
                                       from,
                                       nameStyle,
                                       name,
                                       missingSocioEconomicStatusValue,
                                       call = parent.frame()) {
  # initial checks
  x <- validateX(x, call = call)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- omopgenerics::validateColumn(indexDate, x, "date")
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE)[[1]]
  omopgenerics::assertChoice(order, c("first", "last"), length = 1, call = call)
  opts <- c("imd", "townsend")
  omopgenerics::assertChoice(from, opts, call = call)
  nameStyle <- validateNameStyle(nameStyle, x, call = call)
  x <- omopgenerics::validateNewColumn(x, nameStyle, call = call)
  name <- validateName(name, call = call)
  omopgenerics::assertCharacter(missingSocioEconomicStatusValue, length = 1, call = call)

  if (length(from) == 0) {
    x <- addMissingColumn(x, name, nameStyle, missingSocioEconomicStatusValue)
    return(x)
  }

  id <- omopgenerics::getPersonIdentifier(x)
  sel <- rlang::set_names(id, "person_id")

  nm1 <- omopgenerics::uniqueTableName()
  nm2 <- omopgenerics::uniqueTableName()

  # prepare data
  xs <- x |>
    dplyr::select(dplyr::all_of(c(sel, indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm1)
  col <- omopgenerics::uniqueId(exclude = colnames(xs))

  for (fr in from) {

    cli::cli_inform(c(i = "Trying to add Socio-economic status from {.pkg {fr}}."))

    if (fr == "townsend") {
      table <- "measurement"
      concept <- 715996L
    } else if (fr == "imd") {
      table <- "observation"
      concept <- 35812882L
    }
    date <- omopgenerics::omopColumns(table = table, field = "start_date")
    con <- omopgenerics::omopColumns(table = table, field = "standard_concept")
    sel <- c("person_id", date, "value_as_number") |>
      rlang::set_names(c("person_id", col, nameStyle))

    # find ses records
    ses <- cdm[[table]] |>
      dplyr::filter(.data[[con]] == .env$concept) |>
      dplyr::select(dplyr::all_of(sel)) |>
      dplyr::filter(!is.na(.data[[nameStyle]])) |>
      dplyr::inner_join(xs, by = "person_id") |>
      dplyr::compute(name = nm2) |>
      # subset by window and order
      dplyr::mutate(!!col := clock::date_count_between(
        start = .data[[indexDate]],
        end = .data[[col]],
        precision = "day"
      )) |>
      filterWindow(col, window) |>
      filterOrder(col, order, indexDate) |>
      dplyr::compute(name = nm2) |>
      # remove duplicates
      dplyr::group_by(.data$person_id, .data[[indexDate]]) |>
      dplyr::filter(dplyr::n() == 1) |>
      dplyr::compute(name = nm2) |>
      # group records
      groupRecords(fr, nameStyle) |>
      dplyr::compute(name = nm2)

    # check if there are records
    if (omopgenerics::isTableEmpty(ses)) {
      added <- FALSE
      cli::cli_inform(c("!" = "Socio-economic status could not be added from {.pkg {fr}}."))
    } else {
      added <- TRUE
      cli::cli_inform(c("v" = "Socio-economic status added from {.pkg {fr}}."))
      break
    }
  }

  if (added) {
    sel <- c("person_id", indexDate, nameStyle) |>
      rlang::set_names(c(id, indexDate, nameStyle))
    x <- x |>
      dplyr::left_join(
        ses |>
          dplyr::select(dplyr::all_of(sel)),
        by = c(id, indexDate)
      ) |>
      dplyr::mutate(!!nameStyle := dplyr::coalesce(
        .data[[nameStyle]], .env$missingSocioEconomicStatusValue
      )) |>
      dplyr::compute(name = name)
  } else {
    x <- addMissingColumn(x, name, nameStyle, missingSocioEconomicStatusValue)
  }

  cdm <- omopgenerics::dropSourceTable(cdm = cdm, name = c(nm1, nm2))

  return(x)
}
filterWindow <- function(x, diff, window) {
  if (is.infinite(window[1])) {
    if (!is.infinite(window[2])) {
      x <- x |>
        dplyr::filter(.data[[diff]] <= !!window[2])
    }
  } else {
    if (is.infinite(window[2])) {
      x <- x |>
        dplyr::filter(!!window[1] <= .data[[diff]])
    } else {
      x <- x |>
        dplyr::filter(
          !!window[1] <= .data[[diff]] & .data[[diff]] <= !!window[2]
        )
    }
  }
  x
}
filterOrder <- function(x, diff, order, indexDate) {
  q <- switch(order,
              "first" = ".data[[diff]] == min(.data[[diff]], na.rm = TRUE)",
              "last" = ".data[[diff]] == max(.data[[diff]], na.rm = TRUE)") |>
    rlang::parse_exprs()
  x |>
    dplyr::group_by(.data$person_id, .data[[indexDate]]) |>
    dplyr::filter(!!!q)
}
groupRecords <- function(x, from, ses) {
  if (from == "townsend") {
    x <- x |>
      dplyr::mutate(!!ses := dplyr::case_when(
        .data[[ses]] %in% c(1, 2)  ~ "Q1",
        .data[[ses]] %in% c(3, 4)  ~ "Q2",
        .data[[ses]] %in% c(5, 6)  ~ "Q3",
        .data[[ses]] %in% c(7, 8)  ~ "Q4",
        .data[[ses]] %in% c(9, 10) ~ "Q5"
      ))
  } else if (from == "imd") {
    x <- x |>
      dplyr::mutate(!!ses := dplyr::case_when(
        .data[[ses]] == 1 ~ "Q1",
        .data[[ses]] == 2 ~ "Q2",
        .data[[ses]] == 3 ~ "Q3",
        .data[[ses]] == 4 ~ "Q4",
        .data[[ses]] == 5 ~ "Q5"
      ))
  }
  x
}
addMissingColumn <- function(x, name, nameStyle, missing) {
  q <- ".env$missing" |>
    rlang::parse_exprs() |>
    rlang::set_names(nameStyle)
  x |>
    dplyr::mutate(!!!q) |>
    dplyr::compute(name = name)
}
