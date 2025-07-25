#!/bin/bash

# Local test script for Squid proxy configuration
echo "🧪 Testing Squid proxy configuration locally..."

# Check if Squid is installed
if ! command -v squid &> /dev/null; then
    echo "❌ Squid is not installed. Please install it first."
    exit 1
fi

# Create log directory if it doesn't exist
sudo mkdir -p /var/log/squid
sudo chown $(whoami) /var/log/squid

# Start Squid
echo "🚀 Starting Squid..."
squid -f squid.conf -N -d 1 &
SQUID_PID=$!
echo "Squid started with PID: $SQUID_PID"

# Wait for Squid to start
sleep 3

# Check if Squid is running
if ! pgrep squid > /dev/null; then
    echo "❌ Squid failed to start"
    exit 1
fi

echo "✅ Squid is running"

# Test allowed domains
echo ""
echo "🔍 Testing allowed domains..."
for domain in "circleci.com" "github.com"; do
    echo -n "Testing $domain: "
    response=$(curl -s -o /dev/null -w "%{http_code}" --proxy http://127.0.0.1:3128 --connect-timeout 10 "https://$domain" 2>/dev/null)
    if [ $? -eq 0 ] && [ "$response" != "000" ]; then
        echo "✅ ALLOWED (HTTP $response)"
    else
        echo "❌ BLOCKED"
    fi
done

# Test blocked domains
echo ""
echo "🔍 Testing blocked domains..."
for domain in "google.com" "example.com"; do
    echo -n "Testing $domain: "
    response=$(curl -s -o /dev/null -w "%{http_code}" --proxy http://127.0.0.1:3128 --connect-timeout 10 "https://$domain" 2>/dev/null)
    if [ $? -eq 0 ] && [ "$response" != "000" ]; then
        echo "❌ UNEXPECTEDLY ALLOWED (HTTP $response)"
    else
        echo "✅ BLOCKED"
    fi
done

# Cleanup
echo ""
echo "🧹 Cleaning up..."
kill $SQUID_PID 2>/dev/null
echo "✅ Test completed" 