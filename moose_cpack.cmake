# Packaging.
INCLUDE(InstallRequiredSystemLibraries)

##############
# Architecture.
MESSAGE("++ Testing for architecture: 64 bit or 32 bit")
if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
    MESSAGE("++ 64 bit architecture")
    set(LIBSUFFIX "64")
    set(PKGARCH "amd64")
    set(RPMPKGARCH "x86_64")
else()
    MESSAGE("++ 32 bit architecture")
    set(LIBSUFFIX "")
    set(PKGARCH "i386")
endif()

SET(CPACK_SOURCE_STRIP_FILES ON)
SET(CPACK_STRIP_FILES ON)

SET(IGNORE_PATTERNS
    ${CPACK_SOURCE_IGNORE_FILES}
    ${MOOSE_PYTHON_BUILD_DIR}*
    ${MOOSE_GUI_DIR}*
    ${MOOGLI_BIN_DIR}*
    )
SET(CPACK_SOURCE_IGNORE_FILES  "${IGNORE_PATTERNS}")
SET(CPACK_GENERATOR "DEB;RPM;STGZ;TGZ")
SET(CPACK_PACKAGE_NAME "moose-all")
SET(CPACK_PACKAGE_VENDOR "Bhalla Lab, NCBS Bangalore")
SET(CPACK_PACKAGE_CONTACT "Dilawar Singh <dilawars@ncbs.res.in>")
SET(CPACK_PACKAGE_VERSION "3.0.2")
SET(CPACK_PACKAGE_VERSION_MAJOR "3")
SET(CPACK_PACKAGE_VERSION_MINOR "0")
SET(CPACK_PACKAGE_VERSION_PATCH "2")
SET(CPACK_SOURCE_GENERATOR "TGZ;TZ")
# THis is neccessary else we get /usr/usr, I don't know why. This fixes it. 
SET(CPACK_PACKAGING_INSTALL_PREFIX /)
SET(CPACK_WARN_ON_ABSOLUTE_INSTALL_DESTINATION ON)

## Debian dependencies
SET(CPACK_DEBIAN_PACKAGE_DEPENDS 
    "python-numpy,python-matplotlib,python-lxml,python-nose,python-networkx,python-suds,python-qt4,python-sip,python-qt4-gl,libqt4-gui"
    )
include(CPack)
