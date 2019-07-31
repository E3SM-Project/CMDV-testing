add_executable(cmdv-test-runner ...)
build_name( clubb_release_2019_07_29 )
add_test( clubb_release cmdv-test-runner --test /clubb/G-unit-tests.cmdv.testing.yaml --config /clubb/cmdv-testing.config.yaml --repo /clubb )    
set_tests_properties( clubb_release PROPERTIES
  PASS_REGULAR_EXPRESSION "passed" )