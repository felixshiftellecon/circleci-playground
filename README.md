# CircleCI Squid Proxy Playground

This repository demonstrates how to set up and test a Squid proxy with access control in CircleCI environments.

## Overview

The project tests a Squid proxy configuration that:
- ✅ **Allows** access to CircleCI and GitHub domains
- ❌ **Blocks** access to all other domains (like Google, etc.)

## Fixed Issues

### 1. Squid Command Line Error
**Problem**: The original configuration used an invalid `-p` flag without a port number:
```bash
squid -f squid.conf -N -p -d 1 &  # ❌ Invalid
```

**Solution**: Removed the problematic `-p` flag and added Docker-specific handling:
```bash
squid -f squid.conf -N -d 1 &     # ✅ Fixed
```

### 2. ACL Configuration Issues
**Problem**: Google domains were still being allowed through the proxy despite blocking rules.

**Solution**: Reordered ACL rules to ensure deny rules are processed before allow rules:
```conf
# Block Google domains first
http_access deny blocked_domains
# Then allow permitted domains
http_access allow allowed_domains
```

### 2. Squid Configuration Improvements
**Problem**: Basic configuration without proper logging and caching settings.

**Solution**: Enhanced `squid.conf` with:
- Proper domain ACL definitions with explicit blocking rules
- Localhost access control
- Logging configuration
- Cache disabling for testing
- Better error handling
- Cross-platform compatibility fixes

### 3. CircleCI Setup Improvements
**Problem**: Insufficient error handling and logging in CI environment.

**Solution**: Enhanced setup with:
- Log directory creation
- Better process management
- Improved error reporting
- Cross-platform compatibility (macOS/Linux)

## Files

- `.circleci/config.yml` - CircleCI pipeline configuration
- `squid.conf` - Squid proxy configuration
- `test_squid_local.sh` - Local testing script
- `README.md` - This documentation

## Local Testing

Before running in CI, test the configuration locally:

```bash
# Make sure Squid is installed
# On macOS: brew install squid
# On Ubuntu: sudo apt-get install squid

# Run the local test
./test_squid_local.sh
```

## CircleCI Jobs

The pipeline runs three jobs to test the proxy across different environments:

1. **test-squid-proxy** - Ubuntu machine executor
2. **test-squid-proxy-macos** - macOS executor  
3. **test-squid-proxy-docker** - Docker executor

## Expected Behavior

### Allowed Domains (Should Pass)
- `circleci.com`
- `app.circleci.com`
- `api.circleci.com`
- `github.com`
- `api.github.com`
- `raw.githubusercontent.com`

### Blocked Domains (Should Fail)
- `google.com`
- `www.google.com`
- `gmail.com`
- Any other domain not in the allowed list

## Environment Limitations

### Process Management Issues
The Linux machine executor can have issues with Squid process management:

1. **PID File Conflicts**: Multiple Squid instances can leave stale PID files
2. **Process Cleanup**: Previous test runs may leave processes running
3. **Port Binding**: New instances may fail to start if port is still in use
4. **System Service Conflicts**: Ubuntu package installation may auto-start Squid service

**Evidence from logs**:
```
FATAL: Squid is already running: Found fresh instance PID file (/run/squid.pid) with PID 2618
❌ Squid is running but not listening on port 3128
❌ Port 3128 is already in use: LISTEN 0 256 *:3128 *:*
```

**Solution**: Enhanced cleanup in startup script including:
- Force kill processes using port 3128
- Stop and disable system Squid service
- Remove all PID files
- Extended wait times for process cleanup
- Use absolute path to custom config file (`/home/circleci/project/squid.conf`)

### Docker Executor Issues
The Docker executor has different limitations (see Docker job logs for details).

## Recent Fixes Applied

1. **Enhanced Process Cleanup**: Added comprehensive cleanup for existing Squid processes and PID files (including macOS Homebrew path)
2. **Improved Port Detection**: Better detection of port 3128 availability across different environments using multiple methods
3. **Robust Startup Polling**: Added polling loop to ensure Squid is fully started before proceeding
4. **Enhanced Error Reporting**: More detailed logging and error messages for debugging
5. **Fixed ACL Logic**: Removed problematic `localhost` ACL that was allowing all localhost traffic before domain rules could apply
6. **Fixed Linux PID File Issues**: Added `-p /tmp/squid.pid` flag for Linux environments to avoid permission denied errors
7. **Fixed macOS PID File Issues**: Removed `-p` flag for macOS environments as it's not supported
8. **Fixed Config File Path Issues**: Use absolute path `/home/circleci/project/squid.conf` for Linux to ensure custom config is used
9. **Replaced `netstat` with `ss`**: Updated all port checking commands to use `ss` instead of `netstat` (not available in CircleCI)
10. **Fixed Log File Permissions**: Added `sudo` to log file access commands to handle proxy user ownership
11. **Optimized Cleanup Process**: Reduced sleep times and simplified cleanup to prevent job timeouts
12. **Fixed Curl Exit Code Handling**: Added proper error handling for curl commands to prevent job failures when proxy blocks connections
13. **Fixed Linux PID File Permission**: Added `pid_filename /tmp/squid.pid` to squid.conf to use writable PID file location
14. **Fixed Curl Response Handling**: Improved curl exit code handling to properly set response to "000" when curl fails

## Troubleshooting

### Common Issues

1. **Squid fails to start**
   - Check log files: `/var/log/squid/cache.log`
   - Verify port 3128 is not in use
   - Ensure proper permissions on log directory

2. **Tests fail unexpectedly**
   - Check Squid access logs: `/var/log/squid/access.log`
   - Verify domain patterns in `squid.conf`
   - Test direct connectivity without proxy

3. **Cross-platform issues**
   - macOS and Linux may have different Squid versions
   - Check for platform-specific command differences
   - Verify package installation methods

### Debug Commands

```bash
# Check if Squid is running
pgrep squid

# Check port usage
netstat -tlnp | grep :3128
lsof -i :3128

# Check Squid logs
tail -f /var/log/squid/access.log
tail -f /var/log/squid/cache.log

# Test proxy manually
curl -v --proxy http://127.0.0.1:3128 https://circleci.com
```

## Configuration Details

### Squid Configuration (`squid.conf`)
```conf
http_port 3128
acl allowed_domains dstdomain .circleci.com .github.com .githubusercontent.com .githubassets.com
acl blocked_domains dstdomain .google.com .gmail.com .youtube.com
http_access deny blocked_domains
http_access allow allowed_domains
http_access deny all
```

### Key Features
- **Port 3128**: Standard Squid proxy port
- **Domain ACL**: Uses `dstdomain` for destination domain matching
- **Subdomain Support**: `.domain.com` pattern includes all subdomains
- **Deny All**: Default deny policy for security

## Contributing

1. Test changes locally first using `test_squid_local.sh`
2. Ensure all three CircleCI jobs pass
3. Update documentation for any configuration changes
4. Add new test cases for additional domains as needed