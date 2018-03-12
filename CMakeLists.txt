CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# moogli project is inside ./moogli 
# NOTE: The main cmake file is in ./moogli folder. This script is a top-level
# script to call ./moogli/CMakeLists.txt with proper environment variables set.
project(MOOGLI LANGUAGES CXX)

set(CMAKE_POLICY CMP0017 ON)

# Create a TOP-LEVEL target to dependencies can be set up properly.
set(MOOGLI_MAIN_OUTFILE ${MOOGLI_SRC_DIR}/core/_moogli.so)
add_custom_target(build_moogli ALL 
    DEPENDS ${MOOGLI_MAIN_OUTFILE}
    )

# VERSION.
set(MOOGLI_VERSION 0.5.0)
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/VERSION "${MOOGLI_VERSION}")

set(MOOGLI_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/moogli)
# Check if OpenSceneGraph available.
find_package(OpenSceneGraph)
if(NOT (OPENSCENEGRAPH_FOUND AND OPENSCENEGRAPH_VERSION))
    message(STATUS "Could not find OSG. I will build private OSG.")
    set(OSG_LOCAL ON)
    set(BUILD_STATIC ON)
else()
    set(BUILD_STATIC OFF)
    MESSAGE(STATUS "OSG Found: ${OPENSCENEGRAPH_VERSION}")
endif()

# If we need to build local OSG, make sure that it is called before build_moogli
# is called.
IF(OSG_LOCAL)
    message(STATUS "Needs to build OSG locally")
    include(build_static_osg.cmake)
    add_dependencies(build_moogli _libosg)
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

add_custom_command( OUTPUT ${MOOGLI_MAIN_OUTFILE}
    COMMAND OSGDIR=${OSG_INSTALL_DIR}
        ${CMAKE_COMMAND} -DBUILD_STATIC=${BUILD_STATIC} 
            -DPYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}
            ${MOOGLI_SRC_DIR}
    COMMAND $(MAKE) 
    WORKING_DIRECTORY ${MOOGLI_BUILD_DIR}
    COMMENT "Building ${MOOGLI_MAIN_OUTFILE}"
    VERBATIM
    )

# BDIST, install depends on it.
set(MOOGLI_BDIST_FILE ${MOOGLI_BDIST_DIR}/moogli-${MOOGLI_VERSION}*.CMAKE.tar.gz)
add_custom_target(bdist DEPENDS ${MOOGLI_BDIST_FILE})
add_custom_command( OUTPUT ${MOOGLI_BDIST_FILE}
    DEPENDS ${MOOGLI_MAIN_OUTFILE}
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR} && ${PYTHON_EXECUTABLE} setup.py 
        bdist -d ${MOOGLI_BDIST_DIR} -p CMAKE
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Building bdist"
    VERBATIM
    )
add_custom_command( TARGET bdist POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E chdir ${MOOGLI_BDIST_INSTALL_DIR} 
        tar xvf ${MOOGLI_BDIST_DIR}/moogli-${MOOGLI_VERSION}*.tar.gz
    COMMENT "Extracting tar.gz to install directory"
    # NOT VERBATIM ELSE glob won't work
    )
add_dependencies( build_moogli bdist )

# Install the unarchived bdist
install(DIRECTORY  ${MOOGLI_BDIST_INSTALL_DIR}/usr/ 
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    )
