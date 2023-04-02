#!/bin/bash

# Generate random number
GOAL=$(( $RANDOM % 1000 + 1 ))
# echo "$GOAL"

# Get username
echo "Enter your username:"
read USERNAME

# Connect to database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Search database for username
GAMES_PLAYED="$($PSQL "SELECT games_played FROM scoreboard WHERE username='$USERNAME';")"

# If username not in database
if [[ -z $GAMES_PLAYED ]]
then
  # Create new user
  CREATE_USER_RETURN_VALUE="$($PSQL "INSERT INTO scoreboard(username, games_played, best_game) VALUES('$USERNAME', 0, 0);")"
  GAMES_PLAYED=0
  BEST_GAME=0
  # Welcome new user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # Finish getting data
  BEST_GAME="$($PSQL "SELECT best_game FROM scoreboard WHERE username='$USERNAME';")"
  # Welcome returning user
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Create variable to track number of guesses
NUM_GUESS=0

# Create regex to check for input type
INT_REGEX='^[0-9]+$'

# Prompt user for input
echo "Guess the secret number between 1 and 1000:"

GAME () {
  # Take input from user
  read GUESS
  # Increment number of guesses
  NUM_GUESS=$(( $NUM_GUESS + 1 ))
  if ! [[ $GUESS =~ $INT_REGEX ]]
  then 
    # If guess not an integer, reprompt
    echo "That is not an integer, guess again:"
    GAME
  elif [[ $GUESS -gt $GOAL ]]
  then
    # If guess greater than goal, reprompt
    echo "It's lower than that, guess again:"
    GAME
  elif  [[ $GUESS -lt $GOAL ]]
  then
    # If guess less than goal, reprompt
    echo "It's higher than that, guess again:"
    GAME
  else 
    # Congradulate user
    echo "You guessed it in $NUM_GUESS tries. The secret number was $GOAL. Nice job!"
  fi
}

GAME

# If new user
if [[ $BEST_GAME -eq 0 ]]
then
  # Update user information
  UPDATE_RETURN_VALUE="$($PSQL "UPDATE scoreboard set games_played=1, best_game=$NUM_GUESS WHERE username='$USERNAME';")"
else
  # Else if returning user, increment games played by one
  GAMES_PLAYED=$(( $GAMES_PLAYED + 1 ))
  # If current game better than best game
  if  [[ $NUM_GUESS -lt $BEST_GAME ]]
  then
    # Set beset game to current game
    BEST_GAME=$NUM_GUESS
  fi
  # Update user information
  UPDATE_RETURN_VALUE="$($PSQL "UPDATE scoreboard set games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE username='$USERNAME';")"
fi