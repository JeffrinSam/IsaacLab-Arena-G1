# IsaacLab-Arena Test Fixes - Release 0.1.1

## Summary

This document describes the fixes applied to resolve test failures in IsaacLab-Arena release 0.1.1. All fixes align with the official release documentation and repository structure.

## Issues Fixed

### 1. Missing Python Dependencies

**Problem:** After running `isaaclab.sh -i`, several required dependencies were not installed, causing `ModuleNotFoundError` for:
- `isaaclab` module
- `warp` module  
- `pinocchio` module
- `einops`, `flaky`, `flatdict`, `hidapi`, `junitparser`, `pin-pink`, `prettytable`, `pyglet`, `pytest-mock`, `transformers`, `gymnasium`, `dex-retargeting`

**Root Cause:** The `isaaclab.sh -i` command installs packages, but some dependencies (especially `flatdict`) fail to build due to missing build dependencies.

**Solution:** Added explicit dependency installation in `docker/Dockerfile.isaaclab_arena` after `isaaclab.sh -i` runs.

**Files Modified:**
- `docker/Dockerfile.isaaclab_arena` (lines 46-62)

**Changes:**
```dockerfile
# Install missing dependencies that isaaclab.sh -i may not install correctly
# Note: flatdict needs --no-build-isolation to build properly
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

### 2. Pinocchio Import Order Issue

**Problem:** Tests with cameras and GR00T policy evaluation failed with `module 'pinocchio' has no attribute 'Model'` error.

**Root Cause:** Pinocchio must be imported **before** `AppLauncher` or `SimulationAppContext` is called to ensure the correct version (from `pin-pink`) is used instead of any version bundled with Isaac Sim. Isaac Sim loads its own pinocchio version during initialization, which conflicts with the required `pin-pink` version.

**Solution:** 
1. Added early `import pinocchio` statements in test files that use cameras.
2. For `policy_runner.py`, implemented a more robust solution that manipulates `sys.path` and `sys.modules` to force the correct pinocchio version.

**Files Modified:**
- `isaaclab_arena/tests/test_g1_wbc_embodiment.py` (line 8)
- `isaaclab_arena/tests/test_camera_observation.py` (line 8)
- `isaaclab_arena/examples/policy_runner.py` (lines 6-27)

**Changes:**

For test files:
```python
# Import pinocchio before AppLauncher to force the use of the version installed by IsaacLab
# pinocchio is required by the Pink IK controller
import pinocchio  # noqa: F401
```

For `policy_runner.py` (more robust solution):
```python
# Import pinocchio from pin-pink BEFORE any other imports
# pin-pink installs pinocchio to cmeel.prefix, which has the Model attribute
# This must happen at module level to ensure it's loaded before Isaac Sim can interfere
import sys
pin_pink_pinocchio_path = "/isaac-sim/kit/python/lib/python3.11/site-packages/cmeel.prefix/lib/python3.11/site-packages"
if pin_pink_pinocchio_path not in sys.path:
    sys.path.insert(0, pin_pink_pinocchio_path)
# Remove any existing pinocchio from sys.modules
modules_to_remove = [k for k in list(sys.modules.keys()) if k.startswith('pinocchio') or k == 'pin']
for mod_name in modules_to_remove:
    if mod_name in sys.modules:
        del sys.modules[mod_name]
# Now import pinocchio - it will use the pin-pink version with Model attribute
import pinocchio  # noqa: F401
pin = pinocchio
sys.modules['pinocchio'] = pinocchio
sys.modules['pin'] = pinocchio
```

### 3. PYTHONPATH Configuration

**Problem:** `isaaclab` module was not found because `PYTHONPATH` was not set correctly.

**Root Cause:** The entrypoint script needed to ensure `PYTHONPATH` includes all IsaacLab source directories.

**Solution:** Updated `docker/setup/entrypoint.sh` to automatically set `PYTHONPATH` in the user's `.bashrc` and pass it as an environment variable.

**Files Modified:**
- `docker/setup/entrypoint.sh` (lines 43-49, 67-72)

**Changes:**
- Added automatic `PYTHONPATH` setup in `.bashrc`
- Passed `PYTHONPATH` as environment variable to commands
- Fixed typo: `/etc/aliasess.bashrc` → `/etc/bash.bashrc`
- Changed `bash -ic` to `bash -c` for non-interactive execution

## Verification

After applying these fixes:

✅ **Tests with cameras:** 3 passed  
✅ **Tests without cameras:** 29 passed  
✅ **Example scripts:** `compile_env_notebook.py` runs successfully  
✅ **GR00T Policy Evaluation:** Successfully completed 1200 steps without pinocchio errors

## Testing

Run the tests to verify everything works:

```bash
# Inside the Docker container
pytest -sv -m with_cameras isaaclab_arena/tests/ --ignore=isaaclab_arena/tests/policy/
pytest -sv -m "not with_cameras" isaaclab_arena/tests/ --ignore=isaaclab_arena/tests/policy/
```

## For Future Rebuilds

The Dockerfile has been updated, so rebuilding with:
```bash
./docker/run_docker.sh -r
```

will automatically include all dependencies. No manual installation needed.

## References

- Official Release: https://github.com/isaac-sim/IsaacLab-Arena/tree/release/0.1.1
- Documentation: https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/index.html

---

## Context for Future LLM Agents

### Project Overview
IsaacLab-Arena is a robotics simulation framework built on NVIDIA Isaac Lab (which runs on Isaac Sim). This is release 0.1.1, which requires:
- Isaac Sim 5.1.0
- Isaac Lab 2.3.0
- Python 3.11
- Docker container installation (no local installation support yet)

### Key Architecture Points
1. **Environment Composition**: Environments are composed from:
   - **Scene**: Physical environment layout (background, objects)
   - **Embodiment**: Robot with sensors, observations, actions
   - **Task**: Goal definition, rewards, terminations

2. **Docker Setup**:
   - Base image: `nvcr.io/nvidia/isaac-sim:5.0.0`
   - Work directory: `/workspaces/isaaclab_arena`
   - Python: Use `/isaac-sim/python.sh` (NOT system python)
   - Entrypoint: `/entrypoint.sh` sets up user, permissions, PYTHONPATH

3. **Critical Import Order**:
   - `pinocchio` MUST be imported BEFORE `AppLauncher` in any script using cameras or Pink IK
   - This ensures the correct version (from `pin-pink`) is used, not Isaac Sim's bundled version

4. **Dependency Installation**:
   - `isaaclab.sh -i` installs packages but may miss some dependencies
   - Always install missing deps explicitly after `isaaclab.sh -i`
   - `flatdict==4.0.1` requires `--no-build-isolation` flag

5. **PYTHONPATH Structure**:
   ```
   ${ISAACLAB_PATH}/source/isaaclab
   ${ISAACLAB_PATH}/source/isaaclab_assets
   ${ISAACLAB_PATH}/source/isaaclab_mimic
   ${ISAACLAB_PATH}/source/isaaclab_rl
   ${ISAACLAB_PATH}/source/isaaclab_tasks
   ```

6. **Common Workflows**:
   - G1 Loco-Manipulation: Uses GR00T N1.5 policy, requires HuggingFace login
   - Test execution: Use `pytest` with markers (`with_cameras`, `not with_cameras`)
   - Example scripts: Located in `isaaclab_arena/examples/` and `isaaclab_arena/scripts/`

### Known Issues & Solutions
- **Issue**: `ModuleNotFoundError: No module named 'isaaclab'` → Fix: Ensure PYTHONPATH is set in entrypoint
- **Issue**: `ModuleNotFoundError: No module named 'warp'` → Fix: Install `warp-lang` explicitly
- **Issue**: `module 'pinocchio' has no attribute 'Model'` → Fix: Import pinocchio before AppLauncher/SimulationAppContext. For `policy_runner.py`, use the sys.path/sys.modules manipulation approach.
- **Issue**: `flatdict` build fails → Fix: Use `--no-build-isolation` flag

### Testing Commands
```bash
# Inside Docker container
pytest -sv -m with_cameras isaaclab_arena/tests/ --ignore=isaaclab_arena/tests/policy/
pytest -sv -m "not with_cameras" isaaclab_arena/tests/ --ignore=isaaclab_arena/tests/policy/
```

### Docker Commands
```bash
# Rebuild image
./docker/run_docker.sh -r

# Start container
./docker/run_docker.sh

# Run with GR00T support
./docker/run_docker.sh -g
```
