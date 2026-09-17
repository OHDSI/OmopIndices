
#' Add the location to a table
#'
#' @inheritParams xDoc
#' @param from A character vector specifying the location sources to try, in
#' priority order. The first source that provides a location is used. Supported
#' values are `location_id` and `care_site_id`.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#' @param locationSource A character string specifying the column to retrieve
#' from the `location` table. Supported values include `location_source_value`,
#' `city`, `state`, `zip`, `county`, `country_concept_id`, and
#' `country_source_value`.
#' @param missingLocationValue A character string used to replace missing
#' location values.
#'
#' @returns The table `x` with a new column containing the patient's location.
#'
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
#'   addLocation() |>
#'   select(subject_id, cohort_start_date, location) |>
#'   glimpse()
#' }
#'
addLocation <- function(x,
                        from = c("location_id", "care_site_id"),
                        nameStyle = "location",
                        name = tableName(x),
                        locationSource = "location_source_value",
                        missingLocationValue = "Missing") {
  # initial checks
  x <- validateX(x)
  omopgenerics::assertChoice(from, c("location_id", "care_site_id"))
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)
  omopgenerics::assertCharacter(missingLocationValue, length = 1)
  omopgenerics::assertChoice(locationSource, c(
    "location_id", "city", "state", "zip", "county", "location_source_value",
    "country_concept_id", "country_source_value"
  ), length = 1)

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
        addLocationFromLocationId(locationSource, nameStyle) |>
        dplyr::compute(name = omopgenerics::uniqueTableName(pref))
    } else if (fr == "care_site_id") {
      indLoc <- ind |>
        addLocationFromCareSiteId(locationSource, nameStyle) |>
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

locationTable <- function(cdm, locationSource, nameStyle) {
  if (locationSource == "country_concept_id") {
    sel1 <- c("location_id", "country_concept_id") |>
      rlang::set_names(c("location_id", "concept_id"))
    sel2 <- c("concept_id", "concept_name") |>
      rlang::set_names(c("concept_id", nameStyle))
    loc <- cdm$location |>
      dplyr::select(dplyr::all_of(sel1)) |>
      dplyr::inner_join(
        cdm$concept |>
          dplyr::select(dplyr::all_of(sel2)),
        by = "concept_id"
      )
  } else {
    sel <- c("location_id", locationSource) |>
      rlang::set_names(c("location_id", nameStyle))
    loc <- cdm$location |>
      dplyr::select(dplyr::all_of(sel))
  }
  return(loc)
}
addLocationFromLocationId <- function(x, locationSource, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  loc <- locationTable(cdm, locationSource, nameStyle)
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("person_id", "location_id") |>
        dplyr::inner_join(loc, by = "location_id") |>
        dplyr::select(dplyr::all_of(c("person_id", nameStyle))),
      by = "person_id"
    )
}
addLocationFromCareSiteId <- function(x, locationSource, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  loc <- locationTable(cdm, locationSource, nameStyle)
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("person_id", "care_site_id") |>
        dplyr::inner_join(
          cdm$care_site |>
            dplyr::select("care_site_id", "location_id") |>
            dplyr::inner_join(loc, by = "location_id"),
          by = "care_site_id"
        ) |>
        dplyr::select(dplyr::all_of(c("person_id", nameStyle))),
      by = "person_id"
    )
}
