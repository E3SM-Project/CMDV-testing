add_subdirectory(Archive)
add_subdirectory(Report)
add_subdirectory(test)
add_subdirectory(Workflows)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Config.py
               ${CMAKE_CURRENT_BINARY_DIR}/Config.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/SetupStep.py
               ${CMAKE_CURRENT_BINARY_DIR}/SetupStep.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Workflow.py
               ${CMAKE_CURRENT_BINARY_DIR}/Workflow.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ResultReporter.py
               ${CMAKE_CURRENT_BINARY_DIR}/ResultReporter.py COPYONLY)

