# CMAKE File for SPIRIT building against an installed Trilinos

cmake_minimum_required(VERSION 2.6.4)

#keeping this for example
OPTION (ENABLE_GITPYTHON "Toggle to turn on when gitpython is available, ON by default" ON)
IF (ENABLE_GITPYTHON) 
  MESSAGE("\nGitpython is ON.") 
  SET (ENABLE_GITPYTHON TRUE)
ELSE()
  MESSAGE("\nGitpython is OFF.") 
  SET (ENABLE_GITPYTHON FALSE) 
ENDIF()

PROJECT(CMDV_TESTING)

MESSAGE("")

add_subdirectory(scripts)

enable_testing()
MESSAGE("\nTests are on.") 
SET(CMDV_TESTING_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR})
MESSAGE("   CMDV_TESTING_BIN_DIR ${CMDV_TESTING_BIN_DIR}") 
set(ENV{PYTHONPATH} "${CMDV_TESTING_BIN_DIR}/lib/python")
MESSAGE("   PYTHONPATH=$ENV{PYTHONPATH}")
MESSAGE("")
add_subdirectory(tests)
add_subdirectory(lib)


