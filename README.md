# Actuarial Assassins Game 

Actuarial Assassins is a thrilling, strategy-based game played among our MASS members who are assigned targets to "assassinate" within a set of rules. The game is designed to test strategy, and social skills as players aim to be the last one standing. 

## How to Play

- Each player receives an email with the details of their target and a unique password.
- The objective is to whisper "you're dead" into the ear of your target without being overheard by anyone else.
- Upon a successful "kill," the player must enter their login details and the victim's password on the [Actuarial Assassins Dashboard](https://5csp3-zach-bushby.shinyapps.io/AssassinGame/).
- The game progresses as players receive their next targets upon registering a kill.
- The last player remaining wins the game.

## Rules

1. **Stealth is Key:** You must ensure that only your target hears you. If overheard, the assassination attempt fails.
2. **Confirmation:** Successfully "killed" targets must be registered on the game's dashboard using the provided passwords.
3. **Continuous Play:** Players receive new targets upon successful assassinations.
4. **Be Alert:** The game requires constant awareness, as your assassin could be anyone in the game.

## Actuarial Assassins Dashboard

The [Actuarial Assassins Dashboard](https://5csp3-zach-bushby.shinyapps.io/AssassinGame/) serves as the central hub for the game, facilitating the following functionalities:

- **Kill Registration:** Players enter their victim's password to confirm kills and receive their next target.
- **Game Statistics:** View top kills, number of players remaining, and a leaderboard.
- **Admin Functions:** Special controls for game administrators, including the ability to undo actions and update game states.

The dashboard is built using R and the Shiny framework, incorporating libraries such as `tidyverse`, `shiny`, `shinyauthr`, and `blastula` for data manipulation, user authentication, and email notifications, respectively.
