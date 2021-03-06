MESSAGE("+++ Building local osg")
SET(OSG_INSTALL_DIR ${CMAKE_BINARY_DIR}/_osg_static)
FILE(MAKE_DIRECTORY ${OSG_INSTALL_DIR})

SET(OSG_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/external/OpenSceneGraph-3.4.0/)

# A target which depends on STATIC_OSG_LIBRARY
ADD_CUSTOM_COMMAND(
    OUTPUT ${OSG_INSTALL_DIR}/lib/libosg.a
    COMMAND ${CMAKE_COMMAND} 
        -DCMAKE_INSTALL_PREFIX=${OSG_INSTALL_DIR}
        -DBUILD_OSG_APPLICATIONS:BOOL=OFF
        -DDYNAMIC_OPENSCENEGRAPH:BOOL=OFF
        -DDYNAMIC_OPENTHREADS:BOOL=OFF
        -DCMAKE_C_FLAGS=-fPIC
        -DCMAKE_CXX_FLAGS=-fPIC
        ${OSG_SRC_DIR}
    COMMAND $(MAKE)
    COMMAND $(MAKE) install
    WORKING_DIRECTORY ${OSG_INSTALL_DIR}
    VERBATIM
    )

ADD_CUSTOM_TARGET(_libosg ALL 
    DEPENDS ${OSG_INSTALL_DIR}/lib/libosg.a
    )

MESSAGE(STATUS "Setting OSGDIR environment variable")
SET(ENV{OSGDIR} "${OSG_INSTALL_DIR}")
#add_dependencies(build_moogli _libosg)
