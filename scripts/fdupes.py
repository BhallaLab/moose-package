"""fdupes.py: 

Hardlink duplicate files.

"""
    
__author__           = "Me"
__copyright__        = "Copyright 2016, Me"
__credits__          = ["NCBS Bangalore"]
__license__          = "GNU GPL"
__version__          = "1.0.0"
__maintainer__       = "Me"
__email__            = ""
__status__           = "Development"

import sys
import os
import hashlib
from collections import defaultdict
import shutil

files_ = defaultdict( list )

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def fdupes( files ):
    global files_
    for f in files:
        mdsum = md5( f )
        files_[ mdsum ].append( f )

def create_hardlink( files ):
    basefile = files[0]
    for f in files[1:]:
        # Delete this file and create a hard link to basefile.
        os.remove( f )
        os.link( basefile, f )
        print( '[HARDLINK] %s -> %s' % (f, basefile) )
        # print( os.stat( f ) )

def main( outdir ):
    global files_
    files = []
    for d, sd, fs in os.walk( outdir ):
        [ files.append( os.path.join( d, f ) ) for f in fs ] 

    fdupes( files )
    for m in files_:
        # These files shares md5sum. Now we remove other files and create a
        # hardlink to the first file.
        if len( files_[m] ) > 1:
            create_hardlink( files_[m] )

if __name__ == '__main__':
    d = sys.argv[1]
    outdir = d
    if len(sys.argv) > 2:
        outdir = sys.argv[2]
    if os.path.isdir( outdir ):
        shutil.rmtree( outdir )
    if outdir != d:
        shutil.copytree( d, outdir )
    main( outdir )
