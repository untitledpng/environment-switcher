# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Environment Switcher is a Swift-based CLI tool (`switch`) for managing environment-specific configuration files. It allows users to switch between different environments (e.g., local, staging, production) by swapping files based on a `.switchrc` configuration file.

## Build & Development Commands

**Build the executable:**
```bash
swift build -c release
```

The compiled binary will be in `.build/release/switch`.

**Run during development:**
```bash
swift run EnvironmentSwitcher [args]
```

**Test the CLI locally:**
```bash
.build/release/switch [args]
```

**Distribution:**
The tool is distributed via Homebrew tap: `untitledpng/tap/environment-switcher`

## Architecture

### Entry Point
- `Sources/main.swift` - Command-line argument parsing and main entry point
  - No arguments: Shows current environment and usage
  - `init`: Creates example `.switchrc` file
  - `--list` / `-l`: Lists available environments
  - `<environment>`: Switches to specified environment

### Core Logic
- `Sources/Core/EnvironmentSwitcher.swift` - Main switching logic
  - `switchEnvironment(to:)` - Performs the environment switch
  - `listEnvironments()` - Displays available environments from config
  - `showCurrentEnvironment()` - Detects and displays current active environment by comparing file contents
  - `detectCurrentEnvironment(config:)` - Identifies which environment is currently active by comparing target files with environment-specific versions
  - `switchFile(_:to:)` - Handles individual file switching with backup

### Configuration Model
- `Sources/Models/Config.swift` - Defines `SwitchConfig` and `EnvironmentConfig` structs
  - Configuration is loaded from `.switchrc` JSON file in current directory
  - Structure: `{ "environments": { "env-name": { "files": ["path1", "path2"] } } }`

### Error Handling
- `Sources/Errors/SwitchError.swift` - Custom error types
  - All errors include helpful messages with colored output and suggested next steps

### Extensions
- `Sources/Extensions/String+Colors.swift` - ANSI color codes for terminal output
- `Sources/Extensions/FileManager+Extensions.swift` - File management utilities

## How File Switching Works

1. User has environment-specific files: `.env.local`, `.env.staging`, `.env.production`
2. Running `switch production`:
   - Backs up current `.env` to `.env.backup` (if exists)
   - Copies `.env.production` to `.env`
   - Reports success/failure per file
3. Environment detection compares file content (byte-by-byte) between target file and all environment variants to determine current state

## Code Style

- Uses ANSI colors extensively for user-friendly CLI output (cyan for environment names, yellow for warnings, red for errors, etc.)
- Error messages always suggest next steps
- Indented tree-like output (⎿) for file listings
- All user-facing strings are colored for clarity
