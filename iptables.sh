

# iptables logging
alias iptables-log-incoming="sudo iptables -A INPUT -j LOG --log-prefix \"iptables: \" --log-level 4"
alias iptables-log-outgoing="sudo iptables -A OUTPUT -j LOG --log-prefix \"iptables: \" --log-level 4"
alias iptables-log-dropped="sudo iptables -A INPUT -j LOG --log-prefix \"iptables: \" --log-level 4 && sudo iptables -A INPUT -j DROP"
alias iptables-log-all="iptables-log-incoming && iptables-log-outgoing && iptables-log-dropped"
alias iptables-log-off="sudo iptables -D INPUT -j LOG"
alias iptables-log-show="tail -40 /var/log/iptables.log"


