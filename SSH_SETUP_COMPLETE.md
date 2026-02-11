# SSH Setup for GitHub - Complete Guide

## ✅ Current Status

Your SSH is working, but it's authenticating as **khang123452** instead of **JeffrinSam**.

## Option 1: Add SSH Key to JeffrinSam Account (Recommended)

### Step 1: Get Your Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output (starts with `ssh-ed25519`)

### Step 2: Add to JeffrinSam GitHub Account

1. **Login to GitHub as JeffrinSam:**
   - Go to: https://github.com/login
   - Login with **JeffrinSam** credentials

2. **Add SSH Key:**
   - Go to: https://github.com/settings/keys
   - Click **"New SSH key"**
   - **Title:** `My Computer` (or any name)
   - **Key:** Paste the public key you copied
   - Click **"Add SSH key"**

### Step 3: Test Connection

```bash
ssh -T git@github.com
```

Should now show: `Hi JeffrinSam! You've successfully authenticated...`

## Option 2: Use Current Account (khang123452)

If you want to use the current account, just create the repo under that account and push:

```bash
# After creating repo, push with:
./push_to_my_repo.sh REPO_NAME
```

But update the script to use `khang123452` instead of `JeffrinSam` in the URL.

## Quick Commands

### After SSH is set up for JeffrinSam:

1. **Create repository on GitHub:**
   - Go to: https://github.com/new
   - Name: `IsaacLab-Arena-G1`
   - Don't check any boxes
   - Create

2. **Push using SSH:**
   ```bash
   ./push_to_my_repo.sh IsaacLab-Arena-G1
   ```

   This will automatically use SSH: `git@github.com:JeffrinSam/IsaacLab-Arena-G1.git`

### Manual SSH Push:

```bash
# Add remote with SSH
git remote add myrepo git@github.com:JeffrinSam/REPO_NAME.git

# Push
git push -u myrepo release/0.1.1
```

## Benefits of SSH

✅ **No password needed** - Uses key authentication
✅ **More secure** - Public key cryptography
✅ **Faster** - No credential prompts
✅ **Works with 2FA** - No token needed

## Troubleshooting

### If SSH doesn't work:

1. **Check if key is added:**
   ```bash
   ssh -T git@github.com
   ```

2. **Check which account:**
   The output shows which account the key is associated with

3. **Add key to correct account:**
   - Login to the account you want to use
   - Go to: https://github.com/settings/keys
   - Add the public key

### Switch between accounts:

If you have multiple GitHub accounts, you can configure SSH to use different keys:

```bash
# Edit SSH config
nano ~/.ssh/config

# Add:
Host github.com-jeffrin
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_jeffrin

# Then use:
git remote add myrepo git@github.com-jeffrin:JeffrinSam/REPO_NAME.git
```
