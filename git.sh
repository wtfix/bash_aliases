
glab-init() {
  # 1. Check if glab CLI is installed
  if ! command -v glab &> /dev/null; then
    echo "Error: 'glab' CLI not found. Please install it first." >&2
    return 1
  fi

  # 2. Determine the repository name: use $1 if provided, otherwise use the current folder name
  local repo_name="${1:-$(basename "$(pwd)")}"
  echo "🔧 Creating GitLab repository: $repo_name"

  # 3. Initialize Git if .git directory does not exist
  if [ ! -d ".git" ]; then
    echo "📁 Initializing local Git repository..."
    git init
    # (Optional) Rename default branch to 'main' if your Git defaults to 'master'
    # git branch -M main
  else
    echo "✅ Local Git repository already exists."
  fi

  # 4. Create the remote repository on GitLab and set the remote to 'origin'.
  #    Run glab from inside a fresh temp dir so it cannot create a subdirectory
  #    named $repo_name in the current working directory, then point origin at
  #    the freshly-created remote manually.
  echo "☁️  Creating remote repository on GitLab..."
  local workdir
  workdir="$(mktemp -d)"
  local remote_url
  remote_url="$(cd "$workdir" && glab repo create "$repo_name" --private 2>&1)"
  local glab_status=$?
  if [ $glab_status -ne 0 ]; then
    echo "❌ Failed to create the remote repository. Check if the name is already taken." >&2
    printf '%s\n' "$remote_url" >&2
    rm -rf "$workdir"
    return 1
  fi
  printf '%s\n' "$remote_url"
  # Extract the https URL from glab's "Created project on GitLab: ... - <url>" line
  local extracted
  extracted="$(printf '%s\n' "$remote_url" | grep -oE 'https://[^ ]+' | tail -1)"
  if [ -z "$extracted" ]; then
    echo "❌ Could not parse remote URL from glab output." >&2
    rm -rf "$workdir"
    return 1
  fi
  git remote remove origin 2>/dev/null
  # Prefer SSH if the user has working SSH auth to GitLab, otherwise fall back
  # to the HTTPS URL glab returned. This avoids the ksshaskpass GUI prompt
  # (which can't open in non-interactive sessions) for users with SSH keys.
  local ssh_path="${extracted#https://gitlab.com/}"
  if [ -n "$ssh_path" ] && ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@gitlab.com 2>&1 | grep -q "Welcome to GitLab"; then
    git remote add origin "git@gitlab.com:${ssh_path%.git}.git"
  else
    git remote add origin "$extracted"
  fi
  rm -rf "$workdir"

  # 5. (success path handled inline above)
  #    Note: 'git push' needs a commit to exist. Print the full sequence so
  #    the user copy-pastes the working one.
  if [ -n "${NO_COLOR:-}" ] || ! [ -t 1 ]; then
    # No colors: non-interactive stdout or NO_COLOR is set
    echo "✅ Success! Remote 'origin' is now configured for $repo_name."
    echo "🚀 Run these three commands to push your code:"
    echo "     git add -A"
    echo "     git commit -m \"Initial commit\""
    echo "     git push -u origin HEAD"
  else
    # Bold red for the commands, default for the rest
    local BOLD RED RESET
    BOLD=$(printf '\033[1m')
    RED=$(printf '\033[31m')
    RESET=$(printf '\033[0m')
    echo "✅ Success! Remote 'origin' is now configured for $repo_name."
    echo "🚀 Run these three commands to push your code:"
    echo "     ${BOLD}${RED}git add -A${RESET}"
    echo "     ${BOLD}${RED}git commit -m \"Initial commit\"${RESET}"
    echo "     ${BOLD}${RED}git push -u origin HEAD${RESET}"
  fi
}


glab-init-push-all() {
  # 1. Check if we are inside a Git repository
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "❌ Error: Not inside a Git repository." >&2
    echo "   Please run 'glab-init' first in this directory." >&2
    return 1
  fi

  # 2. Check if the remote 'origin' exists
  if ! git remote get-url origin &> /dev/null; then
    echo "❌ Error: Remote 'origin' not found." >&2
    echo "   Please run 'glab-init' first to set up the remote." >&2
    return 1
  fi

  # 3. Stage all changes (including deletions and untracked files)
  echo "📦 Staging all files..."
  git add -A

  # 4. Check if there is anything to commit
  if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit. Everything is already up to date."
    echo "🚀 Pushing to remote anyway (just in case)..."
    git push -u origin HEAD
    return $?
  fi

  # 5. Commit with a message (use $1 if provided, otherwise use "Initial commit")
  local commit_msg="${1:-Initial commit}"
  echo "✍️  Committing with message: '$commit_msg'"
  git commit -m "$commit_msg"

  # 6. Push and set upstream to the current branch
  echo "🚀 Pushing to remote origin..."
  git push -u origin HEAD

  # 7. Confirm success
  if [ $? -eq 0 ]; then
    echo "✅ All done! Your code is now on GitLab."
  else
    echo "❌ Push failed. Check your network or permissions." >&2
    return 1
  fi
}

