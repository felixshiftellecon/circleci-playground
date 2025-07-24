# Squid Proxy for CircleCI and GitHub Access Control

This project sets up a Squid proxy server that allows access only to CircleCI and GitHub domains while blocking all other internet traffic. This is useful for security environments where you need to restrict network access to specific trusted domains.

## Features

- ✅ **Selective Access Control**: Only CircleCI and GitHub domains are accessible
- ✅ **Comprehensive Blocking**: All other domains are blocked
- ✅ **Easy Testing**: Automated test script to verify functionality
- ✅ **Cross-Platform**: Works on macOS and Linux
- ✅ **No Authentication**: Simple proxy setup without authentication

## Allowed Domains

The following domains are allowed through the proxy:

### CircleCI
- `*.circleci.com`
- `circleci.com`

### GitHub
- `*.github.com`
- `*.githubusercontent.com`
- `*.githubassets.com`
- `github.com`

## Blocked Domains

All other domains are blocked, including:
- Google (google.com, gmail.com)
- Social media (facebook.com, twitter.com)
- E-commerce (amazon.com)
- Any other external domains

## Quick Start

### 1. Setup Squid Proxy

```bash
# Make setup script executable
chmod +x setup_squid.sh

# Run the setup script
./setup_squid.sh
```

### 2. Test the Configuration

The setup script automatically runs comprehensive curl tests to verify the configuration works correctly.

### 3. Configure Your Applications

Set the following environment variables to use the proxy:

```bash
export http_proxy=http://127.0.0.1:3128
export https_proxy=http://127.0.0.1:3128
export HTTP_PROXY=http://127.0.0.1:3128
export HTTPS_PROXY=http://127.0.0.1:3128
```

## Configuration Details

### Squid Configuration (`squid.conf`)

The configuration uses Squid's Access Control Lists (ACLs) to:

1. **Define allowed domains** using `dstdomain` ACLs
2. **Allow localhost access** for testing
3. **Block all other traffic** with `http_access deny all`

Key configuration sections:

```conf
# Define ACLs for allowed domains
acl circleci_domains dstdomain .circleci.com
acl github_domains dstdomain .github.com .githubusercontent.com .githubassets.com
acl allowed_domains dstdomain .circleci.com .github.com .githubusercontent.com .githubassets.com

# Allow localhost to access the proxy
http_access allow localhost

# Allow access only to CircleCI and GitHub domains
http_access allow allowed_domains

# Block everything else
http_access deny all
```

### Port Configuration

- **Proxy Port**: 3128 (default Squid port)
- **Access**: Localhost only (127.0.0.1)
- **Protocol**: HTTP/HTTPS

## Testing

The setup script automatically runs comprehensive curl tests that verify:

### Should Be Allowed ✅
- CircleCI domains (circleci.com, app.circleci.com, api.circleci.com)
- GitHub domains (github.com, api.github.com, raw.githubusercontent.com)

### Should Be Blocked ❌
- Google domains (google.com, gmail.com)
- Social media (facebook.com, twitter.com)
- Other common sites (amazon.com)

### Manual Testing with Curl

You can also test manually using curl commands:

```bash
# Test CircleCI (should work)
curl -s -o /dev/null -w "%{http_code}" --proxy http://127.0.0.1:3128 https://circleci.com

# Test GitHub (should work)
curl -s -o /dev/null -w "%{http_code}" --proxy http://127.0.0.1:3128 https://github.com

# Test Google (should be blocked)
curl -s -o /dev/null -w "%{http_code}" --proxy http://127.0.0.1:3128 https://google.com
```

Expected results:
- CircleCI/GitHub: HTTP 200 (or similar success code)
- Google/Others: Connection timeout or error

## Management Commands

### Start Squid
```bash
# macOS
sudo squid -d 1

# Linux
sudo systemctl start squid
```

### Stop Squid
```bash
# macOS
sudo pkill squid

# Linux
sudo systemctl stop squid
```

### Check Status
```bash
# macOS
ps aux | grep squid

# Linux
sudo systemctl status squid
```

### View Logs
```bash
# macOS
tail -f /usr/local/var/logs/squid/access.log

# Linux
sudo tail -f /var/log/squid/access.log
```

### Validate Configuration
```bash
sudo squid -k parse
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Fix permissions
   sudo chown -R squid:squid /var/spool/squid /var/log/squid
   ```

2. **Port Already in Use**
   ```bash
   # Check what's using port 3128
   sudo lsof -i :3128
   
   # Kill existing process
   sudo pkill squid
   ```

3. **Configuration Errors**
   ```bash
   # Validate configuration
   sudo squid -k parse
   
   # Check syntax
   sudo squid -f /etc/squid/squid.conf -k parse
   ```

### Debug Mode

To run Squid in debug mode for troubleshooting:

```bash
# Stop existing Squid
sudo pkill squid

# Start in debug mode
sudo squid -d 1 -f /etc/squid/squid.conf
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Local Access Only**: This configuration only allows localhost access to the proxy
2. **No Authentication**: The proxy doesn't require authentication (for simplicity)
3. **Trusted Domains**: Only CircleCI and GitHub domains are trusted
4. **Logging**: All access attempts are logged for monitoring

## Customization

### Adding More Allowed Domains

Edit `squid.conf` and add domains to the `allowed_domains` ACL:

```conf
acl allowed_domains dstdomain .circleci.com .github.com .githubusercontent.com .githubassets.com .yourdomain.com
```

### Changing the Port

Edit `squid.conf` and change the `http_port` directive:

```conf
http_port 8080  # Change from 3128 to 8080
```

### Adding Authentication

To add basic authentication, uncomment and configure:

```conf
# auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
# auth_param basic realm proxy
# acl authenticated proxy_auth REQUIRED
# http_access allow authenticated
```

## Files

- `squid.conf` - Main Squid configuration file
- `setup_squid.sh` - Automated setup script with integrated curl testing
- `README.md` - This documentation

## Requirements

- **Operating System**: macOS or Linux
- **Package Manager**: Homebrew (macOS) or apt/yum/dnf (Linux)
- **Dependencies**: Squid, curl
- **Permissions**: sudo access for installation and configuration

## License

This project is provided as-is for educational and testing purposes.