#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Squid Proxy Setup for CircleCI and GitHub Access Control${NC}"
echo "================================================================"

get_homebrew_prefix() {
    if command -v brew >/dev/null 2>&1; then
        brew --prefix
    else
        echo "/usr/local"
    fi
}

install_squid() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo -e "${YELLOW}Installing Squid on Ubuntu/Debian...${NC}"
            sudo apt-get update
            sudo apt-get install -y squid curl
        elif command -v yum &> /dev/null; then
            echo -e "${YELLOW}Installing Squid on CentOS/RHEL...${NC}"
            sudo yum install -y squid curl
        elif command -v dnf &> /dev/null; then
            echo -e "${YELLOW}Installing Squid on Fedora...${NC}"
            sudo dnf install -y squid curl
        else
            echo -e "${RED}Unsupported Linux distribution. Please install Squid manually.${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
        echo -e "${YELLOW}Installing Squid on macOS...${NC}"
        if command -v brew &> /dev/null; then
            brew install squid curl
        else
            echo -e "${RED}Homebrew not found. Please install Homebrew first:${NC}"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    else
        echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
        exit 1
    fi
}

if ! command -v squid &> /dev/null; then
    echo -e "${YELLOW}Squid not found. Installing...${NC}"
    install_squid
else
    echo -e "${GREEN}Squid is already installed.${NC}"
fi

if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}curl not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
        brew install curl
    else
        sudo apt-get install -y curl || sudo yum install -y curl || sudo dnf install -y curl
    fi
fi

echo -e "${YELLOW}Creating Squid directories...${NC}"
sudo mkdir -p /var/spool/squid
sudo mkdir -p /var/log/squid

echo -e "${YELLOW}Setting permissions...${NC}"
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
    sudo chown -R $(whoami):staff /var/spool/squid
    sudo chown -R $(whoami):staff /var/log/squid
else
    sudo chown -R squid:squid /var/spool/squid
    sudo chown -R squid:squid /var/log/squid
fi

echo -e "${YELLOW}Installing Squid configuration...${NC}"
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
    HOMEBREW_PREFIX=$(get_homebrew_prefix)
    SQUID_CONFIG_DIR="$HOMEBREW_PREFIX/etc/squid"
    echo -e "${YELLOW}Using Squid config directory: $SQUID_CONFIG_DIR${NC}"
    
    sudo mkdir -p "$SQUID_CONFIG_DIR"
    sudo cp squid.conf "$SQUID_CONFIG_DIR/squid.conf"
else
    sudo cp squid.conf /etc/squid/squid.conf
fi

echo -e "${YELLOW}Initializing Squid cache...${NC}"
sudo squid -z

echo -e "${YELLOW}Testing Squid configuration...${NC}"
if sudo squid -k parse; then
    echo -e "${GREEN}Configuration is valid!${NC}"
else
    echo -e "${RED}Configuration has errors. Please check squid.conf${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting Squid service...${NC}"
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
    HOMEBREW_PREFIX=$(get_homebrew_prefix)
    SQUID_CONFIG_DIR="$HOMEBREW_PREFIX/etc/squid"
    
    sudo squid -d 1 -f "$SQUID_CONFIG_DIR/squid.conf"
    echo -e "${GREEN}Squid started on port 3128${NC}"
    echo -e "${YELLOW}To stop Squid: sudo pkill squid${NC}"
else
    sudo systemctl enable squid
    sudo systemctl start squid
    echo -e "${GREEN}Squid service started and enabled${NC}"
fi

echo -e "\n${GREEN}Setup complete!${NC}"
echo "=================================="
echo -e "${BLUE}Next steps:${NC}"
echo "1. Configure your applications to use the proxy:"
echo "   - Proxy URL: http://127.0.0.1:3128"
echo "   - No authentication required"
echo ""
echo -e "${YELLOW}To configure environment variables:${NC}"
echo "export http_proxy=http://127.0.0.1:3128"
echo "export https_proxy=http://127.0.0.1:3128"
echo "export HTTP_PROXY=http://127.0.0.1:3128"
echo "export HTTPS_PROXY=http://127.0.0.1:3128"
echo ""
echo -e "${YELLOW}To view Squid logs:${NC}"
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$(uname)" == "Darwin" ]]; then
    HOMEBREW_PREFIX=$(get_homebrew_prefix)
    LOG_PATHS=(
        "$HOMEBREW_PREFIX/var/log/squid/access.log"
        "/usr/local/var/logs/squid/access.log"
        "/var/log/squid/access.log"
    )
    
    LOG_FOUND=false
    for log_path in "${LOG_PATHS[@]}"; do
        if [ -f "$log_path" ]; then
            echo "tail -f $log_path"
            LOG_FOUND=true
            break
        fi
    done
    
    if [ "$LOG_FOUND" = false ]; then
        echo "tail -f $HOMEBREW_PREFIX/var/log/squid/access.log"
    fi
else
    echo "sudo tail -f /var/log/squid/access.log"
fi 