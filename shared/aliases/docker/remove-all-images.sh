#!/usr/bin/env bash
docker rmi $(docker images -aq)