#!/bin/bash
# usage: ./client.sh <number>

if [ $# -eq 0 ]; then
  echo "Uso: ./client.sh <numero>"
  exit 1
fi

CLIENT_NUMBER=$1
NODE_NAME="client$CLIENT_NUMBER"
NODE_ADDRESS=localhost
SNAME="$NODE_NAME@$NODE_ADDRESS"
COOKIE=secret

cd apps/client
elixir --sname $SNAME --cookie $COOKIE -S mix run --no-halt
cd ../..