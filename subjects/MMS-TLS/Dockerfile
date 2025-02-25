FROM ubuntu:20.04

# Install common dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && \
    apt-get -y install sudo \ 
    apt-utils \
    build-essential \
    clang \
    graphviz-dev \
    git \
    autoconf \
    llvm \
    cmake \
    python3-pip \
    net-tools \
    vim \
    gdb \
    libcap-dev \
    netcat \
    strace \
    wget

# Add a new user ubuntu, pass: ubuntu
RUN groupadd ubuntu && \
    useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1000 ubuntu -p "$(openssl passwd -1 ubuntu)"

RUN chmod 777 /tmp

RUN pip3 install gcovr==4.2

# Use ubuntu as default username
USER ubuntu
WORKDIR /home/ubuntu

# Import environment variable to pass as parameter to make (e.g., to make parallel builds with -j)
ARG MAKE_OPT
ARG DFDIR=clones/profuzzbench/subjects/MMS-TLS

# Set up fuzzers
COPY --chown=ubuntu:ubuntu $DFDIR/aflnet.patch /home/ubuntu/aflnet.patch
# COPY --chown=ubuntu:ubuntu clones/aflnet aflnet
RUN cd /home/ubuntu && \
    git clone https://github.com/aflnet/aflnet.git --depth=1 && \
    cd aflnet && \
    patch -p1 < ../aflnet.patch && \
    make clean all -j && \
    cd llvm_mode && make -j


# Set up environment variables for AFLNet
ENV WORKDIR="/home/ubuntu/experiments"
ENV AFLNET="/home/ubuntu/aflnet"
ENV PATH="${PATH}:${AFLNET}:/home/ubuntu/.local/bin:${WORKDIR}"
ENV AFL_PATH="${AFLNET}"
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
    AFL_SKIP_CPUFREQ=1 \
    AFL_NO_AFFINITY=1


RUN mkdir $WORKDIR

COPY --chown=ubuntu:ubuntu $DFDIR/sqlite $WORKDIR/sqlite
COPY --chown=ubuntu:ubuntu $DFDIR/libiec61850.patch ${WORKDIR}/libiec61850.patch
COPY --chown=ubuntu:ubuntu $DFDIR/gcov.patch ${WORKDIR}/gcov.patch

# Download and compile libiec61850 for fuzzing
RUN cd $WORKDIR && \
    git clone https://github.com/mz-automation/libiec61850.git --depth=1 -b v1.4 && \
    cd libiec61850/third_party && \
    git clone https://github.com/Mbed-TLS/mbedtls.git --depth=1 -b archive/mbedtls-2.16 mbedtls/mbedtls-2.16 && \
    # patch -p1 < ${WORKDIR}/fuzzing.patch && \
    cp ${WORKDIR}/sqlite/* sqlite && \
    cd $WORKDIR && \
    cp -r libiec61850 libiec61850-gcov

RUN cd $WORKDIR/libiec61850 && \
    patch -p1 < ../libiec61850.patch && \
    mkdir build && \
    cmake -S . -B build -DWITH_MBEDTLS=ON && \
    cd build && \
    make -j
#
# Download and compile LightFTP for coverage analysis
RUN cd $WORKDIR/libiec61850-gcov && \
    patch -p1 < ../gcov.patch && \
    CFLAGS="-fprofile-arcs -ftest-coverage" CXXFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-fprofile-arcs -ftest-coverage" make clean all examples -j
    

COPY --chown=ubuntu:ubuntu $DFDIR/in-mms-tls ${WORKDIR}/in-mms-tls
COPY --chown=ubuntu:ubuntu $DFDIR/cov_script.sh ${WORKDIR}/cov_script
COPY --chown=ubuntu:ubuntu $DFDIR/run.sh ${WORKDIR}/run
