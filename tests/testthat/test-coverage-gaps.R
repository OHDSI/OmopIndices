test_that("category and window helpers generate correct expressions", {
  expect_equal(OmopIndices:::windowCondition(c(0, Inf)),
               "0 <= .data[[nameStyle]]")
  expect_equal(OmopIndices:::windowCondition(c(-1, 1)),
               "-1 <= .data[[nameStyle]] & .data[[nameStyle]] <= 1")
  expect_match(OmopIndices:::qCategories(list(low = c(0, 1), high = c(1, Inf))),
               "missing")
})

test_that("validation helpers reject invalid and accept valid inputs", {
  expect_equal(OmopIndices:::validateName(NA_character_), NULL)
  expect_equal(OmopIndices:::validateWindow(c(-Inf, 0)), c(-Inf, 0))
  expect_error(OmopIndices:::validateWindow(list(c(-1, 0), c(0, 1))),
               "Only one window")
  expect_error(OmopIndices:::validateName(letters), "length")
})

test_that("record filtering handles all window and ordering choices", {
  x <- dplyr::tibble(person_id = c(1L, 1L, 2L), index_date = as.Date("2020-01-01"),
                     diff = c(-2, 1, 3), bmi_date = as.Date("2020-01-01") + c(1, 2, 3),
                     bmi = c(20, 25, 30))
  expect_equal(nrow(OmopIndices:::filterWindow(x, "diff", c(-Inf, 1))), 2)
  expect_equal(nrow(OmopIndices:::filterWindow(x, "diff", c(-1, Inf))), 2)
  expect_equal(nrow(OmopIndices:::filterWindow(x, "diff", c(-1, 1))), 1)
  expect_equal(nrow(OmopIndices:::filterWindow(x, "diff", c(-Inf, Inf))), 3)
  expect_equal(nrow(OmopIndices:::filterOrder(x, "diff", "first", "index_date")), 2)
  expect_equal(nrow(OmopIndices:::filterOrder(x, "diff", "last", "index_date")), 2)
})

test_that("index codelists and documentation options are available", {
  expect_true(length(OmopIndices::getIndexCodelist("charlson")) > 0)
  expect_true(grepl("and", OmopIndices:::indexOptions(), fixed = TRUE))
})

test_that("public index wrappers pass their documented defaults", {
  fake_add_index <- function(x, type, indexDate, window, conceptSet, categories,
                             nameStyle, ageAdjusted, name) {
    list(type = type, indexDate = indexDate, window = window,
         conceptSet = conceptSet, categories = categories,
         nameStyle = nameStyle, ageAdjusted = ageAdjusted, name = name)
  }
  testthat::local_mocked_bindings(addIndex = fake_add_index,
                                  .package = "OmopIndices")
  hfrs <- OmopIndices::addHospitalFrailtyRiskScore(x = list(), name = "hfrs")
  efi2 <- OmopIndices::addElectronicFrailtyIndex2(x = list(), name = "efi2")
  expect_equal(hfrs$type, "hfrs")
  expect_equal(efi2$type, "electronic_frailty_index_2")
  expect_false(hfrs$ageAdjusted)
  expect_false(efi2$ageAdjusted)
  expect_true(length(hfrs$conceptSet) > 0)
  expect_true(length(efi2$conceptSet) > 0)
})

test_that("ethnicity value and NHS group mappings are tested", {
  cdm <- omock::mockCdmFromTables(tables = list(
    cohort = dplyr::tibble(cohort_definition_id = 1L, subject_id = 1:14,
                           cohort_start_date = as.Date("2020-01-01"),
                           cohort_end_date = as.Date("2020-01-01"))))
  cdm$person <- cdm$person |>
    dplyr::mutate(
      ethnicity_source_value = ifelse(person_id == 1, "Recorded", NA_character_),
      race_source_concept_id = c(700385L:700391L, 700388L:700391L, 999999L, 700362L, 700363L)
    )
  ids <- cdm$cohort |>
    dplyr::transmute(person_id = .data$subject_id)
  values <- OmopIndices:::addEthnicityFromValue(ids, "ethnicity_source_value", "ethnicity")
  expect_equal(dplyr::collect(values)$ethnicity, "Recorded")
  categories <- OmopIndices:::addNhsCategories(ids, "nhs-categories", "ethnicity")
  groups <- OmopIndices:::addNhsCategories(ids, "nhs-groups", "ethnicity")
  expect_true(dplyr::count(categories) |> dplyr::pull(n) > 0)
  expect_true(dplyr::count(groups) |> dplyr::pull(n) > 0)
})
