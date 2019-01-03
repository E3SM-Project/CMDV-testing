
cmake_minimum_required (VERSION 2.8)
set (CTEST_DO_SUBMIT ON)
set (CTEST_TEST_TYPE Experimental)

# What to build and test
set (DOWNLOAD FALSE)  #jenkins should have latest version already
set (CLEAN_BUILD FALSE)
set (BUILD_CMDV_TESTING TRUE)

# Begin User inputs:
set (CTEST_SITE "cmdv-test-runner" ) # generally the output of hostname
set (CTEST_DASHBOARD_ROOT "$ENV{TEST_DIRECTORY}" ) # writable path
set (CTEST_SCRIPT_DIRECTORY "$ENV{SCRIPT_DIRECTORY}" ) # where the scripts live
set (CTEST_CMAKE_GENERATOR "Unix Makefiles" ) # What is your compilation apps ?
set (CTEST_BUILD_CONFIGURATION  Release) # What type of build do you want ?

set (INITIAL_LD_LIBRARY_PATH $ENV{LD_LIBRARY_PATH})

set (CTEST_PROJECT_NAME "ACME_Climate" )
set (CTEST_SOURCE_NAME repos)
set (CTEST_BUILD_NAME "jenkins-lcrc-${CTEST_BUILD_CONFIGURATION}")
set (CTEST_BINARY_NAME build)

set(ENV${PYTHONPATH} "${CMAKE_CURRENT_BINARY_DIR}/lib/python")

set (CTEST_SOURCE_DIRECTORY "${CTEST_DASHBOARD_ROOT}/${CTEST_SOURCE_NAME}")
set (CTEST_BINARY_DIRECTORY "${CTEST_DASHBOARD_ROOT}/${CTEST_BINARY_NAME}")

if (NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
  file (MAKE_DIRECTORY "${CTEST_SOURCE_DIRECTORY}")
endif ()
if (NOT EXISTS "${CTEST_BINARY_DIRECTORY}")
  file (MAKE_DIRECTORY "${CTEST_BINARY_DIRECTORY}")
endif ()

configure_file (${CTEST_SCRIPT_DIRECTORY}/CTestConfig.cmake
  ${CTEST_SOURCE_DIRECTORY}/CTestConfig.cmake COPYONLY)

set (CTEST_NIGHTLY_START_TIME "00:00:00 UTC")
set (CTEST_CMAKE_COMMAND "${PREFIX_DIR}/bin/cmake")
set (CTEST_COMMAND "${PREFIX_DIR}/bin/ctest -D ${CTEST_TEST_TYPE}")
set (CTEST_BUILD_FLAGS "-j4")

set (CTEST_DROP_METHOD "http")

if (CTEST_DROP_METHOD STREQUAL "http")
  set (CTEST_DROP_SITE "my.cdash.org")
  set (CTEST_PROJECT_NAME "ACME_Climate")
  set (CTEST_DROP_LOCATION "/submit.php?project=ACME_Climate")
  set (CTEST_TRIGGER_SITE "")
  set (CTEST_DROP_SITE_CDASH TRUE)
endif ()

find_program (CTEST_GIT_COMMAND NAMES git)
find_program (CTEST_SVN_COMMAND NAMES svn)

set (CMDVTesting_REPOSITORY_LOCATION git@github.com:E3SM-Project/CMDV-Testing.git)

if (CLEAN_BUILD)
  # Initial cache info
  set (CACHE_CONTENTS "
  SITE:STRING=${CTEST_SITE}
  CMAKE_BUILD_TYPE:STRING=Release
  CMAKE_GENERATOR:INTERNAL=${CTEST_CMAKE_GENERATOR}
  BUILD_TESTING:BOOL=OFF
  PRODUCT_REPO:STRING=${CMDVTesting_REPOSITORY_LOCATION}
  " )

  ctest_empty_binary_directory( "${CTEST_BINARY_DIRECTORY}" )
  file(WRITE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "${CACHE_CONTENTS}")
endif ()


#Skipped
if (DOWNLOAD)

  set (CTEST_CHECKOUT_COMMAND)
  set (CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
  #
  # Get CMDV-Testing repo 
  #

  if (NOT EXISTS "${CTEST_SOURCE_DIRECTORY}/CMDV-Testing")
    execute_process (COMMAND "${CTEST_GIT_COMMAND}" 
      clone ${CMDVTesting_REPOSITORY_LOCATION} -b sarich/jenkins ${CTEST_SOURCE_DIRECTORY}/CMDV-Testing
      OUTPUT_VARIABLE _out
      ERROR_VARIABLE _err
      RESULT_VARIABLE HAD_ERROR)
    
    message(STATUS "out: ${_out}")
    message(STATUS "err: ${_err}")
    message(STATUS "res: ${HAD_ERROR}")
    if (HAD_ERROR)
      message(FATAL_ERROR "Cannot clone CMDV-Testing repository!")
    endif ()
  endif ()

  set (CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")


endif ()

ctest_start(${CTEST_TEST_TYPE})

#
# Send the project structure to CDash
#

if (CTEST_DO_SUBMIT)
  ctest_submit (FILES "${CTEST_SCRIPT_DIRECTORY}/Project.xml"
    RETURN_VALUE  HAD_ERROR
    )

  if (HAD_ERROR)
    message(FATAL_ERROR "Cannot submit CMDV-Testing Project.xml!")
  endif ()
endif ()

#Skipped
if (DOWNLOAD)

  #
  # Update CMDV-Testing 
  #

  #set_property (GLOBAL PROPERTY SubProject Build)
  #set_property (GLOBAL PROPERTY Label Build)

  set (CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
  CTEST_UPDATE(SOURCE "${CTEST_SOURCE_DIRECTORY}/CMDV-Testing" RETURN_VALUE count)
  message("Found ${count} changed files")

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Update
      RETURN_VALUE  HAD_ERROR
      )

    if (HAD_ERROR)
      message(FATAL_ERROR "Cannot update CMDV-Testing repository!")
    endif ()
  endif ()

  if (count LESS 0)
    message(FATAL_ERROR "Cannot update CMDV-Testing!")
  endif ()

endif ()


if (BUILD_CMDV_TESTING)

  # "Builds" code
  #

  #set_property (GLOBAL PROPERTY SubProject Build)
  #set_property (GLOBAL PROPERTY Label Build)

  set (CONFIGURE_OPTIONS
    "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
    "-DTESTING_OUTPUT_DIR:PATH=${CTEST_BINARY_DIRECTORY}/Build/testing/cmdv"
    "-DENABLE_GITPYTHON:BOOL=OFF")
  
  if (NOT EXISTS "${CTEST_BINARY_DIRECTORY}/Build")
    file (MAKE_DIRECTORY ${CTEST_BINARY_DIRECTORY}/Build)
  endif ()

  CTEST_CONFIGURE(
    BUILD "${CTEST_BINARY_DIRECTORY}/Build"
    SOURCE "${CTEST_SOURCE_DIRECTORY}/CMDV-Testing"
    OPTIONS "${CONFIGURE_OPTIONS}"
    RETURN_VALUE HAD_ERROR
    APPEND
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Configure
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message(FATAL_ERROR "Cannot submit CMDV-Testing configure results!")
    endif ()
  endif ()

  if (HAD_ERROR)
    message(FATAL_ERROR "Cannot configure CMDV-Testing build!")
  endif ()

  #
  # "Build" CMDV-Testing
  #

  set (CTEST_BUILD_TARGET all)
  #set (CTEST_BUILD_TARGET install)

  MESSAGE("\nBuilding target: '${CTEST_BUILD_TARGET}' ...\n")

  CTEST_BUILD(
    BUILD "${CTEST_BINARY_DIRECTORY}/Build"
    RETURN_VALUE  HAD_ERROR
    NUMBER_ERRORS  BUILD_LIBS_NUM_ERRORS
    APPEND
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Build
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message(FATAL_ERROR "Cannot submit CMDV-Testing build results!")
    endif ()
  endif ()

  if (HAD_ERROR)
    message(FATAL_ERROR "Cannot build CMDV-Testing!")
  endif ()

  if (BUILD_LIBS_NUM_ERRORS GREATER 0)
    message(FATAL_ERROR "Encountered build errors in CMDV-Testing build. Exiting!")
  endif ()

  #
  # Run CMDV-Testing tests
  #
  
  set (CTEST_TEST_TIMEOUT 600)

  CTEST_TEST(
    BUILD "${CTEST_BINARY_DIRECTORY}/Build"
    #              PARALLEL_LEVEL "${CTEST_PARALLEL_LEVEL}"
    #              INCLUDE_LABEL "^${TRIBITS_PACKAGE}$"
    #NUMBER_FAILED  TEST_NUM_FAILED
    RETURN_VALUE  HAD_ERROR
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Test
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message(FATAL_ERROR "Cannot submit CMDV-Testing test results!")
    endif ()
  endif ()

  #if (HAD_ERROR)
  #	message(FATAL_ERROR "Some CMDV-Testing tests failed.")
  #endif ()

endif ()

