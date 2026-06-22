FROM --platform=linux/amd64 ubuntu:22.04

# Prevent interactive prompts (like timezone selections) from freezing the build
ENV DEBIAN_FRONTEND=noninteractive

# Install system utilities, add the OpenEMS official PPA, and install the C++ engine
RUN apt-get update && apt-get install -y \
    software-properties-common \
    python3-pip \
    && add-apt-repository ppa:thliebig/openems -y \
    && apt-get update \
    && apt-get install -y openems

# Link the official Python bindings into the image
RUN cd /usr/share/CSXCAD/python && pip3 install .
RUN cd /usr/share/openEMS/python && pip3 install .

# Set the default working directory for when the container runs
WORKDIR /opt/openems_sim