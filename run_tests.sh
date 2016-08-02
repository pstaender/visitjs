#!/bin/sh
PORT=3300
coffee server.coffee & node_modules/mocha/bin/mocha
./node_modules/.bin/wdio
if [ $? -eq 1 ]
then
  kill $(lsof -t -i:$PORT)
  echo "sth went wrong"
  exit 1
else
  kill $(lsof -t -i:$PORT)
  exit 0
fi
