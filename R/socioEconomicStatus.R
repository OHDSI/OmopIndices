
#' Title
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("socio_economic_status")`
#' @param order Order
#' @param from From
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#' @param missingSocioEconomicStatusValue Missing value
#'
#' @returns The `x` table with a new column added with the socio-economic status
#' of the patient.
#' @export
#'
addSocioEconomicStatus <- function(x,
                                   indexDate = "cohort_start_date",
                                   window = c(-Inf, Inf),
                                   order = "last", # first, last, last-before, first-after
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

#' Title
#'
#' @inheritParams addSocioEconomicStatus
#'
#' @returns The `x` table with a new column added with the socio-economic status
#' (townsend index) of the patient.
#' @export
#'
addTownsend <- function(x,
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
    from = "townsend",
    nameStyle = nameStyle,
    name = name,
    missingSocioEconomicStatusValue = missingSocioEconomicStatusValue
  )
}

#' Title
#'
#' @inheritParams addSocioEconomicStatus
#'
#' @returns The `x` table with a new column added with the socio-economic status
#' (index of multiple deprivation) of the patient.
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
  opts <- c("imd", "townsend")
  omopgenerics::assertChoice(from, opts, call = call)
  nameStyle <- validateNameStyle(nameStyle, x, call = call)
  x <- omopgenerics::validateNewColumn(x, nameStyle, call = call)
  name <- validateName(name, call = call)
  omopgenerics::assertCharacter(missingSocioEconomicStatusValue, length = 1, call = call)

  if (length(from) == 0) {
    q <- ".env$missingSocioEconomicStatusValue" |>
      rlang::parse_exprs() |>
      rlang::set_names(nameStyle)
    x <- x |>
      dplyr::mutate(!!!q) |>
      dplyr::compute(name = name)
    return(x)
  }

  id <- omopgenerics::getPersonIdentifier(x)
  sel <- rlang::set_names(id, "person_id")
}
