# Complete G1 Loco-Manipulation Workflow Guide
## From Setup to GR00T Policy Inference - A Beginner's Guide

**Version:** Based on Isaac Lab Arena Release 0.1.1  
**Last Updated:** February 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Workflow](#step-by-step-workflow)
4. [Common Errors and Solutions](#common-errors-and-solutions)
5. [GR00T Policy Inference Guide](#gr00t-policy-inference-guide)
6. [Troubleshooting](#troubleshooting)
7. [Quick Reference](#quick-reference)

---

## Overview

This guide walks you through the complete G1 Loco-Manipulation workflow, from environment setup to running GR00T N1.5 policy inference. The G1 robot will learn to navigate, pick up a brown box from a shelf, and place it in a blue bin.

### What You'll Learn

- How to set up the Isaac Lab Arena environment
- How to validate the environment with demo replay
- How to run GR00T N1.5 policy inference
- How to evaluate the policy in single and parallel environments

### Task Description

**Task:** `galileo_g1_locomanip_pick_and_place`  
**Goal:** G1 humanoid robot navigates through a lab, picks up a brown box from a shelf, and places it into a blue bin.

**Key Components:**
- **Robot:** Unitree G1 (29 DOF humanoid)
- **Policy:** GR00T N1.5 (vision-language-action foundation model)
- **Scene:** Galileo Lab Environment
- **Control:** 50Hz closed-loop control

---

## Prerequisites

### 1. System Requirements

- **GPU:** NVIDIA GPU with CUDA support (recommended: RTX 3090 or better)
- **RAM:** At least 32GB
- **Storage:** ~50GB free space (for datasets, models, and Docker images)
- **OS:** Linux (Ubuntu 20.04/22.04 recommended)
- **Docker:** Installed and configured with NVIDIA runtime

### 2. Software Setup

#### Install Docker with NVIDIA Support

```bash
# Install Docker (if not already installed)
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Verify NVIDIA Docker support
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

#### Install Hugging Face CLI

```bash
pip install -U "huggingface_hub[cli]"
hf auth login  # Follow prompts to login
```

### 3. Repository Setup

```bash
# Clone the repository (if not already done)
git clone https://github.com/isaac-sim/IsaacLab-Arena.git
cd IsaacLab-Arena
git checkout release/0.1.1

# Initialize submodules
git submodule update --init --recursive
```

---

## Step-by-Step Workflow

### Step 1: Environment Setup and Validation

#### 1.1 Start Docker Container

```bash
# Start the base container
./docker/run_docker.sh
```

**What this does:**
- Builds the Isaac Lab Arena Docker image (first time: ~30 minutes)
- Starts a container with all dependencies
- Mounts your project directory and data folders

**Expected output:**
```
Using Docker image: isaaclab_arena:latest
Building Docker image with GR00T installation: false
...
[IsaacLab Arena] ~user /workspaces/isaaclab_arena $
```

#### 1.2 Set Up Data Directories

Inside the container:

```bash
# Create directories for datasets and models
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
mkdir -p $DATASET_DIR
mkdir -p $MODELS_DIR
```

**Note:** These directories are automatically mounted from your host machine:
- Host: `~/datasets` or `./data/datasets` → Container: `/datasets`
- Host: `~/models` or `./data/models` → Container: `/models`

#### 1.3 Download Test Dataset

```bash
# Download the test dataset (220MB)
hf download \
    nvidia/Arena-G1-Loco-Manipulation-Task \
    arena_g1_loco_manipulation_dataset_generated_small.hdf5 \
    --repo-type dataset \
    --local-dir $DATASET_DIR
```

**What this does:**
- Downloads a pre-recorded demonstration dataset
- Used to validate that the environment works correctly
- Contains robot actions and observations from a successful run

**Expected output:**
```
Downloading 'arena_g1_loco_manipulation_dataset_generated_small.hdf5' to ...
Download complete. Moving file to ...
```

#### 1.4 Validate Environment with Demo Replay

```bash
# Replay the downloaded dataset to verify environment setup
/isaac-sim/python.sh isaaclab_arena/scripts/replay_demos.py \
  --device cpu \
  --enable_cameras \
  --dataset_file ${DATASET_DIR}/arena_g1_loco_manipulation_dataset_generated_small.hdf5 \
  galileo_g1_locomanip_pick_and_place \
  --object brown_box \
  --embodiment g1_wbc_pink
```

**What this does:**
- Loads the G1 robot, brown box, and blue bin in the Galileo lab scene
- Replays the recorded actions from the dataset
- Verifies that the environment loads and runs correctly
- Shows the robot performing the task (if GUI is available)

**Expected behavior:**
- Isaac Sim window opens (if GUI available)
- Robot moves according to recorded actions
- No errors in console
- Script completes successfully

**Success indicators:**
- No `ModuleNotFoundError` or import errors
- Environment loads without crashes
- Robot appears in the scene

---

### Step 2: Data Generation (Optional)

**Note:** You can skip this step if using pre-generated data. The test dataset from Step 1 is sufficient for validation.

If you want to generate your own dataset:

#### 2.1 Download Annotated Dataset

```bash
hf download \
    nvidia/Arena-G1-Loco-Manipulation-Task \
    arena_g1_loco_manipulation_dataset_annotated.hdf5 \
    --repo-type dataset \
    --local-dir $DATASET_DIR
```

#### 2.2 Generate Dataset with Isaac Lab Mimic

```bash
/isaac-sim/python.sh isaaclab_arena/scripts/generate_dataset.py \
  --headless \
  --enable_cameras \
  --mimic \
  --input_file $DATASET_DIR/arena_g1_loco_manipulation_dataset_annotated.hdf5 \
  --output_file $DATASET_DIR/arena_g1_loco_manipulation_dataset_generated.hdf5 \
  --generation_num_trials 100 \
  --device cpu \
  galileo_g1_locomanip_pick_and_place \
  --object brown_box \
  --embodiment g1_wbc_pink
```

**Time:** 1-4 hours depending on CPU/GPU

---

### Step 3: Policy Post-Training (Optional)

**Note:** You can skip this step by downloading the pre-trained model (see Step 4).

If you want to train your own policy:

#### 3.1 Switch to GR00T Container

```bash
# Exit current container
exit

# Start GR00T container (requires GR00T container build)
./docker/run_docker.sh -g
```

**Build time:** 30-60 minutes (first time)

#### 3.2 Convert HDF5 to LeRobot Format

```bash
/isaac-sim/python.sh isaaclab_arena_gr00t/data_utils/convert_hdf5_to_lerobot.py \
  --yaml_file isaaclab_arena_gr00t/config/g1_locomanip_config.yaml
```

#### 3.3 Post-Train GR00T N1.5 Policy

```bash
cd submodules/Isaac-GR00T

/isaac-sim/python.sh scripts/gr00t_finetune.py \
  --dataset_path=$DATASET_DIR/arena_g1_loco_manipulation_dataset_generated/lerobot \
  --output_dir=$MODELS_DIR \
  --data_config=isaaclab_arena_gr00t.data_config:UnitreeG1SimWBCDataConfig \
  --batch_size=24 \
  --max_steps=20000 \
  --num_gpus=8 \
  --save_steps=5000 \
  --base_model_path=nvidia/GR00T-N1.5-3B \
  --no_tune_llm \
  --tune_visual \
  --tune_projector \
  --tune_diffusion_model
```

**Time:** 4-8 hours on 8x L40s GPUs (48GB each)

---

### Step 4: Closed-Loop Policy Inference and Evaluation

This is the main step where you run the GR00T policy to control the robot.

#### 4.1 Prerequisites Check

Before running inference, ensure:

✅ **GR00T container is built:**
```bash
docker images | grep "isaaclab_arena.*cuda_gr00t"
```

✅ **Pre-trained model is downloaded:**
```bash
ls -lh $MODELS_DIR/checkpoint-20000/model-00001-of-00002.safetensors
# Should show ~4.7GB file
```

✅ **Environment variables are set:**
```bash
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
```

#### 4.2 Download Pre-trained Model (If Not Done)

```bash
# Inside GR00T container
hf download \
   nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation \
   --local-dir $MODELS_DIR/checkpoint-20000
```

**Size:** ~17GB  
**Time:** 10-30 minutes depending on connection

**Verify download:**
```bash
ls -lh $MODELS_DIR/checkpoint-20000/
# Should show:
# - model-00001-of-00002.safetensors (4.7GB)
# - model-00002-of-00002.safetensors (2.5GB)
# - optimizer.pt (9.6GB)
# - config.json
# - model.safetensors.index.json
# - Other checkpoint files
```

#### 4.3 Start GR00T Container

```bash
# From host machine
./docker/run_docker.sh -g
```

**What this does:**
- Builds GR00T container with CUDA 12.8 and GR00T dependencies (first time)
- Includes flash-attn and all required packages
- Takes 30-60 minutes to build

**Monitor build progress:**
```bash
# In another terminal
tail -f /tmp/groot_build.log
```

#### 4.4 Run Single Environment Evaluation

Inside the GR00T container:

```bash
# Set environment variables
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial

# Run policy evaluation
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \
  --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
  --num_steps 1200 \
  --enable_cameras \
  galileo_g1_locomanip_pick_and_place \
  --object brown_box \
  --embodiment g1_wbc_joint
```

**What this does:**
- Loads the GR00T N1.5 policy from the checkpoint
- Creates a single G1 robot environment
- Runs the policy for 1200 steps (~24 seconds at 50Hz)
- Robot attempts to pick up the brown box and place it in the blue bin
- Displays camera view from robot's head camera

**Expected output:**
```
[INFO]: Base environment:
	Environment device    : cuda:0
	Environment seed      : None
	Physics step-size     : 0.005
	Rendering step-size   : 0.01
	Environment step-size : 0.02
[INFO]: Time taken for scene creation : 2.7 seconds
[INFO]: Starting the simulation. This may take a few seconds. Please wait...
...
[INFO]: Completed setting up the environment...
...
Metrics: {success_rate: 1.0, num_episodes: 1}
```

**Success indicators:**
- No import errors
- Environment loads successfully
- Robot appears and moves
- Metrics show success_rate at the end

#### 4.5 Run Parallel Environments Evaluation

For faster evaluation with multiple environments:

```bash
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \
  --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
  --num_steps 1200 \
  --num_envs 5 \
  --enable_cameras \
  --device cpu \
  --policy_device cuda \
  galileo_g1_locomanip_pick_and_place \
  --object brown_box \
  --embodiment g1_wbc_joint
```

**What this does:**
- Runs 5 parallel environments simultaneously
- Each environment has its own robot and scene
- Faster evaluation (5x more data in same time)
- Uses CPU for physics (for reproducibility with CPU-generated datasets)

**Expected output:**
```
Resetting policy for terminated env_ids: tensor([3], device='cuda:0') and truncated env_ids: tensor([], device='cuda:0', dtype=torch.int64)
...
Metrics: {'success_rate': 1.0, 'num_episodes': 4}
```

---

## Common Errors and Solutions

### Error Category 1: Docker and Container Issues

#### Error: "the input device is not a TTY"

**Symptoms:**
```
the input device is not a TTY
```

**Cause:** Running Docker command without proper TTY allocation

**Solution:**
- Use `./docker/run_docker.sh` directly (it handles TTY automatically)
- Or run interactively: `./docker/run_docker.sh` then run commands inside

#### Error: "Permission denied" on openxr/run directory

**Symptoms:**
```
ERROR: failed to build: failed to solve: error from sender: lstat .../openxr/run: permission denied
```

**Cause:** Permission issues with submodule directory

**Solution:**
```bash
# Fix permissions
sudo chmod -R u+r submodules/IsaacLab/openxr/

# Or add to .dockerignore (already done)
echo "submodules/IsaacLab/openxr" >> .dockerignore
```

#### Error: "Conflict. The container name is already in use"

**Symptoms:**
```
docker: Error response from daemon: Conflict. The container name "/isaaclab_arena-cuda_gr00t" is already in use by container "..."
```

**Cause:** A stopped container with the same name exists

**Solution:**
```bash
# Manually remove the container
docker stop isaaclab_arena-cuda_gr00t 2>/dev/null
docker rm isaaclab_arena-cuda_gr00t 2>/dev/null

# Or just run the script again (it now auto-removes existing containers)
./docker/run_docker.sh -g
```

**Note:** The script has been updated to automatically remove existing containers before creating new ones.

#### Error: Container exits immediately

**Symptoms:** Container starts but exits right away

**Cause:** No command to keep container running

**Solution:**
```bash
# Run with a command
./docker/run_docker.sh bash -c "your_command_here"

# Or run interactively
./docker/run_docker.sh
# Then run commands inside
```

---

### Error Category 2: Python Environment Issues

#### Error: "ModuleNotFoundError: No module named 'isaaclab'"

**Symptoms:**
```
ModuleNotFoundError: No module named 'isaaclab'
```

**Cause:** PYTHONPATH not set correctly

**Solution:**
```bash
# Inside container, set PYTHONPATH
export PYTHONPATH=${ISAACLAB_PATH}/source/isaaclab:${ISAACLAB_PATH}/source/isaaclab_assets:${ISAACLAB_PATH}/source/isaaclab_mimic:${ISAACLAB_PATH}/source/isaaclab_rl:${ISAACLAB_PATH}/source/isaaclab_tasks:${PYTHONPATH:-}

# Or add to .bashrc (already done in entrypoint)
echo "export PYTHONPATH=..." >> ~/.bashrc
source ~/.bashrc
```

#### Error: "ModuleNotFoundError: No module named 'gr00t'"

**Symptoms:**
```
ModuleNotFoundError: No module named 'gr00t'
```

**Cause:** Running in base container instead of GR00T container

**Solution:**
```bash
# Exit base container
exit

# Start GR00T container
./docker/run_docker.sh -g

# Verify GR00T is available
/isaac-sim/python.sh -c "import gr00t; print('GR00T OK')"
```

#### Error: "ModuleNotFoundError: No module named 'warp'"

**Symptoms:**
```
ModuleNotFoundError: No module named 'warp'
```

**Cause:** Missing warp-lang dependency

**Solution:**
```bash
# Install warp-lang
/isaac-sim/python.sh -m pip install warp-lang
```

#### Error: "ModuleNotFoundError: No module named 'pinocchio'"

**Symptoms:**
```
ModuleNotFoundError: No module named 'pinocchio'
```

**Cause:** Missing pinocchio or wrong version

**Solution:**
```bash
# Install pinocchio via pin-pink
/isaac-sim/python.sh -m pip install pin-pink==3.1.0 pinocchio
```

**Important:** Import pinocchio BEFORE AppLauncher in your scripts:
```python
import pinocchio  # noqa: F401
from isaaclab.app import AppLauncher
```

---

### Error Category 3: GR00T Policy Issues

#### Error: "model 'pinocchio' has no attribute 'Model'"

**Symptoms:**
```
AttributeError: module 'pinocchio' has no attribute 'Model'
```

**Cause:** Wrong pinocchio version (Isaac Sim's version instead of pin-pink)

**Solution:**
```python
# Import pinocchio BEFORE AppLauncher
import pinocchio  # noqa: F401
from isaaclab.app import AppLauncher
```

#### Error: "FileNotFoundError: Model path does not exist"

**Symptoms:**
```
FileNotFoundError: /models/isaaclab_arena/locomanipulation_tutorial/checkpoint-20000 does not exist
```

**Cause:** Model not downloaded or wrong path

**Solution:**
```bash
# Check if model exists
ls -lh $MODELS_DIR/checkpoint-20000/

# Download if missing
hf download \
   nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation \
   --local-dir $MODELS_DIR/checkpoint-20000

# Verify environment variable
echo $MODELS_DIR
# Should show: /models/isaaclab_arena/locomanipulation_tutorial
```

#### Error: "CUDA out of memory"

**Symptoms:**
```
RuntimeError: CUDA out of memory
```

**Cause:** GPU doesn't have enough memory

**Solution:**
```bash
# Use CPU for physics (smaller memory footprint)
--device cpu

# Or reduce number of environments
--num_envs 1  # Instead of 5

# Or use smaller batch size in policy config
```

#### Error: "unrecognized arguments: --enable_pinocchio"

**Symptoms:**
```
error: unrecognized arguments: --enable_pinocchio
```

**Cause:** Flag not supported in this context

**Solution:**
- Remove `--enable_pinocchio` flag
- Pinocchio is imported automatically when needed
- For replay script, pinocchio is handled internally

---

### Error Category 4: Dataset and Model Issues

#### Error: "FileNotFoundError: Dataset file not found"

**Symptoms:**
```
FileNotFoundError: .../arena_g1_loco_manipulation_dataset_generated_small.hdf5 does not exist
```

**Cause:** Dataset not downloaded or wrong path

**Solution:**
```bash
# Check if dataset exists
ls -lh $DATASET_DIR/

# Download if missing
hf download \
    nvidia/Arena-G1-Loco-Manipulation-Task \
    arena_g1_loco_manipulation_dataset_generated_small.hdf5 \
    --repo-type dataset \
    --local-dir $DATASET_DIR

# Verify environment variable
echo $DATASET_DIR
# Should show: /datasets/isaaclab_arena/locomanipulation_tutorial
```

#### Error: "Hugging Face authentication required"

**Symptoms:**
```
401 Client Error: Unauthorized for url
```

**Cause:** Not logged into Hugging Face

**Solution:**
```bash
# Login to Hugging Face
hf auth login

# Follow prompts to enter your token
```

---

### Error Category 5: Build and Installation Issues

#### Error: "Failed to build 'flatdict'"

**Symptoms:**
```
ERROR: Failed to build 'flatdict' when getting requirements to build wheel
ModuleNotFoundError: No module named 'pkg_resources'
```

**Cause:** Missing build dependencies

**Solution:**
```bash
# Install with --no-build-isolation
/isaac-sim/python.sh -m pip install --no-build-isolation flatdict==4.0.1

# Or upgrade setuptools first
/isaac-sim/python.sh -m pip install --upgrade setuptools
/isaac-sim/python.sh -m pip install flatdict==4.0.1
```

#### Error: GR00T container build fails

**Symptoms:**
```
ERROR: failed to build: ...
```

**Cause:** Various build issues (permissions, dependencies, etc.)

**Solution:**
1. **Check permissions:**
   ```bash
   sudo chmod -R u+r submodules/IsaacLab/openxr/
   ```

2. **Check .dockerignore:**
   ```bash
   cat .dockerignore
   # Should include: submodules/IsaacLab/openxr
   ```

3. **Check build log:**
   ```bash
   tail -100 /tmp/groot_build.log
   ```

4. **Rebuild from scratch:**
   ```bash
   ./docker/run_docker.sh -r -g
   ```

---

## GR00T Policy Inference Guide

### Understanding GR00T Policy Inference

#### What is GR00T?

GR00T (Generalist Robot 00) is NVIDIA's vision-language-action foundation model. It:
- Takes camera images and language instructions as input
- Outputs robot actions (joint positions, navigation commands)
- Can be fine-tuned for specific tasks (like G1 loco-manipulation)

#### How GR00T Inference Works

1. **Input Processing:**
   - Camera RGB image (640x480) from robot's head camera
   - Joint states (43 DOF) - current robot joint positions
   - Language instruction: "Pick up the brown box from the shelf, and place it into the blue bin..."

2. **Policy Forward Pass:**
   - GR00T processes inputs through neural network
   - Predicts 16 future actions (action horizon)
   - Outputs: 32-dim action vector (upper body joints)

3. **Action Processing:**
   - Remaps from GR00T's joint space to simulation's joint space
   - Combines with WBC commands (navigation, base height, torso orientation)
   - Final action: 50-dim vector

4. **Execution:**
   - Upper body: Direct joint control (from GR00T)
   - Lower body: WBC policy (Homie V2 neural network)
   - Robot executes action, new observation captured, cycle repeats

#### Action Chunking Mechanism

**Why chunking?**
- GR00T predicts 16 steps ahead in one forward pass
- More efficient than predicting one step at a time
- Reduces inference frequency (predict once, execute 16 times)

**How it works:**
1. Policy predicts action chunk (16 steps)
2. Actions executed sequentially from chunk
3. When chunk exhausted, new chunk predicted
4. On episode reset, chunk is reset

### Configuration File Explained

**File:** `isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml`

```yaml
# Model checkpoint path (17GB pre-trained model)
model_path: /models/isaaclab_arena/locomanipulation_tutorial/checkpoint-20000

# Language instruction for the task
language_instruction: "Pick up the brown box from the shelf, and place it into the blue bin on the table located at the right of the shelf."

# Number of actions predicted per inference (16 steps ahead)
action_horizon: 16

# Number of actions executed per inference (can be <= action_horizon)
action_chunk_length: 16

# Camera name in simulation
pov_cam_name_sim: "robot_head_cam_rgb"

# Joint configuration files
policy_joints_config_path: isaaclab_arena_gr00t/config/g1/gr00t_43dof_joint_space.yaml
action_joints_config_path: isaaclab_arena_gr00t/config/g1/43dof_joint_space.yaml
state_joints_config_path: isaaclab_arena_gr00t/config/g1/43dof_joint_space.yaml
```

### Command-Line Arguments Explained

```bash
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \                    # Use GR00T closed-loop policy
  --policy_config_yaml_path ... \                     # Path to config file
  --num_steps 1200 \                                  # Number of simulation steps to run
  --enable_cameras \                                  # Enable camera rendering
  --num_envs 5 \                                      # Number of parallel environments (optional)
  --device cpu \                                      # Physics device (cpu for reproducibility)
  --policy_device cuda \                              # Policy inference device (cuda for speed)
  galileo_g1_locomanip_pick_and_place \               # Environment name
  --object brown_box \                                # Object to manipulate
  --embodiment g1_wbc_joint                           # Robot embodiment (g1_wbc_joint for inference)
```

**Key Arguments:**
- `--policy_type gr00t_closedloop`: Specifies GR00T policy type
- `--num_steps 1200`: Runs for 1200 steps (~24 seconds at 50Hz)
- `--enable_cameras`: Enables camera rendering (required for GR00T)
- `--device cpu`: Uses CPU physics (matches training data)
- `--embodiment g1_wbc_joint`: Uses joint-space control (not PINK IK)

---

## Troubleshooting

### Issue: GR00T container build is slow

**Solution:**
- First build takes 30-60 minutes (normal)
- Monitor progress: `tail -f /tmp/groot_build.log`
- Ensure stable internet connection (downloads large packages)
- Don't interrupt the build process

### Issue: Policy runs but robot doesn't move

**Check:**
1. Model loaded correctly?
   ```bash
   ls -lh $MODELS_DIR/checkpoint-20000/model-00001-of-00002.safetensors
   ```

2. Environment variables set?
   ```bash
   echo $MODELS_DIR
   echo $DATASET_DIR
   ```

3. Config file path correct?
   ```bash
   ls -lh isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml
   ```

### Issue: Low success rate

**Possible causes:**
- Model checkpoint incomplete or corrupted
- Physics device mismatch (use `--device cpu` if trained on CPU)
- Environment randomization too high
- Insufficient evaluation steps

**Solutions:**
- Re-download model checkpoint
- Use `--device cpu` for physics
- Increase `--num_steps` for longer evaluation
- Check model checkpoint is complete (all files present)

### Issue: Out of memory errors

**Solutions:**
- Reduce `--num_envs` (use 1 instead of 5)
- Use `--device cpu` for physics
- Close other GPU applications
- Use smaller batch size in policy config

---

## Quick Reference

### Essential Commands

```bash
# Start base container
./docker/run_docker.sh

# Start GR00T container
./docker/run_docker.sh -g

# Download test dataset
hf download nvidia/Arena-G1-Loco-Manipulation-Task \
  arena_g1_loco_manipulation_dataset_generated_small.hdf5 \
  --repo-type dataset --local-dir $DATASET_DIR

# Download pre-trained model
hf download nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation \
  --local-dir $MODELS_DIR/checkpoint-20000

# Run replay validation
/isaac-sim/python.sh isaaclab_arena/scripts/replay_demos.py \
  --device cpu --enable_cameras \
  --dataset_file ${DATASET_DIR}/arena_g1_loco_manipulation_dataset_generated_small.hdf5 \
  galileo_g1_locomanip_pick_and_place --object brown_box --embodiment g1_wbc_pink

# Run GR00T policy evaluation (single env)
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \
  --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
  --num_steps 1200 --enable_cameras \
  galileo_g1_locomanip_pick_and_place --object brown_box --embodiment g1_wbc_joint

# Run GR00T policy evaluation (parallel envs)
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \
  --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
  --num_steps 1200 --num_envs 5 --enable_cameras --device cpu --policy_device cuda \
  galileo_g1_locomanip_pick_and_place --object brown_box --embodiment g1_wbc_joint
```

### Environment Variables

```bash
# Always set these in GR00T container
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
export PYTHONPATH=${ISAACLAB_PATH}/source/isaaclab:${ISAACLAB_PATH}/source/isaaclab_assets:${ISAACLAB_PATH}/source/isaaclab_mimic:${ISAACLAB_PATH}/source/isaaclab_rl:${ISAACLAB_PATH}/source/isaaclab_tasks:${PYTHONPATH:-}
```

### File Locations

```
Container Paths:
- Datasets: /datasets/isaaclab_arena/locomanipulation_tutorial/
- Models: /models/isaaclab_arena/locomanipulation_tutorial/checkpoint-20000/
- Config: isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml

Host Paths (mounted to container):
- Datasets: ~/datasets/ or ./data/datasets/
- Models: ~/models/ or ./data/models/
```

### Verification Checklist

Before running GR00T inference, verify:

- [ ] GR00T container is built (`docker images | grep cuda_gr00t`)
- [ ] Model checkpoint downloaded (17GB, all files present)
- [ ] Environment variables set (DATASET_DIR, MODELS_DIR)
- [ ] Config file exists and path is correct
- [ ] Running in GR00T container (not base container)
- [ ] GPU available (for policy inference)
- [ ] Hugging Face authenticated (`hf auth login`)

### ✅ Success Verification

**Expected Output:**
- Progress bar showing step completion (e.g., `100%|██████████| 1200/1200 [01:35<00:00, 12.53it/s]`)
- No pinocchio errors (`AttributeError: module 'pinocchio' has no attribute 'Model'`)
- Environment initializes successfully
- Policy loads and runs without errors
- Metrics computed at the end (if enabled)

**Verified Working Configuration:**
- ✅ GR00T N1.5 policy evaluation completed successfully
- ✅ 1200/1200 steps executed without errors
- ✅ Performance: ~12-13 steps/second
- ✅ Pinocchio import fix working correctly
- ✅ Robot successfully performs pick-and-place task

---

## Additional Resources

- **Official Documentation:** https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/
- **GitHub Repository:** https://github.com/isaac-sim/IsaacLab-Arena (Release 0.1.1)
- **Dataset:** https://huggingface.co/datasets/nvidia/Arena-G1-Loco-Manipulation-Task
- **Pre-trained Model:** https://huggingface.co/nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation
- **System Architecture:** See `G1_SYSTEM_ARCHITECTURE.md` for detailed technical information
- **Quick Start Script:** `./quick_start_groot.sh` - Automated setup and execution

## Document Structure

This guide is organized for easy navigation:

1. **Overview & Prerequisites** - What you need to know and have
2. **Step-by-Step Workflow** - Detailed instructions for each step
3. **Common Errors and Solutions** - Troubleshooting guide organized by error type
4. **GR00T Policy Inference Guide** - Deep explanation of how inference works
5. **Troubleshooting** - Additional help for specific issues
6. **Quick Reference** - Commands and checklists for quick access

---

## Summary

This guide provides a complete walkthrough of the G1 Loco-Manipulation workflow. Key takeaways:

1. **Setup:** Use Docker containers (base for validation, GR00T for inference)
2. **Data:** Download pre-generated datasets and models from Hugging Face
3. **Validation:** Always validate environment before running inference
4. **Inference:** Use GR00T container with proper environment variables
5. **Troubleshooting:** Most errors are due to missing dependencies or wrong container

**Remember:** GR00T requires the GR00T container (`-g` flag). The base container does not have GR00T installed.

For detailed technical information about the system architecture, see `G1_SYSTEM_ARCHITECTURE.md`.
