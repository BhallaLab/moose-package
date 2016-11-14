cmake_minimum_required(VERSION 2.8)

# A dummy target to add dependencies later.
project(moose_all)

# ALL OPTIONS 

# Since we are building package, ask user to provide the version info from
# command line.
option( MOOSE_VERSION "Which moose version?" OFF)
if( NOT MOOSE_VERSION )
    message(FATAL "You must provide version info from command line" )
endif( )

option(PACKAGING_ON_LAUNCHPAD "Enable packaing on launchpad" OFF)
option(PACKAGING_ON_OBS "If we are packaging on OBS" OFF)

message(STATUS "CMAKE_INSTALL_PREFIX : ${CMAKE_INSTALL_PREFIX}")

# CMAKE related option.
# Don't allow building in-source
message(STATUS "CMAKE_INSTALL_PREFIX : ${CMAKE_INSTALL_PREFIX}")
if( CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR AND NOT MSVC_IDE )
    message(FATAL_ERROR 
        "======================================================================\n"
        "In-source builds are not allowed. Remove CMakeCache.txt and CMakeFiles\n"
        "directory and do something like this inside this directory \n"
        "    $ mkdir _build_dir \n"
        "    $ cd _build_dir  \n"
        "    $ cmake ..  \n"
        "===================================================================== \n"
        )
endif()

# SUBMODULE locations.
set(MOOSE_PYTHON_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moose/moose-python)
set(MOOSE_PYTHON_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/__build_moose_python)
file(MAKE_DIRECTORY ${MOOSE_PYTHON_BUILD_DIR})


add_custom_target(moose_all ALL)

# NOTE: Make sure to install moose-python and moose-gui to differnt prefixes.
# Otherwise each call of make install with overwrite.
set(MOOSE_PYTHON_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/_install_moose_python_)
file(MAKE_DIRECTORY ${MOOSE_PYTHON_INSTALL_DIR})
add_custom_command(
    OUTPUT ${MOOSE_PYTHON_BUILD_DIR}/moose.bin ${MOOSE_PYTHON_BUILD_DIR}/moose-${MOOSE_VERSION}.tar.gz
    # Pass the environment variable so local installation gets searched.
    COMMAND ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${MOOSE_PYTHON_INSTALL_DIR}
        -DMOOSE_VERSION=${MOOSE_VERSION}
        ${MOOSE_PYTHON_SOURCE_DIR}
    COMMAND $(MAKE)
    COMMAND ${CMAKE_COMMAND} -P cmake_install.cmake
    WORKING_DIRECTORY ${MOOSE_PYTHON_BUILD_DIR}
    VERBATIM
    )

add_custom_target(_build_moose_python ALL
    DEPENDS ${MOOSE_PYTHON_BUILD_DIR}/moose.bin 
    ${MOOSE_PYTHON_BUILD_DIR}/moose-${MOOSE_VERSION}.tar.gz
    )
add_dependencies(moose_all _build_moose_python)

# build moose-gui.
set(MOOSE_GUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moose/moose-gui)
set(MOOSE_GUI_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moose_gui_)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/moosegui
    COMMAND ${CMAKE_COMMAND} 
        -DCMAKE_INSTALL_PREFIX=${MOOSE_GUI_INSTALL_DIR}
        -DMOOSE_VERSION=${MOOSE_VERSION}
        ${MOOSE_GUI_DIR}
    COMMAND $(MAKE)
    COMMAND $(MAKE) install
    WORKING_DIRECTORY ${MOOSE_GUI_DIR}
    VERBATIM
    )
add_custom_target(_build_moose_gui ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/moosegui
    )
add_dependencies(moose_all _build_moose_gui)

option( WITH_MOOGLI "Build with moogli" OFF)
if( WITH_MOOGLI )
# Build moogli
    set(MOOGLI_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moogli)
    set(MOOGLI_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moogli)
    SET(MOOGLI_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moogli_build)
    FILE(MAKE_DIRECTORY ${MOOGLI_BIN_DIR})
    add_custom_command(
        OUTPUT ${MOOGLI_SRC_DIR}/moogli/core/_moogli.so
        COMMAND ${CMAKE_COMMAND} 
            -DCMAKE_INSTALL_PREFIX=${MOOGLI_INSTALL_DIR} ${MOOGLI_SRC_DIR}
        COMMAND $(MAKE)
        COMMAND $(MAKE) install
        WORKING_DIRECTORY ${MOOGLI_BIN_DIR}
        VERBATIM
        )

    add_custom_target(_build_moogli ALL
        DEPENDS ${MOOGLI_SRC_DIR}/moogli/core/_moogli.so
        )

# Create an archive
set( SOURCE_DISTRIBUTION
    ${CMAKE_CURRENT_BINARY_DIR}/moose-${MOOSE_VERSION}.tar.gz 
    )
add_custom_command(
    OUTPUT ${SOURCE_DISTRIBUTION}
    COMMAND ${CMAKE_COMMAND} -E tar "cfvz" 
        "${SOURCE_DISTRIBUTION}" "${CMAKE_CURRENT_SOURCE_DIR}"
    VERBATIM
    )
endif( WITH_MOOGLI )

add_custom_target(sdist ALL
    DEPENDS ${SOURCE_DISTRIBUTION}
    )

add_dependencies(moose_all _build_moogli)

# Leading character is very important.
INSTALL(DIRECTORY ${MOOSE_GUI_INSTALL_DIR}/
    DESTINATION usr
    USE_SOURCE_PERMISSIONS
    )

INSTALL(DIRECTORY ${MOOSE_PYTHON_INSTALL_DIR}/
    DESTINATION usr
    USE_SOURCE_PERMISSIONS
    )

if( WITH_MOOGLI )
    INSTALL(DIRECTORY ${MOOGLI_INSTALL_DIR}/
        DESTINATION usr
        USE_SOURCE_PERMISSIONS
        )
endif( WITH_MOOGLI )

## Tests.
enable_testing()
add_test(NAME moose-core 
    COMMAND ctest -R pymoose* --output-on-failure
    WORKING_DIRECTORY ${MOOSE_CORE_BUILD_DIR}
    )

######### CPACK ###############################################################
include(moose_cpack.cmake)
