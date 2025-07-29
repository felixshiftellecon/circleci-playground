#!/bin/bash

# Setup iptables rules for Squid proxy on Linux
# This script creates iptables rules to redirect HTTP/HTTPS traffic to Squid

echo "Setting up iptables rules for Squid proxy..."

# Clear existing rules
sudo iptables -t nat -F OUTPUT
sudo iptables -F OUTPUT

# Enforce proxy usage: reject direct HTTP/HTTPS traffic that isn't loopback
sudo iptables -A OUTPUT -p tcp --dport 80  ! -d 127.0.0.1 -j REJECT
sudo iptables -A OUTPUT -p tcp --dport 443 ! -d 127.0.0.1 -j REJECT

# Note: no transparent redirect rules are needed because tools should respect
# the http(s)_proxy environment variables.

# Allow traffic to proxy
sudo iptables -A OUTPUT -p tcp --dport 3128 -j ACCEPT

# Allow DNS traffic (needed for name resolution)
sudo iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow localhost traffic
sudo iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT

# Allow established connections
sudo iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow all other traffic (don't block everything)
sudo iptables -A OUTPUT -j ACCEPT

echo "Checking iptables rules..."
sudo iptables -t nat -L OUTPUT -n --line-numbers
sudo iptables -L OUTPUT -n --line-numbers

echo "✅ iptables rules loaded successfully" 