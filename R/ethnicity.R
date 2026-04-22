
#' Add the ethnicity of a person to a table
#'
#' @inheritParams xDoc
#' @param from Character to indicate how to retrieve ethnicity, if multiple
#' values are provided different sources will be tried sequentially. Available
#' options are:
#' - **ethnicity_concept_id** to assign ethnicity using the `concept_name`
#' associated with the `ethnicity_concept_id` column of person table.
#' - **ethnicity_source_concept_id** to assign ethnicity using the
#' `concept_name` associated with the `ethnicity_source_concept_id` column of
#' person table.
#' - **race_concept_id** to assign ethnicity using the `concept_name` associated
#' with the `race_concept_id` column of person table.
#' - **race_source_concept_id** to assign ethnicity using the `concept_name`
#' associated with the `race_source_concept_id` column of person table.
#' - **ethnicity_source_value** to assign ethnicity using the value of the
#' column `ethnicity_source_value` in the person table.
#' - **race_source_value** to assign ethnicity using the value of the
#' column `race_source_value` in the person table.
#' - **nhs-categories** to assign ethnicity using the broad categories as
#' described in <10.1038/s41597-024-02958-1>.
#' - **nhs-groups** to assign ethnicity using the broad groups as described in
#' <10.1038/s41597-024-02958-1>.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#' @param missingEthnicityValue Character to coaslesce missing values.
#'
#' @returns The `x` table with a new column added with the ethnicity of the
#' patient.
#' @export
#'
#' @examples
#' library(OmopIndices)
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
                         missingEthnicityValue = "Missing") { # Missing vs Unknown
  # initial checks
  x <- validateX(x)
  opts <- c(
    "ethnicity_concept_id", "ethnicity_source_concept_id", "race_concept_id",
    "race_source_concept_id", "ethnicity_source_value", "race_source_value",
    "nhs-categories", "nhs-groups"
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
    } else if (endsWith(fr, "value")) {
      indEth <- ind |>
        addEthnicityFromValue(fr, nameStyle) |>
        dplyr::compute(name = omopgenerics::uniqueTableName(pref))
    } else if (grepl("nhs", fr)) {
      indEth <- ind |>
        addNhsCategories(fr, nameStyle) |>
        dplyr::compute(name = omopgenerics::uniqueTableName(pref))
    }

    # check if it was successful
    if (omopgenerics::numberRecords(indEth) > 0) {
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
  cdm <- omopgenerics::cdmReference(x)
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
addEthnicityFromValue <- function(x, col, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  sel <- rlang::set_names(col, nameStyle)
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("person_id", dplyr::all_of(sel)) |>
        dplyr::filter(!is.na(.data[[nameStyle]]) & .data[[nameStyle]] != ""),
      by = "person_id"
    )
}
addNhsCategories <- function(x, from, nameStyle) {
  cdm <- omopgenerics::cdmReference(x)
  if (from == "nhs-categories") {
    q <- "dplyr::case_when(
      .data$race_source_concept_id == 700362L ~ 'Asian or Asian British - Any other Asian background',
      .data$race_source_concept_id == 700363L ~ 'Asian or Asian British - Pakistani',
      .data$race_source_concept_id == 700364L ~ 'Asian or Asian British - Bangladeshi',
      .data$race_source_concept_id == 700365L ~ 'Asian or Asian British - Any other Asian background',
      .data$race_source_concept_id == 700366L ~ 'Black or Black British - Caribbean',
      .data$race_source_concept_id == 700367L ~ 'Black or Black British - African',
      .data$race_source_concept_id == 700368L ~ 'Black or Black British - Any other Black background',
      .data$race_source_concept_id == 700369L ~ 'Other Ethnic Groups - Chinese',
      .data$race_source_concept_id == 700385L ~ 'White - British',
      .data$race_source_concept_id == 700386L ~ 'White - Irish',
      .data$race_source_concept_id == 700387L ~ 'White - Any other White background',
      .data$race_source_concept_id == 700388L ~ 'Mixed - White and Black Caribbean',
      .data$race_source_concept_id == 700389L ~ 'Mixed - White and Black African',
      .data$race_source_concept_id == 700390L ~ 'Mixed - White and Asian',
      .data$race_source_concept_id == 700391L ~ 'Mixed - Any other mixed background',
      .default = NA_character_
    )"
  } else if (from == "nhs-groups") {
    q <- "dplyr::case_when(
      .data$race_source_concept_id %in% c(700385L, 700386L, 700387L) ~ 'White',
      .data$race_source_concept_id %in% c(700390L, 700391L, 700389L, 700388L) ~ 'Mix',
      .data$race_source_concept_id %in% c(700369L) ~ 'Other',
      .data$race_source_concept_id %in% c(700364L, 700362L, 700363L, 700365L) ~ 'Asian',
      .data$race_source_concept_id %in% c(700367L, 700366L, 700368L) ~ 'Black',
      .default = NA_character_
    )"
  }
  q <- q |>
    rlang::parse_exprs() |>
    rlang::set_names(nameStyle)
  x |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::mutate(!!!q) |>
        dplyr::filter(!is.na(.data[[nameStyle]])) |>
        dplyr::select(dplyr::all_of(c("person_id", nameStyle))),
      by = "person_id"
    )
}
