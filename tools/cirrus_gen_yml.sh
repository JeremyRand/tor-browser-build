#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

(
#for CHANNEL in release nightly; do
for CHANNEL in nightly; do
    OS=linux
    ARCH=x86_64
    for PROJECT in gcc cmake rust firefox release; do
        echo "${CHANNEL}_${OS}_${ARCH}_${PROJECT}_docker_builder:
  timeout_in: 120m
  out_${CHANNEL}_${OS}_${ARCH}_cache:
    folder: out
    fingerprint_script:
      - \"echo out_${CHANNEL}_${OS}_${ARCH}\"
    populate_script:
      - \"mkdir -p out\"
  git_${CHANNEL}_${OS}_${ARCH}_cache:
    folder: git_clones
    fingerprint_script:
      - \"echo git_${CHANNEL}_${OS}_${ARCH}\"
    populate_script:
      - \"mkdir -p git_clones\"
  build_script:
    - \"./tools/cirrus_build_project.sh ${PROJECT} ${CHANNEL} ${OS} ${ARCH}\""
        if [[ "$PROJECT" == "cmake" ]]; then
            echo "  depends_on:
    - \"${CHANNEL}_${OS}_${ARCH}_gcc\""
        fi
        if [[ "$PROJECT" == "rust" ]]; then
            echo "  depends_on:
    - \"${CHANNEL}_${OS}_${ARCH}_cmake\""
        fi
        if [[ "$PROJECT" == "firefox" ]]; then
            echo "  depends_on:
    - \"${CHANNEL}_${OS}_${ARCH}_rust\""
        fi
        if [[ "$PROJECT" == "release" ]]; then
            echo "  depends_on:
    - \"${CHANNEL}_${OS}_${ARCH}_firefox\""
        fi
        echo ""
    done
done
) > .cirrus.yml

#- "make release-linux-x86_64"
# Might try bumping the CPU count if there's a timeout issue.  Blocked by cirrus-ci-docs issue #741.
# What is the CPU count limit?  "Linux Containers" docs say 8.0 CPU and 24 GB RAM; "FAQ" says 16.0 CPU.
# Might try just building firefox by itself if there's a timeout issue.
