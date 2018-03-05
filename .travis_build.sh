#!/bin/bash -
#===============================================================================
#
#          FILE: .travis_build.sh
#
#         USAGE: ./.travis_build.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dilawar Singh (), dilawars@ncbs.res.in
#  ORGANIZATION: NCBS Bangalore
#       CREATED: Monday 05 March 2018 12:26:32  IST
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error
set -e -x

PATH=/usr/bin:/usr/local/bin:$PATH
mkdir -p _build
cd _build
cmake -DCMAKE_INSTALL_PREFIX=/tmp/moogli/usr ..
make -j4 && make bdist && make install
export PYTHONPATH=/tmp/moogli$(python -c 'import site;print(site.getsitepackages()[-1])')
python -c 'import moogli;print(moogli.__file__)'
