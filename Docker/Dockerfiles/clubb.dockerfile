# Dockerfile for CLUBB https://github.com/larson-group/clubb_release
# docker build -f clubb.dockerfile .
FROM centos:7

LABEL maintainer="Andreas Wilke <wilke@mcs.anl.gov>"

RUN yum -y update && yum -y upgrade
RUN yum -y install \
  bzip2 \
  bzip2-devel \
  cmake \
  csh \
  development \
  dpkg-devel \
  expat-devel \
  file \
  gcc \
  gcc-c++ \
  gcc-gfortran \
  gdbm-devel \
  git \
  groupinstall \
  kernel-devel \
  less \
  libmpc-devel.x86_64 \
  libxml2 \
  libxml2-devel \
  libxml2-python \
  libxslt \
  libxslt-devel  \
  m4 \
  make \
  mpfr-devel.x86 \
  openssl-devel \
  readline-devel \
  sqlite-devel \
  tcl \
  tcl-devel \
  tk \
  tk-devel \
  wget \
  which \
  yum-utils \
  zlib-devel \
  && rm -rf /var/lib/apt/lists/* \
  && yum clean all \
  && rm -rf /var/cache/yum

  #   ncl \        # netcdf
  # ncl-dev \

RUN yum -y --enablerepo=extras install epel-release   
RUN yum -y install \
    netcdf-fortran-devel \
    netcdf4-python \
    && rm -rf /var/lib/apt/lists/* \
    && yum clean all \
    && rm -rf /var/cache/yum

WORKDIR /Downloads
# HDF5 1.8.18
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.18/src/hdf5-1.8.18.tar && \
    tar -xvf hdf5-1.8.18.tar && \
    mkdir /hdf5 && \
    cd /Downloads/hdf5-1.8.18 && \
    ./configure --prefix=/hdf5 --enable-fortran && \
    make && make check && \
    make install && make check-install && \
    cd /Downloads && rm -rf *
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/hdf5/lib
ENV PATH $PATH:/hdf5/bin

# netCDF 4.4.1.1
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.1.1.tar.gz && \
    tar -xvf netcdf-4.4.1.1.tar.gz && \
    mkdir /netcdf4 && \
    cd /Downloads/netcdf-4.4.1.1 && \
    CPPFLAGS=-I/hdf5/include LDFLAGS=-L/hdf5/lib ./configure --prefix=/netcdf4 && \
    make all check && \
    make install && \
    cd /Downloads && rm -rf *
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/netcdf4/lib/    

ENV LIBRARY_PATH $LIBRARY_PATH:/usr/lib64/:/usr/lib64/gfortran/modules/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/lib64/:/usr/lib64//usr/lib64/gfortran/modules/

RUN yum install -y atlas atlas-devel lapack-devel blas-devel
# RUN ln -s  `ls -t /usr/lib64/libblas* | tail -n 1` /usr/lib64/libblas.so
# RUN ln -s  `ls -t /usr/lib64/liblapack* | tail -n 1` /usr/lib64/liblapack.so