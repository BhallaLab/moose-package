cmake_minimum_required(VERSION 2.8)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules")

## Options
option(BUILD_STATIC "Link osg statically. Useful for creating standalone packages" OFF)

add_definitions(-std=c++11)

if(APPLE)
    add_definitions( "-stdlib=libc++" )
endif(APPLE)
add_definitions(-fPIC)

FIND_PACKAGE(PythonDev REQUIRED)
INCLUDE_DIRECTORIES(${PYTHON_INCLUDE_DIRS})

FIND_PACKAGE(PyQt4 REQUIRED)
MESSAGE("++ Found SIP flags: ${PYQT4_SIP_FLAGS}")
SEPARATE_ARGUMENTS(PYQT4_SIP_FLAGS) # convert space separated values to a list

SET(SIP_CONCAT_PARTS 4)
SET(SIP_EXTRA_OPTIONS ${PYQT4_SIP_FLAGS})

IF("${PYQT4_SIP_FLAGS}" STREQUAL "")
    MESSAGE(FATAL_ERROR "++ No PYQT4_SIP_FLAGS found. Can't continue")
ENDIF()
MESSAGE("++ Using sip flags: ${SIP_EXTRA_OPTIONS}")


IF (NOT BINDINGS_GLOBAL_INSTALL)
    SET(PYTHON_SITE_PACKAGES_DIR ${QGIS_DATA_DIR}/python)
ENDIF (NOT BINDINGS_GLOBAL_INSTALL)
IF (WITH_CUSTOM_WIDGETS)
    SET(PYUIC_WIDGET_PLUGIN_DIRECTORY ${PYQT4_MOD_DIR}/uic/widget-plugins/)
ENDIF (WITH_CUSTOM_WIDGETS)

FIND_PACKAGE(Qt4 COMPONENTS QtCore QtGui QtOpenGL REQUIRED)
FIND_PACKAGE(OpenSceneGraph 3.0.2 REQUIRED 
    osgFX osgGA
    osgAnimation osgViewer
    osgManipulator osgSim osgText
    osgDB
    osgUtil
    OpenThreads
    )

MESSAGE(STATUS "OSG LIBRARIES: ${OPENSCENEGRAPH_LIBRARIES}")

INCLUDE(${QT_USE_FILE})

FIND_PROGRAM(SIP_EXECUTABLE sip)
MESSAGE("++ SIP ${SIP_EXECUTABLE}")

include_directories(./include ${PROJECT_SOURCE_DIR}/bin/include ".")
include_directories(${OSGQT_INCLUDE_DIR})
include_directories(${SIP_INCLUDES} ${PYTHON_INCLUDE_DIRS})
include_directories(${OPENSCENEGRAPH_INCLUDE_DIRS})
include_directories(${OSGANIMATION_INCLUDE_DIR})

add_subdirectory(${PROJECT_SOURCE_DIR}/bin/sip)
add_subdirectory(${PROJECT_SOURCE_DIR}/bin/src)

ADD_LIBRARY(_moogli SHARED 
    ${PROJECT_SOURCE_DIR}/bin/moc/Viewer.moc.cpp
    )

IF(APPLE)
    SET_TARGET_PROPERTIES(_moogli 
        PROPERTIES OUTPUT_NAME "_moogli.so"  
        LINK_FLAGS "-undefined dynamic_lookup"
        SUFFIX ""
        )
ELSE(APPLE)
    SET_TARGET_PROPERTIES(_moogli PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/core"
        PREFIX ""
        )
ENDIF(APPLE)

## Link the following libraries to moogli.
SET(STATIC_LIBRARIES sip src)

SET(DYNAMIC_LIBRARIES Qt4::QtCore Qt4::QtGui Qt4::QtOpenGL)

IF(BUILD_STATIC)
    LIST(APPEND STATIC_LIBRARIES ${OPENSCENEGRAPH_LIBRARIES})
ELSE(BUILD_STATIC)
    LIST(APPEND DYNAMIC_LIBRARIES ${OPENSCENEGRAPH_LIBRARIES})
ENDIF(BUILD_STATIC)

IF(APPLE)
    TARGET_LINK_LIBRARIES(_moogli "-Wl,-all_load" ${STATIC_LIBRARIES})
ELSE(APPLE)
    TARGET_LINK_LIBRARIES(_moogli
        "-Wl,--whole-archive"
        ${STATIC_LIBRARIES}
        "-Wl,--no-whole-archive"
        )
ENDIF(APPLE)
TARGET_LINK_LIBRARIES(_moogli ${DYNAMIC_LIBRARIES})
