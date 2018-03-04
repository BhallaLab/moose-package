#!/usr/bin/env bash

# Fetch subtree same branch as parent,
CUR_BRANCH=$(git branch | grep \* | cut -d' ' -f2)
echo "We are on $CUR_BRANCH"
(
    git subtree pull --prefix moose https://github.com/BhallaLab/moose \
        $CUR_BRANCH --squash 
)
