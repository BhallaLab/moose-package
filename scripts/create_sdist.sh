#!/bin/bash - 
#===============================================================================
#
#          FILE: create_sdist.sh
# 
#         USAGE: ./create_sdist.sh 
# 
#   DESCRIPTION: Generate source distribution from git repo.
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
set -x
set -e
VERSION="$1"
if [ $# -lt 1 ]; then
    echo "Version for this realeae?"
    read VERSION
fi
./scripts/git-archive-all.sh  --prefix moose-$VERSION/ --format tar.gz moose-$VERSION.tar.gz
