
hfrs <- readr::read_csv("data-raw/hospital_frailty_risk_score.csv")

frailtyConcepts <- hfrs |>
  dplyr::pull("concept_set")

hfrsFormula <- paste0(hfrs$points, " * ", hfrs$concept_set, collapse = " + ")

usethis::use_data(
  frailtyConcepts,
  hfrsFormula,
  internal = TRUE,
  overwrite = TRUE
)
