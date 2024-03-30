#libraries
library(tidyverse)
library(shiny)
library(shinyauthr)
library(sodium)
library(tibble)
library(blastula)
library(shinyjs)
library(shinydashboard)



df_randomised <- read.csv("//Users//zachbushby//Documents//edu//data_science//Projects//Actuarial Assassins//df_randomised.csv")
game_states <- read.csv("//Users//zachbushby//Documents//edu//data_science//Projects//Actuarial Assassins//game_states.csv")

#------------------------- start game -------------------------------

#sends the rules for everyone
#sends each participants kill pwd

#send out an email to everyone saying who their 

start <- function(){
  for (i in 1:nrow(df_randomised)){
  cat("email sent for", df_randomised$names[[i]], "to kill: ", df_randomised$target_names[[i]], "\n")
  }
}


#------------------------- register kill ----------------------------
update_game <- function(playernum, df) {
  #find the row for the killer
  killer_row <- df[ df$playernum == playernum, ]
  
  #if the killer does not exist
  if (nrow(killer_row) == 0) {
    stop("Invalid player number for the killer.")
  }
  
  #find the row for the player who was kills
  kills_row <- df[ df$names == killer_row$target_names, ]
  
  #if the target to be kills does not exist or is already dead
  if (nrow(kills_row) == 0 || kills_row$dead == 1) {
    stop("Invalid target: either does not exist or is already dead.")
  }
  
  #mark the target as dead
  df[ df$names == killer_row$target_names, "dead" ] <- "X"
  
  #update the killer's kills count
  df[ df$playernum == playernum, "kills" ] <- df[ df$playernum == playernum, "kills" ] + 1
  
  #update the killer's next target to the target of the kills player
  df[ df$playernum == playernum, "target_email" ] <- kills_row$target_email
  df[ df$playernum == playernum, "target_names" ] <- kills_row$target_names
  
  
  write.csv(append(game_states, list(df)), file = "//Users//zachbushby//Documents//edu//data_science//Projects//Actuarial Assassins//game_states.csv", row.names = FALSE)
  game_states <- append(game_states, list(df))
  
  write.csv(df, file = "//Users//zachbushby//Documents//edu//data_science//Projects//Actuarial Assassins//df_randomised.csv", row.names = FALSE)
  df_randomised <- df
  
  return(df)
}
  
  



#------------------------- undo kill --------------------------------

undo <- function(game_states) {
  if (length(game_states) <= 1) {
    stop("Nothing to undo.")
  }
  game_states <- head(game_states, -1)
  latest_state <- tail(game_states, 1)[[1]]
  
 
  game_states <- list(
    "df_randomised" = latest_state,
    "game_states" = game_states
  )
  
  write.csv(game_states, file = "//Users//zachbushby//Documents//edu//data_science//Projects//Actuarial Assassins//game_states.csv", row.names = FALSE)
  
  return(game_states)
  
}


#------------------------- dashboard for stats ----------------------
#Top 10 Kills
df_randomised %>% 
  select(names, kills) %>% 
  arrange(-kills) %>% 
  head(n=10)

#people Left:
sum(df_randomised$dead == 0)

#people Dead
sum(df_randomised$dead == "X")

#leaderboard
df_randomised %>% 
  select(names, dead, kills) %>% 
  arrange(-kills)



#------------------------- Testing -----------------------------------

# df_randomised <- update_game(3, df_randomised)
# df_randomised
# game_states <- append(game_states, list(df_randomised))
# 
# # Tested undo feature
# results <- undo(game_states)
# df_randomised <- results$df_randomised
# game_states <- results$game_states
# 
# # Print the current state of df_randomised
# print(df_randomised)


#---------------------------Portal------------------------------------
# if someone puts in their email and the person they killeds pwd run update_game
# if I put in master@gmail.com and pwd: MASS23:
#     show options to run undo function
#     show option to start game. ie. send emails to all people with their thingos

# dataframe that holds usernames, passwords and other user data

#add in admin login to userbase data:

user_base_emails <- c(df_randomised$email, "zbushby")
user_base_password <- c(df_randomised$own_password, "1102")
permission <- rep("standard", length(user_base_emails))
permission[ length(permission) ] <- "admin"
user_base_names <- c(df_randomised$names, "Zach")

user_base <- tibble::tibble(
  user = user_base_emails,
  password = sapply(user_base_password, sodium::password_store),
  permissions = permission,
  name = user_base_names
)


####################          Shiny App            ####################


ui <- navbarPage(
  title = "Actuarial Assassins",
  tabPanel("Game Statistics",
           fluidRow(
             column(3, h3("Top 10 Kills"), tableOutput("top_kills")),
             column(3, h3("People Left"), div(textOutput("people_left"), style = "font-size: 80px; text-align: center; margin-top: 15px;")),
             column(3, h3("People Dead"), div(textOutput("people_dead"), style = "font-size: 80px; text-align: center; margin-top: 15px;")),
             column(3, h3("Leaderboard"), tableOutput("leaderboard"))
           )
           
  ),
  tabPanel("Assassin Kill Page",
           shinyauthr::loginUI(id = "login"),
           uiOutput("main_content")
           
  )
)
# Define server logic
server <- function(input, output, session) {
  # Reactive datastore for game data
  game_data <- reactiveValues(df_randomised = df_randomised, game_states = game_states)
  
  # Setup user authentication
  credentials <- shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = "user",
    pwd_col = "password",
    sodium_hashed = TRUE
  )
  
  kill_confirmed <- reactiveVal(FALSE)
  dead <- reactiveVal(FALSE)

  observeEvent(credentials(), {
    kill_confirmed(FALSE)
  })
  
  # UI output for the main content based on user permissions
  
  output$main_content <- renderUI({
    # Only display content if authenticated
    req(credentials()$user_auth)
    
    user_perm <- credentials()$info$permissions
    
    # Render UI based on permissions
    if (user_perm == "admin") {
      # Admin content
      admin_content_ui()
    } else if(dead()) {
      # Standard user content
      dead_content_ui()
    } else if(user_perm == "standard" && !kill_confirmed()) {
      # Standard user content
      standard_content_ui()
    
    } else if(kill_confirmed()) {
      # Get the player's information
      user_email <- credentials()$info$user
      player_number <- game_data$df_randomised$playernum[game_data$df_randomised$email == user_email]
      
      if (length(player_number) == 1) {
        player_row <- game_data$df_randomised[game_data$df_randomised$playernum == player_number, ]
        
        # Use the confirm_kill_ui function
        confirm_kill_ui(player_row)
      }
    }
  })
  
  dead_content_ui <- function() {
    tagList(
      h3("You are dead."),
      h4("Better luck next time!")
    )
  }
  
  # Function for rendering admin specific UI
  admin_content_ui <- function() {
    tagList(
      h3("Admin Options"),
      actionButton("undo_button", "Undo Last Action"),
      br(),
      h4("Display Table"),
      tableOutput("df_randomised_table"),
      br(),
      h4("Update Game for Player"),
      selectInput("update_game_player", "Select Player:",
                  choices = game_data$df_randomised$names),
      actionButton("update_game_button", "Update Game for Selected Player")
    )
  }
  
  # Function for rendering standard user specific UI
  standard_content_ui <- function() {
    tagList(
      h3("Hitman's Marketplace"),
      textInput("target_password_input", "Enter Target's Password:"),
      div(
        style = "display: flex; align-items: center; justify-content: center;", # Center both horizontally and vertically
        actionButton("confirm_kill", "Confirm Kill")
      ),
      br(),
      h4("Target Information"),
      textOutput("target_name"),
      textOutput("target_email"),
      textOutput("kill_status")
    )
  }
  
  confirm_kill_ui <- function(player_row) {
    new_target_name <- player_row$target_names
    new_target_email <- player_row$target_email
    
    # Display details of the new target and the message about the email
    tagList(
      h4("Successfully killed your target!"),
      h5("Your new target is:", new_target_name),
      h5("Email:", new_target_email),
      h5("An email will be sent with your new target's information")
    )
  }
  observe({
    user_email <- credentials()$info$user
    player_number <- game_data$df_randomised$playernum[game_data$df_randomised$email == user_email]
    player_row <- game_data$df_randomised[game_data$df_randomised$playernum == player_number, ]
    target_name <- player_row$target_names
    target_email <- player_row$target_email
    if (!nrow(player_row) == 0){
      if (player_row$dead == "X"){
        dead(TRUE)
      } else{
        dead(FALSE)
      }
    }
    # Display target information
    output$target_name <- renderText({
      paste("You are about to kill:", target_name)
    })
    output$target_email <- renderText({
      paste("Email: ", target_email)
    })
    output$kill_status <- renderText({ 
      paste("Incorrect target password. Attempts remaining:", 3 - incorrect_attempts())
    })
  })

  incorrect_attempts <- reactiveVal(0)
  
  # Logic when the 'Confirm Kill' button is clicked
  observeEvent(input$confirm_kill, {
    user_email <- credentials()$info$user
    player_number <- game_data$df_randomised$playernum[game_data$df_randomised$email == user_email][1]
    
    if (!is.na(player_number)) {
      player_row <- game_data$df_randomised[game_data$df_randomised$playernum == player_number, ]
      entered_password <- input$target_password_input
      target_email <- player_row$target_email
      
      # Look up the row of the target email
      target_row <- game_data$df_randomised[game_data$df_randomised$email == target_email, ]
      
      if (nrow(target_row) == 1) {
        target_password <- target_row$own_password  # Assuming own_password is the target's password
        
        if (entered_password == target_password) {
          game_data$df_randomised <- update_game(player_number, game_data$df_randomised)
          game_data$game_states <- append(game_data$game_states, list(game_data$df_randomised))
          kill_confirmed(TRUE)
        } else {
          incorrect_attempts(incorrect_attempts() + 1)
          
          if (incorrect_attempts() >= 3) {
            observe({ 
              # Reset incorrect attempts after 3 seconds
              invalidateLater(3000, session)
              incorrect_attempts(0)
            }, once = TRUE)
          }
        }
      } else {
        output$kill_status <- renderText({ "Failed to confirm kill. Target not found." })
      }
    } else {
      output$kill_status <- renderText({ "Failed to confirm kill. Invalid player." })
    }
  })
  
  
  # Reactive expressions for game statistics
  top_kills <- reactive({
    game_data$df_randomised %>%
      select(names, kills, dead) %>% 
      arrange(desc(kills), names) %>%
      head(n = 10) %>%
      mutate(kills = as.integer(kills))
  })
  
  people_left <- reactive({
    sum(game_data$df_randomised$dead == 0)
  })
  
  people_dead <- reactive({
    sum(game_data$df_randomised$dead == "X")
  })
  
  leaderboard <- reactive({
    game_data$df_randomised %>%
      select(names, kills, dead) %>% 
      arrange(desc(kills), names) %>%
      mutate(kills = as.integer(kills))
  })
  
  # Rendering the game statistics
  output$top_kills <- renderTable({
    top_kills()
  })
  
  output$people_left <- renderText({
    people_left()
  })
  
  output$people_dead <- renderText({
    people_dead()
  })
  
  output$leaderboard <- renderTable({
    leaderboard()
  })
  
  observeEvent(input$undo_button, {
    refresh()
  })
  
  output$df_randomised_table <- renderTable({
    game_data$df_randomised
  })
  
  observeEvent(input$start_game_button, {
    start()
    cat("Game started!\n")
  })
  
  observeEvent(input$update_game_button, {
    player_name <- input$update_game_player
    player_number <- game_data$df_randomised$playernum[game_data$df_randomised$names == player_name]
    
    if (length(player_number) == 1) {
      # Update the game data using the reactiveValues
      game_data$df_randomised <- update_game(player_number, game_data$df_randomised)
      game_data$game_states <- append(game_data$game_states, list(game_data$df_randomised))
      cat("Game updated for player:", player_name, "\n")
    } else {
      cat("Failed to update game. Invalid player.\n")
    }
  })
  
}

# Create Shiny app
shinyApp(ui = ui, server = server)







