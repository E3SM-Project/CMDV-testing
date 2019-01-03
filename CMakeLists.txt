# CMAKE File for CMDV_Testing build

cmake_minimum_required(VERSION 2.6.4)

PROJECT(CMDV_TESTING)

#set(ENV{LD_LIBRARY_PATH} "/global/homes/i/ikalash/Install/gitpython/lib")

#keeping this for example
OPTION (ENABLE_GITPYTHON "Toggle to turn on when gitpython is available, ON by default" ON)
IF (ENABLE_GITPYTHON) 
  MESSAGE("\n-- Gitpython is ON.") 
  SET (ENABLE_GITPYTHON TRUE)
  #IF (DEFINED GITPYTHON_PATH)
  #  MESSAGE("---> Setting specified GITPYTHON_PATH=${GITPYTHON_PATH}") 
  #  set(ENV{LD_LIBRARY_PATH} ENV{LD_LIBRARY_PATH}:${GITPYTON_PATH}) 
  #ELSE()
  #  MESSAGE("---> GITPYTHON_PATH not specified; looking for gitpython in your LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}")
  #ENDIF()
ELSE()
  MESSAGE("\n-- Gitpython is OFF.") 
  SET (ENABLE_GITPYTHON FALSE) 
ENDIF()

IF (DEFINED TESTING_OUTPUT_DIR)
  SET(CMAKE_PREFIX_PATH ${TESTING_OUTPUT_DIR} ${CMAKE_PREFIX_PATH})
  MESSAGE("\n-- TESTING_OUTPUT_DIR set: ${TESTING_OUTPUT_DIR}.")
ELSE()
  SET(TESTING_OUTPUT_DIR "/tmp/testing/cmdv")  
  SET(CMAKE_PREFIX_PATH ${TESTING_OUTPUT_DIR} ${CMAKE_PREFIX_PATH})
  MESSAGE("\n-- TESTING_OUTPUT_DIR not set.  Using default path: ${TESTING_OUTPUT_DIR}.")
ENDIF()

add_subdirectory(scripts)

enable_testing()
MESSAGE("\n-- Tests are ON.") 
SET(CMDV_TESTING_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR})
MESSAGE("---> CMDV_TESTING_BIN_DIR ${CMDV_TESTING_BIN_DIR}") 
set(ENV{PYTHONPATH} "${CMDV_TESTING_BIN_DIR}/lib/python")
MESSAGE("---> PYTHONPATH=$ENV{PYTHONPATH}")
MESSAGE("")
add_subdirectory(tests)
add_subdirectory(lib)


