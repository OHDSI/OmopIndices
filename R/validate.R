
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
  omopgenerics::assertList(categories, null = TRUE, named = TRUE, call = call)
}
validateGroup <- function(group, cdm, call = parent.frame()) {
  groups <- c(
    "concept_id", "ingredient drug_era", "ingredient drug_exposure",
    "ATC 1st", "ATC 2nd", "ATC 3rd", "ATC 4th", "ATC 5th"
  )
  omopgenerics::assertChoice(group, groups, length = 1, call = call)

  if (group %in% c("concept_id", "ingredient drug_era")) {
    return(group)
  }

  if (group == "ingredient drug_exposure") {
    join <- cdm$concept_ancestor |>
      dplyr::inner_join(
        cdm$concept |>
          dplyr::filter(
            .data$concept_class_id == "Ingredient" &
              .data$standard_concept == "S"
          ) |>
          dplyr::select("ancestor_concept_id" = "concept_id"),
        by = "ancestor_concept_id"
      ) |>
      dplyr::select(
        "group" = "ancestor_concept_id",
        "drug_concept_id" = "descendant_concept_id"
      )
  } else {
    join <- cdm$concept_ancestor |>
      dplyr::inner_join(
        cdm$concept |>
          dplyr::filter(
            .data$vocabulary_id == "ATC" &
              .data$concept_class_id == .env$group
          ) |>
          dplyr::select("ancestor_concept_id" = "concept_id"),
        by = "ancestor_concept_id"
      ) |>
      dplyr::select(
        "group" = "ancestor_concept_id",
        "drug_concept_id" = "descendant_concept_id"
      )
  }

  return(join)
}
