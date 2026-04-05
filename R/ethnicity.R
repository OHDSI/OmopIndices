
#' Add the ethnicity records to a table
#'
#' @inheritParams xDoc
#' @param from Character to indicate how to retrieve ethnicity, if multiple
#' values are provided different sources will be tried sequentially.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#' @param missingEthnicityValue Character to coaslesce missing values.
#'
#' @returns The `x` table with a new column added with the ethnicity of the
#' patient.
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
#'   addEthnicity() |>
#'   glimpse()
#'
addEthnicity <- function(x,
                         from = c(
                           "ethnicity_concept_id", "ethnicity_source_concept_id",
                           "race_concept_id", "race_source_concept_id"
                          ),
                         nameStyle = "ethnicity",
                         name = tableName(x),
                         missingEthnicityValue = "Missing") {
  # initial checks
  x <- validateX(x)
  opts <- c(
    "ethnicity_concept_id", "ethnicity_source_concept_id", "race_concept_id",
    "race_source_concept_id"
  )
  # TODO add observation option
  omopgenerics::assertChoice(from, opts)
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)
  omopgenerics::assertCharacter(missingEthnicityValue, length = 1)

  if (length(from) == 0) {
    q <- ".env$missingEthnicityValue" |>
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
    cli::cli_inform(c(i = "{verb} ethnicity from: {.emph {fr}}."))

    # try to add ethnicity
    if (endsWith(fr, "concept_id")) {
      indEth <- ind |>
        addEthnicityFromCol(fr, nameStyle) |>
        dplyr::compute(name = omopgenerics::uniqueTableName(pref))
    } else if (fr == "observation") {
      # TODO
    }

    # check if it was successful
    if (omopgenerics::numberRecords(indLoc) > 0) {
      cli::cli_inform(c("v" = "Ethnicity added from {.emph {fr}}."))
      break
    } else {
      cli::cli_inform(c("x" = "Ethnicity could not be added from {.emph {fr}}."))
      if (fr == from[length(from)]) {
        cli::cli_inform(c("!" = "No ethnicity found, variable will be filled with {.var {missingEthnicityValue}}."))
      }
    }
  }

  # add ethnicity
  x <- x |>
    dplyr::left_join(
      indEth |>
        dplyr::select(dplyr::all_of(c(rlang::set_names("person_id", id), nameStyle))),
      by = id
    ) |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(nameStyle),
      \(x) dplyr::coalesce(x, .env$missingEthnicityValue)
    )) |>
    dplyr::compute(name = name)

  # drop tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  return(x)
}

addEthnicityFromCol <- function(x, col, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  sel <- c("concept_id", "concept_name") |>
    rlang::set_names(c("concept_id", nameStyle))
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("person_id", dplyr::all_of(c("concept_id" = col))) |>
        dplyr::filter(.data$concept_id != 0) |>
        dplyr::inner_join(
          cdm$concept |>
            dplyr::select(dplyr::all_of(sel)),
          by = "concept_id"
        ) |>
        dplyr::select(dplyr::all_of(c("person_id", nameStyle))),
      by = "person_id"
    )
}
