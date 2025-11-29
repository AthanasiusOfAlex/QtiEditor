# QTI Quiz Editor - Architecture Documentation

## Project Overview

A macOS native application for editing Canvas LMS quiz exports in QTI 1.2 format. The app provides both HTML and rich-text editing modes with powerful regex search-and-replace capabilities.

## Target Platform

- **OS**: macOS Sequoia (14.0+)
- **Language**: Swift 6.2.1+
- **Framework**: SwiftUI with AppKit integration
- **Deployment**: Personal use (no App Store requirements)

**NOTE**: You will not be able to compile or test this code base directly on your Linux system. It only works in MacOS. Don't bother installing Swift. Let the user do the testing.

## Deployment

We will be using `swift bundler`. See `DEPLOYMENT.md`

If you need to change `Info.plist`, please follow the guide `BUNDLER-PLIST-GUIDE.md`

## Programming Principles

1. Always use modern APIs (SwiftUI, Swift Concurrency, Swift regex) when available
2. Don't attempt backward compatibility; don't be afraid to bump up the minimum requirements
3. For the UI: Keep It Simple Stupid (KISS)

## Core Features

This is an extremely simple editor of QTI quizzes that uses SwiftUI's native document classes.

## Contact & Maintenance

This is a personal-use tool. Architecture designed for:

- Easy understanding and modification
- Minimal dependencies
- Clear, maintainable code
- Extensibility for future features
