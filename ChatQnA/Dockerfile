

# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM python:3.11-slim

RUN apt-get update -y && apt-get install -y --no-install-recommends --fix-missing \
    libgl1-mesa-glx \
    libjemalloc-dev \
    git

RUN useradd -m -s /bin/bash user && \
    mkdir -p /home/user && \
    chown -R user /home/user/

WORKDIR /home/user/
RUN git clone https://github.com/opea-project/GenAIComps.git

WORKDIR /home/user/GenAIComps
RUN pip install --no-cache-dir --upgrade pip setuptools && \
    pip install --no-cache-dir -r /home/user/GenAIComps/requirements.txt && \
    pip install --no-cache-dir langchain_core

COPY ./chatqna.py /home/user/chatqna.py

ENV PYTHONPATH=$PYTHONPATH:/home/user/GenAIComps

USER user

WORKDIR /home/user

RUN echo 'ulimit -S -n 999999' >> ~/.bashrc

ENTRYPOINT ["python", "chatqna.py"]
