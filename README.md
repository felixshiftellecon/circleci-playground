# CircleCI Squid Proxy with Domain Safelist

This project demonstrates how to set up a Squid proxy in CircleCI that **enforces an egress allow-list**.  Every build step must reach the internet through Squid, and Squid only relays requests whose destination host matches the safelist.  Any direct attempt to hit ports 80 or 443 is dropped at the firewall layer.

## Overview

The setup includes:
- **Squid Proxy**: Listens on port 3128 (standard proxy mode). Port 3129 is optional and used only for transparent **HTTP** redirection on macOS.
- **Firewall Enforcement**: iptables (Linux) or pf (macOS) *reject* any direct HTTP (80) or HTTPS (443) connection that is not loopback, forcing tools to respect the proxy.
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
- Squid listens on **3128** in plain forward-proxy mode.
- (Optional) A second listener on **3129** can be enabled for transparent *HTTP* interception on macOS.

### 2. Firewall Enforcement
- **Linux**: `setup_iptables_rules.sh` adds `REJECT` rules for outbound 80/443 traffic (non-localhost) and allows traffic to 3128.
- **macOS**: `setup_pf_rules.sh` has a redirect for HTTP→3129 and `block drop`s direct HTTPS (443).

> Why not transparently redirect HTTPS?  Squid cannot safely interpret raw TLS bytes without SSL-Bump (MITM).  Rejecting direct TLS and relying on proxy env-vars keeps end-to-end encryption intact while still enforcing the safelist.

### 3. Access Control inside Squid
- `allowed_domains` ACL (see `squid.conf`) lists hostnames you trust.
- Only `CONNECT` requests whose target matches `allowed_domains` are permitted: `http_access allow CONNECT allowed_domains`.
- Plain HTTP (port 80) is also allowed only for the same set.
- Everything else is denied.

### 4. Proxy Environment Variables
Every CircleCI job exports:

```bash
export http_proxy="http://127.0.0.1:3128"
export https_proxy="http://127.0.0.1:3128"
export no_proxy="127.0.0.1,localhost"
```

Most CLI tools (git, curl, npm, pip, Maven, etc.) automatically honour these variables, so they route their traffic through Squid.  Any tool that ignores them will hit the firewall `REJECT` rule and fail fast, surfacing mis-configurations.

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