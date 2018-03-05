#!/usr/bin/env bash

set -o nounset                                  # Treat unset variables as an error
set -e -x

mkdir -p _build
cd _build && cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local .. && make install
SITEDIR=$(python -c "import site;print(site.USER_SITE)")
export PYTHONPATH=/tmp/moogli/${SITEDIR}
python -c 'import moogli;print(moogli.__file__);'
