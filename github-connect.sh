#!/bin/bash
#
# github-connect.sh
# First-time setup tool to connect your Bash console to your GitHub account.
# - Checks for git and gh (GitHub CLI)
# - Logs into GitHub
# - Sets up SSH keys
# - Uploads SSH key to GitHub
# - Optionally creates and links a repo for the current folder

set -e

# ---------- Helpers ----------

print_header() {
    echo "========================================"
    echo "  GitHub Connect - First Time Setup"
    echo "========================================"
    echo
}

require_command() {
    local cmd="$1"
    local name="$2"

    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ $name ($cmd) is not installed."
        echo "   Please install $name and run this script again."
        exit 1
    else
        echo "✅ $name found: $cmd"
    fi
}

# ---------- Start ----------

print_header

echo "🔧 Checking required tools..."
require_command git "Git"
require_command gh "GitHub CLI"
echo

# ---------- GitHub login ----------

echo "🔐 GitHub authentication"
echo "   This will open a browser window for login if needed."
echo

gh auth status &> /dev/null && AUTH_OK=true || AUTH_OK=false

if [ "$AUTH_OK" = true ]; then
    echo "✅ Already authenticated with GitHub."
else
    echo "⚠️ Not authenticated. Starting 'gh auth login'..."
    gh auth login
    echo "✅ Authentication complete."
fi

echo
echo "🔍 Current auth status:"
gh auth status
echo

# ---------- SSH key setup ----------

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_PUB="$HOME/.ssh/id_ed25519.pub"

echo "🔑 SSH key setup"

if [ -f "$SSH_KEY" ] && [ -f "$SSH_PUB" ]; then
    echo "✅ SSH key already exists at: $SSH_KEY"
else
    echo "⚠️ No SSH key found. Generating a new one via GitHub CLI..."
    gh ssh-key generate
    echo "✅ SSH key generated."
fi

echo
echo "📤 Uploading SSH public key to GitHub (if not already added)..."

# Try to add the key; if it fails because it's already added, just continue
if gh ssh-key add "$SSH_PUB" --title "github-connect-$(hostname)" 2>&1 | grep -qi "already exists"; then
    echo "ℹ️ SSH key already registered with GitHub."
else
    echo "✅ SSH key uploaded to GitHub."
fi

echo

# ---------- Git config basics ----------

echo "⚙️ Checking basic Git configuration"

GIT_NAME=$(git config --global user.name || true)
GIT_EMAIL=$(git config --global user.email || true)

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    echo "⚠️ Git user.name and/or user.email not set."
    echo "   Let's configure them now."

    read -p "   Your name (for commits): " NAME_INPUT
    read -p "   Your email (for commits): " EMAIL_INPUT

    if [ -n "$NAME_INPUT" ]; then
        git config --global user.name "$NAME_INPUT"
        echo "   ✅ Set user.name to '$NAME_INPUT'"
    fi

    if [ -n "$EMAIL_INPUT" ]; then
        git config --global user.email "$EMAIL_INPUT"
        echo "   ✅ Set user.email to '$EMAIL_INPUT'"
    fi
else
    echo "✅ Git user.name:  $GIT_NAME"
    echo "✅ Git user.email: $GIT_EMAIL"
fi

echo

# ---------- Repo linking ----------

echo "📦 Repository setup for current folder"
echo "   Current directory: $PWD"
echo

# Check if this folder is already a git repo
if git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "✅ This folder is already a Git repository."

    # Check if remote origin exists
    if git remote get-url origin &> /dev/null; then
        echo "✅ Remote 'origin' already configured:"
        git remote get-url origin
    else
        echo "⚠️ No 'origin' remote configured."
        read -p "   Do you want to create/link a GitHub repo for this folder? (y/n): " CREATE_REMOTE
        if [ "$CREATE_REMOTE" = "y" ]; then
            REPO_NAME=$(basename "$PWD")
            echo "   Creating GitHub repo: $REPO_NAME"
            gh repo create "$REPO_NAME" --source=. --remote=origin --push
            echo "   ✅ GitHub repo created and linked as 'origin'."
        else
            echo "   ℹ️ Skipping remote setup."
        fi
    fi
else
    echo "⚠️ This folder is not yet a Git repository."
    read -p "   Initialize Git and create a GitHub repo for this folder? (y/n): " INIT_AND_CREATE

    if [ "$INIT_AND_CREATE" = "y" ]; then
        echo "   Initializing Git..."
        git init

        echo "   Adding all files and making initial commit..."
        git add .
        git commit -m "Initial commit"

        REPO_NAME=$(basename "$PWD")
        echo "   Creating GitHub repo: $REPO_NAME"
        gh repo create "$REPO_NAME" --source=. --remote=origin --push

        echo "   ✅ Repo initialized, committed, and pushed to GitHub."
    else
        echo "   ℹ️ Skipping repo initialization."
    fi
fi

echo
echo "✨ All done!"
echo "   - Git and GitHub CLI are configured"
echo "   - GitHub authentication is active"
echo "   - SSH keys are set up and registered"
echo "   - This folder is optionally linked to a GitHub repo"
echo
echo "You can now use:"
echo "   git status"
echo "   git add / commit / push"
echo "   gh repo clone / gh pr create / etc."
echo
