#!/bin/bash

# Configuración de la base de datos
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Crear tabla si no existe
$PSQL "CREATE TABLE IF NOT EXISTS users(
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(22) UNIQUE,
  games_played INT DEFAULT 0,
  best_game INT
)" &>/dev/null

# Solicitar nombre de usuario
echo "Enter your username:"
read USERNAME

# Verificar si el usuario existe
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # Usuario nuevo
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME')" &>/dev/null
else
  # Usuario existente
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generar número secreto
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"
GUESSES=0

# Juego de adivinanza
while true; do
  read GUESS
  ((GUESSES++))

  # Validar entrada
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Comprobar la adivinanza
  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Actualizar estadísticas del usuario
GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")

# Incrementar juegos jugados
NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
$PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE username='$USERNAME'" &>/dev/null

# Actualizar mejor juego si aplica
if [[ -z $BEST_GAME || $GUESSES -lt $BEST_GAME ]]; then
  $PSQL "UPDATE users SET best_game = $GUESSES WHERE username='$USERNAME'" &>/dev/null
fi
