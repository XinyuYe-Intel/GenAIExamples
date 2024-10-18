# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set -x
IMAGE_REPO=${IMAGE_REPO:-"opea"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
echo "REGISTRY=IMAGE_REPO=${IMAGE_REPO}"
echo "TAG=IMAGE_TAG=${IMAGE_TAG}"
export REGISTRY=${IMAGE_REPO}
export TAG=${IMAGE_TAG}

WORKPATH=$(dirname "$PWD")
LOG_PATH="$WORKPATH/tests"
ip_address=$(hostname -I | awk '{print $1}')
text2image_service_port=9379
MODEL=stabilityai/stable-diffusion-2-1

function build_docker_images() {
    cd $WORKPATH/docker_image_build
    if [ ! -d "GenAIComps" ] ; then
        git clone https://github.com/opea-project/GenAIComps.git && cd GenAIComps && git checkout "${opea_branch:-"main"}" && cd ../
    fi
    docker compose -f build.yaml build --no-cache > ${LOG_PATH}/docker_image_build.log

    docker images && sleep 1s
}

function start_service() {
    cd $WORKPATH/docker_compose/intel/cpu/xeon
    
    export MODEL=${MODEL}
    export HUGGINGFACEHUB_API_TOKEN=${HUGGINGFACEHUB_API_TOKEN}

    # Start Docker Containers
    docker compose -f compose.yaml up -d > ${LOG_PATH}/start_services_with_compose.log

    sleep 30s
}

function validate_microservice() {
    cd $LOG_PATH
    export no_proxy="localhost,127.0.0.1,"${ip_address}

    # test /v1/text2image generate image
    URL="http://${ip_address}:$text2image_service_port/v1/text2image"
    HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -X POST -d '{"prompt":"An astronaut riding a green horse", "num_images_per_prompt":1}' -H 'Content-Type: application/json' "$URL")
    HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    RESPONSE_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
    SERVICE_NAME="text2image-server - generate image"

    if [ "$HTTP_STATUS" -ne "200" ]; then
        echo "[ $SERVICE_NAME ] HTTP status is not 200. Received status was $HTTP_STATUS"
        docker logs text2image-server >> ${LOG_PATH}/text2image-server_generate_image.log
        exit 1
    else
        echo "[ $SERVICE_NAME ] HTTP status is 200. Checking content..."
    fi
    # Check if the parsed values match the expected values
    if [[ $RESPONSE_BODY == *"images"* ]]; then
        echo "Content correct."
    else
        echo "Content wrong."
        docker logs text2image-server >> ${LOG_PATH}/text2image-server_generate_image.log
        exit 1
    fi
}


function validate_frontend() {
    echo "[ TEST INFO ]: --------- frontend test started ---------"
    cd $WORKPATH/ui/svelte
    local conda_env_name="OPEA_e2e"
    export PATH=${HOME}/miniforge3/bin/:$PATH
    if conda info --envs | grep -q "$conda_env_name"; then
        echo "$conda_env_name exist!"
    else
        conda create -n ${conda_env_name} python=3.12 -y
    fi
    source activate ${conda_env_name}
    echo "[ TEST INFO ]: --------- conda env activated ---------"

    sed -i "s/localhost/$ip_address/g" playwright.config.ts

    conda install -c conda-forge nodejs -y
    npm install && npm ci && npx playwright install --with-deps
    node -v && npm -v && pip list

    exit_status=0
    npx playwright test || exit_status=$?

    if [ $exit_status -ne 0 ]; then
        echo "[TEST INFO]: ---------frontend test failed---------"
        exit $exit_status
    else
        echo "[TEST INFO]: ---------frontend test passed---------"
    fi
}

function stop_docker() {
    cd $WORKPATH/docker_compose/intel/cpu/xeon
    docker compose stop && docker compose rm -f
}

function main() {

    stop_docker

    build_docker_images
    start_service

    validate_microservice
    echo "==== microservices validated ===="
    validate_frontend
    echo "==== frontend validated ===="

    stop_docker
    echo y | docker system prune

}

main
