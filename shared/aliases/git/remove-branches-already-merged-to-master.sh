#!/usr/bin/env bash
git branch --merged master |grep -v -e master| xargs -n 1 git branch -d