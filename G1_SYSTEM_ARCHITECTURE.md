# G1 Loco-Manipulation System Architecture - Deep Dive

**For beginners:** Start with `COMPLETE_G1_WORKFLOW_GUIDE.md` for step-by-step instructions.  
This document provides technical details for advanced users.

## Overview

This document provides a comprehensive understanding of the G1 Loco-Manipulation system in Isaac Lab Arena, based on release 0.1.1 documentation and codebase analysis.

## System Components

### 1. G1 Robot Model (`isaaclab_arena_g1/g1_env/robot_model.py`)

**Purpose:** Encapsulates the G1 robot's kinematic and dynamic properties using Pinocchio.

**Key Features:**
- Uses Pinocchio's `RobotWrapper` for URDF-based robot model
- Supports floating base configuration (for world-space movement)
- Maintains joint ordering via `loco_manip_g1_joints_order_43dof.yaml`
- Stores supplemental info (joint limits, groups, mappings)

**Joint Configuration:**
- **43 DOF total:** 29 body joints + 14 hand joints
- **Body joints:** Legs (12), Waist (3), Arms (14)
- **Hand joints:** 7 per hand (thumb, index, middle)

### 2. Whole-Body Controller (WBC) Architecture

The G1 uses a **decoupled WBC** approach:

#### 2.1 Lower Body Policy (`G1HomiePolicyV2`)
- **Type:** Neural network-based locomotion policy (ONNX)
- **Models:** Two policies loaded:
  - `stand.onnx`: Standing/idle behavior
  - `walk.onnx`: Walking/locomotion behavior
- **Input:** Joint positions, velocities, navigation commands
- **Output:** Target joint positions for lower body (legs + waist)
- **Policy Selection:** Based on command magnitude (< 0.05 → stand, else → walk)

#### 2.2 Upper Body Control

**Two Modes:**

1. **`g1_wbc_joint`** (Used in GR00T inference):
   - Direct joint position control
   - GR00T outputs joint positions directly
   - No IK solving needed
   - Used for closed-loop policy evaluation

2. **`g1_wbc_pink`** (Used in data generation/teleoperation):
   - PINK (Pinocchio Inverse Kinematics) controller
   - Converts end-effector poses to joint positions
   - Used during teleoperation where human provides end-effector targets
   - Single environment only (IK solver limitation)

#### 2.3 Decoupled WBC Policy (`G1DecoupledWholeBodyPolicy`)
- **Architecture:** Combines upper and lower body policies
- **Upper body:** Pass-through (IdentityPolicy) or PINK IK
- **Lower body:** Homie V2 neural network policy
- **Coordination:** Synchronizes both policies to produce unified action

### 3. Action Spaces

#### 3.1 `G1DecoupledWBCJointAction`
- **Action Dim:** 50 DOF
  - 43 joint positions (body + hands)
  - 3 navigation commands (lin_vel_x, lin_vel_y, ang_vel)
  - 1 base height command
  - 3 torso orientation RPY commands
- **Usage:** GR00T closed-loop inference
- **WBC Version:** `homie_v2`

#### 3.2 `G1DecoupledWBCPinkAction`
- **Inherits from:** `G1DecoupledWBCJointAction`
- **Additional:** PINK IK controller for upper body
- **Navigation:** P-controller for turning/navigation
- **Usage:** Data generation, teleoperation replay

### 4. GR00T Policy Integration

#### 4.1 Policy Architecture (`Gr00tClosedloopPolicy`)

**Input Processing:**
1. **Camera:** RGB from `robot_head_cam_rgb` (640x480 → resized/padded)
2. **Joint States:** Remapped from sim joint order to GR00T joint order
3. **Language:** Task description ("Pick up the brown box...")

**Joint Remapping:**
- **Policy Joint Config:** `gr00t_43dof_joint_space.yaml` (grouped by body parts)
- **Sim Joint Config:** `43dof_joint_space.yaml` (flat index mapping)
- **Conversion:** `remap_sim_joints_to_policy_joints()` and reverse

**Action Chunking:**
- **Action Horizon:** 16 steps predicted per inference
- **Action Chunk Length:** 16 steps executed (can be < horizon)
- **Mechanism:** 
  - Policy predicts 16 future actions in one forward pass
  - Actions executed sequentially from chunk
  - New chunk computed when current chunk exhausted

**Output Processing:**
- GR00T outputs 32-dim action (upper body joints only)
- Remapped to sim joint space
- Combined with WBC commands (navigation, base height, torso orientation)
- Final action: 50-dim tensor

#### 4.2 Joint Configuration Files

**`gr00t_43dof_joint_space.yaml`:**
- Grouped structure (left_leg, right_leg, waist, left_arm, etc.)
- Used by GR00T policy (input/output format)
- Organized by body part for semantic understanding

**`43dof_joint_space.yaml`:**
- Flat index mapping (joint_name → index)
- Used by simulation (action/state space)
- Total: 43 joints

### 5. Observation Spaces

#### 5.1 Policy Observations (`G1WBCJointObservationsCfg.PolicyCfg`)
- `actions`: Last executed action (50-dim)
- `robot_joint_pos`: Current joint positions (43-dim)
- `robot_joint_vel`: Current joint velocities (43-dim)
- `right_wrist_pose_pelvis_frame`: Right wrist pose relative to pelvis (4x4 matrix)
- `left_wrist_pose_pelvis_frame`: Left wrist pose relative to pelvis (4x4 matrix)
- `camera_obs.robot_head_cam_rgb`: RGB image (480x640x3)

#### 5.2 WBC Observations (`G1WBCJointObservationsCfg.WBCObsCfg`)
- Similar to policy obs but without camera
- Used by lower body WBC policy

### 6. Task Configuration

**Task:** `galileo_g1_locomanip_pick_and_place`

**Scene:**
- Galileo lab environment
- Brown box on shelf
- Blue sorting bin on table

**Success Criteria:**
- Brown box placed in blue bin
- Proximity check: max_x=0.26m, max_y=0.13m, max_z=0.15m

**Termination:**
- Success: Object in bin
- Timeout: 30 seconds
- Object dropped: Box height < -0.6m

### 7. Data Flow

#### 7.1 Training Data Generation
1. **Teleoperation:** Human provides end-effector poses (PINK IK)
2. **Recording:** Actions, observations, camera frames saved to HDF5
3. **Mimic Generation:** Isaac Lab Mimic generates diverse trajectories
4. **Format:** HDF5 → LeRobot format (parquet + videos)

#### 7.2 Policy Inference Flow
```
Camera RGB → Resize/Pad → GR00T Policy
Joint States → Remap → GR00T Policy
Language Instruction → GR00T Policy
                    ↓
GR00T Output (32-dim) → Remap to Sim → Combine with WBC Commands
                    ↓
Action (50-dim) → G1DecoupledWBCJointAction
                    ↓
Upper Body: Direct Joint Control
Lower Body: Homie V2 Policy (stand/walk)
                    ↓
Robot Execution
```

### 8. Key Differences: `g1_wbc_joint` vs `g1_wbc_pink`

| Aspect | `g1_wbc_joint` | `g1_wbc_pink` |
|--------|----------------|---------------|
| **Upper Body Control** | Direct joint positions | PINK IK (end-effector → joints) |
| **Usage** | GR00T inference | Teleoperation, data generation |
| **Input** | Joint positions from policy | End-effector poses from teleop |
| **IK Solver** | Not used | PINK IK controller |
| **Multi-env Support** | Yes | No (single env only) |
| **Navigation** | WBC policy handles | P-controller |

### 9. File Locations

**Data (Moved to Project Directory):**
- `data/datasets/isaaclab_arena/locomanipulation_tutorial/`
  - `arena_g1_loco_manipulation_dataset_generated_small.hdf5` (220MB)
  - `arena_g1_loco_manipulation_dataset_annotated.hdf5` (205MB)
- `data/models/isaaclab_arena/locomanipulation_tutorial/checkpoint-20000/` (17GB)
  - GR00T N1.5 pre-trained model

**Configuration:**
- `isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml`
- `isaaclab_arena_gr00t/config/g1/gr00t_43dof_joint_space.yaml`
- `isaaclab_arena_gr00t/config/g1/43dof_joint_space.yaml`

**Code:**
- `isaaclab_arena_g1/`: G1 robot model, WBC policies, actions
- `isaaclab_arena_gr00t/`: GR00T policy integration
- `isaaclab_arena/examples/policy_runner.py`: Main evaluation script

### 10. Running the System

#### 10.1 Environment Setup
```bash
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial
```

#### 10.2 Single Environment Evaluation
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

#### 10.3 Parallel Environments
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

### 11. Technical Details

#### 11.1 Action Chunking Mechanism
- **Purpose:** Reduce inference frequency (predict 16 steps, execute sequentially)
- **Implementation:** 
  - `current_action_chunk`: Stores predicted actions (num_envs, 16, 50)
  - `current_action_index`: Points to current action in chunk
  - `env_requires_new_action_chunk`: Flag for new inference
- **Reset:** On episode termination/truncation

#### 11.2 Joint Remapping
- **Why:** GR00T uses semantic grouping, sim uses flat indexing
- **Functions:**
  - `remap_sim_joints_to_policy_joints()`: Sim → GR00T format
  - `remap_policy_joints_to_sim_joints()`: GR00T → Sim format
- **Configs:** YAML files define mappings

#### 11.3 WBC Command Integration
- **Navigation:** 3D vector (lin_vel_x, lin_vel_y, ang_vel)
- **Base Height:** 1D scalar (target pelvis height)
- **Torso Orientation:** 3D RPY (roll, pitch, yaw)
- **Note:** Torso orientation manually set to 0 in GR00T output

### 12. References

- [Official Documentation](https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/pages/example_workflows/locomanipulation/index.html)
- [Step 4: Evaluation](https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/pages/example_workflows/locomanipulation/step_4_evaluation.html)
- Dataset: [nvidia/Arena-G1-Loco-Manipulation-Task](https://huggingface.co/datasets/nvidia/Arena-G1-Loco-Manipulation-Task)
- Model: [nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation](https://huggingface.co/nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation)

## Summary

The G1 Loco-Manipulation system is a sophisticated integration of:
1. **GR00T N1.5:** Vision-language-action foundation model for high-level planning
2. **Decoupled WBC:** Combines neural locomotion (lower body) with direct control (upper body)
3. **Action Chunking:** Efficient inference by predicting multiple steps ahead
4. **Joint Remapping:** Seamless translation between GR00T's semantic space and simulation's flat space

The system demonstrates state-of-the-art humanoid robot control for complex loco-manipulation tasks requiring full-body coordination.
