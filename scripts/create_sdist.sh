#!/bin/bash - 
#===============================================================================
#
#          FILE: create_sdist.sh
# 
#         USAGE: ./create_sdist.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dilawar Singh (), dilawars@ncbs.res.in
#  ORGANIZATION: NCBS Bangalore
#       CREATED: Saturday 12 November 2016 03:12:37  IST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
echo "Version for this realeae?"
read VERSION
(
    cd ..
    mkdir -p moose-$VERSION
    rsync --progress -azv --cvs-exclude moose-all-package/ moose-$VERSION/
    tar --exclude-vcs -cvf moose-$VERSION.tar.gz moose-$VERSION
)

