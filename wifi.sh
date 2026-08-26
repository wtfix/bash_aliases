
# @pentest:wifi

# Configuration
local WIFI_INTERFACE_NAME="wlp2s0"
local PASS_THIS_WIFI="PASS_THIS_WIFI"

# Helper Functions
wifi-airodump-by-bssid() { 
    sudo airodump-ng --bssid "$1" -c "$2" -w ~/pentest/capture-"$1"-$(date +%Y%m%d%H%M%S).cap ${WIFI_INTERFACE_NAME}mon 
}

wifi-crack-wpa() {
    sudo aircrack-ng -w "$1" -b "$2" ~/pentest/capture-"$2"-*.cap
}

wifi-show-clients() {
    sudo airodump-ng --bssid "$1" -c "$2" --write /dev/null ${WIFI_INTERFACE_NAME}mon
}

wifi-monitor-clients() {
    sudo airodump-ng --bssid "$1" -c "$2" --write /dev/null ${WIFI_INTERFACE_NAME}mon &
    sleep 5 && sudo aireplay-ng --deauth 5 -a "$1" ${WIFI_INTERFACE_NAME}mon
}

wifite-exclude() {
    if [ -z "$1" ]; then
        echo "Usage: wifite-exclude <BSSID>"
        return 1
    fi
    echo "$1" >> ~/.wifite/exclude_bssid
}

# Monitor Mode Aliases
alias wifi-monitor="sudo airmon-ng start $WIFI_INTERFACE_NAME"
alias wifi-stop-monitor="sudo airmon-ng stop ${WIFI_INTERFACE_NAME}mon"
alias monon="sudo airmon-ng start $WIFI_INTERFACE_NAME"
alias monoff="sudo airmon-ng stop ${WIFI_INTERFACE_NAME}mon"

# Scanning and Capture Aliases
alias wifi-list="sudo airodump-ng ${WIFI_INTERFACE_NAME}mon"
alias wifi-capture-all="sudo airodump-ng -c 6 -w ~/pentest/capture-all ${WIFI_INTERFACE_NAME}mon"
alias ad="sudo airodump-ng --manufacturer --uptime --wps --band abg ${WIFI_INTERFACE_NAME}mon"

# Logging Aliases
alias ad-log="timeout 20 sudo airodump-ng --write /var/log/airodump.log --write-interval=5 --output-format csv --manufacturer --uptime --wps --band abg ${WIFI_INTERFACE_NAME}mon"
alias ad-log-fast="ad-log --write-interval=1"

# Wifite Aliases
alias wfi="sudo wifite -mac -inf --showb --showm -ab -wpat 1000 --nodeauths --skip-crack -p 60 -E $PASS_THIS_WIFI"
alias wifite-init="mkdir -p ~/.wifite/captured ~/.wifite/wordlists && touch ~/.wifite/exclude_bssid && rockyou-download"
alias wifite-exclude-list="cat ~/.wifite/exclude_bssid"
alias wf="sudo wifite --random-mac --infinite"
alias wifite-wps="wf -wps --power 50 --random-mac"
alias wifite-wpa="wf -wpa --power 50 --random-mac"
alias wifite-wep="wf -wep --power 50 --random-mac"
alias wifite-wpa2="wf -wpa2 --power 50 --random-mac"
alias wifite-all="wf -inf --power 45 --random-mac"
alias wifite-all-and-low-power="wf --infinite --random-mac"
alias wifite-all-nodeauths="wifite-all --nodeauths"
alias wifite-all-and-low-power-nodeauths="wifite-all-and-low-power --nodeauths"

# Other Utilities
alias ag="airgraph-ng -g CAPR -i surround.csv -o ~/wifi-surround.png"
alias hc="hashcat -m 2500 "


monitor-mode-support-check() {
    # Check if iw is installed
    if ! command -v iw &> /dev/null; then
        echo "Error: 'iw' command not found. Please install 'iw' package."
        return 1
    fi

    # Get all iw information
    iw_info=$(iw list)

    # List all wireless interfaces
    interfaces=$(echo "$iw_info" | awk '/Wiphy/{print $2}')

    if [ -z "$interfaces" ]; then
        echo "No wireless interfaces found."
        return 1
    fi

    echo "Checking monitor mode support for the following interfaces:"

    while IFS= read -r wiphy; do
        interface=$(iw dev | awk -v wiphy="$wiphy" '$1=="phy#"wiphy{getline; print $2}')
        echo " - $interface (Wiphy $wiphy)"

        # Check for monitor mode support
        if echo "$iw_info" | awk -v wiphy="$wiphy" '/Wiphy/{f=0} $0~"Wiphy "wiphy{f=1} f' | grep -q "* monitor"; then
            echo "   Monitor mode is supported on $interface."
        else
            echo "   Monitor mode is NOT supported on $interface."
        fi
    done <<< "$interfaces"
}
