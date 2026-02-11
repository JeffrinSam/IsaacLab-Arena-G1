# G1 Loco-Manipulation Workflow - Quick Start

**Welcome!** This is your starting point for running GR00T policy inference on the G1 robot.

## 📚 Documentation Guide

### For Beginners (Start Here!)
👉 **Read:** [`COMPLETE_G1_WORKFLOW_GUIDE.md`](COMPLETE_G1_WORKFLOW_GUIDE.md)
- Step-by-step instructions
- Common errors and solutions
- Everything explained in simple terms
- 988 lines of comprehensive guidance

### For Advanced Users
👉 **Read:** [`G1_SYSTEM_ARCHITECTURE.md`](G1_SYSTEM_ARCHITECTURE.md)
- Technical deep dive
- System architecture details
- Component breakdown

## 🚀 Quick Start

### Option 1: Automated Script (Easiest)

```bash
# Once GR00T container is built, just run:
./quick_start_groot.sh
```

This script will:
- ✅ Check if GR00T container exists
- ✅ Download model if needed
- ✅ Run the evaluation automatically

### Option 2: Manual Steps

```bash
# 1. Start GR00T container
./docker/run_docker.sh -g

# 2. Inside container, set environment variables
export DATASET_DIR=/datasets/isaaclab_arena/locomanipulation_tutorial
export MODELS_DIR=/models/isaaclab_arena/locomanipulation_tutorial

# 3. Download model (if not already done)
hf download nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation \
  --local-dir $MODELS_DIR/checkpoint-20000

# 4. Run evaluation
/isaac-sim/python.sh isaaclab_arena/examples/policy_runner.py \
  --policy_type gr00t_closedloop \
  --policy_config_yaml_path isaaclab_arena_gr00t/g1_locomanip_gr00t_closedloop_config.yaml \
  --num_steps 1200 \
  --enable_cameras \
  galileo_g1_locomanip_pick_and_place \
  --object brown_box \
  --embodiment g1_wbc_joint
```

## ⚠️ Important Notes

1. **GR00T Container Required:** You MUST use `./docker/run_docker.sh -g` (not the base container)
2. **Build Time:** First GR00T container build takes 30-60 minutes
3. **Model Size:** Pre-trained model is 17GB (download takes 10-30 minutes)
4. **GPU Required:** For policy inference (CUDA support needed)

## 📋 Prerequisites Checklist

Before running, ensure:

- [ ] Docker installed with NVIDIA runtime
- [ ] Hugging Face CLI installed and authenticated (`hf auth login`)
- [ ] GR00T container built (`docker images | grep cuda_gr00t`)
- [ ] Pre-trained model downloaded (17GB)
- [ ] Environment variables set (DATASET_DIR, MODELS_DIR)

## 🐛 Common Issues

### "ModuleNotFoundError: No module named 'gr00t'"
**Solution:** You're in the base container. Use `./docker/run_docker.sh -g` instead.

### "Model path does not exist"
**Solution:** Download the model:
```bash
hf download nvidia/GN1x-Tuned-Arena-G1-Loco-Manipulation \
  --local-dir $MODELS_DIR/checkpoint-20000
```

### "CUDA out of memory"
**Solution:** Use `--device cpu` for physics or reduce `--num_envs`

## 📖 Full Documentation

For complete details, see:
- **Complete Guide:** [`COMPLETE_G1_WORKFLOW_GUIDE.md`](COMPLETE_G1_WORKFLOW_GUIDE.md)
- **Technical Details:** [`G1_SYSTEM_ARCHITECTURE.md`](G1_SYSTEM_ARCHITECTURE.md)
- **Official Docs:** https://isaac-sim.github.io/IsaacLab-Arena/release/0.1.1/

## 🎯 Expected Output

When successful, you should see:
- Progress bar: `100%|██████████| 1200/1200 [01:35<00:00, 12.53it/s]`
- No errors (especially no pinocchio errors)
- Metrics: `Metrics: {success_rate: X, num_episodes: Y}`

**✅ Verified Working:**
- GR00T N1.5 policy evaluation completed successfully
- 1200/1200 steps executed without errors
- Performance: ~12-13 steps/second
- Robot successfully performs pick-and-place task

---

**Need Help?** Check `COMPLETE_G1_WORKFLOW_GUIDE.md` for detailed troubleshooting.
