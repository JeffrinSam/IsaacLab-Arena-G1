#!/bin/bash
# Quick Start Script for GR00T Policy Evaluation
# This script automates the setup and execution of GR00T policy inference

set -e  # Exit on error

echo "=========================================="
echo "GR00T Policy Evaluation - Quick Start"
echo "=========================================="
echo ""

# Check if GR00T container exists
if ! docker images | grep -q "isaaclab_arena.*cuda_gr00t"; then
    echo "❌ GR00T container not found!"
    echo ""
    echo "Building GR00T container (this will take 30-60 minutes)..."
    echo "Run this command to build:"
    echo "  ./docker/run_docker.sh -g"
    echo ""
    echo "Or check if build is in progress:"
    echo "  tail -f /tmp/groot_build.log"
    exit 1
fi

echo "✅ GR00T container found"
echo ""

# Check if model exists
MODELS_DIR_HOST="${HOME}/models"
if [ -d "./data/models" ]; then
    MODELS_DIR_HOST="./data/models"
fi

if [ ! -f "${MODELS_DIR_HOST}/isaaclab_arena/locomanipulation_tutorial/checkpoint-20000/model-00001-of-00002.safetensors" ]; then
    echo "⚠️  Pre-trained model not found!"
    echo ""
    echo "Downloading model (17GB, this will take 10-30 minutes)..."
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    ./docker/run_docker.sh -g bash -c "
        export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
        mkdir -p \$MODELS_DIR/checkpoint-20000
        echo 'Downloading model...'
        hf download nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation --local-dir \$MODELS_DIR/checkpoint-20000
        echo '✅ Model download complete'
    "
    
    if [ $? -ne 0 ]; then
        echo "❌ Model download failed"
        exit 1
    fi
else
    echo "✅ Pre-trained model found"
fi

echo ""
echo "=========================================="
echo "Starting GR00T Policy Evaluation"
echo "=========================================="
echo ""

# Run the evaluation
./docker/run_docker.sh -g bash -c "
    cd /workspaces/isaaclab_arena
    export PYTHONPATH=\${ISAACLAB_PATH}/source/isaaclab:\${ISAACLAB_PATH}/source/isaaclab_assets:\${ISAACLAB_PATH}/source/isaaclab_mimic:\${ISAACLAB_PATH}/source/isaaclab_rl:\${ISAACLAB_PATH}/source/isaaclab_tasks
    export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
    export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
    
    echo 'Environment variables:'
    echo '  DATASET_DIR='\$DATASET_DIR
    echo '  MODELS_DIR='\$MODELS_DIR
    echo ''
    echo 'Running GR00T policy evaluation...'
    echo 'This will launch Isaac Sim and run the policy for 1200 steps.'
    echo ''
    
    /isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
      --policy_type gr00t_closedloop \
      --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
      --num_steps 1200 \
      --enable_cameras \
      galileo_g1_locomanip_pick_and_place \
      --object brown_box \
      --embodiment g1_wbc_joint
"

echo ""
echo "=========================================="
echo "Evaluation Complete!"
echo "=========================================="
