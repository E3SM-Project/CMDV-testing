#copy files to build directory
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.test.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/config.test.yaml COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/runUnitTest.sh
               ${CMAKE_CURRENT_BINARY_DIR}/runUnitTest.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/unittest-discovery.test.yaml
               ${CMAKE_CURRENT_BINARY_DIR}/unittest-discovery.test.yaml COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/runtest.cmake
               ${CMAKE_CURRENT_BINARY_DIR}/runtest.cmake COPYONLY)

#Name the test with the directory name
get_filename_component(testName ${CMAKE_CURRENT_SOURCE_DIR} NAME)

#create test
add_test(NAME ${testName} COMMAND ${CMAKE_COMMAND} -DTEST_NAME=Cohesive -DPY_PATH=$ENV{PYTHONPATH} -P ${CMAKE_CURRENT_SOURCE_DIR}/runtest.cmake)

