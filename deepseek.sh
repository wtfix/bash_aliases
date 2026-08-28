
alias dsh="pnpm --dir $HOME/Projects/deepseek-harness dsh"


alias dsh-update='(cd "$HOME/Projects/deepseek-harness" && git pull origin master && pnpm install && pnpm run build)'


# Function to check and compare local version with upstream GitHub version
dsh-version-check() {
  (
    cd "$HOME/Projects/deepseek-harness" || exit 1
    echo "📡 Fetching updates from GitHub..."
    git fetch --quiet

    # 1. Get local package version from package.json
    LOCAL_VER=$(node -p "require('./package.json').version" 2>/dev/null || echo "Unknown")

    # 2. Get local active git commit hash
    LOCAL_COMMIT=$(git rev-parse --short HEAD)

    # 3. Get remote origin git commit hash (Using 'master' instead of 'main')
    ACTUAL_COMMIT=$(git rev-parse --short origin/master)

    echo "---------------------------------------"
    echo "🔹 Local App Version : $LOCAL_VER"
    echo "💻 Current Commit    : $LOCAL_COMMIT"
    echo "🌐 Actual (Upstream) : $ACTUAL_COMMIT"
    echo "---------------------------------------"

    if [ "$LOCAL_COMMIT" = "$ACTUAL_COMMIT" ]; then
      echo "✅ Excellent! Your local build matches upstream."
    else
      echo "⚠️ Update Available! Type 'dsh-update' to pull modifications."
    fi
  )
}
