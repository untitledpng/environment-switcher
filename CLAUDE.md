# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Environment Switcher is a Swift-based CLI tool for managing environment-specific configuration files. It allows users to switch between different environments (local, staging, production, etc.) by swapping out configuration files like `.env`, `config.json`, etc.

## Development Commands

### Building
```bash
# Debug build
swift build

# Release build
swift build -c release

# Run the binary after building
.build/release/switch <command>
```

### Testing
```bash
# Run all tests
swift test

# Build for testing without running
swift build --build-tests
```

### Running During Development
```bash
# Run directly with swift run
swift run switch <command>

# Example: Run init command
swift run switch init

# Example: Run status command
swift run switch status
```

## Architecture

### Command Pattern with ArgumentParser

The CLI is built using Swift ArgumentParser with a root command (`EnvironmentSwitcher` in `main.swift`) and subcommands:
- `InitCommand` - Creates `.switchrc` project configuration
- `StatusCommand` - Displays current environment and file states
- `ConfigCommand` - Creates global configuration at `~/.config/switch/.switchrc`
- `SwitchCommand` - Switches between environments

**Important**: The `main.swift` file includes custom fallback logic:
- If no subcommand is provided, it runs `StatusCommand`
- If a single argument is provided that matches an environment name, it automatically runs `SwitchCommand` with that environment (e.g., `switch production` works without the `to` subcommand)

### Configuration System

There are **two separate configuration systems**:

1. **Project Config** (`.switchrc` in project directory)
   - Managed by `ConfigService` (singleton)
   - Model: `Config` struct
   - Contains: `current_environment`, `environments`, `default_files`
   - Location: Current working directory

2. **Global Config** (`~/.config/switch/.switchrc`)
   - Managed by `GlobalConfigService` (singleton)
   - Model: `GlobalConfig` struct
   - Contains: `default_environments`, `default_files`
   - Used for defaults when running `switch init`
   - Falls back to hardcoded defaults if file doesn't exist

**Key difference**: `ConfigService.shared.config` requires a project `.switchrc` to exist and will exit with an error if not found. `GlobalConfigService.shared.config` returns default values if the global config doesn't exist.

### File Management Pattern

Files are organized as:
- **Active file**: `<filename>` (e.g., `.env`)
- **Environment-specific file**: `<filename>.<environment>` (e.g., `.env.production`)
- **Backup file**: `<filename>.backup` (created during switching)

The `getFileEnvironmentPath()` helper in `FileHelper.swift` constructs environment-specific paths.

### File Resolution Strategy

The `Config.getFiles()` method merges files from two sources:
1. `default_files` - Files that apply to all environments
2. `environment.files` - Additional files specific to the current environment

This supports three configuration patterns:
- **Default files only**: All environments use the same file list from `default_files`, with `environment.files` being empty arrays
- **Per-environment files**: Each environment defines its own `files` array, no `default_files`
- **Mixed mode**: Combination of both, where `default_files` are used plus environment-specific additions

**Important**: The method uses static variables for caching and invalidates when `current_environment` changes.

### File Status Detection

The `FileHelper.swift` module uses SHA-256 hashing to detect file changes:
- `sha256()` - Computes hash of a file
- `getFileStatus()` - Compares active file hash with environment-specific file hash
- Returns `FileStatus` enum: `.original`, `.modified`, or `.notFound`

This allows the status command to show if files have been edited since switching environments.

### Console Output System

The `ConsoleHelper.swift` module provides formatted output using Rainbow for colors:
- `printDotLine()` - Prints label and value separated by dots (fixed width: 146 chars)
- `printUpdatableDotLine()` - Same as above but can update in place (for progress indicators)
- `printTitle()` - Prints colored badge with title (INFO, ERROR, WARNING, SUCCESS)

Colors are applied throughout commands for better UX:
- `.cyan` - User prompts and important text
- `.dim` - Secondary information
- `.green` - Success states
- `.yellow` - Modified files
- `.red` - Errors and missing files

### String Extensions

The `String+Formatting.swift` file provides conditional styling:
- `colorIf()` - Apply color only if condition is true
- `styleIf()` - Apply style only if condition is true
- `withoutANSI` - Property that strips ANSI codes (used for length calculations in dot lines)

These are used heavily in status displays to conditionally color file states.

## Important Implementation Details

### Singleton Initialization

Both `ConfigService` and `GlobalConfigService` are singletons that load config on first access. If project config is missing, the app exits immediately. This means:
- Commands that require `.switchrc` (status, switch) will fail before `run()` is called
- `InitCommand` explicitly checks `ConfigService.configExists()` before trying to access the singleton

### Interactive Prompts

`InitCommand` includes sophisticated interactive workflows:
1. Asks for environments (comma-separated, uses global config defaults)
2. Asks for files to manage (comma-separated, uses global config defaults)
3. Offers to create/update `.gitignore` with necessary entries
4. Offers to auto-create all environment-specific files

When creating files:
- If original file exists, copies content to environment files
- If original doesn't exist, creates it with TODO comment
- Skips files that already exist

### Switch Command Logic

When switching environments (`SwitchCommand`):
1. Checks if already on target environment (warns and exits)
2. Backs up current active files to `.backup`
3. Copies environment-specific files to active location
4. Updates `current_environment` in `.switchrc`
5. Shows progress with updatable dot lines

### Testing Considerations

When adding new commands or modifying existing ones:
- Commands should work with both project and global configs
- Interactive prompts should accept empty input to use defaults
- File operations should handle missing files gracefully
- The fallback logic in `main.swift` may intercept arguments before your command runs

## File Organization

```
Sources/
├── Commands/          # ArgumentParser command implementations
├── Models/           # Data models (Config, GlobalConfig, Environment)
├── Services/         # Singleton services for config management
├── Helpers/          # Utility functions (file operations, console output)
├── Enums/           # Simple enums (FileStatus, BadgeType)
├── Errors/          # Custom error types
├── Extensions/      # Swift extensions (String, FileManager)
└── main.swift       # Entry point with custom argument handling
```

## Dependencies

- **swift-argument-parser** (1.6.1+) - CLI command structure
- **Rainbow** (4.0.0+) - Terminal color output

## Branch Strategy

- `main` - Main development branch
- `v2.x` - Current development branch for v2 rewrite

When creating PRs, target `main` unless working on v2-specific features.