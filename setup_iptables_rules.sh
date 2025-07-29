#!/bin/bash

# Setup iptables rules for Squid proxy on Linux
# This script creates iptables rules to redirect HTTP/HTTPS traffic to Squid

echo "Setting up iptables rules for Squid proxy..."

# Clear existing rules
sudo iptables -t nat -F OUTPUT
sudo iptables -F OUTPUT

# Redirect HTTP and HTTPS to proxy
sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3129
sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 3129

# Allow traffic to proxy
sudo iptables -A OUTPUT -p tcp --dport 3128 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 3129 -j ACCEPT

# Block all other outbound traffic
sudo iptables -A OUTPUT -p tcp -j DROP

echo "Checking iptables rules..."
sudo iptables -t nat -L OUTPUT -n --line-numbers
sudo iptables -L OUTPUT -n --line-numbers

echo "✅ iptables rules loaded successfully" 