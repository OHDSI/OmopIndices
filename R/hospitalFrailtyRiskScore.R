
#' Add the hospital frailty risk score as defined in Gilbert et al:
#' <https://doi.org/10.1016/S0140-6736(18)30668-8>
#'
#' @inheritParams xDoc
#' @inheritParams indexDateDoc
#' @param window `r documentationWindow("hospital frailty risk score")`
#' @param conceptSet `r documentationConceptSet(frailtyConcepts)`
#' @param categories Named list of categories to group the values. If NULL the
#' risk score is returned as numeric.
#' @inheritParams nameStyleDoc
#' @inheritParams nameDoc
#'
#' @returns The `x` table with a new column added with the hospital
#' frailty risk score of the patient.
#'
#' @export
#'
addHospitalFrailtyRiskScore <- function(x,
                                        indexDate = "cohort_start_date",
                                        window = c(-365, 0),
                                        conceptSet = NULL,
                                        categories = list(
                                          "low" = c(0, 5),
                                          "intermediate" = c(5, 15),
                                          "high" = c(15, Inf)
                                        ),
                                        nameStyle = "hf_risk",
                                        name = tableName(x)) {
  # initial checks
  x <- validateX(x)
  cdm <- omopgenerics::cdmReference(x)
  indexDate <- omopgenerics::validateColumn(indexDate, x, "date")
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE)[[1]]
  conceptSet <- validateConceptSet(conceptSet, frailtyConcepts, cdm)
  nameStyle <- validateNameStyle(nameStyle, x)
  x <- omopgenerics::validateNewColumn(x, nameStyle)
  name <- validateName(name)
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", null = TRUE)

  id <- omopgenerics::getPersonIdentifier(x)
  q <- hfrsFormula |>
    rlang::set_names(nameStyle) |>
    rlang::parse_exprs()

  # calculate score
  nm <- omopgenerics::uniqueTableName()
  hfrs <- x |>
    dplyr::select(dplyr::any_of(c(id, indexDate))) |>
    dplyr::distinct() |>
    dplyr::compute(name = nm) |>
    PatientProfiles::addConceptIntersectFlag(
      conceptSet = conceptSet,
      indexDate = indexDate,
      window = window,
      name = nm,
      nameStyle = "{concept_name}"
    ) |>
    dplyr::mutate(!!!q)

  if (!is.null(categories)) {
    qc <- qCategories(categories) |>
      rlang::set_names(nameStyle) |>
      rlang::parse_exprs()
    hfrs <- hfrs |>
      dplyr::mutate(!!!qc)
  }

  hfrs <- hfrs |>
    dplyr::select(dplyr::all_of(c(id, indexDate, nameStyle))) |>
    dplyr::compute(name = nm)


  # add hfrs to x
  x <- x |>
    dplyr::inner_join(hfrs, by = c(id, indexDate)) |>
    dplyr::compute(name = name)

  # drop intermediate table
  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  return(x)
}
qCategories <- function(categories) {
  q <- categories |>
    purrr::imap(\(win, nm) {
      paste0(windowCondition(win), " ~ '", nm, "'")
    }) |>
    paste0(", ")
  paste0("dplyr::case_when(", q, ")")
}
windowCondition <- function(window) {
  if (is.infinite(window[2])) {
    paste0(window[1], " <= .data[[nameStyle]]")
  } else {
    paste0(window[1], " <= .data[[nameStyle]] & .data[[nameStyle]] <= ", window[2])
  }
}

#' Hospital Frailty Risk Score data set
#'
#' @format ## `hospitalFrailtyRiskScore`
#' A data frame with 109 rows and 4 columns:
#' \describe{
#'   \item{concept_set}{The name of the concept set to be provided}
#'   \item{points}{Number of points associated with the codelist}
#'   \item{icd10_code}{ICD-10 code used}
#'   \item{icd_description}{Name of the ICD-10 code}
#' }
#' @source <https://doi.org/10.1016/S0140-6736(18)30668-8>
"hospitalFrailtyRiskScore"
