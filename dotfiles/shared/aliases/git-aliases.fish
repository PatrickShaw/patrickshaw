#!/usr/bin/env fish
alias remove-branches-already-merged-to-master="git branch --merged master |grep -v -e master| xargs -n 1 git branch -d"
alias gp="git push --set-upstream (git remote show) (git branch --show-current)"
