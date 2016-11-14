#!/bin/bash
echo "Adding master branch in subtree"
(
    git subtree add  --prefix moose-python \
        https://github.com/BhallaLab/moose-python-package master --squash
    git subtree add  --prefix moose-gui \
        https://github.com/BhallaLab/moose-gui-package master --squash
    git subtree add --prefix moogli \
        https://github.com/BhallaLab/moogli  master --squash
)
