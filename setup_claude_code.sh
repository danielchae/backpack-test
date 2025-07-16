#!/bin/bash

# Claude Code VM Setup Script
# This script sets up a virtual machine with Claude Code and clones a repository
# Usage: bash setup_claude_code.sh

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/danielchae/backpack-test"
MIN_NODE_VERSION=18
CLAUDE_PACKAGE="@anthropic-ai/claude-code"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            PKG_MANAGER="apt"
            PKG_UPDATE="sudo apt-get update"
            PKG_INSTALL="sudo apt-get install -y"
        elif command_exists yum; then
            PKG_MANAGER="yum"
            PKG_UPDATE="sudo yum check-update || true"
            PKG_INSTALL="sudo yum install -y"
        elif command_exists dnf; then
            PKG_MANAGER="dnf"
            PKG_UPDATE="sudo dnf check-update || true"
            PKG_INSTALL="sudo dnf install -y"
        else
            print_error "No supported package manager found (apt, yum, or dnf)"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update"
            PKG_INSTALL="brew install"
        else
            print_error "Homebrew not found. Please install it from https://brew.sh"
            exit 1
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_status "Detected OS: $OSTYPE"
    print_status "Package manager: $PKG_MANAGER"
}

# Function to install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    case $PKG_MANAGER in
        apt)
            # Install Node.js from NodeSource repository
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            $PKG_INSTALL nodejs
            ;;
        yum|dnf)
            # Install Node.js from NodeSource repository
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            $PKG_INSTALL nodejs
            ;;
        brew)
            $PKG_INSTALL node
            ;;
    esac
    
    if command_exists node && command_exists npm; then
        print_success "Node.js installed successfully"
    else
        print_error "Failed to install Node.js"
        exit 1
    fi
}

# Function to check Node.js version
check_node_version() {
    if command_exists node; then
        NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_VERSION" -ge "$MIN_NODE_VERSION" ]; then
            print_success "Node.js version $NODE_VERSION meets requirements (>=$MIN_NODE_VERSION)"
            return 0
        else
            print_warning "Node.js version $NODE_VERSION is below required version $MIN_NODE_VERSION"
            return 1
        fi
    else
        return 1
    fi
}

# Function to install git
install_git() {
    print_status "Installing git..."
    
    case $PKG_MANAGER in
        apt|yum|dnf)
            $PKG_INSTALL git
            ;;
        brew)
            $PKG_INSTALL git
            ;;
    esac
    
    if command_exists git; then
        print_success "Git installed successfully"
    else
        print_error "Failed to install git"
        exit 1
    fi
}

# Main script execution
main() {
    echo "==================================="
    echo "Claude Code VM Setup Script"
    echo "==================================="
    echo
    
    # Detect OS and package manager
    detect_os
    
    # Update package manager
    print_status "Updating package manager..."
    $PKG_UPDATE || true
    
    # Check and install Node.js/npm
    print_status "Checking Node.js installation..."
    if ! check_node_version; then
        install_nodejs
        if ! check_node_version; then
            print_error "Failed to install Node.js with required version"
            exit 1
        fi
    fi
    
    print_status "Node.js version: $(node -v)"
    print_status "npm version: $(npm -v)"
    
    # Check and install git
    print_status "Checking git installation..."
    if ! command_exists git; then
        install_git
    else
        print_success "Git is already installed: $(git --version)"
    fi
    
    # Check and install Claude Code
    print_status "Checking Claude Code installation..."
    if ! command_exists claude; then
        print_status "Installing Claude Code globally..."
        npm install -g "$CLAUDE_PACKAGE"
        
        if command_exists claude; then
            print_success "Claude Code installed successfully"
        else
            print_error "Failed to install Claude Code"
            print_error "Try running: npm install -g $CLAUDE_PACKAGE"
            exit 1
        fi
    else
        print_success "Claude Code is already installed"
    fi
    
    # Create unique working directory
    WORKSPACE_DIR="claude_workspace_$(date +%Y%m%d_%H%M%S)_$$"
    print_status "Creating workspace directory: $WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    print_success "Created and entered workspace: $(pwd)"
    
    # Clone the repository
    print_status "Cloning repository: $REPO_URL"
    if git clone "$REPO_URL"; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        exit 1
    fi
    
    # Get repository name from URL
    REPO_NAME=$(basename "$REPO_URL" .git)
    
    # Change to repository directory
    cd "$REPO_NAME"
    print_success "Changed to repository directory: $(pwd)"
    
    # Launch Claude Code
    echo
    echo "==================================="
    echo "Setup Complete!"
    echo "==================================="
    print_success "All dependencies installed"
    print_success "Repository cloned to: $(pwd)"
    echo
    print_status "Launching Claude Code interactive mode..."
    echo "Type 'exit' or press Ctrl+C to quit Claude Code"
    echo
    
    # Start Claude Code
    claude
}

# Run main function
main