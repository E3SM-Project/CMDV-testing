#copy files to build directory
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../Tests/config.test.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/config.test.yaml COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/runUnitTest.sh
               ${CMAKE_CURRENT_BINARY_DIR}/runUnitTest.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/set_paths.sh
               ${CMAKE_CURRENT_BINARY_DIR}/set_paths.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/turn_off_gitpython.sh
               ${CMAKE_CURRENT_BINARY_DIR}/turn_off_gitpython.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/check_error.sh
               ${CMAKE_CURRENT_BINARY_DIR}/check_error.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../Tests/unittest-discovery.test.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/unittest-discovery.test.yaml COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/runtest.cmake
               ${CMAKE_CURRENT_BINARY_DIR}/runtest.cmake COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../cmdv-testing.config.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/cmdv-testing.config.yaml COPYONLY)

#Name the test with the directory name
get_filename_component(testName ${CMAKE_CURRENT_SOURCE_DIR} NAME)

#create test
add_test(NAME ${testName}_run_unit_verification_test COMMAND ${CMAKE_COMMAND} -DTEST_NAME=Cohesive -DPY_PATH=$ENV{PYTHONPATH} -DPY_DIR=${CMAKE_CURRENT_BINARY_DIR}/../lib/python -DCLONE_DIR_PATH=${CMAKE_CURRENT_BINARY_DIR}/../scripts -P ${CMAKE_CURRENT_SOURCE_DIR}/runtest.cmake)

