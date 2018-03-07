CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# moogli project is inside ./moogli 
# NOTE: The main cmake file is in ./moogli folder. This script is a top-level
# script to call ./moogli/CMakeLists.txt with proper environment variables set.
project(build_moogli)

set(CMAKE_POLICY CMP0017 ON)


# A phony target to setup correct depedencies. This is always out-of-date.
add_custom_target(_moogli_all ALL)

# VERSION.
set(MOOGLI_VERSION 0.5.0)
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/VERSION "${MOOGLI_VERSION}")

set(MOOGLI_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moogli)
add_custom_target(_build_moogli ALL
    DEPENDS ${MOOGLI_SRC_DIR}/core/_moogli.so
    )

# Check if OpenSceneGraph available.
FIND_PACKAGE(OpenSceneGraph 3.2.0)
IF(NOT OPENSCENEGRAPH_FOUND)
    MESSAGE(STATUS "Building OSG locally")
    SET(OSG_LOCAL ON)
    SET(BUILD_STATIC ON)
else()
    SET(BUILD_STATIC OFF)
    MESSAGE(STATUS "OSG Found: ${OPENSCENEGRAPH_VERSION}")
ENDIF()

IF(OSG_LOCAL)
    include(build_static_osg.cmake)
ENDIF(OSG_LOCAL)

FIND_PACKAGE(PythonInterp REQUIRED)


# On debian or ubuntu, --install-layout=deb needs to be passed.
if(UNIX AND NOT APPLE)
    find_program(LSB_RELEASE lsb_release)
    if(LSB_RELEASE)
        execute_process(COMMAND ${LSB_RELEASE} -is
            OUTPUT_VARIABLE LSB_RELEASE_ID_SHORT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            )
        if(${LSB_RELEASE_ID_SHORT} STREQUAL "Ubuntu" 
                OR ${LSB_RELEASE_ID_SHORT} STREQUAL "Debian" )
            message(STATUS "Debian based LINUX: ${LSB_RELEASE_ID_SHORT}" )
            # Create a setup.cfg file.
            file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/setup.cfg
                "[install]\nprefix=/usr\ninstall-layout=deb" 
                )
            set(CMAKE_PYMOOSE_ARGS "-DDISTUTILS_EXTRA_ARGS=\"--layout=deb\"" )
            set(INSTALL_OPTIONS "--layout=deb" )
        endif( )
    endif( )
endif( )


# BUILD
set(MOOGLI_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moogli_)
set(MOOGLI_BDIST_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moogli_bdist_)
set(MOOGLI_BDIST_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/_moogli_bdist_install_)
file(MAKE_DIRECTORY ${MOOGLI_BUILD_DIR})
file(MAKE_DIRECTORY ${MOOGLI_BDIST_DIR})
file(MAKE_DIRECTORY ${MOOGLI_BDIST_INSTALL_DIR})

set(MOOGLI_MAIN_OUTFILE ${MOOGLI_SRC_DIR}/core/_moogli.so)
add_custom_command( OUTPUT ${MOOGLI_MAIN_OUTFILE}
    COMMAND OSGDIR=${OSG_INSTALL_DIR}
        ${CMAKE_COMMAND} -DBUILD_STATIC=${BUILD_STATIC} 
            -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
            ${MOOGLI_SRC_DIR}
    COMMAND $(MAKE) VERBOSE=1
    WORKING_DIRECTORY ${MOOGLI_BUILD_DIR}
    VERBATIM
    )
add_custom_target(build_moogli DEPENDS ${MOOGLI_MAIN_OUTFILE})
add_dependencies(_moogli_all build_moogli)

# BDIST, install depends on it.
add_custom_target( bdist DEPENDS build_moogli )
add_custom_command( TARGET bdist 
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR} && ${PYTHON_EXECUTABLE} setup.py 
        bdist_dumb -d ${MOOGLI_BDIST_DIR}
    COMMAND ${CMAKE_COMMAND} -E chdir ${MOOGLI_BDIST_INSTALL_DIR} 
    tar xvf ${MOOGLI_BDIST_DIR}/moogli-${MOOGLI_VERSION}*.tar.gz
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
add_dependencies( _moogli_all bdist )

# Install the unarchived bdist
install(DIRECTORY  ${MOOGLI_BDIST_INSTALL_DIR}/usr/ 
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    )
