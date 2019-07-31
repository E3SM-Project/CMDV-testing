FROM e3sm/clubb-env:2019-07-25

RUN yum update
# RUN yum install python3-pip
RUN yum install -y \
    python36 \
    python36-devel \
    python36-setuptools \
    python36-pip

RUN pip3 install --upgrade pip
RUN pip3 install \
        ipykernel \
        jupyter_client \
        matplotlib \
        nbconvert \
        pypandoc \
        pyyaml

RUN git clone https://github.com/E3SM-Project/CMDV-testing.git &&\
    ln -s `pwd`/CMDV-testing /CMDV &&\
    ln -s `pwd`/CMDV-testing /CMDV-testing &&\
    cd CMDV-testing &&\
    git checkout ctest 

ENV PYTHONPATH $PYTHONPATH:/CMDV-testing/lib/python
ENV PATH $PATH:/CMDV-testing/scripts

WORKDIR /clubb
