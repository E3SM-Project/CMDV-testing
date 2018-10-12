FROM python:2.7

WORKDIR /cmdv-test-runner

# COPY requirements.txt ./
RUN pip install --no-cache-dir  \
    gitpython \
    ipykernel \
    jupyter_client \
    matplotlib \
    nbconvert \
    pypandoc \
    pyyaml

COPY . .

# CMD [ "python", "./scripts/cmdv-test-runner.py" ]



