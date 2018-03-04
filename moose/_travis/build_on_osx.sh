#!/bin/bash -
#===============================================================================
#
#          FILE: build_on_osx.sh
#
#         USAGE: ./build_on_osx.sh
#
#   DESCRIPTION: 
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dilawar Singh (), dilawars@ncbs.res.in
#  ORGANIZATION: NCBS Bangalore
#       CREATED: Tuesday 27 June 2017 01:55:11  IST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -e
(
    cd _travis
    # brew audit --strict --online moose.rb # Failling with seg-fault.
    brew install -V --build-from-source moose.rb
)
