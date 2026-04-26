
hospitalFrailtyRiskScore <- readr::read_csv("data-raw/hospital_frailty_risk_score.csv")

usethis::use_data(hospitalFrailtyRiskScore, overwrite = TRUE)
