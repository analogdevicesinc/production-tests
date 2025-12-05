cmake_minimum_required(VERSION 3.8)
project(adrd3161_tests)

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)
find_package(rclpy REQUIRED)
find_package(canopen REQUIRED)
find_package(lely_core_libraries REQUIRED)

# Generate CANopen dcf, bin
cogen_dcf(canopen_one_adrd3161)

# Install share files
install(
  DIRECTORY urdf test config
  DESTINATION share/${PROJECT_NAME}
  PATTERN "bus.yml" EXCLUDE
)

# Install test script
if(BUILD_TESTING)
  # Integration tests
  find_package(ament_cmake_ros REQUIRED)
  find_package(launch_testing_ament_cmake REQUIRED)
  function(add_ros_isolated_launch_test path)
    set(RUNNER "${ament_cmake_ros_DIR}/run_test_isolated.py")
    add_launch_test("${path}" RUNNER "${RUNNER}" ${ARGN})
  endfunction()
  add_ros_isolated_launch_test(test/test_board.py)
endif()

ament_package()

