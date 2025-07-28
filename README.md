# CircleCI Squid Proxy Playground

This repository demonstrates how to set up and test a Squid proxy with access control in CircleCI across different environments (Linux, macOS, Docker).

## Overview

The project configures a Squid proxy with network-level enforcement that:
- **Redirects all HTTP/HTTPS traffic** through the proxy using iptables/pf rules
- **Forces all traffic through the proxy** - no application changes needed
- **Allows** access to CircleCI and GitHub domains
- **Blocks** access to Google and other domains
- Runs on port 3128 with transparent proxy mode
- Works across Linux and macOS executors

## Files

- `.circleci/config.yml` - CircleCI pipeline configuration
- `squid.conf` - Squid proxy configuration with access control rules
- `test_squid_local.sh` - Local testing script

## Configuration

### Squid Configuration (`squid.conf`)

```conf
http_port 3128 transparent

acl allowed_domains dstdomain .circleci.com .github.com .githubusercontent.com .githubassets.com

http_access allow allowed_domains
http_access deny all

access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

debug_options ALL,1

cache_mem 0
```

### CircleCI Pipeline

The pipeline runs two jobs:
1. **Linux** (`machine` executor)
2. **macOS** (`macos` executor)

Each job:
1. Installs Squid and curl
2. Starts Squid with transparent proxy mode
3. Sets up network-level enforcement (redirects traffic to proxy)
4. Tests domain access control - all traffic automatically goes through proxy

## Testing

The pipeline tests:
- **CircleCI domains** (should be ALLOWED): `circleci.com`, `app.circleci.com`, `api.circleci.com`
- **GitHub domains** (should be ALLOWED): `github.com`, `api.github.com`, `raw.githubusercontent.com`
- **Google domains** (should be BLOCKED): `google.com`, `www.google.com`, `gmail.com`

### Expected Results

- **Allowed domains**: HTTP 200/301 responses
- **Blocked domains**: curl exit code 56 (CURLE_RECV_ERROR)

## Local Testing

Run the local test script to validate the configuration:

```bash
chmod +x test_squid_local.sh
./test_squid_local.sh
```

## Key Features

- **Network-level enforcement**: Redirects all HTTP/HTTPS traffic through proxy using iptables/pf
- **Zero application changes**: No need to configure applications to use proxy
- **Cross-platform compatibility**: Works on Linux and macOS
- **Access control**: Domain-based allow/deny rules
- **Debug logging**: Verbose logging for troubleshooting
- **No caching**: Disabled for testing purposes