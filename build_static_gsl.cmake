MESSAGE("++ Building local GSL")

SET(GSL_SRC_DIR ${CMAKE_SOURCE_DIR}/external/gsl)
SET(GSL_INSTALL_DIR ${CMAKE_BINARY_DIR}/__gsl_install)
FILE(MAKE_DIRECTORY ${GSL_INSTALL_DIR})
MESSAGE("++ GSL_SRC_DIR := ${GSL_SRC_DIR}")

SET(GSL_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/__gsl_build__)
FILE(MAKE_DIRECTORY ${GSL_BUILD_DIR})

# NOTE: Set WORKING_DIRECTORY to GSL_SRC_DIRECTORY else the build might fail
# because of missing texinfo and texi2html package.
SET(GSL_OUTPUT_LIB ${GSL_INSTALL_DIR}/lib/libgsl.a)
ADD_CUSTOM_COMMAND(
    OUTPUT ${GSL_OUTPUT_LIB}
    # When cmake is used, we can't build gsl-config
    COMMAND ${CMAKE_COMMAND} 
        -DCMAKE_INSTALL_PREFIX=${GSL_INSTALL_DIR} 
        -DCMAKE_C_FLAGS=-fPIC
        -DCMAKE_CXX_FLAGS=-fPIC
        ${GSL_SRC_DIR}
    COMMAND $(MAKE) 
    COMMAND $(MAKE) install
    WORKING_DIRECTORY ${GSL_SRC_DIR}
    VERBATIM  # needed to handle escape characters.
    )

ADD_CUSTOM_TARGET(_libgsl ALL DEPENDS ${GSL_OUTPUT_LIB})

set(GSL_INCLUDE_DIR ${GSL_INSTALL_DIR}/include)

# Next time moose module must be able to find static libraries.
set(ENV{GSL_HOME} ${GSL_INSTALL_DIR})

## Ofcourse, moose-full depends on it.
add_dependencies(_moose_static_dependencies _libgsl)
