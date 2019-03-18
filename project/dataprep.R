library(tidyverse)
source("utils.R")

dataprep <- function() {
  # Datasource ----
  
  kpi_cols <- c(
    "semaines_presence",
    "commission_presences",
    "commission_interventions",
    "hemicycle_interventions",
    "hemicycle_interventions_courtes",
    "amendements_proposes",
    "amendements_signes",
    "rapports",
    "propositions_ecrites",
    "propositions_signees",
    "questions_ecrites",
    "questions_orales")
  
  metric_cols <- c(
    kpi_cols,
    "amendements_adoptes")
  
  keep_cols <- c(
    "nom",
    "nom_circo",
    "num_circo",
    "parti_ratt_financier",
    "place_en_hemicycle",
    "url_an",
    "url_nosdeputes",
    metric_cols)
  
  # Documentation : https://www.nosdeputes.fr/synthese
  datasource_filename <- get_datasource_filename()
  synthese <- read_delim(datasource_url, ";") %>%
    select(keep_cols) %>%
    rename_at(metric_cols, clean_colname)
  
  synthese_absolute <- synthese %>%
    select(-url_an, -url_nosdeputes, -place_en_hemicycle) %>%
    rename_all(clean_colname)
  
  datasource_date <- datasource_filename %>% get_filename_date()
  datasource_time <- Sys.time()
  kpi_cols <- kpi_cols %>% clean_colname()
  metric_cols <- metric_cols %>% clean_colname()
  
  # Feature engineering ----
  
  synthese_scale <- 100
  
  # FIXME: use `kpi_cols` vector to sum columns.
  synthese <- synthese %>%
    mutate_at(metric_cols, function(x) { x / max(x) * synthese_scale }) %>%
    mutate(score = ((`semaines presence` +
                     `commission presences` +
                     `hemicycle interventions` +
                     `hemicycle interventions courtes` +
                     `amendements proposes` +
                     `amendements signes` +
                     `rapports` +
                     `propositions ecrites` +
                     `propositions signees` +
                     `questions ecrites` +
                     `questions orales`
                   ) / length(kpi_cols)) %>% round(digits = 2)) %>%
    mutate(score_rank = nrow(synthese) - min_rank(score) + 1) %>%
    mutate(quartile_rank = as.integer(cut(score, quantile(score), include.lowest = T)))
  
  synthese_absolute <- synthese_absolute %>%
    mutate(score = synthese$score, rank = synthese$score_rank)
  
  synthese_median <- synthese %>%
    select(metric_cols) %>%
    summarise_all(median) %>%
    gather("indicator", "value")
  
  # Save ----
  
  save(synthese,
       synthese_absolute,
       synthese_median,
       metric_cols,
       synthese_scale,
       datasource_date,
       datasource_time,
       file = "data/synthese.RData")
}
