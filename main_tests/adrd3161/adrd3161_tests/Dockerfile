ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}-ros-base

LABEL maintainer="Ioan Dragomir <ioan.dragomir@analog.com>"

# Install apt dependencies
RUN apt-get update && apt-get install -y \
        can-utils \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /ros2_ws/src/
WORKDIR /ros2_ws/

# BODGE: install packages we KNOW we will need, to speed up later steps
RUN apt-get update && apt-get install -y ros-humble-xacro ros-humble-urdf ros-humble-ament-cmake-python ros-humble-canopen-ros2-control ros-humble-canopen-ros2-controllers ros-humble-canopen-402-driver

# Copy ros packages
COPY . /ros2_ws/src/adrd3161_tests

# Install ros dependencies
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
        && apt-get update \
        && rosdep update \
        && rosdep install -i --from-path src --rosdistro ${ROS_DISTRO} -y \
        && rm -rf /var/lib/apt/lists/*

# Build and clean up
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
        && MAKEFLAGS="-l2" colcon build

COPY entrypoint.sh .
ENTRYPOINT ["/ros2_ws/entrypoint.sh"]
CMD ["bash"]

