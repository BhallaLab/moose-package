cmake_minimum_required(VERSION 2.8)

project(moose-all)

# Since we are building package, ask user to provide the version info from
# command line.
set(_MOOSE_VERSION 3.1.2)
if(NOT _MOOSE_VERSION)
    message(FATAL_ERROR 
        "You must provide version info from command line e.g. "
        "\n   $ cmake -D_MOOSE_VERSION=3.1.1 "
        )
endif( )
option(WITH_MOOGLI "Build with moogli" ON)

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

################################################################################
# BUILD
################################################################################
add_custom_target(moose_all ALL)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/moose/moose-core/cmake_modules)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_INSTALL_RPATH "")

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


# This variable keep additional arguments I need to pass to pymoose cmake
# command. Its value is used to determine if we should link with shared or
# static version of HDF5 libraries.
set(CMAKE_PYMOOSE_ARGS "-D_MOOSE_VERSION=${_MOOSE_VERSION}" )

# Create shell script to build local gsl
if(LOCAL_GSL)
    # CMAKE version of gsl does not play well with different build path. It
    # needs to be built in source directory only.
    set( GSL_SOURCE_DIR ${CMAKE_SOURCE_DIR}/external/gsl )
    set( GSL_BUILD_DIR ${GSL_SOURCE_DIR} )
    set( GSL_INSTALL_DIR ${CMAKE_BINARY_DIR}/__gsl_install )
    set( CMAKE_GSL_ARGS "-DCMAKE_C_FLAGS=-fPIC" )
    configure_file( ${CMAKE_SOURCE_DIR}/build_static_gsl.sh.in 
        ${CMAKE_BINARY_DIR}/build_static_gsl.sh 
        )
    set(GSL_ROOT_DIR ${GSL_INSTALL_DIR} )
endif()

find_package(HDF5 COMPONENTS CXX HL)
if ( NOT HDF5_FOUND )
    MESSAGE( STATUS "HDF5 is not found. Building private copy of hdf5")
    set( HDF5_SOURCE_DIR ${CMAKE_SOURCE_DIR}/external/hdf5 )
    set( HDF5_BUILD_DIR ${CMAKE_BINARY_DIR}/__hdf5_build )
    file( MAKE_DIRECTORY ${HDF5_BUILD_DIR} )
    set( HDF5_INSTALL_DIR ${CMAKE_BINARY_DIR}/__hdf5_install )
    set( CMAKE_HDF5_ARGS "-DHDF5_BUILD_HL_LIB=ON -DBUILD_SHARED_LIB=OFF" )
    # NOTE: Before writing script, we must set this option if static libraries
    # are to be used.
    set( CMAKE_PYMOOSE_ARGS "${CMAKE_PYMOOSE_ARGS} -DHDF5_USE_STATIC_LIBRARIES=ON" )
    configure_file( ${CMAKE_SOURCE_DIR}/build_static_hdf5.sh.in 
        ${CMAKE_BINARY_DIR}/build_static_hdf5.sh
        )
    set(HDF5_ROOT ${HDF5_INSTALL_DIR} )
endif ( )

# This option make sure that static libraries are picked up by CMAKE.
if(LOCAL_GSL)
    set(CMAKE_PYMOOSE_ARGS "${CMAKE_PYMOOSE_ARGS} -DGSL_USE_STATIC_LIBRARIES=ON")
endif(LOCAL_GSL)

## NOW setup MOOSE project.
set(MOOSE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/moose )
set(MOOSE_BUILD_DIR ${CMAKE_BINARY_DIR}/__moose_build)
set(MOOSE_INSTALL_DIR ${CMAKE_BINARY_DIR}/__moose_install)
add_custom_target(moose ALL DEPENDS ${MOOSE_INSTALL_DIR}/bin/moose.bin )

# Create dependency targets.
if(LOCAL_GSL)
    add_custom_target( gsl ALL DEPENDS ${GSL_INSTALL_DIR}/bin/gsl-config )
    add_custom_command( OUTPUT ${GSL_INSTALL_DIR}/bin/gsl-config 
        COMMAND MAKE=$(MAKE) bash -c ${CMAKE_BINARY_DIR}/build_static_gsl.sh 
        VERBATIM
        )
    add_dependencies( moose gsl )
endif(LOCAL_GSL)

if(NOT HDF5_FOUND)
    add_custom_target( hdf5 ALL DEPENDS ${HDF5_INSTALL_DIR}/lib/libhdf5.a )
    add_custom_command( OUTPUT ${HDF5_INSTALL_DIR}/lib/libhdf5.a 
        COMMAND MAKE=$(MAKE) bash -c ${CMAKE_BINARY_DIR}/build_static_hdf5.sh 
        VERBATIM
        )
    add_dependencies( moose hdf )
endif(NOT HDF5_FOUND)

# Once dependencies are built, build moose project.
file(MAKE_DIRECTORY ${MOOSE_BUILD_DIR})
add_custom_command( 
    OUTPUT ${MOOSE_INSTALL_DIR}/bin/moose.bin 
    COMMAND ${CMAKE_COMMAND} 
            -DHDF5_ROOT=${HDF5_INSTALL_DIR}
            -DGSL_ROOT_DIR=${GSL_INSTALL_DIR}
            -DCMAKE_PYMOOSE_ARGS=${CMAKE_PYMOOSE_ARGS}
            -DCMAKE_INSTALL_PREFIX=${MOOSE_INSTALL_DIR}
        ${MOOSE_SOURCE_DIR}
    COMMAND $(MAKE)
    COMMAND $(MAKE) install
    WORKING_DIRECTORY ${MOOSE_BUILD_DIR}
    VERBATIM 
    )

add_dependencies(moose_all moose )

################################################################################
# MOOGLI
################################################################################
if( WITH_MOOGLI )
# Build moogli
    set(MOOGLI_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moogli)
    set(MOOGLI_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/__moogli_install)
    set(MOOGLI_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/__moogli_build)
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

    add_custom_target(moogli ALL
        DEPENDS ${MOOGLI_SRC_DIR}/moogli/core/_moogli.so
        )

    add_dependencies(moose_all moogli)

endif( WITH_MOOGLI )

################################################################################
# OTHERS
################################################################################

################################################################################
# INSTALL 
################################################################################

# We only want python module and not the moose components.
INSTALL( DIRECTORY ${MOOSE_INSTALL_DIR}/lib/
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/
    USE_SOURCE_PERMISSIONS
    PATTERN "libmoose.so" EXCLUDE
    )

## install the launchers,
install(PROGRAMS ${MOOSE_INSTALL_DIR}/bin/moose DESTINATION bin)

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
    COMMAND ${PYTHON_EXECUTABLE} -c
        "import moose; print(moose.__file__); print(moose.__version__ )" 
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
