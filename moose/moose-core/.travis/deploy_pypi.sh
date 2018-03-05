#!/bin/bash -
#===============================================================================
#
#          FILE: deploy_pypi.sh
#
#         USAGE: ./deploy_pypi.sh
#
#   DESCRIPTION:  Build docker image and deploy on PyPI.
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dilawar Singh (), dilawars@ncbs.res.in
#  ORGANIZATION: NCBS Bangalore
#       CREATED: Sunday 04 February 2018 11:46:32  IST
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
export PYTHONPATH=/tmp/usr/lib/
echo "Testing moose/moogli. PYTHONPATH=$PYTHONPATH"
python -c 'import moose;print(moose.__file__);print(moose.version())'
python -c 'import moogli;print(moogli.__file__);' 
