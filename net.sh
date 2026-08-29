 #!/bin/bash

# Network-related aliases

# Test internet connection by pinging 1.1.1.1 (Cloudflare's DNS) 5 times
alias pp='ping -c 5 1.1.1.1'

# Display network statistics
# Shows all TCP and UDP connections with numeric addresses and port numbers
# Displays the PID and name of the program to which each socket belongs
alias nn='netstat -anputW'

# Display public IP address using ifconfig.me service
alias myip='curl -s ifconfig.me && echo'

# Add more network-related aliases below


# Network management (using NetworkManager)
alias nm-list='nmcli device wifi list'
alias nm-connect='nmcli device wifi connect'
alias nm-show-connections='nmcli connection show'

alias ss-top-by-socket='sudo ss -tnp | grep -oP '\''users:\(\("\K[^"]+'\'' | sort | uniq -c | sort -nr | head -20'
