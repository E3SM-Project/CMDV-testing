FROM jupyter/datascience-notebook:8d9388cac562

MAINTAINER Andreas Wilke <wilke@mcs.anl.gov>
USER root
RUN apt-get upgrade && apt-get update
RUN apt-get install -y \
  less \
  pandoc  \
  pandoc-citeproc
RUN pip install --upgrade pip
RUN pip install netCDF4
# RUN conda install netCDF4   
COPY ./documentation/prototype/converter.py /usr/local/bin
CMD bash
