#!/usr/bin/env bash

# Fetch subtree same branch as parent,
CUR_BRANCH=$(git branch | grep \* | cut -d' ' -f2)
echo "We are on $CUR_BRANCH"
(
    git subtree push --prefix moose https://github.com/BhallaLab/moose $CUR_BRANCH 
    git subtree push --prefix moogli https://github.com/BhallaLab/moogli $CUR_BRANCH 
)
