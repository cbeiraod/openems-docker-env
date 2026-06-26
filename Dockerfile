FROM ubuntu:22.04

# Build argument for Python version (e.g., 3, 3.10, 3.11).
# Setting it to '3' will pull the system default.
ARG PYTHON_VERSION=3

# Prevent interactive prompts (like timezone selections) from freezing the build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, add deadsnakes PPA, configure python aliases, and install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git \
    libhdf5-dev libvtk9-dev libboost-all-dev \
    libcgal-dev libtinyxml-dev qtbase5-dev libvtk9-qt-dev \
    python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-setuptools python3-wheel \
    && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python${PYTHON_VERSION} -m pip install "numpy>=2.0" matplotlib cython h5py \
    && rm -rf /root/.cache/pip

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

# Clone, build C++ core, build Python bindings, and cleanup IN A SINGLE LAYER
# This prevents intermediate build files from bloating the final Docker image.
WORKDIR /tmp
RUN git clone --recursive https://github.com/thliebig/openEMS-Project.git && \
    cd openEMS-Project && \
    ./update_openEMS.sh /opt/openEMS && \
    cd CSXCAD/python && \
    python${PYTHON_VERSION} setup.py build_ext -I/opt/openEMS/include -L/opt/openEMS/lib -R/opt/openEMS/lib install && \
    cd ../../openEMS/python && \
    python${PYTHON_VERSION} setup.py build_ext -I/opt/openEMS/include -L/opt/openEMS/lib -R/opt/openEMS/lib install && \
    cd /tmp && \
    rm -rf /tmp/openEMS-Project && \
    find /opt/openEMS -type f \( -name "*.so" -o -executable \) -exec strip --strip-unneeded {} + || true

# Set the default working directory for when the container runs
WORKDIR /opt/openems_sim