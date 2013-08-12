cmake_minimum_required(VERSION 2.8)

project(av)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)
set(CMAKE_BUILD_TYPE Release)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pagezero_size 10000 -image_base 100000000")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pagezero_size 10000 -image_base 100000000")

find_package(LuaJIT REQUIRED)
find_package(OpenGL REQUIRED)
find_package(GLUT REQUIRED)

execute_process(
  COMMAND luajit h2ffi.lua av.h av_ffi_header
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/source
  RESULT_VARIABLE result
)

set(SOURCES
  ${CMAKE_SOURCE_DIR}/source/av.cpp
  ${CMAKE_SOURCE_DIR}/source/av_audio.cpp
  ${CMAKE_SOURCE_DIR}/rtaudio/RtAudio.cpp
  ${CMAKE_SOURCE_DIR}/lpeg/lpeg.c
  ${CMAKE_SOURCE_DIR}/http-parser/http_parser.c
)

set(INCLUDE_DIRS
  ${CMAKE_SOURCE_DIR}/rtaudio/
  ${CMAKE_SOURCE_DIR}/lpeg/
  ${CMAKE_SOURCE_DIR}/http-parser/
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
