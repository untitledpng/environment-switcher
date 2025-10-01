# 🔄 Environment Switcher

A lightweight CLI tool for seamlessly switching between different environment configurations in your projects.

## ✨ Features

- 🚀 Fast environment switching with a single command
- 📝 JSON-based configuration (`.switchrc`)
- 🔒 Automatic backup of existing files
- 🎯 Support for multiple files per environment
- 💡 Simple and intuitive CLI

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
switch init          # Create example .switchrc file
switch --list        # List available environments
switch <env>         # Switch to specified environment
```

## ⚙️ Configuration

The `.switchrc` file defines your environments and which files to switch. Environments are **completely dynamic** — you define them based on your project's needs.

**Example `.switchrc`:**
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
      "files": [".env"]
    }
  }
}
```

> 💡 **Note:** Environment names like "local", "staging", and "production" are just examples. You can create any custom environments that match your workflow (e.g., "dev", "test", "demo", "client-a", etc.).

### How It Works

When you run `switch production`:
1. Backs up current files (e.g., `.env` → `.env.backup`)
2. Copies environment-specific files (e.g., `.env.production` → `.env`)
3. Your application now uses the production configuration!

## 🔄 Updating

```bash
brew update
brew upgrade untitledpng/tap/environment-switcher
```

## 📄 License

MIT
