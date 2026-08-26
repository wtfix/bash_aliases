

# Logging function
_log() {
    local msg="$1"
    local level="${2:-$LOG_LEVEL}"
    
    if [[ " ${LOG_LEVELS[@]} " =~ " $level " ]]; then
        case $level in
            ERROR) echo -e "\033[41m$msg\033[0m";;
            WARNING) echo -e "\033[91m$msg\033[0m";;
            INFO) echo -e "\033[93m$msg\033[0m";;
            DEBUG) echo -e "\033[35m$msg\033[0m";;
            *) echo "$msg";;
        esac
    fi
}

