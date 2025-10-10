# 🔄 Environment Switcher

A lightweight CLI tool for seamlessly switching between different environment configurations in your projects.

## ✨ Features

- 🚀 Fast environment switching with a single command
- 📝 JSON-based configuration (`.switchrc`)
- 🔒 Automatic backup of existing files
- 🎯 Support for multiple files per environment
- 💡 Simple and intuitive CLI
- 👨‍💻 Interactive init command to create `.switchrc` file and update your `.gitignore`
- 🌍 Global configuration for customizing default behaviors
- 📋 Default files mode - define files once, share across environments
- 🎨 Color-coded output for better visibility
- 📊 Status command to view current environment and file states

## 📦 Installation

### Using Homebrew (Recommended)

```bash
brew install untitledpng/tap/environment-switcher
```

### From Source

```bash
# Clone the repository
git clone https://github.com/untitledpng/environment-switcher.git
cd environment-switcher

# Build the project
swift build -c release

# Copy the binary to a location in your PATH
cp .build/release/switch /usr/local/bin/
```

## 🚀 Quick Start

1. **Initialize configuration** in your project directory:
   ```bash
   switch init
   ```
   This creates a `.switchrc` file with your chosen environments and files.

2. **Create environment-specific files**:
   ```bash
   # The init command can create these automatically, or you can create them manually
   # Example: Create different .env files for each environment
   touch .env.local .env.staging .env.production
   ```

3. **Check current status**:
   ```bash
   switch status
   # or simply
   switch
   ```

4. **Switch to an environment**:
   ```bash
   switch production
   # or using the explicit command
   switch to production
   ```

## 📖 Usage

### Commands

```bash
switch                    # Show current status (default command)
switch init               # Create .switchrc configuration file in current directory
switch status             # View current environment and file states
switch config             # Create/update global configuration
switch to <env>           # Switch to specified environment
switch <env>              # Shorthand for switching (e.g., switch production)
switch save               # Save modified files to current environment-specific files
switch rollback           # Restore files from backup (undo changes to active files)
switch --help             # Show help information
```

### Status Command

The `status` command (or just `switch` without arguments) displays:
- Current active environment
- Available environments
- Files being managed with their status:
  - Normal (dim) - File matches the environment version
  - Modified (yellow) - File has been changed since switching
  - Not found (red) - Expected file is missing

### Save Command

The `save` command persists your changes back to the current environment-specific files:
- Saves modifications from active files (e.g., `.env`) to environment files (e.g., `.env.staging`)
- Only saves files that have been modified (detected via SHA-256 hash comparison)
- Shows which files were saved, skipped, or failed
- Useful for updating environment configurations after making changes

**Example usage:**
```bash
# Switch to staging
switch staging

# Make changes to .env
echo "DEBUG=true" >> .env
echo "LOG_LEVEL=verbose" >> .env

# Check status - file shows as modified
switch status

# Save changes back to .env.staging
switch save
# .env.staging now contains your changes
```

### Rollback Command

The `rollback` command restores your environment files from their backup copies:
- Reverts any changes made to active files after switching environments
- Restores files from `.backup` versions created during environment switches
- Shows detailed feedback about which files were rolled back
- Useful when you've made unwanted changes to environment files

**Example usage:**
```bash
# Switch to production
switch production

# Make changes to .env
echo "DEBUG=true" >> .env

# Oops! Rollback the changes
switch rollback
# .env is now restored to its state from before the modifications
```

## ⚙️ Configuration

### Project Configuration (`.switchrc`)

The `.switchrc` file in your project directory defines your environments and which files to switch. Environments are **completely dynamic** — you define them based on your project's needs.

**Example with default files (recommended):**
```json
{
  "current_environment": "local",
  "default_files": [".env"],
  "environments": {
    "local": { "files": [] },
    "staging": { "files": [] },
    "production": { "files": [] }
  }
}
```

In this mode:
- `default_files` lists files that apply to all environments
- Individual environments have `"files": []` to use the default files
- Each environment needs corresponding files: `.env.local`, `.env.staging`, etc.

**Example with per-environment files:**
```json
{
  "current_environment": "local",
  "default_files": [],
  "environments": {
    "local": {
      "files": [".env"]
    },
    "staging": {
      "files": [".env", "config.json"]
    },
    "production": {
      "files": [".env", "config.json", "credentials.json"]
    }
  }
}
```

In mixed mode:
- `local` and `staging` use only `.env` (from default_files)
- `production` uses both `.env` (from default_files) and `credentials.json` (from environment-specific files)

> 💡 **Note:** Environment names like "local", "staging", and "production" are just examples. You can create any custom environments that match your workflow (e.g., "dev", "test", "demo", "client-a", etc.).

### Global Configuration (`~/.config/switch/.switchrc`)

Customize default behaviors across all projects:

```json
{
  "default_environments": ["local", "staging", "production"],
  "default_files": [".env", "config.json"]
}
```

These defaults are used when running `switch init` to provide suggestions. Run `switch config` to create your global configuration file.

### How It Works

When you run `switch production`:
1. Backs up current files (e.g., `.env` → `.env.backup`)
2. Copies environment-specific files (e.g., `.env.production` → `.env`)
3. Tracks the current environment in `.switchrc`
4. Your application now uses the production configuration!

### File Management

- **Environment-specific files**: Store configurations as `<filename>.<environment>` (e.g., `.env.local`, `.env.production`)
- **Active files**: The base filename (e.g., `.env`) contains the current environment's configuration
- **Backups**: Previous active files are saved as `<filename>.backup`
- **File status tracking**: The `status` command shows if files have been modified since switching

### Interactive Setup Features

During `switch init`, you'll be prompted to:

1. **Choose environments**: Enter comma-separated environment names (default suggestions from global config)
2. **Select files to manage**: Choose which files should be switched between environments
3. **Update .gitignore**: Automatically add entries for:
   - `.switchrc` (your configuration)
   - Base files (e.g., `.env`)
   - All environment-specific files (e.g., `.env.*`)
4. **Create environment files**: Optionally create all environment-specific files:
   - If base file exists, copies its content to environment files
   - If base file doesn't exist, creates it with a TODO comment
   - Creates environment files with appropriate headers/comments

## 🎯 Use Cases

### Single Project Configuration
```bash
# Initialize for a typical web project
switch init
# Environments: local, staging, production
# Files: .env, config.json

# Switch to staging for testing
switch staging

# Switch to production for deployment
switch production
```

### Multiple Configuration Files
```bash
# Manage multiple files per environment
switch init
# Environments: dev, test, prod
# Files: .env, database.yml, credentials.json

# All files are switched together
switch prod
```

### Team Development
```bash
# Set up global defaults for consistency across team
switch config
# Edit ~/.config/switch/.switchrc with team standards

# Each team member runs in their projects
switch init
# Uses team's standard environments and files
```

### Rollback After Mistakes
```bash
# Switch to production environment
switch production

# Accidentally modify the active .env file
echo "FEATURE_FLAG=true" >> .env

# Check status - file shows as modified
switch status

# Rollback to restore the original production config
switch rollback

# File is now back to its original state
```

### Iterative Development Workflow
```bash
# Switch to development environment
switch dev

# Make changes to configuration
echo "API_ENDPOINT=http://localhost:3000" >> .env
echo "DEBUG_MODE=true" >> .env

# Test your changes
npm start

# Changes work! Save them to the dev environment
switch save

# Now .env.dev has your updates, and they're persistent
```

## 🛡️ Safety Features

- **Automatic backups**: Original files are backed up before switching
- **Save capability**: Persist your changes back to environment-specific files
- **Rollback capability**: Restore files from backup if you make mistakes
- **File existence checks**: Warns if environment-specific files are missing
- **Current environment tracking**: Prevents redundant switches to the same environment
- **Status visualization**: Color-coded file states help identify issues
- **Git integration**: Prompts to update `.gitignore` to protect sensitive files

## 🔄 Updating

```bash
# Using Homebrew (recommended)
brew update
brew upgrade untitledpng/tap/environment-switcher

# From source
cd environment-switcher
git pull
swift build -c release
cp .build/release/switch /usr/local/bin/
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💡 Tips

- Use `switch` without arguments to quickly check your current environment
- Use `switch save` after making changes to persist them to the current environment
- The `.switchrc` file should be committed to version control
- Environment-specific files (`.env.local`, etc.) should be in `.gitignore`
- Base files (`.env`) should also be in `.gitignore` if they contain sensitive data
- Use global config (`switch config`) to standardize settings across multiple projects
- The tool creates `.backup` files when switching - these are safe to delete or add to `.gitignore`

## 🐛 Troubleshooting

### Files not switching?
- Run `switch status` to check file states
- Verify environment-specific files exist (e.g., `.env.production`)
- Check that files are listed in your `.switchrc` configuration

### Environment not found?
- Run `switch status` to see available environments
- Check your `.switchrc` file for the correct environment name
- Environment names are case-sensitive

### Save says no modified files?
- Run `switch status` to check if files are actually modified
- The save command uses SHA-256 hashing to detect changes
- If the file content matches the environment file, it won't be saved
- Make sure you've actually changed the active file, not the environment-specific file

### Rollback not working?
- Backup files are created when you switch environments
- If you haven't switched yet, there won't be any `.backup` files
- Check if `.backup` files exist in your project directory
- Rollback only restores files that have backup copies

### Permission errors?
- Ensure you have write permissions in the project directory
- Check that environment-specific files are readable
