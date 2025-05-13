library(argparser)

args <- arg_parser("Pull executive orders from the federal register") |>
  add_argument("output_file", help = "The output CSV file") |>
  parse_args()

library(httr2)
library(lubridate, warn.conflicts = FALSE)
library(stringr)
library(dplyr, warn.conflicts = FALSE)
library(readr)
library(glue)

page_size <- 1000
documents_url <- function(page_number) {
  stringr::str_c(
    "https://www.federalregister.gov/api/v1/documents.csv",
    glue("?per_page={page_size}"),
    glue("&page={page_number}"),
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
}

fetch_page <- function(page_number) {
  df <- request(documents_url(current_page)) |>
    req_perform() |>
    resp_body_string() |>
    I() |>
    readr::read_csv(show_col_types = FALSE)
  print(glue("Fetched page {page_number} ({length(df[[1]])} records)"))
  df
}

current_page <- 1
page_df <- fetch_page(current_page)
df <- page_df
while (length(page_df[[1]]) == page_size) {
  current_page <- current_page + 1
  page_df <- fetch_page(current_page)
  df <- bind_rows(df, page_df)
}

df <- df |> mutate(
  publication_date = mdy(publication_date),
  president = str_split_fixed(president, "; ", 4)[, 4]
)

write_csv(df, args$output_file)
write_file(as.character(today()), "last_update")
