# read Charlson and Updated Charlson concepts
charlson <- readr::read_csv(
  file = here::here("data-raw", "concepts", "charlson.csv"),
  col_types = c(concept_id = "i", codelist_name = "c", concept_name = "c", vocabulary_id = "c")
)

# read Hospital Frailty Risk Score
hfrs <- list.files(
  path = here::here("data-raw", "concepts"),
  pattern = "^hfrs",
  full.names = TRUE
) |>
  rlang::set_names() |>
  purrr::map(\(x) readr::read_csv(file = x, col_types = c(concept_id = "i"))) |>
  dplyr::bind_rows(.id = "icd10_code") |>
  dplyr::mutate(icd10_code = toupper(substr(basename(.data$icd10_code), 6, 8))) |>
  dplyr::left_join(
    hfrs |>
      dplyr::select("codelist_name" = "concept_set", "icd10_code"),
    by = "icd10_code"
  )

# create concept dataset
concepts <- charlson |>
  dplyr::select("codelist_name", "concept_id") |>
  dplyr::mutate(index = "charlson") |>
  dplyr::union_all(
    charlson |>
      dplyr::select("codelist_name", "concept_id") |>
      dplyr::filter(.data$codelist_name %in% .env$updatedCharlsonConcepts) |>
      dplyr::mutate(index = "updatedCharlson")
  ) |>
  dplyr::union_all(
    hfrs |>
      dplyr::select("codelist_name", "concept_id") |>
      dplyr::mutate(index = "hfrs")
  ) |>
  dplyr::select("index", "codelist_name", "concept_id") |>
  dplyr::arrange(.data$index, .data$codelist_name, .data$concept_id)

# add concept name
cdm <- omock::mockCdmFromDataset(datasetName = "delphi-100k")
concepts <- concepts |>
  dplyr::left_join(
    cdm$concept |>
      dplyr::select(
        "concept_id", "concept_name", "domain_id", "vocabulary_id",
        "concept_code"
      ),
    by = "concept_id"
  )

# check if any name is not present
x <- concepts |>
  dplyr::filter(is.na(.data$concept_name))
if (nrow(x) > 0) {
  cli::cli_abort(c(x = "There are concepts that are not present in cdm."))
}
