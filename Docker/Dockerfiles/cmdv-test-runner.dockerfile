FROM cmdv/gcc:5.3.0
# Upgrade pip and install python modules
RUN pip2 install --upgrade pip
RUN pip2 install \
    gitpython \
    pyyaml
RUN pip install --upgrade pip
RUN pip install \
    gitpython \
    pyyaml    


COPY . /CMDV-testing
ENV PATH $PATH:/CMDV-testing/scripts
ENV PYTHONPATH $PYTHONPATH:/CMDV-testing/lib/python/

