#!/bin/bash

STATE_FILE="$HOME/.gitconnect-setup-complete"

# -------------------------------
# GitHub Dashboard Function
# -------------------------------
github_dashboard() {
    clear
    echo "========================================"
    echo "        GitHub Console Dashboard"
    echo "========================================"
    echo

    # GitHub auth status
    if gh auth status &>/dev/null; then
        GH_STATUS="connected"
    else
        GH_STATUS="not logged in"
    fi

    # Repo + branch
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
        BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    else
        REPO_NAME="—"
        BRANCH_NAME="—"
    fi

    echo "[GitHub: $GH_STATUS] [Repo: $REPO_NAME] [Branch: $BRANCH_NAME]"
    echo
    echo "Type 'exit' to leave dashboard mode."
    echo
}

# -------------------------------
# Interactive Dashboard Loop
# -------------------------------
dashboard_mode() {
    while true; do
        github_dashboard
        read -p "gitconnect> " CMD

        if [ "$CMD" = "exit" ]; then
            echo "Leaving GitHub dashboard."
            exit 0
        fi

        # Run any command the user types
        eval "$CMD"
    done
}

# -------------------------------
# First-Time Setup
# -------------------------------
first_time_setup() {
    echo "🔧 Checking for Git..."
    command -v git >/dev/null || { echo "Git missing"; exit 1; }

    echo "🔧 Checking for GitHub CLI..."
    command -v gh >/dev/null || { echo "GitHub CLI missing"; exit 1; }

    echo "🔐 Logging into GitHub..."
    gh auth login

    echo "🔑 Checking SSH key..."
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        gh ssh-key generate
    fi

    echo "📤 Uploading SSH key..."
    gh ssh-key add ~/.ssh/id_ed25519.pub || true

    echo "⚙️ Setting Git identity..."
    if ! git config --global user.name >/dev/null; then
        read -p "Your name: " NAME
        git config --global user.name "$NAME"
    fi

    if ! git config --global user.email >/dev/null; then
        read -p "Your email: " EMAIL
        git config --global user.email "$EMAIL"
    fi

    echo "✨ Setup complete!"
    touch "$STATE_FILE"
}

# -------------------------------
# Main Logic
# -------------------------------
if [ ! -f "$STATE_FILE" ]; then
    first_time_setup
fi

dashboard_mode
