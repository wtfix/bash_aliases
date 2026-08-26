#!/bin/bash

# Nmap Vulnerability Scanning Aliases
# @net, @pentest, @nmap

# Quick scan
alias nmap-quick="sudo nmap -T4 -F"

# Intense scan (comprehensive service/OS detection)
alias nmap-intense="sudo nmap -T4 -A -v"

# Ping sweep (find live hosts)
alias nmap-ping-sweep="sudo nmap -sn"

# UDP scan
alias nmap-udp="sudo nmap -sU -p123,161,500"

# Stealthy SYN scan
alias nmap-stealth="sudo nmap -sS -T2"

# HTTP-specific scan
alias nmap-http="sudo nmap -p 80,443 --script http-*"
# Scan for open ports and version information
alias nmap-services="sudo nmap -sS -sV -O -PN -p-"

# Scan for all vulnerabilities using built-in scripts
alias nmap-vuln="sudo nmap --script vuln -v"

# Scan for vulnerabilities using the Vulners script
alias nmap-vulners="sudo nmap -sV --script vulners"

# All DBs scan
alias nmap-vulners-all="sudo nmap -sV -Pn --script vuln,vulners,vulscan/vulscan.nse"

# Scan using the Vulscan script (ensure it's installed)
alias nmap-vulscan="sudo nmap -sV --script vulscan/vulscan.nse"

# Scan with default scripts and version detection
alias nmap-default="sudo nmap -sC -sV"

# Explanations for each alias

# nmap-quick: Performs a fast scan of the most common 100 ports
# nmap-intense: Performs an aggressive scan with OS detection, version scanning, script scanning, and traceroute
# nmap-ping-sweep: Performs a simple ping sweep to discover live hosts
# nmap-udp: Performs a UDP scan on common ports (DNS, SNMP, VPN)
# nmap-stealth: Performs a stealthy SYN scan with slower timing
# nmap-http: Scans HTTP and HTTPS ports and runs all HTTP-related scripts
# nmap-services: Scans all ports for open services and attempts version detection and OS fingerprinting
# nmap-vuln: Runs built-in vulnerability scanning scripts
# nmap-vulners: Uses the Vulners script to check for known vulnerabilities
# nmap-vulscan: Uses the Vulscan script to check offline vulnerability databases
# nmap-default: Runs default scripts and version scanning

