#!/bin/bash

screen -dmS jekyll-serve bundle exec jekyll serve --unpublished --future -w --drafts

echo "#### Starting screen session -- press ctrl-d to detach"
screen -x jekyll-serve
echo #### Screen exited.
