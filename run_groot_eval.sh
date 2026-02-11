#!/bin/bash
# Quick command to run GR00T policy evaluation
# Usage: ./run_groot_eval.sh

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "=== GR00T Policy Evaluation ==="
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^isaaclab_arena-cuda_gr00t$"; then
    echo "⚠️  GR00T container not running. Starting it..."
    cd "$SCRIPT_DIR"
    ./docker/run_docker.sh -g bash -c "
        export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
        export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
        export PYTHONPATH=\${ISAACLAB_PATH}/source/isaaclab:\${ISAACLAB_PATH}/source/isaaclab_assets:\${ISAACLAB_PATH}/source/isaaclab_mimic:\${ISAACLAB_PATH}/source/isaaclab_rl:\${ISAACLAB_PATH}/source/isaaclab_tasks
        cd /workspaces/isaaclab_arena
        /isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
          --policy_type gr00t_closedloop \
          --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
          --num_steps 1200 \
          --enable_cameras \
          galileo_g1_locomanip_pick_and_place \
          --object brown_box \
          --embodiment g1_wbc_joint
    "
else
    echo "✅ GR00T container is running. Executing evaluation..."
    docker exec isaaclab_arena-cuda_gr00t bash -c "
        export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
        export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
        export PYTHONPATH=\${ISAACLAB_PATH}/source/isaaclab:\${ISAACLAB_PATH}/source/isaaclab_assets:\${ISAACLAB_PATH}/source/isaaclab_mimic:\${ISAACLAB_PATH}/source/isaaclab_rl:\${ISAACLAB_PATH}/source/isaaclab_tasks
        cd /workspaces/isaaclab_arena
        /isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
          --policy_type gr00t_closedloop \
          --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
          --num_steps 1200 \
          --enable_cameras \
          galileo_g1_locomanip_pick_and_place \
          --object brown_box \
          --embodiment g1_wbc_joint
    "
fi
