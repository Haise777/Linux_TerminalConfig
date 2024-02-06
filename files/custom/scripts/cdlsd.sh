#!/bin/bash

printf "\033[0;96m$(pwd)\033[0m\n"
cd "$1" || exit 1
lsd -lA
