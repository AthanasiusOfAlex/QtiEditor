#!/bin/bash

# Session Start Hook for QtiEditor
# This script runs automatically when a new Claude Code session starts

echo "🚀 Setting up QtiEditor development environment..."

# Install Swift toolchain if not already present
if [ ! -d "$HOME/.swift/swift-6.0.3" ]; then
    echo "📦 Installing Swift 6.0.3 toolchain..."

    # Download Swift for Ubuntu 24.04
    cd /tmp
    wget -q https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz

    # Extract to user directory
    tar xzf swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
    mkdir -p ~/.swift
    mv swift-6.0.3-RELEASE-ubuntu24.04 ~/.swift/swift-6.0.3

    # Cleanup
    rm swift-6.0.3-RELEASE-ubuntu24.04.tar.gz

    echo "✅ Swift 6.0.3 installed successfully"
else
    echo "✅ Swift 6.0.3 already installed"
fi

# Add Swift to PATH
export PATH="$HOME/.swift/swift-6.0.3/usr/bin:$PATH"

# Verify installation
echo "🔧 Swift version:"
swift --version

echo "✨ Development environment ready!"
