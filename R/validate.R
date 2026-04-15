
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
    cli::cli_inform(c(i = "Downloading {.pkg {nms}}."))
    conceptSet <- OmopConcepts::downloadConceptSet(conceptSetName = nms)
  }
  conceptSet <- omopgenerics::validateConceptSetArgument(conceptSet, cdm, call = call)
  notPresent <- nms[!nms %in% names(conceptSet)]
  if (length(notPresent) > 0) {
    cli::cli_abort(c(x = "{.pkg {notPresent}} not found in `conceptSet`."), call = call)
  }
  return(conceptSet)
}
validateBmiThreshold <- function(bmiThreshold, call = parent.frame()) {
  if (is.null(bmiThreshold)) {
    cli::cli_inform(c(i = "Using internal {.pkg bmiThreshold} for BMI cut-offs."))
    bmiThreshold <- OmopIndices::bmiThreshold
  }
  msg <- paste0(
    "`bmiThreshold` must be a single number or a tibble with the columns: ",
    "`bmi_threshold` for the threshold; use `sex` to use sex specific ",
    "thresholds; use `age_min` and `age_max` to use age specific thresholds. ",
    "Leave it `NULL` to use `OmopIndices::bmiThreshold`."
  )
  if (is.numeric(bmiThreshold)) {
    if (length(bmiThreshold) != 1) {
      cli::cli_abort(c(x = msg), call = call)
    }
  } else {
    omopgenerics::assertTable(bmiThreshold, class = "data.frame", columns = "bmi_threshold", call = call, msg = msg)
    if (!"sex" %in% colnames(bmiThreshold)) {
      bmiThreshold <- bmiThreshold |>
        dplyr::mutate(sex = "Female") |>
        dplyr::union_all(
          bmiThreshold |>
            dplyr::mutate(sex = "Male")
        )
    } else {
      labs <- unique(bmiThreshold$sex)
      labs <- labs[!labs %in% c("Female", "Male")]
      if (length(labs) > 0) {
        cli::cli_abort(c(x = "Allowed labels for sex are: 'Female' and 'Male'"), call = call)
      }
    }
    if (!"age_min" %in% colnames(bmiThreshold)) {
      bmiThreshold <- bmiThreshold |>
        dplyr::mutate(age_min = 0)
    }
    if (!"age_max" %in% colnames(bmiThreshold)) {
      bmiThreshold <- bmiThreshold |>
        dplyr::mutate(age_max = Inf)
    }
    # cast
    bmiThreshold <- bmiThreshold |>
      dplyr::select("age_min", "age_max", "sex", "bmi_threshold") |>
      dplyr::mutate(
        age_min = as.numeric(.data$age_min),
        age_max = as.numeric(.data$age_max),
        sex = as.character(.data$sex),
        bmi_threshold = as.numeric(.data$bmi_threshold)
      )
    # add age groups
    bmiThreshold <- bmiThreshold |>
      dplyr::cross_join(dplyr::tibble(age = 0:150)) |>
      dplyr::filter(.data$age_min <= .data$age & .data$age <= .data$age_max) |>
      dplyr::select("age", "sex", "bmi_threshold")
  }
  return(bmiThreshold)
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
