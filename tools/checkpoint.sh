#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

echo "Checking for container to checkpoint..."

container_id=$(runc list | grep running | grep --max-count=1 rbm | cut --fields=1 --delimiter=" ")

echo "Checkpointing container ID $container_id"

runc checkpoint "$container_id"

echo "Checkpointed!"
