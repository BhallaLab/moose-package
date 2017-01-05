#!/bin/bash - 
#===============================================================================
#
#          FILE: build_locally_obs.sh
# 
#         USAGE: ./build_locally_obs.sh 
# 
#   DESCRIPTION:  Build this version of repository using open-build-service
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dilawar Singh (), dilawars@ncbs.res.in
#  ORGANIZATION: NCBS Bangalore
#       CREATED: Thursday 17 November 2016 09:48:02  IST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -x
set -e

VERSION=3.1.1
if [ ! -d home:moose/moose ]; then
    echo "Checking out open-build-service version"
    osc co home:moose/moose 
fi

if [ ! -f home:moose/moose/moose-${VERSION}.tar.gz ]; then
    echo "Now create a tar file"
    ( 
        cd ..
        ./scripts/create_sdist.sh ${VERSION}
        cp moose-${VERSION}.tar.gz ./OBS/home:moose/moose 
    )
fi

echo "Now building using OBS"
(
    cd home:moose/moose 
    chmod +x ./build.sh
    ./build.sh openSUSE_13.2 
)
