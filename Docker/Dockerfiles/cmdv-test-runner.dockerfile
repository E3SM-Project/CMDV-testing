FROM cmdv/gcc:5.3.0
# Upgrade pip and install python modules
RUN pip2 install --upgrade pip
RUN pip2 install \
    gitpython \
    ipykernel \
    jupyter_client \
    matplotlib \
    nbconvert \
    pypandoc \
    pyyaml
RUN pip install --upgrade pip
RUN pip install \
    gitpython \
    ipykernel \
    jupyter_client \
    matplotlib \
    nbconvert \
    pypandoc \
    pyyaml    

install ipykernel

COPY . /CMDV-testing
ENV PATH $PATH:/CMDV-testing/scripts
ENV PYTHONPATH $PYTHONPATH:/CMDV-testing/lib/python/

