#!/usr/bin/env bash

set -eu
set -o pipefail
cd $(dirname $0)

source config.sh
cd ..

BUILD_TARGET=${BUILD_TARGET:-"dev"}
echo "[+] BUILD_TARGET=$BUILD_TARGET"

if [[ "$BUILD_TARGET" == "prebuilt" ]]; then
    image_name="$PREBUILT_IMAGE_NAME"
else
    image_name="$IMAGE_NAME"
fi


log_success "[+] Building docker image"
docker build --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" --target "$BUILD_TARGET" $@ -t $image_name .
if [[ $?  -ne 0 ]]; then
    log_error "[+] Error while building the docker image."
    exit 1
else
    log_success "[+] Docker image successfully build. Use ./env/start.sh and ./env/stop.sh to manage the containers lifecycle."
fi

exit 0
