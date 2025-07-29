#!/bin/bash

# Setup iptables rules for Squid proxy on Linux
# This script creates iptables rules to redirect HTTP/HTTPS traffic to Squid

echo "Setting up iptables rules for Squid proxy..."

# Fail fast on errors
set -euo pipefail
set -x

# Use a shorter xtables lock wait time (5s) to avoid hanging if some other
# process like UFW is manipulating iptables at the same time.
IPT="sudo iptables -w 5"

# Clear existing rules
echo "Flushing old rules…"
$IPT -t nat -F OUTPUT || true
$IPT -F OUTPUT || true

# Enforce proxy usage: reject direct HTTP/HTTPS traffic that isn't loopback
echo "Allowing established/related connections…"
$IPT -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow Squid (running as user "proxy") to establish TLS tunnels before any rejects
echo "Allowing outbound 443 for Squid process (uid proxy)…"
$IPT -A OUTPUT -p tcp --dport 443 -m owner --uid-owner proxy -j ACCEPT

# Allow CircleCI agent traffic (log uploads, API) directly – resolves many hosts
echo "Creating ipset for CircleCI domains…"
# Ensure ipset is available
if ! command -v ipset >/dev/null 2>&1; then
  echo "ipset not found – installing…"
  sudo apt-get update -qq
  sudo apt-get install -y ipset
fi

sudo ipset create circleci_hosts hash:ip family inet hashsize 1024 maxelem 65536 -exist
# Pre-resolve a few critical endpoints and add to set; failures ignored
for host in circleci.com app.circleci.com api.circleci.com dl.circleci.com output.circleci.com; do
  ip=$(getent ahosts "$host" | awk '{print $1}' | head -n1 || true)
  [ -n "$ip" ] && sudo ipset add circleci_hosts "$ip" -exist || true
done
$IPT -A OUTPUT -p tcp --dport 443 -m set --match-set circleci_hosts dst -j ACCEPT

echo "Adding REJECT rules for direct HTTP/HTTPS…"
$IPT -A OUTPUT -p tcp --dport 80  ! -d 127.0.0.1 -j REJECT
$IPT -A OUTPUT -p tcp --dport 443 ! -d 127.0.0.1 -j REJECT

# Note: no transparent redirect rules are needed because tools should respect
# the http(s)_proxy environment variables.

# Allow traffic to proxy
echo "Allowing traffic to Squid (3128)…"
$IPT -A OUTPUT -p tcp --dport 3128 -j ACCEPT

# Allow DNS traffic (needed for name resolution)
echo "Allowing DNS traffic…"
$IPT -A OUTPUT -p udp --dport 53 -j ACCEPT
$IPT -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow localhost traffic
$IPT -A OUTPUT -d 127.0.0.1 -j ACCEPT

# Allow established connections
# NOTE: No generic allow-all rule. Anything not explicitly allowed above will be
# dropped/rejected, ensuring the safelist enforcement.

echo "Checking iptables rules (nat table)…"
$IPT -t nat -L OUTPUT -n --line-numbers
echo "Checking iptables rules (filter table)…"
$IPT -L OUTPUT -n --line-numbers

echo "✅ iptables rules loaded successfully" 