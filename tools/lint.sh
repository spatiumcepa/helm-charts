#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

changed_charts=`git diff --find-renames --name-only $(git merge-base origin/devel HEAD) stable/ | awk -F/ '{print $1 "/" $2}' | uniq`

ROOT_DIR="$(cd "$(dirname "$(readlink "$0")")" && pwd)"

docker_working_dir=/tmp/helm_charts
docker_helm_image_name=charts-linting-$RANDOM
docker_helm_image=lachlanevenson/k8s-helm:v3.6.3

for chart_path in $changed_charts; do
    docker run --rm --name=$docker_helm_image_name \
        --volume=$ROOT_DIR:$docker_working_dir \
        --workdir=$docker_working_dir \
        $docker_helm_image \
        init --client-only && helm lint $chart_path
done
