#!/usr/bin/env bash

###############################################
# GitHub Connect - First Time Setup & Dashboard
###############################################

set -e

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${GREEN}========================================"
echo -e "  GitHub Connect - First Time Setup"
echo -e "========================================${RESET}"

###############################################
# Check required tools
###############################################

echo "🔧 Checking required tools..."

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found. Install Git first.${RESET}"
    exit 1
fi
echo "✅ Git found: git"

if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not found. Install gh first.${RESET}"
    exit 1
fi
echo "✅ GitHub CLI found: gh"

###############################################
# GitHub Authentication
###############################################

echo
echo "🔐 GitHub authentication"
echo "   This will open a browser window for login if needed."
echo

AUTH_STATUS=$(gh auth status 2>&1 || true)

if [[ "$AUTH_STATUS" == *"Logged in"* ]]; then
    echo "✅ Already authenticated."
else
    echo "⚠️ Not authenticated. Starting 'gh auth login'..."
    gh auth login
fi

echo "🔍 Current auth status:"
gh auth status

###############################################
# SSH Key Setup
###############################################

echo
echo "🔑 SSH key setup"

SSH_KEY="$HOME/.ssh/id_ed25519"

if [[ -f "$SSH_KEY" ]]; then
    echo "✅ SSH key already exists at: $SSH_KEY"
else
    echo "⚠️ No SSH key found. Generating new key..."
    ssh-keygen -t ed25519 -C "github" -f "$SSH_KEY"
    gh ssh-key add "$SSH_KEY.pub" --title "gc"
    echo "✓ Uploaded SSH key to GitHub"
fi

###############################################
# Git Configuration
###############################################

echo
echo "⚙️ Checking basic Git configuration"

if [[ -z "$(git config --global user.name)" ]]; then
    read -p "   Your name (for commits): " NAME
    git config --global user.name "$NAME"
    echo "   ✅ Set user.name to '$NAME'"
fi

if [[ -z "$(git config --global user.email)" ]]; then
    read -p "   Your email (for commits): " EMAIL
    git config --global user.email "$EMAIL"
    echo "   ✅ Set user.email to '$EMAIL'"
fi

###############################################
# Help Menu
###############################################

gc_help() {
    echo
    echo "========================================"
    echo "              GitConnect Help"
    echo "========================================"
    echo
    echo "Available commands:"
    echo
    echo "  gc help        - Show this help menu"
    echo "  help           - Same as gc help"
    echo "  gc link repo   - Link or clone a GitHub repository"
    echo "  exit           - Quit the dashboard"
    echo
    echo "Usage examples:"
    echo "  gc link repo   → Select a repo from your GitHub account"
    echo "  help           → Display all available commands"
    echo
}

###############################################
# Repo Linker Function
###############################################

gc_link_repo() {
    echo
    echo "Fetching your GitHub repositories..."
    REPOS=$(gh repo list --limit 200 --json name --jq '.[].name')

    if [ -z "$REPOS" ]; then
        echo "No repositories found."
        return
    fi

    echo
    echo "Select a GitHub repository to link:"
    echo

    i=1
    declare -A REPO_MAP

    for repo in $REPOS; do
        echo "$i) $repo"
        REPO_MAP[$i]=$repo
        ((i++))
    done

    echo
    read -p "Enter number: " CHOICE

    SELECTED=${REPO_MAP[$CHOICE]}

    if [ -z "$SELECTED" ]; then
        echo "Invalid selection."
        return
    fi

    echo "You selected: $SELECTED"
    echo

    # If folder is empty → clone
    if [ -z "$(ls -A .)" ]; then
        echo "Folder is empty. Cloning repo..."
        gh repo clone "$SELECTED" .
        echo "Repo cloned."
        return
    fi

    # If folder has files → link as remote
    echo "Folder has files. Linking repo as remote origin..."
    git init
    USERNAME=$(gh api user --jq .login)
    git remote add origin "git@github.com:$USERNAME/$SELECTED.git"
    echo "Linked remote origin."
}

###############################################
# Dashboard Loop
###############################################

echo
echo -e "${GREEN}========================================"
echo -e "        GitConnect Dashboard"
echo -e "========================================${RESET}"

while true; do
    echo
    echo "Available commands:"
    echo "  gc help"
    echo "  help"
    echo "  gc link repo"
    echo "  exit"
    echo
    read -p "gitconnect> " CMD

    case "$CMD" in
        "gc help"|"help")
            gc_help
            ;;
        "gc link repo")
            gc_link_repo
            ;;
        "exit")
            echo "Goodbye."
            exit 0
            ;;
        *)
            echo "Unknown command: $CMD"
            ;;
    esac
done
