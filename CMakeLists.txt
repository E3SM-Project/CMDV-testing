# CMAKE File for SPIRIT building against an installed Trilinos

cmake_minimum_required(VERSION 2.6.4)

#keeping this for example
#OPTION (MATRIX_MARKET_OUTPUT "Toggle to turn on writing of matrices/vectors to matrix market file, off by default" OFF)
#IF (MATRIX_MARKET_OUTPUT) 
  #enable writing to matrix market?
#  MESSAGE("\nMatrix Market output is on.  Configuring with -DWRITE_MATRIX_MARKET flag.") 
#  ADD_DEFINITIONS(-DWRITE_TO_MATRIXMARKET)
#ELSE()
#  MESSAGE("\nMatrix Market output is off.") 
#ENDIF()

PROJECT(CMDV_TESTING)

MESSAGE("")

add_subdirectory(scripts)

enable_testing()
MESSAGE("\nTests are on.") 
set(ENV{PYTHONPATH} "${CMAKE_CURRENT_SOURCE_DIR}/lib/python")
MESSAGE("\n   PYTHONPATH=$ENV{PYTHONPATH}")
SET(CMDV_TESTING_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}) 
add_subdirectory(tests)


