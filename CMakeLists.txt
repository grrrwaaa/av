cmake_minimum_required(VERSION 2.8)

project(av)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)
set(CMAKE_BUILD_TYPE Release)

# do if/else to fix this on some platforms...
set(CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_CXX_LINK_EXECUTABLE} -pagezero_size 10000 -image_base 100000000")

find_package(LuaJIT REQUIRED)
find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)

# generate embedded script .cpp (aka av_ffi_header). check "result" variable if desired.
#
execute_process(
  COMMAND luajit h2ffi.lua av.h av_ffi_header
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/source
  RESULT_VARIABLE result
)

set(SOURCES
  ${CMAKE_SOURCE_DIR}/source/av.cpp
  ${CMAKE_SOURCE_DIR}/source/av_audio.cpp
  ${CMAKE_SOURCE_DIR}/rtaudio/RtAudio.cpp
)

set(INCLUDE_DIRS
  ${CMAKE_SOURCE_DIR}/rtaudio/
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

set(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/source)
add_executable(${CMAKE_PROJECT_NAME} ${SOURCES})
target_link_libraries(${CMAKE_PROJECT_NAME} ${LINK_LIBRARIES})
