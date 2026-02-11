# Step-by-Step Guide: Create Repository and Push Code

## Step 1: Login to GitHub

### Option A: Using GitHub CLI (if installed)
```bash
gh auth login
```
Follow the prompts to authenticate.

### Option B: Using Web Browser
1. Go to: https://github.com/login
2. Login with your credentials (username: JeffrinSam)

## Step 2: Create Repository

### Option A: Using GitHub CLI (easiest)
Once logged in, I can run:
```bash
gh repo create IsaacLab-Arena-G1 --public --source=. --remote=myrepo --push
```

### Option B: Using Web Interface
1. Go to: https://github.com/new
2. Repository name: `IsaacLab-Arena-G1` (or your preferred name)
3. Description: "IsaacLab-Arena G1 Loco-Manipulation with GR00T N1.5 - Fixed and Documented"
4. Visibility: Choose Public or Private
5. **IMPORTANT:** Do NOT check:
   - ❌ Add a README file
   - ❌ Add .gitignore
   - ❌ Choose a license
   (We already have all these files)
6. Click "Create repository"

## Step 3: Push Code

Once the repository is created, I'll run:
```bash
git remote add myrepo https://github.com/JeffrinSam/IsaacLab-Arena-G1.git
git push -u myrepo release/0.1.1
```

Or if you used a different name, replace `IsaacLab-Arena-G1` with your repository name.

## Quick Commands Summary

After you login and create the repo, tell me the repository name and I'll push it for you!

Or you can run manually:
```bash
# Add remote
git remote add myrepo https://github.com/JeffrinSam/REPO_NAME.git

# Push
git push -u myrepo release/0.1.1
```
