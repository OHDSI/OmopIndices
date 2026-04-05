
#' BMI obesity thresholds
#'
#' A dataset containing the thresholds used for obesity definition from BMI
#' measurements.
#'
#' @format A [`tibble`][tibble::tibble] with `r nrow(bmiThreshold)` rows
#'   and `r ncol(bmiThreshold)` columns:
#'   \describe{
#'     \item{`age_min`}{Double. Minimum age of the threshold.}
#'     \item{`age_max`}{Double. Maximum age of the threshold.}
#'     \item{`sex`}{Character. Either Female or Male.}
#'     \item{`bmi_threshold`}{Double. BMI threshold.}
#'   }
#'
"bmiThreshold"
