cmake_minimum_required(VERSION 2.8)

# A dummy target to add dependencies later.
project(moose_all)

# Since we are building package, ask user to provide the version info from
# command line.
option(MOOSE_VERSION "Which moose version?" OFF)
if(NOT MOOSE_VERSION)
    message(FATAL_ERROR 
        "You must provide version info from command line e.g. "
        "\n   $ cmake -DMOOSE_VERSION=3.1.1 "
        )
endif( )
option( WITH_MOOGLI "Build with moogli" ON)

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

#################
# SUBMODULE locations.
set(MOOSE_PYTHON_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moose/moose-core)
set(MOOSE_PYTHON_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/__build_moose_python)
file(MAKE_DIRECTORY ${MOOSE_PYTHON_BUILD_DIR})

################################################################################
# BUILD
################################################################################
add_custom_target(moose_all ALL)

################################################################################
# Build dependencies 
################################################################################
add_custom_target(_moose_static_dependencies ALL)
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/moose/moose-core/cmake_modules)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_INSTALL_RPATH "")

# Collect all options for moose-core/python module here.
set(MOOSE_CORE_CMAKE_OPTIONS "")

find_package(GSL 1.16)
# If installed version of gsl is not 1.16 then download and build gsl locally.
# THIS IS USEFULL TO BUILD MOOSE FOR VARIOUS DISTRIBUTIONS.
if(NOT GSL_FOUND)
    MESSAGE(STATUS "No GSL found. Using local gsl")
    set(LOCAL_GSL 1)
else()
    message(STATUS "GSL_VERSION ${GSL_VERSION}")
    if(${GSL_VERSION} VERSION_LESS 1.16)
        MESSAGE(STATUS  "Needed version 1.16. I'll now build priavate copy of GSL" )
        SET(LOCAL_GSL 1)
    endif()
endif()

if(LOCAL_GSL)
    include(${CMAKE_CURRENT_SOURCE_DIR}/build_static_gsl.cmake)
    list(APPEND MOOSE_CORE_CMAKE_OPTIONS "-DGSL_STATIC_HOME=${GSL_INSTALL_DIR}")
    list(APPEND MOOSE_CORE_CMAKE_OPTIONS "-DGSL_ROOT=${GSL_INSTALL_DIR}")
endif()

find_package(HDF5 COMPONENTS CXX HL)
if(NOT HDF5_FOUND)
    MESSAGE(STATUS "HDF5 is not found. Building private copy of hdf5")
    include(${CMAKE_CURRENT_SOURCE_DIR}/build_static_hdf.cmake)
    list(APPEND MOOSE_CORE_CMAKE_OPTIONS 
        "-DHDF5_USE_STATIC_LIBRARIES=ON"
        "-DHDF5_ROOT=${HDF5_INSTALL_DIR}" 
        )
endif( )

message( 
    STATUS "Following options are passed down to moose-core module"
    "${MOOSE_CORE_CMAKE_OPTIONS}"
    )
add_custom_command(
    OUTPUT ${MOOSE_CORE_BUILD_DIR}/moose.bin ${MOOSE_CORE_BUILD_DIR}/moose-${MOOSE_VERSION}.tar.gz
    # Pass the environment variable so local installation gets searched.
    COMMAND GSL_HOME=${GSL_INSTALL_DIR} 
    COMMAND HDF5_ROOT=${HDF5_INSTALL_DIR}
    ${CMAKE_COMMAND} 
        -DDEBUG:BOOL=OFF 
        -DWITH_DOC:BOOL=${WITH_DOC}
        # This variable will make sure that static libraries are linked 
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_SKIP_RPATH=ON
        -DMOOSE_VERSION=${MOOSE_VERSION}
        ${MOOSE_CORE_CMAKE_OPTIONS}
        ${MOOSE_SOURCE_DIRECTORY}
    COMMAND $(MAKE) VERBOSE=1
    # Not running neuroml test since it requires matplotlib.
    #COMMAND ctest -E neuroml --output-on-failure
    # Build and test, do not install here.
    WORKING_DIRECTORY ${MOOSE_CORE_BUILD_DIR}
    VERBATIM
    )

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
    COMMAND GSL_HOME=${GSL_INSTALL_DIR} 
    ${CMAKE_COMMAND} 
        -DMOOSE_VERSION=${MOOSE_VERSION}
        -DGSL_STATIC_HOME=${GSL_INSTALL_DIR}
        -DHDF5_STATIC_HOME=${HDF5_INSTALL_DIR}
        -DCMAKE_INSTALL_PREFIX=${MOOSE_PYTHON_INSTALL_DIR}
        -DCMAKE_SKIP_RPATH=ON
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
add_dependencies( _build_moose_python _moose_static_dependencies )

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
    set(MOOGLI_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moogli_build)
    file(MAKE_DIRECTORY ${MOOGLI_BIN_DIR})
    file(MAKE_DIRECTORY ${MOOGLI_INSTALL_DIR} )
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

install(DIRECTORY ${MOOSE_EXAMPLE_DIR}
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


######################## CTEST #################################################
enable_testing( )

add_test( NAME test_moose 
    COMMAND ${PYTHON_EXECUTABLE} -c "import moose" 
    )

add_test( NAME test_moogli
    COMMAND ${PYTHON_EXECUTABLE} -c "import moogli" 
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/lib/python2.7/site-packages
    )

add_test( NAME test_gui
    COMMAND ${PYTHON_EXECUTABLE} mgui.py
    WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/lib/moose/gui
    )

set_tests_properties(  test_moose test_moogli test_gui 
    PROPERTIES ENVIRONMENT
    "PYTHONPATH=${CMAKE_INSTALL_PREFIX}/lib/python2.7/site-packages"
    )
