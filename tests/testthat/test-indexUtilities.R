test_that("index utility functions work", {
  expect_no_error(purrr::map(indexDefinitions, getFormula))
  expect_no_error(purrr::map(indexDefinitions, getAddComponents))
  expect_no_error(purrr::map(indexDefinitions, getPointsMatrix))
  expect_no_error(purrr::map(indexDefinitions, getCohortComponents))
  expect_no_error(purrr::map(indexDefinitions, getNeededConcepts))
})
