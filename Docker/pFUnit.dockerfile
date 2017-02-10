FROM centos:7
MAINTAINER Andreas Wilke <wilke@mcs.anl.gov>
RUN yum -y update && yum -y upgrade && yum -y install \
  cmake \
  gcc \
  gcc-c++ \
  gcc-fortran \
  gcc-gfortran \
  git \
  kernel-devel \
  less \
  make \
  wget \
  which
WORKDIR /Downloads
RUN wget http://www.mpich.org/static/downloads/3.1.4/mpich-3.1.4.tar.gz && tar -xvf mpich-3.1.4.tar.gz && mkdir /mpich3
ENV LD_LIBRARY_PATH /mpich3/lib/
RUN wget https://cmake.org/files/v3.7/cmake-3.7.1.tar.gz && \
 tar -xvf cmake-3.7.1.tar.gz
RUN cd cmake-3.7.1 && \
 cmake . && \
 make && \
 make install
WORKDIR /Downloads/mpich-3.1.4
RUN ./configure --prefix=/mpich3 && make && make install
ENV PATH /Downloads/cmake-3.7.1.bin:$PATH:/mpich3/bin
WORKDIR /Downloads
RUN git clone git://git.code.sf.net/p/pfunit/code pFUnit
ENV F90_VENDOR=GNU F90=gfortran MPIF90=mpif90 PFUNIT=/pfUnit
RUN mkdir pFUnit/build /pfUnit && \
  cd pFUnit/build &&\
  cmake -DMPI=YES -DOPENMP=NO -DINSTALL_PATH=/pfUnit -DCMAKE_INSTALL_PREFIX=/pfUnit ../ &&\
  make tests
RUN cd pFUnit/build && make install INSTALL_DIR=/pfUnit
ENV PATH /pfUnit/bin:$PATH  

