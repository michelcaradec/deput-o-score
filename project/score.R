# Mesures utilisées pour le calcul du score.
kpis <- tribble(
  ~name_source, ~coeff,
  "semaines_presence", 1,
  "commission_presences", 1,
  "commission_interventions", 1,
  "hemicycle_interventions", 1,
  "hemicycle_interventions_courtes", 0,
  "amendements_proposes", 1,
  "amendements_signes", 1,
  "amendements_adoptes", 0,
  "rapports", 1,
  "propositions_ecrites", 1,
  "propositions_signees", 1,
  "questions_ecrites", 1,
  "questions_orales", 1
) %>%
  mutate(
    name = name_source %>% clean_colname(),
    # Conversion des coefficients en pourcentages.
    coeff_pct = coeff / sum(coeff)
  )

compute_score <- function(df) {
  # DF :
  # | kpi1 | kpi2 | kpi3 |
  # |------|------|------|
  # | 1    | 10   | 100  |
  # | 2    | 20   | 200  |
  # | 3    | 30   | 300  |
  
  # COEFF :
  # | name   | rate |
  # |--------|------|
  # | "kpi1" | 0.2  |
  # | "kpi2" | 0.3  |
  # | "kpi3" | 0.5  |
  
  # score = (DF * COEFF$rate) / count(COEFF$rate) = (kpi1 * rate["kpi1"] + kpi2 * rate["kpi2"] + kpi3 * rate["kpi3"]) / 3
  
  # /!\ Les colonnes des mesures dans `df` doivent correspondre à celles dans  `kpis` afin que le produit matrice x vecteur donne le résultat attendu.
  # (((df %>% select(kpis$name) %>% as.matrix()) %*%
  #     kpis$coeff_pct) / nrow(kpis)) %>%
  # round(digits = 2)
  (((df %>% select(kpis$name) %>% as.matrix()) %*%
      kpis$coeff_pct)) %>%
    round(digits = 2)
}
