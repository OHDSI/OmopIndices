test_that("ethnicity works", {
  cdm <- omock::mockCdmFromTables(tables = list(
    cohort = dplyr::tibble(
      cohort_definition_id = 1L,
      subject_id = 1:8L,
      cohort_start_date = as.Date("2020-01-01"),
      cohort_end_date = cohort_start_date
    )
  ))

  # ethnicity
  cdm$person <- cdm$person |>
    dplyr::mutate(
      race_concept_id = NA_integer_,
      race_source_concept_id = NA_integer_,
      race_source_value = NA_character_,
      ethnicity_concept_id = NA_integer_,
      ethnicity_source_concept_id = NA_integer_,
      ethnicity_source_value = NA_character_
    )

  cdm <- copyCdm(cdm)

  # expect all missing
  expect_no_error(
    cdm$cohort <- cdm$cohort |>
      addEthnicity()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("ethnicity") |>
      unique(),
    "Missing"
  )

  # add ethnicity via ethnicity_source_concept_id
  cdm$person <- cdm$person |>
    dplyr::mutate(ethnicity_source_concept_id = dplyr::case_when(
      person_id %in% 1:4 ~ 8515L,
      person_id %in% 5:6 ~ 8522L,
      person_id == 7 ~ 8527L,
      person_id == 8 ~ 8557L
    ))
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addEthnicity()
  )
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("ethnicity") |>
      unique(),
    c("Asian", "Other Race", "White", "Native Hawaiian or Other Pacific Islander")
  )

  # NHS ethnicity categories and broad groups use race_source_concept_id.
  cdm$person <- cdm$person |>
    dplyr::mutate(race_source_concept_id = dplyr::case_when(
      .data$person_id == 1L ~ 700362L,
      .data$person_id == 2L ~ 700363L,
      .data$person_id == 3L ~ 700364L,
      .data$person_id == 4L ~ 700366L,
      .data$person_id == 5L ~ 700367L,
      .data$person_id == 6L ~ 700369L,
      .data$person_id == 7L ~ 700385L,
      .data$person_id == 8L ~ 700388L
    ))
  cdm$cohort <- cdm$cohort |>
    addEthnicity(from = "nhs-categories", nameStyle = "nhs_categories")
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("nhs_categories"),
    c(
      "Asian or Asian British - Any other Asian background",
      "Asian or Asian British - Pakistani",
      "Asian or Asian British - Bangladeshi",
      "Black or Black British - Caribbean",
      "Black or Black British - African",
      "Other Ethnic Groups - Chinese",
      "White - British",
      "Mixed - White and Black Caribbean"
    )
  )
  cdm$cohort <- cdm$cohort |>
    addEthnicity(from = "nhs-groups", nameStyle = "nhs_groups")
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("nhs_groups"),
    c("Asian", "Asian", "Asian", "Black", "Black", "Other", "White", "Mix")
  )

  # Free-text race values are accepted as an ethnicity source.
  cdm$person <- cdm$person |>
    dplyr::mutate(race_source_value = paste("race", person_id))
  cdm$cohort <- cdm$cohort |>
    addEthnicity(from = "race_source_value", nameStyle = "race_value")
  expect_identical(
    cdm$cohort |>
      dplyr::collect() |>
      dplyr::arrange(.data$subject_id) |>
      dplyr::pull("race_value"),
    paste("race", 1:8)
  )

  # expect all missing if no from is supplied
  expect_warning(
    cdm$cohort <- cdm$cohort |>
      addEthnicity(from = character())
  )
  expect_identical(
    cdm$cohort |>
      dplyr::pull("ethnicity") |>
      unique(),
    "Missing"
  )

  dropCreatedTables(cdm = cdm)
})
