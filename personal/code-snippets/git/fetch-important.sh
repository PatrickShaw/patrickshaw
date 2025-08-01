#!/usr/bin/env bash

# Fetch the current branch
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

declare -a branches_to_fetch

branches_to_fetch+=($CURRENT_BRANCH)

# Check for 'main' and fetch, otherwise fetch 'master'
if (! echo $CURRENT_BRANCH | grep -q main) && git branch -r | grep -q origin/main; then
  branches_to_fetch+=('main')
fi

if (! echo $CURRENT_BRANCH | grep -q master) && git branch -r | grep -q origin/master; then
  branches_to_fetch+=('master')
fi

git fetch origin ${branches_to_fetch[@]}

echo Fetched "${branches_to_fetch[@]}" 
