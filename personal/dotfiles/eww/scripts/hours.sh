#!/usr/bin/env bash

execOutput() {
  date '+%H'
}

while true; do
  execOutput

  # Sleep for 1 second less than the tick just in case we sped up
  SLEEP_TIME=$(echo $(date "+%M") $(date "+%S%N") | frawk '{ print ((60 - $1) * 60 * 1000 * 1000 * 1000 - $2) / (1000 * 1000 * 1000) - 1 }')
  sleep $SLEEP_TIME
  execOutput

  # Wait the remainding time in case we didn't speed up
  SLEEP_TIME=$(echo $(date "+%M") $(date "+%S%N") | frawk '{ print ((60 - $1) * 60 * 1000 * 1000 * 1000 - $2) / (1000 * 1000 * 1000) - 1 }')
  sleep $SLEEP_TIME
  execOutput

  # Sleep 1 second after in case we're slow
  sleep 1
done
