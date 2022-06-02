#!/bin/bash

screen -dmS serve bundle exec jekyll serve --unpublished --future -w

echo "#### Starting screen session -- press ctrl-d to detach"
screen -x serve
echo #### Screen exited.
