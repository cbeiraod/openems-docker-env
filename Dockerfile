FROM --platform=linux/amd64 ubuntu:22.04

# Prevent interactive prompts (like timezone selections) from freezing the build
ENV DEBIAN_FRONTEND=noninteractive

# Install system utilities, add the OpenEMS official PPA, and install the C++ engine
RUN apt-get update && apt-get install -y \
    build-essential cmake git \
    libhdf5-dev libvtk9-dev libboost-all-dev \
    libcgal-dev libtinyxml-dev qtbase5-dev libvtk9-qt-dev \
    python3-numpy python3-matplotlib cython3 python3-h5py python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Clone the official OpenEMS-Project meta-repository
WORKDIR /tmp
RUN git clone --recursive https://github.com/thliebig/openEMS-Project.git

# Build and install OpenEMS and its Python bindings into /usr/local
WORKDIR /tmp/openEMS-Project
RUN ./update_openEMS.sh /usr/local --python

# Cleanup the source code to keep the final Docker image size small
RUN rm -rf /tmp/openEMS-Project

# Set the default working directory for when the container runs
WORKDIR /opt/openems_sim