cmake_minimum_required(VERSION 2.8)

# A dummy target to add dependencies later.
project(moose_all)

# ALL OPTIONS 

# Since we are building package, ask user to provide the version info from
# command line.
option(MOOSE_VERSION "Which moose version?" OFF)
if(NOT MOOSE_VERSION)
    message(FATAL_ERROR 
        "You must provide version info from command line e.g. "
        "\n   $ cmake -DMOOSE_VERSION=3.1.1 "
        )
endif( )

option(PACKAGING_ON_LAUNCHPAD "Enable packaing on launchpad" OFF)
option(PACKAGING_ON_OBS "If we are packaging on OBS" OFF)
option( WITH_MOOGLI "Build with moogli" ON)
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
set(MOOSE_PYTHON_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moose/moose-core)
set(MOOSE_PYTHON_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/__build_moose_python)
file(MAKE_DIRECTORY ${MOOSE_PYTHON_BUILD_DIR})


add_custom_target(moose_all ALL)

# NOTE: Install moose-python and moose-gui to differnt location.
# Otherwise each call of make install with overwrite.
set(MOOSE_PYTHON_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/_install_moose_python_)
file(MAKE_DIRECTORY ${MOOSE_PYTHON_INSTALL_DIR})
add_custom_command(
    # Using .so in dependency is not a great idea since its suffix will change
    # on different platforms e.g. dynlib on OSX etc. Therefore using moose.bin
    # target to generate dependency. This target is never installed.
    OUTPUT ${MOOSE_PYTHON_BUILD_DIR}/moose.bin
    # Pass the environment variable so local installation gets searched.
    COMMAND ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${MOOSE_PYTHON_INSTALL_DIR}
        -DMOOSE_VERSION=${MOOSE_VERSION}
        ${MOOSE_PYTHON_SOURCE_DIR}
    COMMAND $(MAKE)
    COMMAND $(MAKE) install _moose # We only need python interface.
    #COMMAND ${CMAKE_COMMAND} -P cmake_install.cmake
    WORKING_DIRECTORY ${MOOSE_PYTHON_BUILD_DIR}
    VERBATIM
    )


# NOTICE: Using .so in dependency is not a great idea since its suffix will change
# on different platforms e.g. dynlib on OSX etc. Therefore using moose.bin
# target to generate dependency. This target is never installed.
add_custom_target(_build_moose_python ALL
    DEPENDS ${MOOSE_PYTHON_BUILD_DIR}/moose.bin
    )
add_dependencies(moose_all _build_moose_python)

################################################################################
# GUI
################################################################################
set(MOOSE_GUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moose/moose-gui)
set(MOOSE_EXAMPLE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moose/moose-examples)
set(MOOSE_GUI_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moose_gui_)
file(MAKE_DIRECTORY ${MOOSE_GUI_INSTALL_DIR})

find_package(PythonInterp REQUIRED)

# Target does not build anything.
add_custom_target(moosegui ALL)

################################################################################
# MOOGLI
################################################################################
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

    add_dependencies(moose_all _build_moogli)

endif( WITH_MOOGLI )

################################################################################
# OTHERS
################################################################################
set( SOURCE_DISTRIBUTION
    ${CMAKE_CURRENT_BINARY_DIR}/moose-${MOOSE_VERSION}.tar.gz 
    )
add_custom_command(
    OUTPUT ${SOURCE_DISTRIBUTION}
    COMMAND ${CMAKE_COMMAND} -E tar "cfvz" 
        "${SOURCE_DISTRIBUTION}" "${CMAKE_CURRENT_SOURCE_DIR}"
    VERBATIM
    )
add_custom_target(sdist 
    DEPENDS ${SOURCE_DISTRIBUTION}
    )


################################################################################
# INSTALL 
################################################################################

# We only want python module and not the moose components.
INSTALL(
    DIRECTORY ${MOOSE_PYTHON_INSTALL_DIR}/lib/
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/
    USE_SOURCE_PERMISSIONS
    PATTERN "libmoose.so" EXCLUDE
    )

install(DIRECTORY ${MOOSE_GUI_DIR}/
    DESTINATION lib/moose/gui
    COMPONENT moose-gui
    )

install(DIRECTORY ${MOOSE_EXAMPLE_DIR}/
    DESTINATION lib/moose/
    COMPONENT moose-gui
    PATTERN "_travis" EXCLUDE
    PATTERN "CVS" EXCLUDE
    PATTERN ".git*" EXCLUDE
    )

# create the launcher.
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/moosegui.in 
    ${CMAKE_CURRENT_BINARY_DIR}/moosegui
    )

## install the launchers,
install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/moosegui
    DESTINATION bin
    )

if( WITH_MOOGLI )
    INSTALL(DIRECTORY ${MOOGLI_INSTALL_DIR}/
        DESTINATION ${CMAKE_INSTALL_PREFIX}
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
