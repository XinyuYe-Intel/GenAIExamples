# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM python:3.11-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update -y && apt-get install -y --no-install-recommends --fix-missing \
    libgl1-mesa-glx \
    libjemalloc-dev 

RUN useradd -m -s /bin/bash user && \
    mkdir -p /home/user && \
    chown -R user /home/user/

COPY ./requirements.txt /home/user/requirements.txt
COPY ./chatqna.py /home/user/chatqna.py

WORKDIR /home/user
RUN pip install --no-cache-dir -r requirements.txt

USER user

RUN echo 'ulimit -S -n 999999' >> ~/.bashrc

ENTRYPOINT ["python", "chatqna.py"]
