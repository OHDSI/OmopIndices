
indexCohort <- function(cdm,
                        definition,
                        categories,
                        name,
                        conceptSet,
                        subsetCohort,
                        subsetCohortId,
                        call = parent.frame()) {
  # input check
  cdm <- omopgenerics::validateCdmArgument(cdm = cdm, call = call)
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", call = call)
  name <- omopgenerics::validateNameArgument(name = name, cdm = cdm, call = call, validation = "warning")
  neededConcepts <- getNeededConcepts(definition)
  conceptSet <- validateConceptSet(conceptSet, neededConcepts, cdm, call = call)
  omopgenerics::assertCharacter(subsetCohort, null = TRUE, call = call)

  # get points and cohort components
  points <- getPointsMatrix(definition)
  cohortComponents <- getCohortComponents(definition)

  # get individuals of interest
  pref <- omopgenerics::tmpPrefix()
  if (!is.null(subsetCohort)) {
    subset <- cdm[[subsetCohort]] |>
      PatientProfiles::filterCohortId(cohortId = {{subsetCohortId}}) |>
      dplyr::distinct(.data$subject_id) |>
      dplyr::rename("person_id" = "subject_id") |>
      dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))
  } else {
    subset <- cdm$person |>
      dplyr::select("person_id")
  }

  # get the episodes per component
  episodes  <- list()
  for (i in seq_along(cohortComponents)) {
    comp <- cohortComponents[[i]]
    if (comp$type == "age_group") {
      episodes[[i]] <- ageGroupEpisodes(cdm, comp, pref, subset)
    } else if (comp$type == "polypharmacy") {
      episodes[[i]] <- polypharmacyEpisodes(cdm, comp, subset, pref)
    } else if (comp$type == "bmi") {
      episodes[[i]] <- bmiEpisodes(cdm, comp, pref, subset, conceptSet)
    } else if (comp$type == "concept") {
      episodes[[i]] <- conceptEpisodes(cdm, conceptSet, comp, subset, pref)
    }
  }

  # join all episodes
  episodeTable <- omopgenerics::uniqueTableName()
  episodes <- purrr::compact(episodes)
  if (length(episodes)) {
    episodes <- purrr::reduce(episodes, dplyr::union_all)
  } else {
    episodes <- subset |>
      dplyr::filter(FALSE) |>
      dplyr::mutate(episode_start = as.Date(NA), episode_end = as.Date(NA), cohort_name = NA_character_)
  }
  episodes <- dplyr::compute(episodes, name = episodeTable)

  # baseline intervals ensure people without component events receive 0 points
  baselineTable <- omopgenerics::uniqueTableName()
  baseline <- subset |>
    dplyr::inner_join(
      cdm$observation_period |>
        dplyr::select(
          "person_id",
          "episode_start" = "observation_period_start_date",
          "episode_end" = "observation_period_end_date"
        ),
      by = "person_id"
    ) |>
    dplyr::mutate(points = 0L) |>
    dplyr::select("person_id", "episode_start", "episode_end", "points") |>
    dplyr::compute(name = baselineTable)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  # apply points and categories
  pointsTable <- omopgenerics::uniqueTableName()
  scoredTable <- omopgenerics::uniqueTableName()
  cdm <- omopgenerics::insertTable(cdm = cdm, name = pointsTable, table = points)
  episodes <- episodes |>
    dplyr::inner_join(cdm[[pointsTable]], by = c("cohort_name" = "label")) |>
    dplyr::select(!"cohort_name") |>
    dplyr::compute(name = scoredTable)
  cdm <- omopgenerics::dropSourceTable(cdm = cdm, name = episodeTable)
  combinedTable <- omopgenerics::uniqueTableName()
  episodes <- dplyr::union_all(episodes, baseline) |>
    dplyr::compute(name = combinedTable)
  cdm <- omopgenerics::dropSourceTable(
    cdm = cdm,
    name = c(scoredTable, baselineTable)
  )

  # calculate points and categories
  nameStyle <- "points"
  q <- qCategories(categories) |>
    rlang::set_names("cohort_name") |>
    rlang::parse_exprs()
  splitTable <- omopgenerics::uniqueTableName()
  aggregateTable <- omopgenerics::uniqueTableName()
  aggregate <- splitEpisodes(episodes, splitTable) |> # split in small episodes
    dplyr::inner_join(
      episodes |>
        dplyr::select("person_id", "episode_start", "episode_end", "points"),
      by = dplyr::join_by(
        "person_id",
        x$cohort_start_date <= y$episode_end,
        y$episode_start <= x$cohort_end_date
      )
    ) |>
    # Sum the active contributions; grouped concepts have already been censored.
    dplyr::group_by(.data$person_id, .data$cohort_start_date, .data$cohort_end_date) |>
    dplyr::summarise(points = sum(.data$points, na.rm = TRUE), .groups = "drop") |>
    # add categories
    dplyr::mutate(!!!q) |>
    dplyr::filter(!is.na(.data$cohort_name)) |>
    dplyr::select(!"points") |>
    dplyr::compute(name = aggregateTable)
  cdm <- omopgenerics::dropSourceTable(
    cdm = cdm,
    name = c(combinedTable, splitTable, pointsTable)
  )

  collapsedTable <- omopgenerics::uniqueTableName()
  collapsed <- OmopConstructor::collapseRecords(
    aggregate,
    startDate = "cohort_start_date",
    endDate = "cohort_end_date",
    by = c("person_id", "cohort_name"),
    gap = 1L,
    name = collapsedTable
  )
  cdm[[name]] <- collapsed |>
    dplyr::rename("subject_id" = "person_id") |>
    dplyr::compute(name = name)
  cdm <- omopgenerics::dropSourceTable(
    cdm = cdm,
    name = c(aggregateTable, collapsedTable)
  )

  # create settings
  set <- dplyr::tibble(
    cohort_definition_id = as.integer(seq_along(categories)),
    cohort_name = names(categories)
  )
  q <- set |>
    purrr::pmap_chr(\(cohort_definition_id, cohort_name) {
      paste0(".data$cohort_name == '", cohort_name, "' ~ ", cohort_definition_id, "L")
    }) |>
    paste(collapse = ",") |>
    (\(x) paste0("dplyr::case_when(", x, ")"))() |>
    rlang::parse_exprs() |>
    rlang::set_names("cohort_definition_id")
  cdm[[name]] <- cdm[[name]] |>
    dplyr::mutate(!!!q) |>
    dplyr::select(!"cohort_name") |>
    dplyr::compute(name = name) |>
    omopgenerics::newCohortTable(
      cohortSetRef = set,
      cohortAttritionRef = NULL,
      cohortCodelistRef = NULL # TODO add codelists??
    )

  return(cdm[[name]])
}

ageGroupEpisodes <- function(cdm, comp, pref, subset) {
  # parameters
  ageGroup <- comp$ageGroup

  # internal prefix
  ip <- omopgenerics::tmpPrefix()

  # add observation periods
  subset <- subset |>
    dplyr::inner_join(
      cdm$observation_period |>
        dplyr::select(
          "person_id",
          "observation_period_start_date",
          "observation_period_end_date"
        ),
      by = "person_id"
    ) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))

  # get dates of interest
  ageGroup <- ageGroup |>
    purrr::map(\(ag) suppressWarnings(as.integer(ag)))
  birthdays <- ageGroup |>
    purrr::map(\(ag) {ag + c(0L, 1L)}) |>
    unlist(use.names = FALSE) |>
    unique() |>
    purrr::keep(\(x) !is.na(x))
  for (bd in birthdays) {
    subset <- subset |>
      PatientProfiles::addBirthday(
        birthday = bd,
        birthdayName = sprintf("bd_%i", bd),
        name = omopgenerics::uniqueTableName(prefix = ip)
      )
  }

  # filter to contribution of interest
  ageGroupRecords <- ageGroup |>
    purrr::imap(\(ag, nm) {
      if (is.na(ag[1])) {
        q <- ".data$observation_period_start_date"
      } else {
        q <- sprintf(
          "dplyr::if_else(
            .data$observation_period_start_date < .data$bd_%i,
            .data$bd_%i,
            .data$observation_period_start_date
          )", ag[1], ag[1]
        )
      }
      if (is.na(ag[2])) {
        q <- c(q, ".data$observation_period_end_date")
      } else {
        q <- c(q, sprintf(
          "dplyr::if_else(
            .data$observation_period_end_date > as.Date(clock::add_days(.data$bd_%i, -1L)),
            as.Date(clock::add_days(.data$bd_%i, -1L)),
            .data$observation_period_end_date
          )", ag[2] + 1, ag[2] + 1
        ))
      }
      q <- c(q, paste0('"', nm, '"')) |>
        rlang::parse_exprs() |>
        rlang::set_names(c("episode_start", "episode_end", "cohort_name"))

      subset |>
        dplyr::mutate(!!!q) |>
        dplyr::filter(.data$episode_start <= .data$episode_end) |>
        dplyr::select("person_id", "episode_start", "episode_end", "cohort_name") |>
        dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))
    }) |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))

  # drop created tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  return(ageGroupRecords)
}
bmiEpisodes <- function(cdm, bmiGroup, pref, subset, conceptSet, categoryExpression = NULL) {
  # internal prefix
  ip <- omopgenerics::tmpPrefix()

  # get bmi records
  bmiTable <- omopgenerics::uniqueTableName(prefix = ip)
  bmiRecords <- getMeasurementRecords(cdm, conceptSet$bmi, subset, c(-Inf, Inf), bmiTable) |>
    dplyr::filter(!is.na(.data$value_as_number)) |>
    PatientProfiles::filterInObservation(indexDate = "measurement_date") |>
    # Match addBMI's tie rule: keep the maximum when dates are identical.
    dplyr::group_by(.data$person_id, .data$measurement_date) |>
    dplyr::summarise(bmi = max(.data$value_as_number, na.rm = TRUE), .groups = "drop") |>
    dplyr::rename(bmi_date = "measurement_date")

  # add observation periods
  subset <- subset |>
    dplyr::inner_join(
      cdm$observation_period |>
        dplyr::select(
          "person_id",
          "observation_period_start_date",
          "observation_period_end_date"
        ),
      by = "person_id"
    ) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))

  # construct bmi episodes
  nameStyle <- "bmi"
  q <- (if (is.null(categoryExpression)) qCategories(bmiGroup) else categoryExpression) |>
    rlang::set_names("cohort_name") |>
    rlang::parse_exprs()
  bmiRecords <- subset |>
    dplyr::select("person_id", "bmi_date" = "observation_period_start_date") |>
    dplyr::mutate(bmi = NA_real_) |>
    dplyr::union_all(bmiRecords) |>
    dplyr::group_by(.data$person_id, .data$bmi_date) |>
    dplyr::summarise(bmi = mean(.data$bmi, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(!!!q) |>
    dplyr::select(
      "person_id",
      "episode_start" = "bmi_date",
      "cohort_name"
    ) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip)) |>
    # add id group
    dplyr::group_by(.data$person_id) |>
    dplyr::arrange(.data$episode_start) |>
    dplyr::mutate(id = as.integer(dplyr::row_number())) |>
    dplyr::ungroup() |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))

  bmiRecords <- bmiRecords |>
    # add end of observation
    dplyr::inner_join(
      subset |>
        dplyr::select("person_id", "observation_period_end_date"),
      by = "person_id"
    ) |>
    # add start of next episode
    dplyr::left_join(
      bmiRecords |>
        dplyr::select("person_id", "episode_end" = "episode_start", "id") |>
        dplyr::mutate(
          episode_end = as.Date(clock::add_days(.data$episode_end, -1L)),
          id = .data$id - 1L
        ),
      by = c("person_id", "id")
    ) |>
    dplyr::mutate(episode_end = dplyr::coalesce(.data$episode_end, .data$observation_period_end_date)) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip)) |>
    # erafy
    OmopConstructor::collapseRecords(
      startDate = "episode_start",
      endDate = "episode_end",
      by = c("person_id", "cohort_name"),
      gap = 1L,
      name = omopgenerics::uniqueTableName(prefix = pref)
    )

  # drop tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  return(bmiRecords)
}
splitEpisodes <- function(episodes, nm) {
  # split at every episode start and the day after every episode end
  episodes |>
    dplyr::select("person_id", "cohort_start_date" = "episode_start") |>
    dplyr::union_all(
      episodes |>
        dplyr::select("person_id", "cohort_start_date" = "episode_end") |>
        dplyr::mutate(cohort_start_date = as.Date(clock::add_days(.data$cohort_start_date, 1L)))
    ) |>
    dplyr::distinct() |>
    dplyr::group_by(.data$person_id) |>
    dplyr::arrange(.data$cohort_start_date) |>
    dplyr::mutate(
      cohort_end_date = as.Date(clock::add_days(dplyr::lead(.data$cohort_start_date), -1L))
    ) |>
    dplyr::filter(!is.na(.data$cohort_end_date)) |>
    dplyr::select("person_id", "cohort_start_date", "cohort_end_date") |>
    dplyr::compute(name = nm)
}
domainsData <- dplyr::tribble(
  ~"domain_id",    ~"table",               ~"concept",                ~"source",                         ~"start",                     ~"end",
  "drug",          "drug_exposure",        "drug_concept_id",         "drug_source_concept_id",         "drug_exposure_start_date",   "drug_exposure_end_date",
  "condition",     "condition_occurrence", "condition_concept_id",    "condition_source_concept_id",    "condition_start_date",       "condition_end_date",
  "procedure",     "procedure_occurrence", "procedure_concept_id",    "procedure_source_concept_id",    "procedure_date",             "procedure_date",
  "observation",   "observation",          "observation_concept_id",  "observation_source_concept_id",  "observation_date",           "observation_date",
  "measurement",   "measurement",          "measurement_concept_id",  "measurement_source_concept_id",  "measurement_date",           "measurement_date",
  "visit",         "visit_occurrence",     "visit_concept_id",        "visit_source_concept_id",        "visit_start_date",           "visit_end_date",
  "device",        "device_exposure",      "device_concept_id",       "device_source_concept_id",       "device_exposure_start_date", "device_exposure_end_date",
  "visit_detail",  "visit_detail",         "visit_detail_concept_id", "visit_detail_source_concept_id", "visit_detail_start_date",    "visit_detail_end_date",
  "drug_era",      "drug_era",             "drug_concept_id",         NA,                               "drug_era_start_date",        "drug_era_end_date",
  "condition_era", "condition_era",        "condition_concept_id",    NA,                               "condition_era_start_date",   "condition_era_end_date"
)
getEvents <- function(cdm, conceptSet, subset, nm) {
  # internal prefix
  ip <- omopgenerics::tmpPrefix()

  # insert concept table
  con <- omopgenerics::uniqueTableName(prefix = ip)
  x <- dplyr::as_tibble(conceptSet) |>
    dplyr::rename("cohort_name" = "codelist_name")
  cdm <- omopgenerics::insertTable(cdm = cdm, name = con, table = x)

  # tables
  domains <- cdm$concept |>
    dplyr::inner_join(cdm[[con]], by = "concept_id") |>
    dplyr::distinct(.data$domain_id) |>
    dplyr::pull() |>
    tolower()

  # not supported domains
  notSupported <- domains |>
    purrr::keep(\(x) !x %in% domainsData$domain_id)
  if (length(notSupported)) {
    cli::cli_warn(c("!" = "Some of the provided concept domains are not supported: {notSupported}."))
  }

  # records
  records <- domains |>
    purrr::keep(\(x) x %in% domainsData$domain_id) |>
    purrr::map(\(domain) {
      table <- domainsData$table[domainsData$domain_id == domain]
      start <- domainsData$start[domainsData$domain_id == domain]
      concept <- domainsData$concept[domainsData$domain_id == domain]
      cdm[[table]] |>
        dplyr::inner_join(subset, by = "person_id") |>
        dplyr::inner_join(
          cdm[[con]] |>
            dplyr::select(!!concept := "concept_id", "cohort_name"),
          by = concept
        ) |>
        dplyr::select("person_id", "event_date" = dplyr::all_of(start), "cohort_name") |>
        dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))
    }) |>
    purrr::compact()

  if (length(records) == 0) {
    records <- cdm$person |>
      dplyr::select("person_id") |>
      dplyr::filter(.data$person_id < 0L & .data$person_id > 0L) |>
      dplyr::mutate(
        event_date = as.Date(NA),
        cohort_name = ""
      ) |>
      dplyr::compute(name = nm)
    return(records)
  }

  records <- records |>
    purrr::reduce(dplyr::union_all) |>
    PatientProfiles::filterInObservation("event_date") |>
    dplyr::compute(name = nm)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  return(records)
}
conceptEpisodes <- function(cdm, conceptSet, comp, subset, pref) {
  # get events of interest
  conceptSet <- conceptSet[c(comp$conceptSet, comp$censor)]
  nm <- omopgenerics::uniqueTableName()
  events <- getEvents(cdm, conceptSet, subset, nm)

  censor <- !is.null(comp$censor)
  followUp <- comp$followUp
  infinite <- is.infinite(followUp)

  indexEvents <- events |>
    dplyr::rename("episode_start" = "event_date")

  # end limit: end of observation or first censor event
  limits <- cdm$observation_period |>
    dplyr::select("person_id", "episode_end" = "observation_period_end_date")
  if (censor) {
    censorDates <- events |>
      dplyr::filter(.data$cohort_name %in% !!comp$censor) |>
      dplyr::group_by(.data$person_id) |>
      dplyr::summarise(
        censor_date = min(.data$event_date, na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::mutate(censor_date = as.Date(clock::add_days(.data$censor_date, -1L)))
    limits <- limits |>
      dplyr::left_join(censorDates, by = "person_id") |>
      dplyr::mutate(
        episode_end = dplyr::if_else(
          is.na(.data$censor_date) | .data$episode_end <= .data$censor_date,
          .data$episode_end,
          .data$censor_date
        )
      ) |>
      dplyr::select("person_id", "episode_end")
    indexEvents <- indexEvents |>
      dplyr::filter(.data$cohort_name %in% !!comp$conceptSet)
  }

  # episodes
  if (infinite) {
    # only first event
    indexEvents <- indexEvents |>
      dplyr::group_by(.data$person_id, .data$cohort_name) |>
      dplyr::summarise(episode_start = min(.data$episode_start, na.rm = TRUE), .groups = "drop")
  }
  records <- indexEvents |>
    dplyr::inner_join(limits, by = "person_id")
  if (!infinite) {
    followUp <- as.integer(followUp)
    records <- records |>
      dplyr::mutate(
        follow_up = as.Date(clock::add_days(.data$episode_start, !!followUp)),
        episode_end = dplyr::if_else(.data$episode_end < .data$follow_up, .data$episode_end, .data$follow_up)
      )
  }
  records <- records |>
    dplyr::filter(.data$episode_start <= .data$episode_end) |>
    dplyr::select("cohort_name", "person_id", "episode_start", "episode_end")

  name <- omopgenerics::uniqueTableName(prefix = pref)
  if (infinite) {
    records <- dplyr::compute(records, name = name)
  } else {
    records <- OmopConstructor::collapseRecords(
      records,
      startDate = "episode_start",
      endDate = "episode_end",
      by = c("person_id", "cohort_name"),
      gap = 1L,
      name = name
    )
  }

  # drop events table
  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  return(records)
}
polypharmacyEpisodes <- function(cdm, comp, subset, pref) {
  # parameters
  group <- comp$group
  categories <- comp$categories
  overlap <- comp$overlap
  window <- comp$window
  windowStart <- as.integer(window[1])
  windowEnd <- as.integer(window[2])

  table <- if (identical(group, "ingredient drug_era")) "drug_era" else "drug_exposure"
  join <- validateGroup(group, cdm)

  # check table is empty
  if (omopgenerics::isTableEmpty(cdm[[table]])) {
    cli::cli_warn(c("!" = "{.pkg {table}} table is empty."))
    return(NULL)
  }

  # subset to people of interest
  records <- cdm[[table]] |>
    dplyr::inner_join(subset, by = "person_id")

  # join by groups
  if (!is.character(join)) {
    records <- records |>
      dplyr::inner_join(join, by = "drug_concept_id")
  }

  records <- records |>
    dplyr::select(
      "person_id",
      "episode_start" = omopgenerics::omopColumns(table = table, field = "start_date"),
      "episode_end" = omopgenerics::omopColumns(table = table, field = "end_date"),
      "group" = ifelse(is.character(join), "drug_concept_id", "group")
    )

  # collapse by group
  nm1 <- omopgenerics::uniqueTableName()
  records <- records |>
    OmopConstructor::collapseRecords(
      startDate = "episode_start",
      endDate = "episode_end",
      by = c("person_id", "group"),
      name = nm1
    )

  concurrentName <- NULL
  if (!overlap) {
    # count distinct groups that intersect with window
    if (windowEnd != 0L) {
      records <- records |>
        dplyr::mutate(
          episode_start = as.Date(clock::add_days(.data$episode_start, !!(-windowEnd)))
        )
    }
    if (windowStart != 0L) {
      records <- records |>
        dplyr::mutate(
          episode_end = as.Date(clock::add_days(.data$episode_end, !!(-windowStart)))
        )
    }
    if (windowStart != 0L || windowEnd != 0L) {
      expandedName <- omopgenerics::uniqueTableName()
      records <- records |>
        OmopConstructor::collapseRecords(
          startDate = "episode_start",
          endDate = "episode_end",
          by = c("person_id", "group"),
          name = expandedName
        )
      omopgenerics::dropSourceTable(cdm = cdm, name = nm1)
      nm1 <- expandedName
    }
    records <- polypharmacyCountIntervals(records)
  } else {
    concurrentName <- omopgenerics::uniqueTableName()
    concurrent <- polypharmacyCountIntervals(records)
    if (windowEnd != 0L) {
      concurrent <- concurrent |>
        dplyr::mutate(
          episode_start = as.Date(clock::add_days(.data$episode_start, !!(-windowEnd)))
        )
    }
    if (windowStart != 0L) {
      concurrent <- concurrent |>
        dplyr::mutate(
          episode_end = as.Date(clock::add_days(.data$episode_end, !!(-windowStart)))
        )
    }
    concurrent <- concurrent |>
      dplyr::compute(name = concurrentName)

    boundaries <- concurrent |>
      dplyr::select("person_id", "event_date" = "episode_start") |>
      dplyr::union_all(
        concurrent |>
          dplyr::mutate(event_date = as.Date(clock::add_days(.data$episode_end, 1L))) |>
          dplyr::select("person_id", "event_date")
      ) |>
      dplyr::distinct()

    records <- boundaries |>
      dplyr::left_join(
        concurrent,
        by = dplyr::join_by(
          "person_id",
          x$event_date >= y$episode_start,
          x$event_date <= y$episode_end
        )
      ) |>
      dplyr::group_by(.data$person_id, .data$event_date) |>
      dplyr::summarise(
        num_counts = max(dplyr::coalesce(.data$num_counts, 0L), na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::group_by(.data$person_id) |>
      dplyr::arrange(.data$event_date) |>
      dplyr::mutate(
        episode_start = .data$event_date,
        episode_end = as.Date(clock::add_days(dplyr::lead(.data$event_date), -1L))
      ) |>
      dplyr::filter(
        !is.na(.data$episode_end),
        .data$episode_start <= .data$episode_end,
        .data$num_counts > 0L
      ) |>
      dplyr::ungroup()
  }

  # calculate categories from the count at each index date
  nameStyle <- "num_counts"
  q <- qCategories(categories) |>
    rlang::set_names("cohort_name") |>
    rlang::parse_exprs()
  records <- records |>
    dplyr::mutate(!!!q)

  records <- records |>
    dplyr::select("person_id", "episode_start", "episode_end", "cohort_name")

  nm2 <- omopgenerics::uniqueTableName()
  records <- records |>
    dplyr::compute(name = nm2)
  if (!is.null(concurrentName)) {
    omopgenerics::dropSourceTable(cdm = cdm, name = concurrentName)
  }
  omopgenerics::dropSourceTable(cdm = cdm, name = nm1)

  # collapse by categories
  records <- records |>
    OmopConstructor::collapseRecords(
      startDate = "episode_start",
      endDate = "episode_end",
      by = c("person_id", "cohort_name"),
      gap = 1L,
      name = omopgenerics::uniqueTableName(prefix = pref)
    )

  omopgenerics::dropSourceTable(cdm = cdm, name = nm2)

  return(records)
}

polypharmacyCountIntervals <- function(records) {
  records |>
    dplyr::select("person_id", "event_date" = "episode_start") |>
    dplyr::mutate(delta = 1L) |>
    dplyr::union_all(
      records |>
        dplyr::mutate(event_date = as.Date(clock::add_days(.data$episode_end, 1L))) |>
        dplyr::select("person_id", "event_date") |>
        dplyr::mutate(delta = -1L)
    ) |>
    dplyr::group_by(.data$person_id, .data$event_date) |>
    dplyr::summarise(delta = sum(.data$delta, na.rm = TRUE), .groups = "drop") |>
    dplyr::group_by(.data$person_id) |>
    dplyr::arrange(.data$event_date) |>
    dplyr::mutate(
      num_counts = cumsum(.data$delta),
      episode_start = .data$event_date,
      episode_end = as.Date(clock::add_days(dplyr::lead(.data$event_date), -1L))
    ) |>
    dplyr::filter(
      !is.na(.data$episode_end),
      .data$episode_start <= .data$episode_end,
      .data$num_counts > 0L
    ) |>
    dplyr::select("person_id", "episode_start", "episode_end", "num_counts") |>
    dplyr::ungroup()
}
