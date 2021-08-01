#!/usr/bin/env fish
alias stop-all-containers="docker stop (docker ps -q)"
alias remove-all-containers="docker rm (docker container ls -aq)"
alias remove-all-images="docker rmi (docker images -aq)"
	