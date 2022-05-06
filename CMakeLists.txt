cmake_minimum_required(VERSION 3.23)

project(eap)

set(ROOT ${CMAKE_CURRENT_SOURCE_DIR})

#buid type
if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to 'Debug' as none was specified.")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
endif()

#output dirs
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${ROOT}/\@bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${ROOT}/\@lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${ROOT}/\@lib)


if(WIN32)

SET(CMAKE_CXX_FLAGS_DEBUG "/std:c++20 /Zc:__cplusplus /MDd /Zi /Od /D DEBUG /D _DEBUG")
SET(CMAKE_CXX_FLAGS_RELEASE "/std:c++20 /Zc:__cplusplus /D NDEBUG")
set(_WIN32_WINNT 0x0601 CACHE STRING "Define Windows API version to use.")

else()

# include dirs
include_directories(
    /usr/local/include
)

link_directories(
    /usr/local/lib
)

add_definitions(
    -std=c++20
)

endif()

add_subdirectory(lua)
