#copy files to build directory
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/clone-dir.bat
               ${CMAKE_CURRENT_BINARY_DIR}/clone-dir.bat COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/clone-dir.sh
               ${CMAKE_CURRENT_BINARY_DIR}/clone-dir.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmdv-test-runner.py
               ${CMAKE_CURRENT_BINARY_DIR}/cmdv-test-runner.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.json
               ${CMAKE_CURRENT_BINARY_DIR}/config.json COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/deploy-code.py
               ${CMAKE_CURRENT_BINARY_DIR}/deploy-code.py COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/nb2html_old.py
               ${CMAKE_CURRENT_BINARY_DIR}/nb2html_old.py COPYONLY)

#create sym-link
set(cmdv-test-runner.exe ${CMAKE_CURRENT_SOURCE_DIR}/cmdv-test-runner)
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
  ${cmdv-test-runner.exe} ${CMAKE_CURRENT_BINARY_DIR}/cmdv-test-runner)

