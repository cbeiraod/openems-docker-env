FROM ubuntu:24.04

# Build argument for Python version
# Default to 3 to pick up the Ubuntu system default automatically over time
ARG PYTHON_VERSION=3

# Prevent interactive prompts (like timezone selections) from freezing the build
ENV DEBIAN_FRONTEND=noninteractive

# Consolidate dependencies, Deadsnakes PPA, venv creation, and Python package installs into a SINGLE layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common gnupg ca-certificates && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git \
    libhdf5-dev libvtk9-dev libboost-all-dev \
    libcgal-dev libtinyxml-dev qtbase5-dev libvtk9-qt-dev \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python${PYTHON_VERSION} -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip setuptools wheel \
    && /opt/venv/bin/pip install "numpy>=2.0" matplotlib cython h5py \
    && rm -rf /root/.cache/pip

# Set environment variables for the venv and system to find OpenEMS C++ binaries and libraries
ENV PATH="/opt/venv/bin:/opt/openEMS/bin:${PATH}"
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
    python setup.py build_ext -I/opt/openEMS/include -L/opt/openEMS/lib -R/opt/openEMS/lib install && \
    cd ../../openEMS/python && \
    python setup.py build_ext -I/opt/openEMS/include -L/opt/openEMS/lib -R/opt/openEMS/lib install && \
    cd /tmp && \
    rm -rf /tmp/openEMS-Project && \
    find /opt/openEMS -type f \( -name "*.so" -o -executable \) -exec strip --strip-unneeded {} + || true

# Set the default working directory for when the container runs
WORKDIR /opt/openems_sim