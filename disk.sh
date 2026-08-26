#!/bin/bash

# Show disk usage in human-readable format, excluding snapd snapshots
#alias df="df -h | grep -v snapd"
alias df='df -h | grep -v -e snapd -e "/run/credentials"'

# Disk usage
dush()
{
    du -sh $1 | sort -h
}
alias du-sh="dush"


# Disk usage top
dutop() {
    max_depth=${2:-1}
    count=${3:-20}
    du -ah "$1" --max-depth="$max_depth" | sort -rh | head -n "$count"
}
alias du-top="dutop"
