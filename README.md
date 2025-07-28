# CircleCI Squid Proxy Playground

This repository demonstrates how to set up and test a Squid proxy with access control in CircleCI across different environments (Linux, macOS, Docker).

## Overview

The project configures a Squid proxy that:
- **Allows** access to CircleCI and GitHub domains
- **Blocks** access to Google and other domains
- Runs on port 3128
- Works across Linux, macOS, and Docker executors

## Files

- `.circleci/config.yml` - CircleCI pipeline configuration
- `squid.conf` - Squid proxy configuration with access control rules
- `test_squid_local.sh` - Local testing script

## Configuration

### Squid Configuration (`squid.conf`)

```conf
http_port 3128

# Define allowed domains (CircleCI and GitHub)
acl allowed_domains dstdomain .circleci.com .github.com .githubusercontent.com .githubassets.com

# Define blocked domains (explicitly block Google)
acl blocked_domains dstdomain .google.com .gmail.com .youtube.com

# Block requests to blocked domains FIRST
http_access deny blocked_domains

# Allow requests to allowed domains
http_access allow allowed_domains

# Deny all other requests
http_access deny all

# Basic logging
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

# Enable debug logging for ACL matching
debug_options ALL,1

# Disable caching for testing
cache_mem 0
```

### CircleCI Pipeline

The pipeline runs three jobs:
1. **Linux** (`machine` executor)
2. **macOS** (`macos` executor) 
3. **Docker** (`docker` executor)

Each job:
1. Installs Squid and curl
2. Starts Squid with the custom configuration
3. Tests domain access control

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

- **Cross-platform compatibility**: Works on Linux, macOS, and Docker
- **Simple setup**: Minimal configuration with proven working approach
- **Access control**: Domain-based allow/deny rules
- **Debug logging**: Verbose logging for troubleshooting
- **No caching**: Disabled for testing purposes