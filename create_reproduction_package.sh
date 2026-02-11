#!/bin/bash
# Script to create a reproducible package of the IsaacLab-Arena G1 work
# This includes all code, documentation, and fixes needed to reproduce on another PC

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

PACKAGE_NAME="isaaclab_arena_g1_work"
PACKAGE_DIR="${SCRIPT_DIR}/${PACKAGE_NAME}"
ZIP_FILE="${SCRIPT_DIR}/${PACKAGE_NAME}.zip"

echo "=== Creating Reproduction Package ==="
echo ""

# Remove existing package if it exists
if [ -d "$PACKAGE_DIR" ]; then
    echo "Removing existing package directory..."
    rm -rf "$PACKAGE_DIR"
fi

if [ -f "$ZIP_FILE" ]; then
    echo "Removing existing zip file..."
    rm -f "$ZIP_FILE"
fi

echo "Creating package directory..."
mkdir -p "$PACKAGE_DIR"

echo "Copying essential files and directories..."

# Copy source code
echo "  - Source code..."
cp -r isaaclab_arena "$PACKAGE_DIR/"
cp -r isaaclab_arena_g1 "$PACKAGE_DIR/" 2>/dev/null || true
cp -r isaaclab_arena_gr00t "$PACKAGE_DIR/" 2>/dev/null || true

# Copy Docker files
echo "  - Docker configuration..."
cp -r docker "$PACKAGE_DIR/"

# Copy configuration files
echo "  - Configuration files..."
cp setup.py "$PACKAGE_DIR/" 2>/dev/null || true
cp pyproject.toml "$PACKAGE_DIR/" 2>/dev/null || true
cp pytest.ini "$PACKAGE_DIR/" 2>/dev/null || true
cp mypy.ini "$PACKAGE_DIR/" 2>/dev/null || true
cp extension.toml "$PACKAGE_DIR/" 2>/dev/null || true

# Copy documentation
echo "  - Documentation..."
cp FIXES.md "$PACKAGE_DIR/" 2>/dev/null || true
cp WORKFLOW_STATUS.md "$PACKAGE_DIR/" 2>/dev/null || true
cp COMPLETE_G1_WORKFLOW_GUIDE.md "$PACKAGE_DIR/" 2>/dev/null || true
cp README_G1_WORKFLOW.md "$PACKAGE_DIR/" 2>/dev/null || true
cp G1_SYSTEM_ARCHITECTURE.md "$PACKAGE_DIR/" 2>/dev/null || true
cp AI_AGENT_MEMORY.md "$PACKAGE_DIR/" 2>/dev/null || true
cp README.md "$PACKAGE_DIR/" 2>/dev/null || true
cp LICENSE.md "$PACKAGE_DIR/" 2>/dev/null || true
cp CONTRIBUTING.md "$PACKAGE_DIR/" 2>/dev/null || true

# Copy scripts
echo "  - Scripts..."
cp run_groot_eval.sh "$PACKAGE_DIR/" 2>/dev/null || true
cp quick_start_groot.sh "$PACKAGE_DIR/" 2>/dev/null || true

# Copy submodules (if they exist and are small)
echo "  - Submodules (checking size)..."
if [ -d "submodules" ]; then
    # Only copy if submodules directory is reasonable size (< 1GB)
    SUBMODULE_SIZE=$(du -sm submodules 2>/dev/null | cut -f1 || echo "0")
    if [ "$SUBMODULE_SIZE" -lt 1024 ]; then
        cp -r submodules "$PACKAGE_DIR/"
        echo "    Submodules copied (${SUBMODULE_SIZE}MB)"
    else
        echo "    Submodules too large (${SUBMODULE_SIZE}MB), skipping (will need git clone)"
        mkdir -p "$PACKAGE_DIR/submodules"
        echo "# Submodules are too large to include in package" > "$PACKAGE_DIR/submodules/README.md"
        echo "# Run: git submodule update --init --recursive" >> "$PACKAGE_DIR/submodules/README.md"
    fi
fi

# Create README for package
echo "Creating package README..."
cat > "$PACKAGE_DIR/README_PACKAGE.md" << 'EOF'
# IsaacLab-Arena G1 Loco-Manipulation - Reproduction Package

This package contains all the code, documentation, and fixes needed to reproduce the G1 Loco-Manipulation workflow on another PC.

## Quick Start

1. **Read the AI Agent Memory document first:**
   ```bash
   cat AI_AGENT_MEMORY.md
   ```
   This document contains all critical bugs, fixes, and technical information.

2. **Set up submodules (if needed):**
   ```bash
   git submodule update --init --recursive
   ```

3. **Build Docker containers:**
   ```bash
   ./docker/run_docker.sh -r  # Base container
   ./docker/run_docker.sh -g  # GR00T container (30-60 minutes)
   ```

4. **Follow the workflow:**
   - Read `COMPLETE_G1_WORKFLOW_GUIDE.md` for step-by-step instructions
   - Or use `README_G1_WORKFLOW.md` for quick start

## What's Included

- ✅ All source code with fixes applied
- ✅ Docker configuration files
- ✅ All documentation (FIXES.md, workflow guides, etc.)
- ✅ AI Agent Memory document (critical for understanding bugs)
- ✅ Scripts for running evaluation

## What's NOT Included

- ❌ Large datasets (download from HuggingFace)
- ❌ Model checkpoints (download from HuggingFace)
- ❌ Large submodules (clone with git submodule)
- ❌ Docker images (build locally)
- ❌ Python cache files (__pycache__, .pyc)

## Critical Information

**MOST IMPORTANT FIX:** Pinocchio import order issue
- See `AI_AGENT_MEMORY.md` section "Bug #1: Pinocchio Import Order"
- Fixed in `isaaclab_arena/examples/policy_runner.py` (lines 6-27)

**Key Files:**
- `AI_AGENT_MEMORY.md` - Complete context for AI agents
- `FIXES.md` - All bugs and fixes
- `isaaclab_arena/examples/policy_runner.py` - Main evaluation script (contains pinocchio fix)

## Prerequisites

- Docker installed and running
- NVIDIA GPU with CUDA support
- NVIDIA Container Toolkit
- HuggingFace CLI (`hf`) installed and logged in
- At least 100GB free disk space

## Verification

After setup, verify everything works:
```bash
./run_groot_eval.sh
```

Expected: Progress bar completes 1200/1200 steps without errors.

## Support

If you encounter issues:
1. Read `AI_AGENT_MEMORY.md` - it contains solutions to all known bugs
2. Check `FIXES.md` for detailed fix information
3. Review `COMPLETE_G1_WORKFLOW_GUIDE.md` for workflow details
EOF

# Create .gitignore for the package (to exclude unnecessary files)
cat > "$PACKAGE_DIR/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/
dist/
build/

# IDE
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
/tmp/

# Data (too large)
data/
datasets/
models/

# Docker
*.tar

# OS
.DS_Store
Thumbs.db
EOF

# Remove unnecessary files from package
echo "Cleaning up unnecessary files..."
find "$PACKAGE_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$PACKAGE_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true
find "$PACKAGE_DIR" -type f -name "*.pyo" -delete 2>/dev/null || true
find "$PACKAGE_DIR" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

# Create zip file
echo ""
echo "Creating zip archive..."
cd "$SCRIPT_DIR"
zip -r "$ZIP_FILE" "$PACKAGE_NAME" -x "*.git*" "*.pyc" "*__pycache__*" "*.egg-info/*" "*.log" "*.tmp" > /dev/null

# Calculate sizes
PACKAGE_SIZE=$(du -sh "$PACKAGE_DIR" | cut -f1)
ZIP_SIZE=$(du -sh "$ZIP_FILE" | cut -f1)

echo ""
echo "=== Package Created Successfully ==="
echo ""
echo "Package directory: $PACKAGE_DIR ($PACKAGE_SIZE)"
echo "Zip file: $ZIP_FILE ($ZIP_SIZE)"
echo ""
echo "Contents:"
echo "  ✅ Source code (isaaclab_arena, isaaclab_arena_g1, isaaclab_arena_gr00t)"
echo "  ✅ Docker configuration"
echo "  ✅ All documentation (including AI_AGENT_MEMORY.md)"
echo "  ✅ Scripts (run_groot_eval.sh, etc.)"
echo "  ✅ Configuration files"
echo ""
echo "To extract on another PC:"
echo "  unzip $ZIP_FILE"
echo "  cd $PACKAGE_NAME"
echo "  cat AI_AGENT_MEMORY.md  # Read this first!"
echo ""
