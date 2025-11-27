# QTI Editor - Deployment Guide

This guide covers how to build, bundle, and deploy the QTI Editor app for macOS.

## Project Configuration Summary

Use Swift Bundler.

### Installing Swift Bundler

1. Install `mint`.

   ```bash
   brew install mint
   ```

2. Install Swift Bundler.

   ```bash
   mint install stackotter/swift-bundler@main
   ```

### Updating Swift Bundler

Just force an install.

```bash
mint install -f stackotter/swift-bundler@main
```

### Running QtiEditor Once

```bash
swift bundler run
```

### Deploying the App

```bash
swift bundler bundle --configuration release
```

or

```bash
swift bundler bundle -c release
```

Omit `--configuration release`/`-c release` if you would like to create a bundle that still has debugging symbols.
