library(argparser)

args <- arg_parser(
  "Pull executive orders from the federal register",
  hide.opts = TRUE
) |>
  add_argument("output_file", help = "The output CSV file") |>
  parse_args()

library(httr2)
library(glue)
library(tidyr)
library(readr)

url <- stringr::str_c( # nolint
  "https://www.federalregister.gov/api/v1/documents.json",
  "?per_page=1000",
  "&fields[]=title",
  "&fields[]=citation",
  "&fields[]=document_number",
  "&fields[]=president",
  "&fields[]=signing_date",
  "&fields[]=publication_date",
  "&order=newest",
  "&conditions[type][]=PRESDOCU",
  "&include_pre_1994_docs=true",
  "&conditions[presidential_document_type][]=executive_order"
)

page_number <- 1
while (!is.null(url)) {
  res <- request(url) |>
    req_perform() |>
    resp_body_json()

  url <- res[["next_page_url"]]

  tibble(json = res[["results"]]) |>
    unnest_wider(json) |> # unpack json lists into columns
    hoist(president, president_name = "name") |> # unpack president sub-object
    dplyr::select(
      title,
      citation,
      document_number,
      president = president_name,
      signing_date,
      publication_date
    ) |>
    write_csv(args[["output_file"]], na = "", append = page_number != 1)

  print(glue("Fetched page {page_number} ({length(res[['results']])} records)"))
  page_number <- page_number + 1
}
