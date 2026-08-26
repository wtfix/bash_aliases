#!/bin/bash

# Cache cleaning aliases

# Package Managers
alias cache-clean-dnf="sudo dnf clean all"
alias cache-clean-flatpak="flatpak uninstall --unused"
alias cache-clean-pip="pip cache purge"
alias cache-clean-npm="npm cache clean --force"
alias cache-clean-yarn="yarn cache clean"
alias cache-clean-composer="composer clear-cache"
alias cache-clean-apt-get="sudo apt-get clean && sudo apt-get autoclean"

# System Caches
alias cache-clean-memory="sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches"
alias cache-clean-logs="sudo journalctl --vacuum-time=10d"
alias cache-clean-temp="sudo rm -rf /tmp/*"
alias cache-clean-thumbnails="rm -rf ~/.cache/thumbnails/*"

# User Cache
alias cache-clean-user="find ~/.cache -type d -mtime +30 -exec rm -rf {} \;"

# Development Tools
alias cache-clean-docker="docker system prune -af --volumes"
alias cache-clean-gradle="rm -rf ~/.gradle/caches"
alias cache-clean-maven="rm -rf ~/.m2/repository"

# Web Browsers
alias cache-clean-firefox="rm -rf ~/.cache/mozilla/firefox/*.default/cache2"
alias cache-clean-chrome="rm -rf ~/.cache/google-chrome"

# All Caches
alias cache-clean-all="
    # Package Managers
    cache-clean-dnf && cache-clean-flatpak && cache-clean-pip && cache-clean-npm && cache-clean-yarn && cache-clean-composer && cache-clean-apt-get &&
    # System Caches
    cache-clean-memory && cache-clean-logs && cache-clean-temp && cache-clean-thumbnails &&
    # User Cache
    cache-clean-user &&
    # Development Tools
    cache-clean-docker && cache-clean-gradle && cache-clean-maven &&
    # Web Browsers
    cache-clean-firefox && cache-clean-chrome
"

# Function to display cache cleanup information
cache-clean-info() {
    echo "Available cache cleanups and their current space usage:"
    echo

    echo "Package Managers:"
    echo "DNF cache: $(du -sh /var/cache/dnf 2>/dev/null || echo "N/A")"
    echo "Flatpak unused: $(flatpak list --runtime --app --show-details | grep "Unused\|Partially unused" | wc -l) packages"
    echo "Pip cache: $(du -sh ~/.cache/pip 2>/dev/null || echo "N/A")"
    echo "NPM cache: $(du -sh ~/.npm 2>/dev/null || echo "N/A")"
    echo "Yarn cache: $(du -sh ~/.yarn/cache 2>/dev/null || echo "N/A")"
    echo "Composer cache: $(du -sh ~/.composer/cache 2>/dev/null || echo "N/A")"
    echo "APT cache: $(du -sh /var/cache/apt 2>/dev/null || echo "N/A")"
    echo

    echo "System Caches:"
    echo "Journal logs: $(du -sh /var/log/journal 2>/dev/null || echo "N/A")"
    echo "Temporary files: $(du -sh /tmp 2>/dev/null || echo "N/A")"
    echo "Thumbnails: $(du -sh ~/.cache/thumbnails 2>/dev/null || echo "N/A")"
    echo

    echo "User Cache:"
    echo "User cache (older than 30 days): $(find ~/.cache -type d -mtime +30 -print0 | du -sh --files0-from=- 2>/dev/null || echo "N/A")"
    echo

    echo "Development Tools:"
    echo "Docker: $(docker system df 2>/dev/null || echo "N/A")"
    echo "Gradle cache: $(du -sh ~/.gradle/caches 2>/dev/null || echo "N/A")"
    echo "Maven repository: $(du -sh ~/.m2/repository 2>/dev/null || echo "N/A")"
    echo

    echo "Web Browsers:"
    echo "Firefox cache: $(du -sh ~/.cache/mozilla/firefox/*.default/cache2 2>/dev/null || echo "N/A")"
    echo "Chrome/Chromium cache: $(du -sh ~/.cache/google-chrome 2>/dev/null || echo "N/A")"
    echo

    echo "To clean up a specific cache, use the corresponding alias."
    echo "Use 'cache-clean-' <TAB> to see all available aliases."
    echo "To clean all caches, use 'cache-clean-all'."
}
