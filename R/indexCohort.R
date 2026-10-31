
indexCohortFromKey <- function(cdm,
                               key,
                               categories,
                               name,
                               conceptSet,
                               subsetCohort,
                               subsetCohortId,
                               call = parent.frame()) {
  indexCohort(
    cdm = cdm,
    points = points[[key]],
    cohortComponents = cohortComponents[[key]],
    categories = categories,
    name = name,
    conceptSet = conceptSet,
    subsetCohort = subsetCohort,
    subsetCohortId = {{subsetCohortId}},
    call = call
  )
}

indexCohort <- function(cdm,
                        points,
                        cohortComponents,
                        categories,
                        name,
                        conceptSet,
                        subsetCohort,
                        subsetCohortId,
                        call = parent.frame()) {
  # input check
  cdm <- omopgenerics::validateCdmArgument(cdm = cdm, call = call)
  omopgenerics::assertList(categories, named = TRUE, class = "numeric", call = call)
  name <- omopgenerics::validateNameArgument(name = name, cdm = cdm, call = call)
  neededConcepts <- neededConceptSet(cohortComponents)
  conceptSet <- validateConceptSet(conceptSet, neededConcepts, cdm, call = call)
  omopgenerics::assertCharacter(subsetCohort, null = TRUE, call = call)

  # get individuals of interest
  pref <- omopgenerics::tmpPrefix()
  if (!is.null(subsetCohort)) {
    subset <- cdm[[subsetCohort]] |>
      PatientProfiles::filterCohortId(cohortId = {{subsetCohortId}}) |>
      dplyr::distinct(.data$subject_id) |>
      dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))
  } else {
    subset <- cdm$person |>
      dplyr::select("person_id")
  }

  # identify all events of interest

  # get the episodes per component
  episodes  <- list()
  for (i in seq_along(cohortComponents)) {
    comp <- component[[i]]
    if (comp$type == "age_group") {
      episodes[[i]] <- ageGroupEpisodes(cdm, comp$ageGroup, pref, subset)
    } else if (comp$type == "polypharmacy") {

    } else if (comp$type == "bmi") {
      episodes[[i]] <- bmiEpisodes(cdm, comp$bmiGroup, pref, subset, conceptSet)
    } else if (comp$type == "concept_flag") {
      episodes[[i]] <- conceptEpisodes(cdm, conceptSet[comp$conceptSet], comp$window, subset, pref)
    } else if (comp$type %in% c("measurement_flag", "cohort_flag")) {
      if (comp$type == "measurement_flag") {

      } else {

      }
    }
  }

  # join all episodes
  nm <- omopgenerics::uniqueTableName()
  episodes <- episodes |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = nm)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(pref))

  # apply points and categories
  nm <- omopgenerics::uniqueTableName()
  cdm <- omopgenerics::insertTable(cdm = cdm, name = nm, table = points)
  episodes <- episodes |>
    dplyr::inner_join(cdm[[nm]], by = "cohort_name") |>
    dplyr::select(!"cohort_name") |>
    dplyr::compute(name = nm)

  # calculate points and categories
  nameStyle <- "points"
  q <- qCategories(categories) |>
    rlang::set_names("cohort_name") |>
    rlang::parse_exprs()
  cdm[[name]] <- splitEpisodes(episodes, nm) |> # split in small episodes
    dplyr::inner_join(
      episodes |>
        dplyr::select("person_id", "start", "end", "points"),
      by = dplyr::join_by("person_id", cohort_start_date <= end, start <= cohort_end_date)
    ) |>
    # calculate points per path
    dplyr::group_by(.data$person_id, .data$cohort_start_date, .data$cohort_end_date) |>
    dplyr::summarise(points = sum(.data$points, na.rm = TRUE), .groups = "drop") |>
    # add categories
    dplyr::mutate(!!!q) |>
    dplyr::compute(name = nm) |>
    # erafy
    OmopConstructor::collapseRecords(
      startDate = "cohort_start_date",
      endDate = "cohort_end_date",
      by = c("cohort_name"),
      gap = 1L,
      name = name
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

  # drop tables

  return(cdm[[name]])
}

ageGroupEpisodes <- function(cdm, ageGroup, pref, subset) {
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
            .data$observation_period_start_date
          )", ag[2] + 1, ag[2] + 1
        ))
      }
      q <- c(q, paste0('"', nm, '"')) |>
        rlang::parse_exprs() |>
        rlang::set_names(c("start", "end", "cohort_name"))

      subset |>
        dplyr::mutate(!!!q) |>
        dplyr::filter(.data$start <= .data$end) |>
        dplyr::select("person_id", "start", "end", "cohort_name") |>
        dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))
    }) |>
    purrr::reduce(dplyr::union_all) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))

  # drop created tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  return(ageGroupRecords)
}
bmiEpisodes <- function(cdm, bmiGroup, pref, subset, conceptSet) {
  # internal prefix
  ip <- omopgenerics::tmpPrefix()

  # get bmi records
  bmiTable <- omopgenerics::uniqueTableName(prefix = ip)
  bmiRecords <- tablesToSubset(conceptSet, cdm) |>
    getRecords(cdm, conceptSet, subset, c(-Inf, Inf), bmiTable) |>
    subsetInObservation(TRUE, bmiTable)

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
  q <- qCategories(bmiGroup) |>
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
      "cohort_start_date" = "bmi_date",
      "cohort_name"
    ) |>
    dplyr::compute(name = bmiTable) |>
    # add id group
    dplyr::group_by(.data$person_id) |>
    dplyr::arrange(.data$cohort_start_date) |>
    dplyr::mutate(id = as.integer(dplyr::row_number())) |>
    dplyr::ungroup() |>
    dplyr::compute(name = bmiTable)

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
        dplyr::select("person_id", "cohort_end_date" = "cohort_start_date", "id") |>
        dplyr::mutate(
          cohort_end_date = as.Date(clock::add_days(.data$cohort_end_date, -1L)),
          id = .data$id - 1L
        ),
      by = c("person_id", "id")
    ) |>
    dplyr::mutate(cohort_end_date = dplyr::coalesce(
      .data$cohort_end_date, .data$observation_period_end_date
    )) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip)) |>
    # erafy
    OmopConstructor::collapseRecords(
      startDate = "cohort_start_date",
      endDate = "cohort_end_date",
      by = c("person_id", "cohort_name"),
      gep = 1L,
      name = omopgenerics::uniqueTableName(prefix = pref)
    )

  # drop tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  return(bmiRecords)
}
splitEpisodes <- function(episodes, nm) {
  ip <- omopgenerics::tmpPrefix()

  # start dates
  startDates <- episodes |>
    dplyr::select("person_id", "cohort_start_date") |>
    dplyr::union_all(
      episodes |>
        dplyr::select("person_id", "cohort_start_date" = "cohort_end_date") |>
        dplyr::mutate(cohort_start_date = as.Date(clock::add_days(.data$cohort_start_date, 1L)))
    ) |>
    dplyr::distinct() |>
    dplyr::group_by(.data$person_id) |>
    dplyr::arrange(.data$cohort_start_date) |>
    dplyr::mutate(id = as.integer(dplyr::row_number())) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))

  # end dates
  endDates <- episodes |>
    dplyr::select("person_id", "cohort_end_date") |>
    dplyr::union_all(
      episodes |>
        dplyr::select("person_id", "cohort_end_date" = "cohort_start_date") |>
        dplyr::mutate(cohort_end_date = as.Date(clock::add_days(.data$cohort_end_date, -1L)))
    ) |>
    dplyr::distinct() |>
    dplyr::group_by(.data$person_id) |>
    dplyr::arrange(.data$cohort_end_date) |>
    dplyr::mutate(id = as.integer(dplyr::row_number())) |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))

  # splitted episodes
  episodes <- startDates |>
    dplyr::inner_join(endDates, by = c("person_id", "id")) |>
    dplyr::select(!"id") |>
    dplyr::compute(name = nm)

  # drop tables
  episodes |>
    omopgenerics::cdmReference() |>
    omopgenerics::dropSourceTable(name = dplyr::starts_with(ip))

  return(episodes)
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
conceptEpisodes <- function(cdm, conceptSet, window, subset, pref) {

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
  nm <- omopgenerics::uniqueTableName()
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
        dplyr::select("person_id", "start" = dplyr::all_of(start), "cohort_name") |>
        dplyr::compute(name = omopgenerics::uniqueTableName(prefix = ip))
    }) |>
    purrr::compact() |>
    purrr::reduce(dplyr::union_all) |>
    PatientProfiles::filterInObservation("start") |>
    dplyr::compute(name = nm)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(ip))

  # use window
  nm1 <- omopgenerics::uniqueTableName()
  if (is.infinite(window[1])) {
    records <- records |>
      dplyr::group_by(.data$person_id, .data$cohort_name) |>
      dplyr::summarise(start = min(.data$start, na.rm = TRUE), .groups = "drop") |>
      dplyr::mutate(end = as.Date(NA)) |>
      dplyr::compute(name = nm1)
  } else {
    records <- records |>
      dplyr::mutate(end = as.Date(clock::add_days(.data$start, !!-window[1]))) |>
      OmopConstructor::collapseRecords(
        startDate = "start",
        endDate = "end",
        by = c("person_id", "cohort_name"),
        gap = 1L,
        name = nm1
      )
  }
  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  # correct by observation_period_end_date
  records <- records |>
    dplyr::inner_join(
      cdm$observation_period |>
        dplyr::select("person_id", "observation_period_end_date"),
      by = "person_id"
    ) |>
    dplyr::mutate(end = dplyr::case_when(
      is.na(.data$end) ~ .data$observation_period_end_date,
      .data$observation_period_end_date < .data$end ~ .data$observation_period_end_date,
      .default = .data$end
    )) |>
    dplyr::select("cohort_name", "person_id", "start", "end") |>
    dplyr::compute(name = omopgenerics::uniqueTableName(prefix = pref))

  # drop tables
  omopgenerics::dropSourceTable(cdm = cdm, name = nm1)

  return(records)
}
