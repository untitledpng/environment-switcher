# 🔄 Environment Switcher

A lightweight CLI tool for seamlessly switching between different environment configurations in your projects.

## ✨ Features

- 🚀 Fast environment switching with a single command
- 📝 JSON-based configuration (`.switchrc`)
- 🔒 Automatic backup of existing files
- 🎯 Support for multiple files per environment
- 💡 Simple and intuitive CLI
- 👨‍💻 Interactive init command to create `.switchrc` file and update your .gitignore
- 🌍 Global configuration for customizing default behaviors
- 📋 Default files mode - define files once, share across environments

## 📦 Installation

```bash
brew install untitledpng/tap/environment-switcher
```

## 🚀 Quick Start

1. **Initialize configuration** in your project directory:
   ```bash
   switch init
   ```
   This creates a `.switchrc` file with example environments (local, staging, production).

2. **Create environment-specific files**:
   ```bash
   # Example: Create different .env files for each environment
   touch .env.local .env.staging .env.production
   ```

3. **List available environments**:
   ```bash
   switch --list
   ```

4. **Switch to an environment (example)**:
   ```bash
   switch production
   ```

## 📖 Usage

```bash
switch init          # Create .switchrc configuration file in current directory
switch config        # Create/update global configuration
switch --list        # List available environments
switch <env>         # Switch to specified environment
switch --help        # Show help information
```

## ⚙️ Configuration

### Project Configuration (`.switchrc`)

The `.switchrc` file in your project directory defines your environments and which files to switch. Environments are **completely dynamic** — you define them based on your project's needs.

**Example with default files (recommended):**
```json
{
  "files": [".env", "config.json"],
  "environments": {
    "local": { "files": [] },
    "staging": { "files": [] },
    "production": { "files": [] }
  }
}
```

**Example with per-environment files:**
```json
{
  "environments": {
    "local": {
      "files": [".env"]
    },
    "staging": {
      "files": [".env"]
    },
    "production": {
      "files": [".env", "credentials.json"]
    }
  }
}
```

> 💡 **Note:** Environment names like "local", "staging", and "production" are just examples. You can create any custom environments that match your workflow (e.g., "dev", "test", "demo", "client-a", etc.).

### Global Configuration (`~/.config/switch/.switchrc`)

Customize default behaviors across all projects:

```json
{
  "initDefaults": {
    "environments": ["dev", "test", "prod"],
    "files": [".env", "config.yml"]
  }
}
```

Run `switch config` to create or update your global configuration.

### How It Works

When you run `switch production`:
1. Backs up current files (e.g., `.env` → `.env.backup`)
2. Copies environment-specific files (e.g., `.env.production` → `.env`)
3. Tracks the current environment in `.switchrc`
4. Your application now uses the production configuration!

## 🔄 Updating

```bash
brew update
brew upgrade untitledpng/tap/environment-switcher
```

## 📄 License

MIT
