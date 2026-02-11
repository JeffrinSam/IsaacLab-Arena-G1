#!/bin/bash
# Helper script to push to JeffrinSam's repository
# Usage: ./push_to_my_repo.sh <REPO_NAME> [branch]
# Example: ./push_to_my_repo.sh IsaacLab-Arena-G1 release/0.1.1

set -euo pipefail

REPO_NAME="${1:-}"
BRANCH="${2:-release/0.1.1}"

if [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <REPO_NAME> [branch]"
    echo ""
    echo "Examples:"
    echo "  $0 IsaacLab-Arena-G1"
    echo "  $0 IsaacLab-Arena-G1 main"
    echo ""
    echo "Or provide full URL:"
    echo "  git remote add myrepo git@github.com:JeffrinSam/YOUR_REPO.git"
    echo "  git push myrepo $BRANCH"
    exit 1
fi

# Use HTTPS URL (since GitHub CLI is configured for HTTPS)
REPO_URL="https://github.com/JeffrinSam/${REPO_NAME}.git"
# Alternative SSH URL (uncomment if you prefer SSH):
# REPO_URL="git@github.com:JeffrinSam/${REPO_NAME}.git"

echo "=== Pushing to Your Repository ==="
echo ""
echo "Repository: $REPO_URL"
echo "Branch: $BRANCH"
echo ""

# Check if remote already exists
if git remote get-url myrepo >/dev/null 2>&1; then
    echo "Remote 'myrepo' already exists. Updating..."
    git remote set-url myrepo "$REPO_URL"
else
    echo "Adding remote 'myrepo'..."
    git remote add myrepo "$REPO_URL"
fi

echo ""
echo "Pushing to your repository..."
git push myrepo "$BRANCH"

echo ""
echo "✅ Successfully pushed to: $REPO_URL"
echo ""
echo "View your repository at:"
echo "  https://github.com/JeffrinSam/$REPO_NAME"
