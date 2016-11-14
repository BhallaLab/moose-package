#!/bin/bash
echo "Updating moose-master branch in subtree"
(
git subtree push --prefix moose-python \
    https://github.com/BhallaLab/moose-python-package master --squash
git subtree push --prefix moose-gui \
    https://github.com/BhallaLab/moose-gui-package master --squash
)
