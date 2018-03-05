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
#       CREATED: Sunday 04 March 2018 04:37:10  IST
#      REVISION:  ---
#===============================================================================

set -o nounset                                  # Treat unset variables as an error
set -e
export PATH=/usr/bin:/usr/local/bin:$PATH
mkdir -p _BUILD 
cd _BUILD 
cmake -DCMAKE_INSTALL_PREFIX=/tmp/usr -DWITH_MOOGLI=ON ..
make -j4
ctest -V
make install
SITEDIR=$(python -c 'import site;print(site.getsitepackages()[0]')
export PYTHONPATH=/tmp/${SITEDIR}
echo "Testing moose/moogli. PYTHONPATH=$PYTHONPATH"
python -c 'import moose;print(moose.__file__);print(moose.version())'
python -c 'import moogli;print(moogli.__file__);' 
