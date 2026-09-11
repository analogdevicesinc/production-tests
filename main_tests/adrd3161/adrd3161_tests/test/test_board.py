"""

"""

import os
import sys
import time
import threading
import unittest

from math import pi

import rclpy
import std_msgs.msg
import sensor_msgs.msg
import std_srvs.srv
import canopen_interfaces.srv

import launch
import launch_ros
import launch_testing.actions
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration, Command, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare
from launch_ros.parameter_descriptions import ParameterValue

class Adrd3161BasicTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        rclpy.init()

        cls.node = rclpy.create_node("adrd3161_basic_test")

        cls.state_sub = cls.node.create_subscription(sensor_msgs.msg.JointState, "/dut_adrd3161/joint_states", cls.state_cb, 1)
        cls.state_futures = []
        cls.state_futures_lock = threading.Lock()

        cls.target_pos_pub = cls.node.create_publisher(std_msgs.msg.Float64MultiArray, "/pos_controller/commands", 1)
        cls.target_vel_pub = cls.node.create_publisher(std_msgs.msg.Float64MultiArray, "/vel_controller/commands", 1)

        cls.init_srv     = cls.node.create_client(std_srvs.srv.Trigger, "/dut_adrd3161/init")
        cls.halt_srv     = cls.node.create_client(std_srvs.srv.Trigger, "/dut_adrd3161/halt")
        cls.target_srv   = cls.node.create_client(canopen_interfaces.srv.COTargetDouble, "/dut_adrd3161/target")
        cls.mode_csv_srv = cls.node.create_client(std_srvs.srv.Trigger, "/dut_adrd3161/cyclic_velocity_mode")
        cls.mode_csp_srv = cls.node.create_client(std_srvs.srv.Trigger, "/dut_adrd3161/cyclic_position_mode")

        cls.hardware_mutex = threading.Lock()

        assert cls.init_srv.wait_for_service(timeout_sec=5.0), "Service '/dut_adrd3160/init' must be up"

    @classmethod
    def tearDownClass(cls):

        rclpy.shutdown()

    def setUp(self):
        self.motor_init()

    def tearDown(self):
        self.motor_halt()

    @classmethod
    def motor_init(cls):
        rclpy.spin_until_future_complete(cls.node, cls.init_srv.call_async(std_srvs.srv.Trigger.Request()))
        print("--- MOTOR INIT ---")

    @classmethod
    def motor_halt(cls):
        rclpy.spin_until_future_complete(cls.node, cls.halt_srv.call_async(std_srvs.srv.Trigger.Request()))
        print("--- MOTOR HALT ---")
        time.sleep(0.5)

    @classmethod
    def state_cb(cls, msg):
        with cls.state_futures_lock:
            for f in cls.state_futures:
                f.set_result(msg)

            cls.state_futures.clear()

    @classmethod
    def get_next_state(cls):
        """ Wait for next JointState message and return it. Multiple concurrent callees supported. """

        f = rclpy.task.Future()
        with cls.state_futures_lock:
            cls.state_futures.append(f)
        rclpy.spin_until_future_complete(cls.node, f)
        return f.result()

    def set_mode(self, mode):
        """ Set position (csp) / velocity (csv) mode of operation. """

        match mode:
            case "csp":
                f = self.mode_csp_srv.call_async(std_srvs.srv.Trigger.Request())

            case "csv":
                f = self.mode_csv_srv.call_async(std_srvs.srv.Trigger.Request())

            case _:
                raise ValueError(f"Mode '{mode}' not supported")

        rclpy.spin_until_future_complete(self.node, f)

        # assert f.result().success, f"set_mode('{mode}') failed: {f.result().message}"

    @classmethod
    def set_target(cls, target):
        req = canopen_interfaces.srv.COTargetDouble.Request()
        req.target = float(target)
        f = cls.target_srv.call_async(req)
        rclpy.spin_until_future_complete(cls.node, f)

    def set_position(self, target_pos):
        #self.set_target(target_pos)
        #return
        msg = std_msgs.msg.Float64MultiArray()
        msg.data = [float(target_pos)]
        self.target_pos_pub.publish(msg)

    def set_velocity(self, target_vel):
        #self.set_target(target_vel)
        #return
        msg = std_msgs.msg.Float64MultiArray()
        msg.data = [float(target_vel)]
        self.target_vel_pub.publish(msg)

    def get_position(self):
        return self.get_next_state().position[0]

    def get_velocity(self):
        return self.get_next_state().velocity[0]

    def test_position_feedback_noisy(self, proc_output):
        """ Test position feedback is not perfectly constant -- to be expected if getting real life noisy inputs. """

        with self.hardware_mutex:
            positions = [self.get_position() for _ in range(10)]

        assert not all(pos == positions[0] for pos in positions), f"{positions=} must not be constant"

    def test_position(self, proc_output):
        """ Test position control by sending a sequence of position targets. """

        proc_output.assertWaitFor("Configured and activated pos_controller")

        with self.hardware_mutex:
            self.set_mode("csp")

            DEG = pi / 180
            for target_pos in [0, 90*DEG, -180*DEG, 270*DEG, 0]:
                print(f"{target_pos=:.2f}")
                self.set_position(target_pos)

                time_limit = time.time() + 1.0
                while time.time() < time_limit:
                    actual_pos = self.get_position()
                    print(f"{actual_pos=:.2f}")
                    if abs(actual_pos - target_pos) < 5 * DEG:
                        break
                else:
                    assert False, f"{actual_pos=} must converge to {target_pos=}"

    def test_velocity(self, proc_output):
        """ Test velocity control by sending a sequence of velocity targets. """

        proc_output.assertWaitFor("Configured and activated vel_controller")

        with self.hardware_mutex:
            self.set_mode("csv")

            RPM = 2 * pi / 60
            for target_vel in [0, 60*RPM, -60*RPM, 120*RPM, 0]:
                print(f"{target_vel=:.2f}")
                self.set_velocity(target_vel)
                time_limit = time.time() + 1.0
                while time.time() < time_limit:
                    actual_vel = self.get_velocity()
                    print(f"{actual_vel=:.2f}")
                    if abs(actual_vel - target_vel) < 5 * RPM:
                        break
                else:
                    assert False, f"{actual_vel=} must converge to {target_vel=}"

def generate_test_description():
    # Declare launch arguments
    decl_can_iface = DeclareLaunchArgument("can_iface", default_value="can0")

    # Build robot description
    robot_description = ParameterValue(Command([
        "xacro ", PathJoinSubstitution([FindPackageShare("adrd3161_tests"), "urdf", "one_adrd3161.urdf.xacro"]),
        " can_iface:=", LaunchConfiguration("can_iface")
    ]), value_type=str)

    control_config = PathJoinSubstitution([FindPackageShare("adrd3161_tests"), "config", "one_adrd3161.yaml"])

    return (launch.LaunchDescription([
        decl_can_iface,

        launch_ros.actions.Node(
            package="robot_state_publisher", executable="robot_state_publisher",
            parameters=[{"robot_description": robot_description}],
            output="both"
        ),

        launch_ros.actions.Node(
            package="controller_manager", executable="ros2_control_node",
            parameters=[control_config],
            remappings=[("~/robot_description", "/robot_description")],
            output="both"
        ),

        launch_ros.actions.Node(
            package="controller_manager", executable="spawner",
            arguments=["pos_controller", "--controller-manager", "/controller_manager"],
            parameters=[control_config],
            output="both"
        ),

        launch_ros.actions.Node(
            package="controller_manager", executable="spawner",
            arguments=["vel_controller", "--controller-manager", "/controller_manager"],
            parameters=[control_config],
            output="both"
        ),

        launch.actions.TimerAction(
            period=5.0,
            actions=[launch_testing.actions.ReadyToTest()]
        )
    ]), {})

