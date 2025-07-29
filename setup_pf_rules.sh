#!/bin/bash

# Setup pf rules for Squid proxy on macOS
# This script creates and loads pf rules to redirect HTTP/HTTPS traffic to Squid

echo "Setting up pf rules for Squid proxy..."

# Create pf configuration file
cat > /tmp/pf.conf << 'EOF'
# Redirect HTTP and HTTPS traffic to Squid proxy
rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port 3129
rdr pass inet proto tcp from any to any port 443 -> 127.0.0.1 port 3129

# Allow traffic to the proxy itself
pass out proto tcp to 127.0.0.1 port 3128
pass out proto tcp to 127.0.0.1 port 3129

# Allow traffic from localhost
pass out proto tcp from 127.0.0.1 to any

# Allow DNS traffic
pass out proto udp to any port 53
pass out proto tcp to any port 53

# Allow established connections
pass out proto tcp from any to any established
EOF

echo "=== DEBUG: Generated pf.conf content ==="
cat /tmp/pf.conf
echo "=== END DEBUG ==="

echo "=== DEBUG: Testing pf syntax ==="
sudo pfctl -nf /tmp/pf.conf
echo "=== END DEBUG ==="

echo "=== DEBUG: Loading pf rules ==="
sudo pfctl -ef /tmp/pf.conf
echo "=== END DEBUG ==="

echo "✅ pf rules loaded successfully" 