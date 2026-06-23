FROM ubuntu:22.04

# Prevent interactive prompts (like timezone selections) from freezing the build
ENV DEBIAN_FRONTEND=noninteractive

# Install all required C++ build dependencies and Python packages
RUN apt-get update && apt-get install -y \
    build-essential cmake git \
    libhdf5-dev libvtk9-dev libboost-all-dev \
    libcgal-dev libtinyxml-dev qtbase5-dev libvtk9-qt-dev \
    python3-numpy python3-matplotlib cython3 python3-h5py python3-pip \
    python3-dev python3-setuptools python-is-python3 python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Clone the official OpenEMS-Project meta-repository
WORKDIR /tmp
RUN git clone --recursive https://github.com/thliebig/openEMS-Project.git

# Build and install the OpenEMS C++ core cleanly into /opt/openEMS
WORKDIR /tmp/openEMS-Project
RUN ./update_openEMS.sh /opt/openEMS

# Set environment variables for the system to find OpenEMS C++ binaries and libraries
ENV PATH="/opt/openEMS/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/openEMS/lib"

# Expose C++ headers and libraries so `pip` and `gcc` can find them during the Python build
ENV CPLUS_INCLUDE_PATH="/opt/openEMS/include:/opt/openEMS/include/CSXCAD:/opt/openEMS/include/openEMS"
ENV C_INCLUDE_PATH="/opt/openEMS/include:/opt/openEMS/include/CSXCAD:/opt/openEMS/include/openEMS"
ENV LIBRARY_PATH="/opt/openEMS/lib"

# OpenEMS Python scripts explicitly require these environment variables to locate the C++ libraries
ENV CSXCAD_INSTALL_PATH="/opt/openEMS"
ENV OPENEMS_INSTALL_PATH="/opt/openEMS"

# Explicit compiler flags are often required by Python's setuptools to link properly
ENV CFLAGS="-I/opt/openEMS/include -I/opt/openEMS/include/CSXCAD -I/opt/openEMS/include/openEMS"
ENV LDFLAGS="-L/opt/openEMS/lib"

# Explicitly build the Python bindings using the native setup.py script.
# We pass the include (-I), library (-L), and run-path (-R) flags that OpenEMS expects.
WORKDIR /tmp/openEMS-Project/CSXCAD/python
RUN python3 setup.py build_ext -I/opt/openEMS/include -L/opt/openEMS/lib -R/opt/openEMS/lib install

WORKDIR /tmp/openEMS-Project/openEMS/python
RUN python3 setup.py build_ext -I/opt/openEMS/include -L/opt/openEMS/lib -R/opt/openEMS/lib install


# Cleanup the source code to keep the final Docker image size small
RUN rm -rf /tmp/openEMS-Project

# Set the default working directory for when the container runs
WORKDIR /opt/openems_sim