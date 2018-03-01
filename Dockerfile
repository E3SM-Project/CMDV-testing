FROM cmdv/gcc:5.3.0

COPY . /CMDV-testing
ENV PATH $PATH:/CMDV-testing/scripts
ENV PYTHONPATH $PYTHONPATH:/CMDV-testing/lib/python/

