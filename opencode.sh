
alias oc='opencode'

alias oc-root='sudo XDG_CONFIG_HOME=$HOME/.config XDG_DATA_HOME=$HOME/.local/share XDG_STATE_HOME=$HOME/.local/state $(command -v opencode) .'

alias oc-last-sessions="sqlite3 -header -column ~/.local/share/opencode/opencode.db \"SELECT datetime(time_created/1000,'unixepoch','localtime') AS created, datetime(time_updated/1000,'unixepoch','localtime') AS updated, substr(title,1,60) AS title, directory FROM session ORDER BY time_updated DESC LIMIT 20;\""

alias oc-upgrade='brew update && brew upgrade opencode'

alias oc-clear-cache='rm -rf ~/.cache/opencode'
