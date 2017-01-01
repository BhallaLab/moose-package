!/bin/bash

echo "||NOTICE
If you are using this script on MacOSX 10.11.2, be careful about the following
error:
    illegal instruction: 4
I could get everything working fine on MacOSX- 10.8 
"

set -x
set -e

CURRDIR=`pwd`

# Unset any enviroment PYTHONPATH. They can confuse us.
unset PYTHONPATH
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin
export HOMEBREW_BUILD_FROM_SOURCE=YES

## This is not needed. Forgot why I put it here in first place.
#CFLAGS+=-march=native

APPNAME="Moose"
VERSION="3.1.1"
MAC_NAME=`sw_vers -productVersion`
PKGNAME="${APPNAME}_${VERSION}"

VOLNAME="${PKGNAME}"

### SAFETY
set +e
echo "|| Detaching possibly attached disk"
hdiutil detach /Volumes/${PKGNAME}
set -e

DMGFILELABEL="${PKGNAME}"
THISDIR=`pwd`

# create the temp DMG file
STAGING_DIR=_Install
DMG_TMP="${PKGNAME}-${MAC_NAME}_BREWED.dmg"
mkdir -p ${STAGING_DIR}

if [ ! -f "${DMG_TMP}" ]; then
    ## NOTE: When building MOOGLI, size should be at least 1 GB.
    hdiutil create -srcfolder "${STAGING_DIR}" -volname "${PKGNAME}" \
        -format UDRW -size 1.5G "${DMG_TMP}"
else
    echo "DMG file $DMG_TMP exists. Mounting ..."
fi

# TODO
# mount it and save the device
DEVICE=$(hdiutil attach -readwrite -noverify "${DMG_TMP}" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')

############################# EXIT gacefully ################################ 
# Traps etc
# ALWAYS DETACH THE DEVICE BEFORE EXITING...
function detach_device 
{
    hdiutil detach "${DEVICE}"
    exit
}
trap detach_device SIGINT SIGTERM SIGKILL

sleep 1

echo "Install whatever you want now"
BREW_PREFIX="/Volumes/${VOLNAME}"
BREW=$BREW_PREFIX/bin/brew
export PATH=${BREW_PREFIX}/bin:$PATH
(
    cd $BREW_PREFIX
    if [ ! -f $BREW_PREFIX/bin/brew ]; then
        curl -L https://github.com/Homebrew/homebrew/tarball/master | \
            tar xz --strip 1 -C $BREW_PREFIX
    else
        echo "[I] Brew exists. Not installing"
    fi

    echo "Copying moose.rb and moogli.rb"
    rsync -azv --progress $CURRDIR/*.rb $BREW_PREFIX/Library/Formula/

    # This even works without python.
    ## NOTE: DO NOT install matplotlib using brew unless also installing python
    ## using brew. Since we are going to uninstall later, use pip to install
    ## matplotlib and numpy.
    $BREW update
    $BREW -v install homebrew/python/matplotlib --with-pyqt
    $BREW -v install homebrew/python/numpy
    $BREW link --overwrite matplotlib
    $BREW -v install homebrew/science/hdf5
    $BREW -v install moose --with-gui | tee "$CURRDIR/__brew_moose_log__"
    # Set home of Qt4, openscenegraph etc.
    # Install python-gobject 
    $BREW -v install gobject-introspection --env=std --with-head
    export QT_HOME=$BREW_PREFIX
    export OSG_HOME=$BREW_PREFIX 
    export PYQT_HOME=$BREW_PREFIX
    set +e
    $BREW_PREFIX/bin/pip uninstall networkx -y
    set -e
    $BREW_PREFIX/bin/pip install networkx  --upgrade

    ## Tests
    set -e
    export PYTHONPATH=$BREW_PREFIX/lib/python2.7/site-packages
    python -c 'import moose'
    set +e  ## This might fail.
    python -c 'import moogli'
    set -e
    python -c 'import suds'
    python -c 'import matplotlib'
    $BREW_PREFIX/bin/python -c 'import six'
    set +e

    # Also write script to launch the moosegui.
    MOOSEPATH=${BREW_PREFIX}/lib/python2.7/site-packages
    echo "Writing launcher script"
    cat > $BREW_PREFIX/moose <<EOF
#!/bin/bash
touch \$HOME/.bash_profile
source \$HOME/.bash_profile
if [[ "\${PYTHONPATH}" == *"${MOOSEPATH}"* ]]; then
    echo "[INFO] PYTHONPATH aleady contains ${MOOSEPATH}"
else
    # Also write to .bash_profile, so that we can use it.
    echo "[INFO] Adding ${MOOSEPATH} to PYTHONPATH"
    echo "export PYTHONPATH=${MOOSEPATH}:\$PYTHONPATH" >> \$HOME/.bash_profile
    source \$HOME/.bash_profile
fi
# make sure that for current runtime, we have correct path.
export PYTHONPATH=${MOOSEPATH}:\$PYTHONPATH
exec ${BREW_PREFIX}/bin/moose
EOF
    chmod a+x $BREW_PREFIX/moose
)

################ INSTALL THE ICON ########################################
DMG_BACKGROUND_IMG="${CURRDIR}/moose_icon_large.png"
# Check the background image DPI and convert it if it isn't 72x72
_BACKGROUND_IMAGE_DPI_H=`sips -g dpiHeight ${DMG_BACKGROUND_IMG} | grep -Eo '[0-9]+\.[0-9]+'`
_BACKGROUND_IMAGE_DPI_W=`sips -g dpiWidth ${DMG_BACKGROUND_IMG} | grep -Eo '[0-9]+\.[0-9]+'`

if [ $(echo " $_BACKGROUND_IMAGE_DPI_H != 72.0 " | bc) -eq 1 -o $(echo " $_BACKGROUND_IMAGE_DPI_W != 72.0 " | bc) -eq 1 ]; then
    echo "WARNING: The background image's DPI is not 72."
    echo "This will result in distorted backgrounds on Mac OS X 10.7+."
    echo "I will convert it to 72 DPI for you."
    _DMG_BACKGROUND_TMP="${DMG_BACKGROUND_IMG%.*}"_dpifix."${DMG_BACKGROUND_IMG##*.}"
    sips -s dpiWidth 72 -s dpiHeight 72 ${DMG_BACKGROUND_IMG} --out ${_DMG_BACKGROUND_TMP}
    DMG_BACKGROUND_IMG="${_DMG_BACKGROUND_TMP}"
fi

echo "TODO. Now resize and compress using hdiutil"
echo "|| use: hdiutil convert a.dmg -format UDBZ -o b.dmg"

## Finally detach the device
detach_device
