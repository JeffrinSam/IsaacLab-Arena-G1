#!/bin/bash
# Script to ensure PYTHONPATH is set for IsaacLab modules
# This is sourced by the entrypoint to set up the Python environment

if [ -n "${ISAACLAB_PATH:-}" ]; then
    export PYTHONPATH="${ISAACLAB_PATH}/source/isaaclab:${ISAACLAB_PATH}/source/isaaclab_assets:${ISAACLAB_PATH}/source/isaaclab_mimic:${ISAACLAB_PATH}/source/isaaclab_rl:${ISAACLAB_PATH}/source/isaaclab_tasks:${PYTHONPATH:-}"
fi
