library(shiny)
library(tidyverse)
library(shinyjs)
source("style.R")
source("dataprep.R")

poll_frequency <- ifelse(interactive(), 5, 60 * 60 * 12) * 1000
# Variables utilisées pour la simulation du changement de source de données.
poll_simulate_counter <- 0
poll_simulate_max <- 10

check_datasource <- reactivePoll(
  poll_frequency,
  NULL,
  checkFunc = function() {
    print(paste0(date(), " - checkFunc(", poll_simulate_counter, ")"))
    filename <- get_datasource_filename()
    
    poll_simulate_counter <<- poll_simulate_counter + 1
    filename <- ifelse(!interactive() || poll_simulate_counter < poll_simulate_max, filename, "")
    
    print(paste0(date(), " - checkFunc = ", filename))
    
    filename
  },
  valueFunc = function() {
    print(paste0(date(), " - dataprep() started"))
    dataprep()
    print(paste0(date(), " - dataprep() completed"))
    
    print(paste0(date(), " - load data"))
    # Chargement dans l'environnement global.
    load("data/synthese.RData", .GlobalEnv)

    poll_simulate_counter <<- 0
  }
)

get_synthese <- reactive({
  synthese
})

get_synthese_absolute <- reactive({
  synthese_absolute
})

get_depute <- function(id) {
  depute <- get_synthese() %>% filter(place_en_hemicycle == as.integer(!!id))
  
  # Déclenche une exception silencieuse si aucun député n'est trouvé.
  req(nrow(depute) == 1)
  
  depute
}

get_emoji_def <- function(id) {
  depute <- get_depute(id)
  
  emojis %>% filter(quartile_rank == depute$quartile_rank) %>% select(emoji, colour) %>% as.list()
}

get_score_plot <- function(id) {
  depute <- get_depute(id)
  
  depute_metrics <- depute %>%
    select(metric_cols) %>%
    gather("indicator", "value") %>%
    mutate(position = ifelse(
      value > synthese_median[match(indicator, synthese_median$indicator), "value"],
      "+",
      ifelse(
        value < synthese_median[match(indicator, synthese_median$indicator), "value"],
        "-",
        "="
      ))
    )

  # FIXME: Le filtre sur le nom n'est pas fiable en cas d'homonymie.
  depute_absolute <- get_synthese_absolute() %>%
    filter(nom == depute$nom) %>%
    select(metric_cols) %>%
    gather("indicator", "value")

  ggplot() +
    # Député (scores)
    geom_bar(aes(x = str_replace_all(indicator, " ", "\n"), y = value, fill = position),
             data = depute_metrics,
             stat = "identity",
             show.legend = T) +
    # Député (légende)
    scale_fill_manual(
      values = colours_rank,
      labels = c(" > médiane", " = médiane", " < médiane")
    ) +
    # Député (valeurs absolues)
    geom_text(aes(x = str_replace_all(indicator, " ", "\n"), y = 50, label = prettyNum(value, big.mark = " ")),
              data = depute_absolute,
              size = 5,
              colour = "black",
              fontface = "bold") +
    # Députés (médianes scores)
    geom_bar(aes(x = str_replace_all(indicator, " ", "\n"), y = value),
             data = synthese_median,
             stat = "identity",
             fill = alpha("black", 0),
             colour = "black",
             show.legend = F) +
    # Echelle axe Y avec borne négative pour l'aspect donut.
    scale_y_continuous(
      breaks = seq(0, synthese_scale, length.out = 3),
      limits = c(-synthese_scale / 5, synthese_scale)) +
    theme_minimal() +
    theme(
      legend.title = element_blank(),
      legend.text = element_text(size = 15),
      axis.title = element_blank(),
      axis.text.y = element_blank(),
      axis.text.x = element_text(size = 15),
      #panel.grid.minor=element_blank(),
      panel.grid.major.x = element_line(linetype = "dotted", size = .7, colour = alpha("black", .4)),
      panel.grid.major.y = element_line(linetype = "solid", size = .7)
    ) +
    coord_polar(clip = "off")
}

shinyServer(function(input, output, session) {
  enableBookmarking(store = "url")
  
  observe({
    print(paste0(date(), " - check_datasource() started"))
    check_datasource()
    print(paste0(date(), " - check_datasource() completed"))
    
    hide(id = "loading-content", anim = TRUE, animType = "fade")
    show("app-content")
  })
  
  observe({
    query <- getQueryString()
    id <- 0
    if (!is.null(query[[querystring_depute]])) {
      # www.site.com/?depute=${PLACE_EN_HEMICYCLE}
      id <- as.integer(query[[querystring_depute]])
    }
    if (is.na(id) ||
        is.null(id) ||
        !(id %in% get_synthese()$place_en_hemicycle)) {
      # Sélection aléatoire d'un député à chaque rafraîchissement de page.
      id <- sample(get_synthese()$place_en_hemicycle, 1)
    }
    
    print(paste0("Sélection du député ", id))
    
    updateSelectInput(
      session,
      "deputy",
      choices = setNames(get_synthese()$place_en_hemicycle, get_synthese()$nom),
      selected = id
    )
  })
  
  output$datasource_info <- renderText({
    paste0("fichier du ", datasource_date, " récupéré à ", datasource_time)
  })
  
  output$depute_info <- renderText({
    depute <- get_depute(input$deputy)
    
    depute$nom
  })
  
  output$depute_info2 <- renderText({
    depute <- get_depute(input$deputy)
    
    paste0(depute$parti_ratt_financier, " (", depute$nom_circo, " / ", depute$num_circo, ")")
  })
  
  output$depute_url_an <- renderUI({
    depute <- get_depute(input$deputy)
    
    a("sur le site de l'assemblée nationale", href = depute$url_an, target = "_blank")
  })
  
  output$depute_url_nosdeputes <- renderUI({
    depute <- get_depute(input$deputy)
    
    a("sur le site nosdéputés.fr", href = depute$url_nosdeputes, target = "_blank")
  })
  
  output$depute_score <- renderUI({
    depute <- get_depute(input$deputy)
    
    rank_suffix <- ifelse(depute$score_rank == 1, "er", ifelse(depute$score_rank == 2, "nd", "ème"))
    
    emoji_def <- get_emoji_def(input$deputy)

    div(
      h1(paste0("Score : ", depute$score)),
      h4(paste0("classement : ", depute$score_rank, rank_suffix, " / ", nrow(get_synthese()))),
      HTML(paste0("<span style=\"color: ", emoji_def$colour , "\"><i class=\"far ", emoji_def$emoji, " fa-3x\"></i></span>")),
      align = "center"
    )
  })

  output$circularPlot <- renderPlot({
    print(paste0("Affichage du député ", input$deputy))
    
    updateQueryString(paste0("?", querystring_depute, "=", input$deputy))

    get_score_plot(input$deputy)
  })
  
  output$deputes <- renderDataTable({
    get_synthese_absolute()
  })
})
