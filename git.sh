
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

  # 4. Create the remote repository on GitLab and set the remote to 'origin'
  echo "☁️  Creating remote repository on GitLab..."
  glab repo create "$repo_name" --private --remoteName origin

  # 5. Check if the command succeeded
  if [ $? -eq 0 ]; then
    echo "✅ Success! Remote 'origin' is now configured for $repo_name."
    echo "🚀 To push your code, run: git push -u origin HEAD"
  else
    echo "❌ Failed to create the remote repository. Check if the name is already taken." >&2
    return 1
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

