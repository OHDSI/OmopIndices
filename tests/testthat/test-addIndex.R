test_that("category and window helpers generate correct expressions", {
  expect_equal(categoriesCondition(c(0, Inf)),
               "0 <= .data[[nameStyle]]")
  expect_equal(categoriesCondition(c(-1, 1)),
               "-1 <= .data[[nameStyle]] & .data[[nameStyle]] < 1")
  expect_equal(
    OmopIndices:::qCategories(list(
      robust = c(0, 0.0857),
      mild = c(0.0857, 0.1624),
      moderate = c(0.1624, 0.2392),
      severe = c(0.2392, Inf)
    )),
    paste0(
      "dplyr::case_when(",
      "is.na(.data[[nameStyle]]) ~ 'missing',",
      "0 <= .data[[nameStyle]] & .data[[nameStyle]] < 0.0857 ~ 'robust', ",
      "0.0857 <= .data[[nameStyle]] & .data[[nameStyle]] < 0.1624 ~ 'mild', ",
      "0.1624 <= .data[[nameStyle]] & .data[[nameStyle]] < 0.2392 ~ 'moderate', ",
      "0.2392 <= .data[[nameStyle]] ~ 'severe')"
    )
  )
  expect_match(qCategories(list(low = c(0, 1), high = c(1, Inf))), "missing")
})
