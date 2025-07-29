#!/bin/bash

# Local test script for Squid proxy setup
# This script helps verify that your Squid proxy is working correctly

set -e

echo "🔧 Testing Squid Proxy Setup"
echo "============================"

# Create log directory and set permissions for nobody user
echo "0. Setting up log directory..."
sudo mkdir -p /var/log/squid
sudo chown nobody:nobody /var/log/squid
sudo chmod 755 /var/log/squid

# Check if Squid is running
echo "1. Checking if Squid is running..."
if pgrep squid > /dev/null; then
    echo "✅ Squid is running (PID: $(pgrep squid))"
else
    echo "❌ Squid is not running"
    echo "Starting Squid..."
    sudo squid -f squid.conf -N -d 1 &
    sleep 3
    if pgrep squid > /dev/null; then
        echo "✅ Squid started successfully"
    else
        echo "❌ Failed to start Squid"
        echo "Checking Squid logs..."
        sudo tail -n 10 /var/log/squid/cache.log 2>/dev/null || echo "No cache log found"
        exit 1
    fi
fi

# Check if ports are listening
echo ""
echo "2. Checking if Squid ports are listening..."
if lsof -i :3128 > /dev/null 2>&1; then
    echo "✅ Port 3128 is listening"
else
    echo "❌ Port 3128 is not listening"
fi

if lsof -i :3129 > /dev/null 2>&1; then
    echo "✅ Port 3129 is listening"
else
    echo "❌ Port 3129 is not listening"
fi

# Test allowed domains
echo ""
echo "3. Testing allowed domains (should work)..."
ALLOWED_DOMAINS=("circleci.com" "github.com" "api.github.com")
for domain in "${ALLOWED_DOMAINS[@]}"; do
    echo -n "Testing $domain: "
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --proxy 127.0.0.1:3128 "https://$domain" > /dev/null 2>&1; then
        echo "✅ ALLOWED"
    else
        echo "❌ BLOCKED"
    fi
done

# Test blocked domains
echo ""
echo "4. Testing blocked domains (should fail)..."
BLOCKED_DOMAINS=("google.com" "facebook.com" "twitter.com")
for domain in "${BLOCKED_DOMAINS[@]}"; do
    echo -n "Testing $domain: "
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --proxy 127.0.0.1:3128 "https://$domain" > /dev/null 2>&1; then
        echo "❌ UNEXPECTEDLY ALLOWED"
    else
        echo "✅ BLOCKED (as expected)"
    fi
done

echo ""
echo "🎉 Test completed!"
echo ""
echo "To view Squid logs:"
echo "  sudo tail -f /var/log/squid/access.log"
echo "  sudo tail -f /var/log/squid/cache.log"
echo ""
echo "To stop Squid:"
echo "  sudo pkill squid" 