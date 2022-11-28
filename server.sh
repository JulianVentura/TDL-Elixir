#!/bin/bash
# usage: ./server.sh <number>

SERVER_NUMBER=$1
NODE_NAME="server"
NODE_ADDRESS=localhost
SNAME="$NODE_NAME@$NODE_ADDRESS"
COOKIE=secret

cd apps/server

if [ $# -eq 0 ]; then
  echo "Iniciando server root $SNAME"
  elixir --sname $SNAME --cookie $COOKIE -S mix run --no-halt
else
  SNAME="$NODE_NAME-$SERVER_NUMBER@$NODE_ADDRESS"
  echo "Iniciando server $SNAME"
  elixir --sname $SNAME --cookie $COOKIE -S mix run --no-halt
fi

cd ../..
