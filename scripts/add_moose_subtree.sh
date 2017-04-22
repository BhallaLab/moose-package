#!/bin/bash
echo "Adding master branch in subtree"
(
    git subtree add --prefix moogli \
        https://github.com/BhallaLab/moogli  master --squash
)
