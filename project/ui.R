library(shiny)
library(shinyjs)

shinyUI(fluidPage(
  # Awesome Fonts ----
  HTML("<link rel=\"stylesheet\" href=\"https://use.fontawesome.com/releases/v5.7.2/css/all.css\" integrity=\"sha384-fnmOCqbTlWIlj8LyTjo7mOUStjsKC4pOpQbqyi7RrhN7udi9RwhKkMHpvLbHG9Sr\" crossorigin=\"anonymous\">"),
  # Loading-screen ----
  # Taken from https://github.com/daattali/advanced-shiny/tree/master/loading-screen
  useShinyjs(),
  inlineCSS("#loading-content {
            position: absolute;
            background: #000000;
            opacity: 0.9;
            z-index: 100;
            left: 0;
            right: 0;
            height: 100%;
            text-align: center;
            color: #FFFFFF;}"),
  div(
    id = "loading-content",
    h2("Chargement en cours...")
  ),
  # Application page ----
  hidden(
    div(
      id = "app-content",
      # Header ----
      
      titlePanel(textOutput("depute_info"), "Déput-O-Score"),
      h3(textOutput("depute_info2")),
    
      p(
        "Retrouvez votre député·e",
        uiOutput("depute_url_an", inline = T),
        " ou ",
        uiOutput("depute_url_nosdeputes", inline = T),
        "."
      ),
      
      tabsetPanel(
        # Tab "Député" ----
        tabPanel("Député",
          fluidRow(
            p(),
            column(
              4,
              selectInput(
                "deputy",
                "Sélectionnez un·e député·e",
                choices = NULL
              ),
              offset = 0
            ),
            column(
              4,
              uiOutput("depute_score"),
              offset = 0
            )
          ),
          fluidRow(plotOutput("circularPlot", width = "100%", height = "700px"))
        ),
        # Tab "Députés" ----
        tabPanel("Députés",
          p(),
          dataTableOutput("deputes")
        ),
        # Tab "FAQ" ----
        tabPanel("FAQ",
          p(),
          includeMarkdown("assets/faq.md")
        )
      ),
      
      # Footer ----
      
      p(),
      p(
        span("Créé par "),
        a("Michel Caradec", href = "https://fr.linkedin.com/in/michel-caradec-36997650"),
        span(". Le projet est disponible sur "),
        a("Github", href = "https://github.com/michelcaradec/"),
        span(".")
      ),
      p(
        span("Les informations contenues dans cette page proviennent des "),
        a("données d'activité des parlementaires (synthèse des 12 derniers mois ou de toute la législature)", href = "https://github.com/regardscitoyens/nosdeputes.fr/blob/master/doc/api.md#données-dactivité-des-parlementaires"),
        span(" du site "),
        a("nosdeputes.fr", href = "https://www.nosdeputes.fr/"),
        span(" ("),
        textOutput("datasource_info", inline = T),
        span(").")
      ),
      p(
        span("Ce projet est sous licence "),
        strong("Creative Commons"),
        a("Attribution - Pas d’Utilisation Commerciale - Partage dans les Mêmes Conditions 4.0 International", href = "https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr"),
        span(".")
      ),
      p(
        img(src = "https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png")
      )
    )
  )
))
