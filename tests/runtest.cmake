
MESSAGE("CLONE_DIR_PATH=${CLONE_DIR_PATH}")
MESSAGE("CLONE_DIR_PATH=${PY_DIR}")
MESSAGE("TESTING_OUTPUT_PATH=${TESTING_OUTPUT_PATH}") 
set(LOGFILE log.txt)

IF (NOT ENABLE_GITPYTHON) 
EXECUTE_PROCESS(COMMAND bash turn_off_gitpython.sh
    RESULT_VARIABLE ERROR0)
if(ERROR0)
        message(FATAL_ERROR "Error turning off gitpython!")
endif()

 
ENDIF()

EXECUTE_PROCESS(COMMAND bash set_paths.sh ${PY_DIR} ${CLONE_DIR_PATH} ${TESTING_OUTPUT_PATH} 
    RESULT_VARIABLE ERROR1)
if(ERROR1)
        message(FATAL_ERROR "Error setting paths!")
endif()

EXECUTE_PROCESS(COMMAND bash runUnitTest.sh ${PY_PATH} ${LOGFILE}
    RESULT_VARIABLE ERROR)
if(ERROR)
        message(FATAL_ERROR "Test failed!")
endif()

EXECUTE_PROCESS(COMMAND bash check_error.sh ${LOGFILE}
    RESULT_VARIABLE LOG_ERROR)
if(LOG_ERROR)
        message(FATAL_ERROR "Test failed!")
endif()

EXECUTE_PROCESS(COMMAND cat
          INPUT_FILE ${LOGFILE}
          RESULT_VARIABLE CAT_ERROR)



