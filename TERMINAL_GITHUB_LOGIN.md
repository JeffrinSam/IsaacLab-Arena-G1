# GitHub Login via Terminal

## Step 1: Install GitHub CLI

```bash
sudo apt update
sudo apt install gh
```

## Step 2: Login to GitHub

```bash
gh auth login
```

**Follow the interactive prompts:**

1. **What account do you want to log into?**
   - Choose: `GitHub.com`

2. **What is your preferred protocol for Git operations?**
   - Choose: `SSH` (recommended) or `HTTPS`

3. **How would you like to authenticate GitHub CLI?**
   - Choose: `Login with a web browser` (easiest)
   - Or: `Paste an authentication token` (if you have one)

4. **If you chose "web browser":**
   - Press Enter to open browser
   - Authorize GitHub CLI
   - Come back to terminal

5. **If you chose "token":**
   - Go to: https://github.com/settings/tokens
   - Generate new token (classic)
   - Select scopes: `repo`, `workflow`, `write:packages`
   - Copy token and paste in terminal

## Step 3: Verify Login

```bash
gh auth status
```

Should show your username and authentication status.

## Step 4: Create Repository (via CLI)

Once logged in, you can create the repository:

```bash
gh repo create IsaacLab-Arena-G1 --public --description "IsaacLab-Arena G1 Loco-Manipulation with GR00T N1.5"
```

Or if you want it private:
```bash
gh repo create IsaacLab-Arena-G1 --private --description "IsaacLab-Arena G1 Loco-Manipulation with GR00T N1.5"
```

## Step 5: Push Code

After repository is created:

```bash
# Add remote
git remote add myrepo git@github.com:JeffrinSam/IsaacLab-Arena-G1.git

# Push
git push -u myrepo release/0.1.1
```

Or use the helper script:
```bash
./push_to_my_repo.sh IsaacLab-Arena-G1
```

## Alternative: Just Use SSH (No CLI needed)

If you don't want to install GitHub CLI, you can:

1. **Add SSH key to GitHub via web:**
   - Go to: https://github.com/settings/keys
   - Add your public key: `cat ~/.ssh/id_ed25519.pub`

2. **Test SSH:**
   ```bash
   ssh -T git@github.com
   ```

3. **Create repo on GitHub web interface:**
   - Go to: https://github.com/new

4. **Push using SSH:**
   ```bash
   ./push_to_my_repo.sh REPO_NAME
   ```
