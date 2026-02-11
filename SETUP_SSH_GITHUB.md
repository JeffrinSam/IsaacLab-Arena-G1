# Setup SSH Key for GitHub

## Step 1: Check if you have SSH keys

```bash
ls -la ~/.ssh/id_*.pub
```

If you see files like `id_rsa.pub` or `id_ed25519.pub`, you have keys. Skip to Step 3.

## Step 2: Generate SSH Key (if you don't have one)

```bash
# Generate a new SSH key (use your GitHub email)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or if ed25519 is not supported:
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

**When prompted:**
- Press Enter to accept default file location (`~/.ssh/id_ed25519`)
- Enter a passphrase (optional but recommended) or press Enter for no passphrase

## Step 3: Add SSH Key to SSH Agent

```bash
# Start the ssh-agent
eval "$(ssh-agent -s)"

# Add your SSH key
ssh-add ~/.ssh/id_ed25519
# Or if you used RSA:
# ssh-add ~/.ssh/id_rsa
```

## Step 4: Copy Your Public Key

```bash
# Display and copy your public key
cat ~/.ssh/id_ed25519.pub
# Or if you used RSA:
# cat ~/.ssh/id_rsa.pub
```

**Copy the entire output** (starts with `ssh-ed25519` or `ssh-rsa`)

## Step 5: Add SSH Key to GitHub

1. Go to: **https://github.com/settings/keys**
2. Click **"New SSH key"**
3. Fill in:
   - **Title:** `My Computer` (or any name you like)
   - **Key:** Paste the public key you copied
4. Click **"Add SSH key"**

## Step 6: Test SSH Connection

```bash
ssh -T git@github.com
```

You should see:
```
Hi JeffrinSam! You've successfully authenticated, but GitHub does not provide shell access.
```

## Step 7: Use SSH URL for Git Remote

Once SSH is set up, use SSH URL instead of HTTPS:

```bash
# Add remote with SSH
git remote add myrepo git@github.com:JeffrinSam/REPO_NAME.git

# Push
git push -u myrepo release/0.1.1
```

## Quick Setup Script

I can create a script to help you set this up. Would you like me to?
