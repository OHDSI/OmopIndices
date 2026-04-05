
bmiThreshold <- readr::read_csv(
  file = "data-raw/bmi_threshold.csv",
  col_types = c(sex = "c", age_min = "d", age_max = "d", bmi_threshold = "d")
)

usethis::use_data(bmiThreshold, overwrite = TRUE)
