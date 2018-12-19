

EXECUTE_PROCESS(COMMAND bash runUnitTest.sh ${PY_PATH}
    RESULT_VARIABLE ERROR)
if(ERROR)
        message(FATAL_ERROR "Test failed!")
endif()


