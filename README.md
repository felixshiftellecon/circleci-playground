# CircleCI Squid Proxy with Domain Safelist

This project demonstrates how to set up a Squid proxy in CircleCI with network-level traffic redirection and domain-based access control. All outbound HTTP/HTTPS traffic is forced through the proxy, and only domains in the safelist are allowed.

## Overview

The setup includes:
- **Squid Proxy**: Running on ports 3128 (normal) and 3129 (transparent)
- **Network Redirection**: Using iptables (Linux) or pf (macOS) to redirect all traffic
- **Domain Safelist**: Only allowing specific domains to be accessed
- **CI/CD Integration**: Automated testing in CircleCI

## Allowed Domains

The following domains are allowed through the proxy:
- `*.circleci.com` - CircleCI services
- `*.github.com` - GitHub services
- `*.githubusercontent.com` - GitHub user content
- `*.githubassets.com` - GitHub assets
- `api.github.com` - GitHub API
- `raw.githubusercontent.com` - GitHub raw content

All other domains are blocked.

## Files

- `.circleci/config.yml` - CircleCI configuration with Squid setup
- `squid.conf` - Squid proxy configuration
- `test_squid_local.sh` - Local testing script

## How It Works

### 1. Squid Proxy Setup
- Squid runs on two ports:
  - Port 3128: Normal proxy mode
  - Port 3129: Transparent proxy mode (for intercepted traffic)

### 2. Network Redirection
- **Linux**: Uses iptables to redirect HTTP (80) and HTTPS (443) traffic to port 3129
- **macOS**: Uses pf (Packet Filter) to redirect traffic to port 3129

### 3. Access Control
- Squid configuration defines allowed domains using ACLs
- SSL CONNECT method is allowed for HTTPS connections
- All other traffic is denied

## Local Testing

To test the setup locally:

```bash
# Make the test script executable
chmod +x test_squid_local.sh

# Run the test
./test_squid_local.sh
```

## CircleCI Jobs

The pipeline includes two jobs:
- `squid-proxy-linux`: Tests on Ubuntu machine executor
- `squid-proxy-macos`: Tests on macOS executor

Both jobs:
1. Install and configure Squid
2. Set up network redirection rules
3. Test allowed domains (should succeed)
4. Test blocked domains (should fail)

## Troubleshooting

### Common Issues

1. **pf syntax errors on macOS**
   - The pf rules have been fixed to use proper syntax
   - Rules now use `rdr pass inet` instead of `rdr pass out`

2. **Squid not starting**
   - Check if ports 3128/3129 are already in use
   - Verify squid.conf syntax: `squid -k parse squid.conf`

3. **Traffic not being redirected**
   - Check iptables/pf rules are loaded
   - Verify Squid is listening on port 3129

### Debug Commands

```bash
# Check Squid status
pgrep squid
lsof -i :3128
lsof -i :3129

# View Squid logs
sudo tail -f /var/log/squid/access.log
sudo tail -f /var/log/squid/cache.log

# Check iptables rules (Linux)
sudo iptables -t nat -L OUTPUT -n --line-numbers
sudo iptables -L OUTPUT -n --line-numbers

# Check pf rules (macOS)
sudo pfctl -s rules
sudo pfctl -s nat
```

## Security Considerations

- This setup provides network-level enforcement
- All HTTP/HTTPS traffic is intercepted and filtered
- Only explicitly allowed domains can be accessed
- SSL/TLS connections are properly handled
- Proxy logs provide audit trail

## Customization

To modify the allowed domains, edit the `allowed_domains` ACL in `squid.conf`:

```
acl allowed_domains dstdomain .yourdomain.com .anotherdomain.com
```

To add more ports or protocols, modify the network redirection rules in `.circleci/config.yml`.