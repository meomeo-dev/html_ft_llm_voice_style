#!/usr/bin/env bash
set -euo pipefail

# One-shot deploy to GitHub Pages via Actions.
# - Initializes git repo (default branch main) if missing
# - Commits current changes
# - Creates GitHub repo (public by default) if origin is absent
# - Pushes to origin and prints probable Pages URL

DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
VISIBILITY=${VISIBILITY:-public} # public|private|internal (org only)
COMMIT_MSG=${COMMIT_MSG:-"chore: setup GitHub Pages deployment"}

usage() {
  cat <<EOF
Usage: $0 [--private|--public] [--branch <name>] [--message <msg>]
Env:  DEFAULT_BRANCH=main  VISIBILITY=public  COMMIT_MSG="message"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --private) VISIBILITY=private; shift ;;
    --public) VISIBILITY=public; shift ;;
    --branch) DEFAULT_BRANCH="$2"; shift 2 ;;
    --message|-m) COMMIT_MSG="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 127; }; }
need git
if ! command -v gh >/dev/null 2>&1; then
  echo "Warning: GitHub CLI 'gh' not found. You can still commit/push to an existing origin."
fi

REPO_DIR="$PWD"
REPO_NAME=$(basename "$REPO_DIR")
OWNER=$(gh api user -q .login 2>/dev/null || echo "")

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Initializing git repo on branch $DEFAULT_BRANCH..."
  git init -b "$DEFAULT_BRANCH"
fi

current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
if [[ -n "$current_branch" && "$current_branch" != "$DEFAULT_BRANCH" ]]; then
  echo "Switching branch to $DEFAULT_BRANCH (was: $current_branch)"
  git branch -M "$DEFAULT_BRANCH"
fi

echo "Staging all changes..."
git add -A
if git diff --cached --quiet; then
  echo "No staged changes."
else
  git commit -m "$COMMIT_MSG"
fi

if ! git remote | grep -q '^origin$'; then
  if command -v gh >/dev/null 2>&1; then
    # If repo exists on GitHub, wire up origin instead of creating
    TARGET_REPO="$REPO_NAME"
    [[ -n "$OWNER" ]] && TARGET_REPO="$OWNER/$REPO_NAME"
    if gh repo view "$TARGET_REPO" >/dev/null 2>&1; then
      echo "Existing GitHub repo detected: $TARGET_REPO"
      # Prefer HTTPS origin for portability
      ORIGIN_URL="https://github.com/${TARGET_REPO}.git"
      git remote add origin "$ORIGIN_URL"
      echo "Pushing to origin..."
      git push -u origin "$DEFAULT_BRANCH"
    else
      echo "Creating GitHub repo ($VISIBILITY) and pushing..."
      if [[ -n "$OWNER" ]]; then
        gh repo create "$OWNER/$REPO_NAME" --$VISIBILITY --source=. --remote=origin --push -y \
          --description "AI 对话风格调优器 - GitHub Pages"
      else
        gh repo create "$REPO_NAME" --$VISIBILITY --source=. --remote=origin --push -y \
          --description "AI 对话风格调优器 - GitHub Pages"
      fi
    fi
  else
    echo "No origin and 'gh' missing. Please add a remote manually, e.g.:"
    echo "  git remote add origin git@github.com:<owner>/$REPO_NAME.git"
    echo "Then run: git push -u origin $DEFAULT_BRANCH"
    exit 2
  fi
else
  echo "Pushing to existing origin..."
  git push -u origin "$DEFAULT_BRANCH"
fi

if [[ -n "$OWNER" ]]; then
  echo "Possible Pages URL: https://$OWNER.github.io/$REPO_NAME/"
fi

echo "Done. If Actions is enabled, Pages will deploy automatically."
