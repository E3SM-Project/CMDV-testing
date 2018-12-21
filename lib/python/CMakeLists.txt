add_subdirectory(Archive)
add_subdirectory(Report)
add_subdirectory(test)
add_subdirectory(Workflows)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Config.py
               ${CMAKE_CURRENT_BINARY_DIR}/Config.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Config.pyc
               ${CMAKE_CURRENT_BINARY_DIR}/Config.pyc COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Deploy.py
               ${CMAKE_CURRENT_BINARY_DIR}/Deploy.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Deploy.pyc
               ${CMAKE_CURRENT_BINARY_DIR}/Deploy.pyc COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Workflow.py
               ${CMAKE_CURRENT_BINARY_DIR}/Workflow.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Workflow.pyc
               ${CMAKE_CURRENT_BINARY_DIR}/Workflow.pyc COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ResultReporter.py
               ${CMAKE_CURRENT_BINARY_DIR}/ResultReporter.py COPYONLY)

