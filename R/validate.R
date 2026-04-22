
validateX <- function(x, call = parent.frame()) {
  omopgenerics::validateCdmTable(table = x, call = call)
  return(x)
}
validateIndexDate <- function(indexDate, x, call = parent.frame()) {
  omopgenerics::validateColumn(column = indexDate, x = x, type = "date", call = call)
}
validateWindow <- function(window, call = parent.frame()) {
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE, call = call)
  if (length(window) > 1) {
    cli::cli_abort(c(x = "Only one window is allowed."))
  }
  return(window[[1]])
}
validateConceptSet <- function(conceptSet, nms, cdm, call = parent.frame()) {
  if (is.null(conceptSet)) {
    if (!identical(getOption("omop.concepts.source"), "OmopConcepts")) {
      cli::cli_inform(c(
        "!" = "`conceptSet` is `NULL`, the conceptSet will be downloaded using {.pkg OmopConcepts}",
        "i" = "Set `options('omop.concepts.source' = 'OmopConcepts')` to silence this message."
      ))
    }
    rlang::check_installed("OmopConcepts", reason = "download concept sets")
    conceptSet <- OmopConcepts::downloadConceptSet(conceptSetName = nms)
  }
  conceptSet <- omopgenerics::validateConceptSetArgument(conceptSet, cdm, call = call)
  notPresent <- nms[!nms %in% names(conceptSet)]
  if (length(notPresent) > 0) {
    cli::cli_abort(c(x = "{.pkg {notPresent}} not found in `conceptSet`."), call = call)
  }
  return(conceptSet[nms])
}
validateNameStyle <- function(nameStyle, x, ..., call = parent.frame()) {
  omopgenerics::assertCharacter(nameStyle, length = 1, call = call)
}
validateName <- function(name, call = parent.frame()) {
  if (all(is.na(name))) {
    name <- NULL
  }
  omopgenerics::validateNameArgument(name = name, null = TRUE, call = call)
}
validateCategories <- function(categories, call = parent.frame()) {
  omopgenerics::assertList(categories, call = call)
}
