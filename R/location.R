
#' Add the location to a table
#'
#' @inheritParams xDoc
#' @param from Character to indicate how to retrieve location, if multiple
#' values are provided different sources will be tried sequentially.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#' @param missingLocationValue Character to coaslesce missing values.
#'
#' @returns The `x` table with a new column added with the location of the
#' patient.
#'
#' @export
#'
#' @examples
#' library(OmopIndexes)
#' library(omock)
#' library(dplyr)
#'
#' cdm <- mockCdmFromDataset(source = "duckdb")
#'
#' cdm$condition_occurrence |>
#'   addLocation() |>
#'   glimpse()
#'
addLocation <- function(x,
                        from = c("location_id", "care_site_id"),
                        nameStyle = "location",
                        name = tableName(x),
                        missingLocationValue = "Missing") {
  # initial checks
  x <- validateX(x)
  omopgenerics::assertChoice(from, c("location_id", "care_site_id"))
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)
  omopgenerics::assertCharacter(missingLocationValue, length = 1)

  if (length(from) == 0) {
    q <- ".env$missingLocationValue" |>
      rlang::parse_exprs() |>
      rlang::set_names(nameStyle)
    x <- x |>
      dplyr::mutate(!!!q) |>
      dplyr::compute(name = name)
    return(x)
  }

  id <- omopgenerics::getPersonIdentifier(x)
  sel <- rlang::set_names(id, "person_id")

  pref <- omopgenerics::tmpPrefix()
  ind <- x |>
    dplyr::select(dplyr::all_of(sel)) |>
    dplyr::distinct() |>
    dplyr::compute(name = omopgenerics::uniqueTableName(pref))

  for (fr in from) {
    verb <- ifelse(length(from) == 1, "Getting", "Trying to get")
    cli::cli_inform(c(i = "{verb} location from: {.emph {fr}}."))

    # try to add location
    if (fr == "location_id") {
      indLoc <- ind |>
        addLocationFromLocationId(nameStyle) |>
        dplyr::compute(name = omopgenerics::uniqueTableName(pref))
    } else if (fr == "care_site_id") {
      indLoc <- ind |>
        addLocationFromCareSiteId(nameStyle) |>
        dplyr::compute(name = omopgenerics::uniqueTableName(pref))
    }

    # check if it was successful
    if (omopgenerics::numberRecords(indLoc) > 0) {
      cli::cli_inform(c("v" = "Location added from {.emph {fr}}."))
      break
    } else {
      cli::cli_inform(c("x" = "Location could not be added from {.emph {fr}}."))
      if (fr == from[length(from)]) {
        cli::cli_inform(c("!" = "No location found, variable will be filled with {.var {missingLocationValue}}."))
      }
    }
  }

  # add location
  x <- x |>
    dplyr::left_join(
      indLoc |>
        dplyr::select(dplyr::all_of(c(rlang::set_names("person_id", id), nameStyle))),
      by = id
    ) |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(nameStyle),
      \(x) dplyr::coalesce(x, .env$missingLocationValue)
    )) |>
    dplyr::compute(name = name)

  # drop tables
  cdm <- omopgenerics::cdmReference(x)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  return(x)
}

addLocationFromLocationId <- function(x, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  sel <- c("location_id", "location_source_value") |>
    rlang::set_names(c("location_id", nameStyle))
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("person_id", "location_id") |>
        dplyr::inner_join(
          cdm$location |>
            dplyr::select(dplyr::all_of(sel)),
          by = "location_id"
        ) |>
        dplyr::select(dplyr::all_of(c("person_id", nameStyle))),
      by = "person_id"
    )
}
addLocationFromCareSiteId <- function(x, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  sel <- c("location_id", "location_source_value") |>
    rlang::set_names(c("location_id", nameStyle))
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("person_id", "care_site_id") |>
        dplyr::inner_join(
          cdm$care_site |>
            dplyr::select("care_site_id", "location_id") |>
            dplyr::inner_join(
              cdm$location |>
                dplyr::select(dplyr::all_of(sel)),
              by = "location_id"
            ),
          by = "care_site_id"
        ) |>
        dplyr::select(dplyr::all_of(c("person_id", nameStyle))),
      by = "person_id"
    )
}
