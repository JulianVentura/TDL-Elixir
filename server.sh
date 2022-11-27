#!/bin/bash
# usage: ./server.sh <number>

NUMBER_OF_SERVERS=$1
NODE_NAME="server"
NODE_ADDRESS=localhost
SNAME="$NODE_NAME@$NODE_ADDRESS"
COOKIE=secret

cd apps/server

if [ $# -eq 0 ]; then
  echo "Iniciando un solo server"
  echo "Si se quiere inicar multiples instancias usar: ./server.sh <numero_instancias>"
  elixir --sname $SNAME --cookie $COOKIE -S mix run --no-halt
else
  echo "Iniciando un $NUMBER_OF_SERVERS instancias de servidores"
  # TODO: ver como hacer, si abrir varios bash o que hacer
  # TODO: borrar carpeta client? run?
  elixir --sname $SNAME --cookie $COOKIE -S mix run --no-halt
fi

cd ../..
