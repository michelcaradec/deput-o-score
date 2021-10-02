library(tidyverse)
source("utils.R")
source("score.R")

dataprep <- function() {
  # Datasource ----
  
  # Documentation : https://www.nosdeputes.fr/synthese
  synthese <- read_delim(datasource_url, ";")
  
  keep_cols <- c(
    "nom",
    "nom_circo",
    "num_circo",
    "parti_ratt_financier",
    "place_en_hemicycle",
    "url_an",
    "url_nosdeputes",
    kpis$name_source)
  
  # Data-frame utilisée pour le calcul du score et la dataviz.
  synthese <- synthese %>%
    select(all_of(keep_cols)) %>%
    mutate_at(kpis$name_source, ~ replace_na(.x, 0)) %>%
    rename_at(kpis$name_source, clean_colname)
  
  # Data-frame utilisée pour l'affichage des vrais valeurs.
  synthese_absolute <- synthese %>%
    select(-url_an, -url_nosdeputes, -place_en_hemicycle) %>%
    rename_all(clean_colname)
  
  # Feature engineering ----
  
  synthese <- synthese %>%
    # Mise l'échelle des mesures
    mutate_at(kpis$name, set_at_scale)

  # Data-flow séparé afin de bénéficier de la data-frame `synthese` avec les mesures mises à l'échelle.
  synthese <- synthese %>%
    mutate(score = compute_score(synthese)) %>%
    mutate(score_rank = nrow(synthese) - min_rank(score) + 1) %>%
    mutate(quartile_rank = as.integer(cut(score, quantile(score), include.lowest = T)))

  synthese_absolute <- synthese_absolute %>%
    mutate(score = synthese$score, rank = synthese$score_rank)
  
  synthese_median <- synthese %>%
    select(kpis$name) %>%
    summarise_all(median) %>%
    gather("indicator", "value")
  
  # Save ----

  datasource_date <- get_datasource_filename() %>% get_filename_date()
  datasource_time <- Sys.time()
  
  metric_cols <- kpis$name
  
  save(synthese,
       synthese_absolute,
       synthese_median,
       metric_cols,
       synthese_scale,
       datasource_date,
       datasource_time,
       file = "data/synthese.RData")
}
