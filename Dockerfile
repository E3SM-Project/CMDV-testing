FROM cmdv/gcc:5.3.0
RUN apt-get update -y
RUN apt-get install -y cmake \
    less
COPY . /CMDV-testing
ENV PATH $PATH:/CMDV-testing/scripts
ENV PYTHONPATH $PYTHONPATH:/CMDV-testing/lib/python/

