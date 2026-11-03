getFormula <- function(definition) {
  terms <- definition |>
    purrr::map_chr(\(x) {
      column <- paste0(".data[['", componentName(x), "']]")

      # if the output is the value
      if (identical(x$score, "value")) {
        return(column)
      }

      # if concept
      if (x$type == "concept") {
        if (is.null(x$group)) {
          return(paste(x$score, "*", column))
        } else {
          return(paste(column, " == 1 ~ ", x$score))
        }
      }

      # get values per group
      groups <- switch(x$type,
                       age_group = x$age_groups,
                       polypharmacy = x$drug_groups,
                       measurement = x$measurement_groups)
      labels <- purrr::map_chr(groups, "label")
      scores <- purrr::map_dbl(groups, "score")
      paste0(
        "dplyr::case_when(",
        paste0(column, " == '", labels, "' ~ ", scores, collapse = ", "),
        ", .default = 0)"
      )
    })

  # Apply group logic
  noGroup <- "_NONE_"
  groups <- purrr::map_chr(definition, \(x) x$group %||% noGroup)
  groupTerms <- unique(groups[groups != noGroup]) |>
    purrr::map_chr(\(group) {
      paste0(
        "dplyr::case_when(",
        paste0(terms[groups == group], collapse = ", "),
        ", .default = 0)"
      )
    })

  # return formula
  paste0(c(terms[groups == noGroup], groupTerms), collapse = " + ")
}

getAddComponents <- function(definition) {
  # age groups
  defAgeGroups <- definition[purrr::map_chr(definition, "type") == "age_group"]
  if (length(defAgeGroups) > 0) {
    names(defAgeGroups) <- purrr::map(defAgeGroups, "name_style")
    defAgeGroups <- defAgeGroups |>
      purrr::map(\(x) {
        purrr::map(x$age_groups, "age_range") |>
          rlang::set_names(purrr::map_chr(x$age_groups, "label"))
      })
    defAgeGroups <- list(list(
      type = "age_group",
      ageGroup = defAgeGroups
    ))
  }

  # polypharmacy
  defPoly <- definition[purrr::map_chr(definition, "type") == "polypharmacy"] |>
    purrr::map(\(x) {
      list(
        type = "polypharmacy",
        window = c(-x$follow_up, 0),
        overlap = x$overlap,
        group = x$drug_group,
        categories = purrr::map(x$drug_groups, "drug_range") |>
          rlang::set_names(purrr::map_chr(x$drug_groups, "label"))
      )
    })

  # concept flags
  defConcept <- definition[purrr::map_chr(definition, "type") == "concept"]
  windows <- defConcept |>
    purrr::map(\(x) c(-x$follow_up, 0))
  defConcept <- unique(windows) |>
    purrr::map(\(x) {
      list(
        type = "concept_flag",
        conceptSet = unique(purrr::map_chr(
          defConcept[purrr::map_lgl(windows, \(w) identical(w, x))], componentName
        )),
        window = x
      )
    })

  c(defAgeGroups, defPoly, defConcept)
}

getPointsMatrix <- function(definition) {
  definition |>
    purrr::map(\(x) {
      if (x$type == "concept") {
        dplyr::tibble(
          label = if (is.null(x$label)) x$concept_set else x$label,
          points = as.numeric(x$score)
        )
      } else if (x$type == "age_group") {
        dplyr::tibble(
          label = purrr::map_chr(x$age_groups, "label"),
          points = purrr::map_dbl(x$age_groups, "score")
        )
      } else if (x$type == "polypharmacy") {
        dplyr::tibble(
          label = purrr::map_chr(x$drug_groups, "label"),
          points = purrr::map_dbl(x$drug_groups, "score")
        )
      } else if (x$type == "measurement") {
        dplyr::tibble(
          label = purrr::map_chr(x$measurement_groups, "label"),
          points = purrr::map_dbl(x$measurement_groups, "score")
        )
      }
    }) |>
    dplyr::bind_rows()
}

getCohortComponents <- function(definition) {
  # age groups
  defAgeGroups <- definition[purrr::map_chr(definition, "type") == "age_group"] |>
    purrr::map(\(x) {
      list(
        type = "age_group",
        ageGroup = purrr::map(x$age_groups, "age_range") |>
          rlang::set_names(purrr::map_chr(x$age_groups, "label"))
      )
    })

  # polypharmacy
  defPoly <- definition[purrr::map_chr(definition, "type") == "polypharmacy"] |>
    purrr::map(\(x) {
      categories <- purrr::map(x$drug_groups, \(band) {
        # Convert exclusive count bounds to inclusive integer bounds.
        lower <- ceiling(band$drug_range[1])
        upper <- floor(band$drug_range[2])
        if (identical(band$lower_inclusive, FALSE)) {
          lower <- floor(band$drug_range[1]) + 1
        }
        if (identical(band$upper_inclusive, FALSE)) {
          upper <- ceiling(band$drug_range[2]) - 1
        }
        c(lower, upper)
      }) |> rlang::set_names(purrr::map_chr(x$drug_groups, "label"))

      list(
        type = "polypharmacy",
        window = c(-x$follow_up, 0),
        overlap = x$overlap,
        group = x$drug_group,
        categories = categories
      )
    })

  # concepts: earlier components in the same group censor later ones
  defConcept <- definition[purrr::map_chr(definition, "type") == "concept"]
  defConcept <- defConcept |>
    purrr::imap(\(x, i) {
      comp <- list(
        type = "concept",
        conceptSet = x$concept_set,
        followUp = x$follow_up
      )
      if (!is.null(x$group)) {
        censor <- defConcept[seq_len(i - 1L)] |>
          purrr::keep(\(previous) identical(previous$group, x$group)) |>
          purrr::map_chr("concept_set")
        if (length(censor) > 0) comp$censor <- censor
      }
      comp
    })

  c(defAgeGroups, defPoly, defConcept)
}

getNeededConcepts <- function(definition) {
  definition |>
    purrr::map(\(x) {
      if (x$type == "concept") {
        x$concept_set
      } else if (x$type == "measurement") {
        c(x$concept_set, as.character(unlist(purrr::map(x$measurement_groups, "measurement_concept"))))
      } else {
        character()
      }
    }) |>
    purrr::flatten_chr() |>
    unique() |>
    sort()
}

componentName <- function(x) {
  if (!is.null(x$name_style)) return(x$name_style)
  if (!is.null(x$label)) return(x$label)
  if (!is.null(x$concept_set)) return(x$concept_set)
  cli::cli_abort(c(x = "Component has no name"))
}
