cmake_minimum_required(VERSION 2.8)

project(av)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)
set(CMAKE_BUILD_TYPE Release)

#add_subdirectory(${CMAKE_SOURCE_DIR}/lpeg)
#get_target_property(ALLOCORE_LIBRARY allocore LOCATION)
#get_target_property(ALLOCORE_INCLUDE_DIR allocore ALLOCORE_INCLUDE_DIR)


find_package(LuaJIT REQUIRED)
find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)

set(SOURCES
  ${CMAKE_SOURCE_DIR}/source/av.cpp
  ${CMAKE_SOURCE_DIR}/source/av_audio.cpp
  ${CMAKE_SOURCE_DIR}/source/rtaudio-4.0.11/RtAudio.cpp
  ${CMAKE_SOURCE_DIR}/lpeg/lpeg.c
)

set(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR})

set(INCLUDE_DIRS
  ${CMAKE_SOURCE_DIR}/source/rtaudio-4.0.11/
  ${CMAKE_SOURCE_DIR}/lpeg/
  ${LUAJIT_INCLUDE_DIR}
  ${OPENGL_INCLUDE_DIR}
  ${GLUT_INCLUDE_DIR}
)
include_directories(${INCLUDE_DIRS})

set(LINK_LIBRARIES
  ${LUAJIT_LIBRARIES}
  ${GLUT_LIBRARIES}
  ${OPENGL_LIBRARY}
)

execute_process(
  COMMAND luajit h2ffi.lua av.h av_ffi_header
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/source
  RESULT_VARIABLE result
)

add_executable(${CMAKE_PROJECT_NAME} ${SOURCES})
target_link_libraries(${CMAKE_PROJECT_NAME} ${LINK_LIBRARIES})
