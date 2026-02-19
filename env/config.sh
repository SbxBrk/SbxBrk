#!/usr/bin/env bash

USER_SUFFIX="$(id -u -n)"
NAME="v8-heap-sandbox-artifact-env"
IMAGE_NAME="${NAME}:latest"
PREBUILT_IMAGE_NAME="${NAME}-prebuilt:latest"
PREBUILT_PUSH_URL=nbars/$PREBUILT_IMAGE_NAME
PREBUILT_PULL_NAME="nbars/${PREBUILT_IMAGE_NAME}"
#PREBUILT_PULL_NAME="nbars/${PREBUILT_IMAGE_NAME}@sha256:02492d1df06633e49c89948c0cb87853ccb8c2254fdaa43851ef9e911beb371b"
export PREBUILT_ENV_VAR_NAME='USE_PREBUILT'
CONTAINER_NAME="${NAME}"
PREBUILT_CONTAINER_NAME="prebuilt-${NAME}"

# Limit the max memory consumption to max % of host memory.
# Comment to in order to disable.
LIMIT_MEMORY_PERCENT=90

if [ -t 1 ]; then
    text_red=$(tput setaf 1)    # Red
    text_green=$(tput setaf 2)  # Green
    text_bold=$(tput bold)      # Bold
    text_reset=$(tput sgr0)     # Reset your text
else
    text_red=""
    text_green=""
    text_bold=""
    text_reset=""
fi


function log_error {
    echo "${text_bold}${text_red}${1}${text_reset}"
}

function log_success {
    echo "${text_bold}${text_green}${1}${text_reset}"
}

function use_prebuilt {
    if [[ ! -z "${!PREBUILT_ENV_VAR_NAME:-}" ]]; then
        return 0
    fi
    return 1
}
