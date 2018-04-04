FROM centos:7
LABEL maintainer "Andreas Wilke <wilke@mcs.anl.gov>"

RUN yum -y update && yum -y upgrade &&  yum -y install \
  bzip2 \
  cmake \
  file \
  gcc \
  gcc-c++ \
  git \
  kernel-devel \
  less \
  libmpc-devel.x86_64 \
  m4 \
  make \
  mpfr-devel.x86 \
  wget \
  which \
  zlib-devel
  
