# BMI obesity thresholds

A dataset containing the thresholds used for obesity definition from BMI
measurements.

## Usage

``` r
bmiThreshold
```

## Format

A \[\`tibble\`\]\[tibble::tibble\] with \`r nrow(bmiThreshold)\` rows
and \`r ncol(bmiThreshold)\` columns:

- \`age_min\`:

  Double. Minimum age of the threshold.

- \`age_max\`:

  Double. Maximum age of the threshold.

- \`sex\`:

  Character. Either Female or Male.

- \`bmi_threshold\`:

  Double. BMI threshold.
