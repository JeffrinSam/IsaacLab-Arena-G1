# AI Agent Memory - IsaacLab-Arena G1 Loco-Manipulation Project

**Purpose:** This document provides comprehensive context for AI agents working on this project, including all bugs encountered, fixes applied, and critical technical information needed to understand and reproduce the work.

**Project:** IsaacLab-Arena Release 0.1.1 - G1 Loco-Manipulation with GR00T N1.5 Policy  
**Date:** February 2025  
**Status:** ✅ Fully Working - GR00T evaluation successfully completed

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Critical Bugs and Fixes](#critical-bugs-and-fixes)
3. [System Architecture](#system-architecture)
4. [Docker Setup](#docker-setup)
5. [Import Order Dependencies](#import-order-dependencies)
6. [GR00T Policy Workflow](#gr00t-policy-workflow)
7. [File Structure and Key Files](#file-structure-and-key-files)
8. [Common Errors and Solutions](#common-errors-and-solutions)
9. [Reproduction Instructions](#reproduction-instructions)
10. [Technical Deep Dive](#technical-deep-dive)

---

## Project Overview

### What This Project Does

This project implements a complete G1 humanoid robot loco-manipulation system using:
- **Isaac Lab Arena** (Release 0.1.1) - Robotics simulation framework
- **Isaac Sim 5.1.0** - NVIDIA's physics simulation engine
- **Isaac Lab 2.3.0** - Reinforcement learning framework
- **GR00T N1.5** - Vision-language-action foundation model for robot control
- **Unitree G1** - 29 DOF humanoid robot

### Task Description

**Task:** `galileo_g1_locomanip_pick_and_place`  
**Goal:** G1 robot navigates through a lab, picks up a brown box from a shelf, and places it into a blue bin.

### Key Components

- **Scene:** Galileo Lab Environment (background, objects, physics)
- **Embodiment:** G1 robot with sensors, observations, actions
- **Task:** Goal definition, rewards, terminations
- **Policy:** GR00T N1.5 (3B parameter model, pre-trained on G1 task)

---

## Critical Bugs and Fixes

### Bug #1: Pinocchio Import Order (CRITICAL - Most Important Fix)

**Error:**
```
AttributeError: module 'pinocchio' has no attribute 'Model'
```

**Root Cause:**
- Isaac Sim bundles its own `pinocchio` library (incomplete version without `Model` attribute)
- `pin-pink` (required for Pink IK controller) installs a complete `pinocchio` with `Model` attribute
- When `SimulationAppContext` initializes Isaac Sim, it loads Isaac Sim's `pinocchio` first
- Later imports of `pink` or code using `pinocchio.Model` fail because the wrong version is loaded

**Solution Applied:**
Modified `isaaclab_arena/examples/policy_runner.py` to force the correct `pinocchio` version:

```python
# At module level (BEFORE any other imports)
import sys
pin_pink_pinocchio_path = "/isaac-sim/kit/python/lib/python3.11/site-packages/cmeel.prefix/lib/python3.11/site-packages"
if pin_pink_pinocchio_path in sys.path:
    sys.path.remove(pin_pink_pinocchio_path)
sys.path.insert(0, pin_pink_pinocchio_path)  # Ensure it's first

# Remove any existing pinocchio from sys.modules
modules_to_remove = [k for k in list(sys.modules.keys()) 
                     if k.startswith('pinocchio') or k == 'pin']
for mod_name in modules_to_remove:
    if mod_name in sys.modules:
        del sys.modules[mod_name]

# Now import pinocchio - it will use the pin-pink version
import pinocchio  # noqa: F401
pin = pinocchio
sys.modules['pinocchio'] = pinocchio
sys.modules['pin'] = pinocchio

# Verify immediately
if not hasattr(pinocchio, 'Model'):
    raise RuntimeError(f"pinocchio does not have Model attribute! File: {pinocchio.__file__}")
```

**Why This Works:**
1. `pin-pink` installs `pinocchio` to a specific `cmeel.prefix` path
2. By adding this path to `sys.path[0]`, Python finds it first
3. Clearing `sys.modules` ensures no cached wrong version
4. Module-level import happens before `SimulationAppContext` can interfere

**Files Modified:**
- `isaaclab_arena/examples/policy_runner.py` (lines 6-27)
- `isaaclab_arena/tests/test_g1_wbc_embodiment.py` (line 8 - simpler fix)
- `isaaclab_arena/tests/test_camera_observation.py` (line 8 - simpler fix)

**Verification:**
- ✅ GR00T evaluation completed 1200 steps successfully
- ✅ No `AttributeError` during execution
- ✅ Performance: ~12-13 steps/second

---

### Bug #2: Missing Python Dependencies

**Error:**
```
ModuleNotFoundError: No module named 'isaaclab'
ModuleNotFoundError: No module named 'warp'
ModuleNotFoundError: No module named 'pinocchio'
ModuleNotFoundError: No module named 'flatdict'
```

**Root Cause:**
- `isaaclab.sh -i` installs packages but some dependencies fail to build
- `flatdict` requires special build flags
- Some packages are not included in the base installation

**Solution Applied:**
Added explicit dependency installation in `docker/Dockerfile.isaaclab_arena`:

```dockerfile
# Install missing dependencies that isaaclab.sh -i may not install correctly
RUN /isaac-sim/python.sh -m pip install \
    einops \
    flaky \
    hidapi==0.14.0.post2 \
    junitparser \
    pin-pink==3.1.0 \
    prettytable==3.3.0 \
    "pyglet<2" \
    pytest-mock \
    transformers \
    gymnasium==1.2.1 \
    dex-retargeting==0.4.6 \
    pinocchio \
    warp-lang && \
    /isaac-sim/python.sh -m pip install --no-build-isolation flatdict==4.0.1
```

**Files Modified:**
- `docker/Dockerfile.isaaclab_arena` (lines 46-62)

---

### Bug #3: PYTHONPATH Configuration

**Error:**
```
ModuleNotFoundError: No module named 'isaaclab'
```

**Root Cause:**
- `PYTHONPATH` not set correctly in entrypoint script
- IsaacLab source directories not in Python path

**Solution Applied:**
Updated `docker/setup/entrypoint.sh` to automatically set `PYTHONPATH`:

```bash
# In .bashrc
export PYTHONPATH="${ISAACLAB_PATH}/source/isaaclab:${ISAACLAB_PATH}/source/isaaclab_assets:${ISAACLAB_PATH}/source/isaaclab_mimic:${ISAACLAB_PATH}/source/isaaclab_rl:${ISAACLAB_PATH}/source/isaaclab_tasks"
```

**Files Modified:**
- `docker/setup/entrypoint.sh` (lines 43-49, 67-72)

---

### Bug #4: Docker Container Name Conflict

**Error:**
```
docker: Error response from daemon: Conflict. The container name "/isaaclab_arena-cuda_gr00t" is already in use.
```

**Root Cause:**
- Previous container (stopped or running) with same name exists

**Solution Applied:**
Modified `docker/run_docker.sh` to remove existing containers:

```bash
# Remove existing container if it exists
docker stop isaaclab_arena-cuda_gr00t 2>/dev/null || true
docker rm isaaclab_arena-cuda_gr00t 2>/dev/null || true
```

**Files Modified:**
- `docker/run_docker.sh`

---

## System Architecture

### Docker Containers

**Base Container:**
- Image: `nvcr.io/nvidia/isaac-sim:5.0.0`
- Purpose: Base Isaac Sim environment
- Can run: Environment setup, validation, data generation
- Work directory: `/workspaces/isaaclab_arena`

**GR00T Container:**
- Base: Base container + CUDA 12.8 + GR00T dependencies
- Purpose: GR00T policy training and evaluation
- Includes: `flash-attn`, transformers, GR00T codebase
- Build time: 30-60 minutes (first time)
- Start command: `./docker/run_docker.sh -g`

### Python Environment

**Critical:** Always use `/isaac-sim/python.sh` (NOT system python)

**PYTHONPATH Structure:**
```
${ISAACLAB_PATH}/source/isaaclab
${ISAACLAB_PATH}/source/isaaclab_assets
${ISAACLAB_PATH}/source/isaaclab_mimic
${ISAACLAB_PATH}/source/isaaclab_rl
${ISAACLAB_PATH}/source/isaaclab_tasks
```

**Key Dependencies:**
- `pin-pink==3.1.0` (provides correct pinocchio)
- `warp-lang` (for physics)
- `flatdict==4.0.1` (requires `--no-build-isolation`)
- `gymnasium==1.2.1`
- `dex-retargeting==0.4.6`

---

## Import Order Dependencies

### CRITICAL RULE: Pinocchio Must Be Imported First

**For any script using cameras or Pink IK:**

1. **Module-level import** (before `AppLauncher` or `SimulationAppContext`):
   ```python
   import pinocchio  # noqa: F401
   ```

2. **For `policy_runner.py` specifically:** Use the full `sys.path`/`sys.modules` manipulation (see Bug #1 fix)

3. **Why:** Isaac Sim loads its own `pinocchio` during initialization, which conflicts with `pin-pink`'s version

### Import Order Pattern

```python
# 1. Pinocchio first (module level)
import pinocchio  # noqa: F401

# 2. Standard library
import sys
import os

# 3. Third-party (non-Isaac Sim)
import numpy as np
import torch

# 4. Isaac Lab components (after AppLauncher)
from isaaclab_arena.utils.isaaclab_utils.simulation_app import SimulationAppContext

# 5. Inside SimulationAppContext:
#    - Import Isaac Sim dependent modules
#    - Import policy modules
#    - Import task-specific modules
```

---

## GR00T Policy Workflow

### Complete Workflow Steps

1. **Environment Setup** ✅
   - Create directories: `/datasets/isaaclab_arena/locomanipulation_tutorial`
   - Create directories: `/models/isaaclab_arena/locomanipulation_tutorial`

2. **Dataset Download** ✅
   - Download from HuggingFace: `nvidia/Arena-G1-Loco-Manipulation-Task`
   - File: `arena_g1_loco_manipulation_dataset_generated_small.hdf5` (220MB)

3. **Model Download** ✅
   - Download from HuggingFace: `nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation`
   - Location: `/models/isaaclab_arena/locomanipulation_tutorial/checkpoint-20000`
   - Size: ~17GB

4. **Policy Evaluation** ✅
   - Run in GR00T container
   - Command: See [Reproduction Instructions](#reproduction-instructions)

### Environment Variables

```bash
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
```

### GR00T Evaluation Command

```bash
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \
  --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
  --num_steps 1200 \
  --enable_cameras \
  galileo_g1_locomanip_pick_and_place \
  --object brown_box \
  --embodiment g1_wbc_joint
```

**Expected Output:**
- Progress bar: `100%|██████████| 1200/1200 [01:35<00:00, 12.53it/s]`
- Metrics at end: `{success_rate: 1.0, num_episodes: 1}`
- No errors

---

## File Structure and Key Files

### Critical Files (Must Understand)

1. **`isaaclab_arena/examples/policy_runner.py`**
   - Main script for GR00T evaluation
   - Contains pinocchio fix (lines 6-27)
   - Handles policy loading and execution

2. **`docker/Dockerfile.isaaclab_arena`**
   - Base container definition
   - Contains dependency installation fixes

3. **`docker/run_docker.sh`**
   - Container management script
   - Handles container name conflicts

4. **`docker/setup/entrypoint.sh`**
   - Container entrypoint
   - Sets up PYTHONPATH

5. **`isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml`**
   - GR00T policy configuration
   - Defines model path, observation/action spaces

### Documentation Files

- `FIXES.md` - All bugs and fixes
- `WORKFLOW_STATUS.md` - Workflow progress tracking
- `COMPLETE_G1_WORKFLOW_GUIDE.md` - Complete user guide
- `README_G1_WORKFLOW.md` - Quick start guide
- `G1_SYSTEM_ARCHITECTURE.md` - Technical architecture
- `AI_AGENT_MEMORY.md` - This file

### Scripts

- `run_groot_eval.sh` - Quick evaluation script
- `quick_start_groot.sh` - Automated setup script

---

## Common Errors and Solutions

### Error: `AttributeError: module 'pinocchio' has no attribute 'Model'`

**Solution:** Ensure pinocchio is imported at module level before `SimulationAppContext`. For `policy_runner.py`, use the full `sys.path`/`sys.modules` manipulation.

**Check:**
```python
import pinocchio
print(pinocchio.__file__)  # Should point to cmeel.prefix path
print(hasattr(pinocchio, 'Model'))  # Should be True
```

---

### Error: `ModuleNotFoundError: No module named 'isaaclab'`

**Solution:** 
1. Check `PYTHONPATH` is set correctly
2. Ensure you're using `/isaac-sim/python.sh`
3. Verify entrypoint script sets PYTHONPATH

**Check:**
```bash
echo $PYTHONPATH
# Should include: ${ISAACLAB_PATH}/source/isaaclab:...
```

---

### Error: `docker: Error response from daemon: Conflict. The container name...`

**Solution:** Remove existing container:
```bash
docker stop <container_name> 2>/dev/null || true
docker rm <container_name> 2>/dev/null || true
```

---

### Error: `flatdict` build fails

**Solution:** Use `--no-build-isolation` flag:
```bash
pip install --no-build-isolation flatdict==4.0.1
```

---

## Reproduction Instructions

### On a New PC

1. **Extract the archive:**
   ```bash
   unzip isaaclab_arena_g1_work.zip
   cd isaaclab_arena_g1_work
   ```

2. **Read this document first:**
   - Understand the pinocchio fix (Bug #1)
   - Review Docker setup
   - Check prerequisites

3. **Build Docker containers:**
   ```bash
   # Base container
   ./docker/run_docker.sh -r
   
   # GR00T container (takes 30-60 minutes)
   ./docker/run_docker.sh -g
   ```

4. **Set up environment:**
   ```bash
   # Inside GR00T container
   export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
   export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
   
   # Download dataset
   hf download nvidia/Arena-G1-Loco-Manipulation-Task \
     arena_g1_loco_manipulation_dataset_generated_small.hdf5 \
     --repo-type dataset \
     --local-dir $DATASET_DIR
   
   # Download model
   hf download nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation \
     --local-dir $MODELS_DIR/checkpoint-20000
   ```

5. **Run evaluation:**
   ```bash
   ./run_groot_eval.sh
   # OR manually:
   /isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
     --policy_type gr00t_closedloop \
     --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
     --num_steps 1200 \
     --enable_cameras \
     galileo_g1_locomanip_pick_and_place \
     --object brown_box \
     --embodiment g1_wbc_joint
   ```

### Prerequisites

- **Docker** installed and running
- **NVIDIA GPU** with CUDA support
- **NVIDIA Container Toolkit** installed
- **HuggingFace CLI** (`hf`) installed and logged in
- **Disk space:** At least 100GB free (for containers, models, datasets)

---

## Technical Deep Dive

### Pinocchio Version Conflict Resolution

**The Problem:**
- Isaac Sim bundles `pinocchio` at: `/isaac-sim/kit/python/lib/python3.11/site-packages/pinocchio/`
- `pin-pink` installs `pinocchio` at: `/isaac-sim/kit/python/lib/python3.11/site-packages/cmeel.prefix/lib/python3.11/site-packages/pinocchio/`
- Python's import system loads the first one it finds
- Isaac Sim's version is incomplete (no `Model` attribute)

**The Solution:**
1. Manipulate `sys.path` to prioritize `pin-pink`'s path
2. Clear `sys.modules` to remove any cached wrong version
3. Import at module level before Isaac Sim initializes
4. Verify the correct version is loaded

**Why Module Level:**
- Python imports happen when the module is first loaded
- `SimulationAppContext` initializes Isaac Sim, which may trigger imports
- Module-level code runs before any function calls
- Ensures pinocchio is loaded before Isaac Sim can interfere

### Docker Container Architecture

**Base Container:**
- Extends `nvcr.io/nvidia/isaac-sim:5.0.0`
- Installs Isaac Lab 2.3.0
- Installs missing dependencies
- Sets up PYTHONPATH

**GR00T Container:**
- Extends base container
- Adds CUDA 12.8
- Installs GR00T dependencies (flash-attn, transformers, etc.)
- Includes GR00T codebase from submodules

**Volume Mounts:**
- `/workspaces/isaaclab_arena` - Source code
- `/datasets` - Datasets (persistent)
- `/models` - Models (persistent)

### GR00T Policy Architecture

**Model:**
- Base: `nvidia/GR00T-N1.5-3B` (3 billion parameters)
- Fine-tuned: `nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation`
- Format: HuggingFace safetensors

**Inference:**
- Input: Camera observations (RGB images)
- Output: Joint actions (29 DOF for G1)
- Control frequency: 50Hz
- Policy type: `gr00t_closedloop`

**Configuration:**
- Config file: `isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml`
- Defines: Model path, observation spaces, action spaces, device

---

## Key Takeaways for AI Agents

1. **ALWAYS import pinocchio before SimulationAppContext** - This is the most critical fix
2. **Use `/isaac-sim/python.sh`** - Never use system python
3. **Check PYTHONPATH** - Must include all IsaacLab source directories
4. **GR00T requires GR00T container** - Base container won't work for policy evaluation
5. **Pinocchio path:** `/isaac-sim/kit/python/lib/python3.11/site-packages/cmeel.prefix/lib/python3.11/site-packages`
6. **Verify pinocchio:** Always check `hasattr(pinocchio, 'Model')` after import
7. **Docker containers:** Remove existing containers before creating new ones
8. **Dependencies:** Some require special flags (`flatdict` needs `--no-build-isolation`)

---

## Verification Checklist

Before considering the setup complete, verify:

- [ ] Pinocchio has `Model` attribute: `hasattr(pinocchio, 'Model') == True`
- [ ] Pinocchio path points to `cmeel.prefix`: Check `pinocchio.__file__`
- [ ] PYTHONPATH includes all IsaacLab directories
- [ ] GR00T container builds successfully
- [ ] Dataset downloaded and accessible
- [ ] Model downloaded and accessible
- [ ] GR00T evaluation runs without errors
- [ ] Progress bar completes 1200/1200 steps
- [ ] Metrics are printed at the end

---

## References

- **Official Release:** https://github.com/isaac-sim/IsaacLab-Arena/tree/release/0.1.1
- **Documentation:** https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/index.html
- **G1 Tutorial:** https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/pages/example_workflows/locomanipulation/index.html
- **Dataset:** https://huggingface.co/datasets/nvidia/Arena-G1-Loco-Manipulation-Task
- **Model:** https://huggingface.co/nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation

---

## Contact and Support

If you encounter issues not covered in this document:

1. Check `FIXES.md` for all known fixes
2. Review `COMPLETE_G1_WORKFLOW_GUIDE.md` for detailed workflow
3. Check Isaac Lab Arena documentation
4. Review error messages carefully - most issues are import order related

---

**Last Updated:** February 2025  
**Status:** ✅ All systems operational  
**GR00T Evaluation:** ✅ Successfully completed 1200 steps
