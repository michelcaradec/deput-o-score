library(RCurl)

clean_colname <- function(name) {
  str_replace_all(name, "_", " ")
}

datasource_url <- "https://www.nosdeputes.fr/synthese/data/csv"

get_datasource_filename <- function() {
  url.exists(datasource_url, .header = T) %>%
    enframe() %>%
    filter(name == "Content-Disposition") %>%
    select(value) %>%
    transmute(value = value %>% str_extract("filename=\"[^\"]*\"")) %>%
    transmute(value = value %>% str_extract("\"[^\"]*\"")) %>%
    transmute(value = value %>% str_replace_all("\"", "")) %>%
    # `str_remove_all` dans laversion 1.4.0.9000 du package "stringr".
    # transmute(value = value %>% str_remove_all("\"")) %>%
    as.character()
}

get_filename_date <- function(filename) {
  filename %>% str_extract("\\d{4}-\\d{2}-\\d{2}")
}

synthese_scale <- 100

set_at_scale <- function(x, scale = synthese_scale) {
  coalesce(x / max(x) * scale, 0)
}

querystring_depute <- "depute"
