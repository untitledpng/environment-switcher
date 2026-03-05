# Extend Mode

> **ALPHA** -- Extend mode is experimental and may produce invalid files in edge cases. Use with caution in production projects.

## Overview

By default, Environment Switcher uses **replace** mode: when you switch to an environment, each managed file is fully overwritten with its environment-specific copy. This works well when environment files are completely different, but many projects share 90% of their configuration across environments with only a handful of values changing (an API URL, a database host, a debug flag).

**Extend mode** solves this by *merging* environment-specific values into a shared base file instead of replacing it. You maintain a single `.default` file with all your shared configuration, and each environment file only contains the values that differ. When you switch, the tool deep-merges the two together.

## How It Works

Extend mode introduces a new file: `<filename>.default`. This file acts as the base template that all environments build on.

**File structure with replace mode (traditional):**

```
.env              <-- active file (fully replaced on switch)
.env.local        <-- complete config for local
.env.staging      <-- complete config for staging
.env.production   <-- complete config for production
.env.backup       <-- backup of previous active file
```

**File structure with extend mode:**

```
.env              <-- active file (merged result)
.env.default      <-- shared base values
.env.local        <-- only overrides for local
.env.staging      <-- only overrides for staging
.env.production   <-- only overrides for production
.env.backup       <-- backup of previous active file
```

When you run `switch production`, the tool:

1. Backs up the current `.env` to `.env.backup`
2. Reads `.env.default` (the shared base)
3. Reads `.env.production` (the environment overrides)
4. Merges them together -- base values are kept, overridden values are replaced
5. Writes the merged result to `.env`

### Conditions for Extend Mode

A file will only use extend mode when **all** of these are true:

- The resolved mode for that file is `extend`
- `extend_enabled` is `true` (from project or global config)
- The file is in the `extend_whitelist`
- The file type has a supported merge handler (`.env` or `env.php`)

If any condition is not met, the file falls back to standard **replace** behavior silently.

## Supported File Types

### `.env` (Dotenv)

Matches any file named `.env` or ending with `.env`.

**Merge behavior:** Key-value pair merge. Every key from the `.default` file is preserved. Keys present in the environment file override the default value. New keys in the environment file are appended.

**Example:**

`.env.default`:
```
APP_NAME=MyApp
APP_URL=http://localhost
APP_ENV=local
DB_HOST=127.0.0.1
DB_NAME=myapp
DEBUG=true
```

`.env.production`:
```
APP_URL=https://myapp.com
APP_ENV=production
DEBUG=false
```

**Merged result (`.env`):**
```
APP_NAME=MyApp
APP_URL=https://myapp.com
APP_ENV=production
DB_HOST=127.0.0.1
DB_NAME=myapp
DEBUG=false
```

Comments and blank lines from the `.default` file are preserved in their original position. Only key-value lines are subject to merging.

### `env.php` (Magento)

Matches files named `env.php`.

**Merge behavior:** Recursive deep merge of PHP associative arrays. Nested keys are merged at every level -- only leaf values are overridden. Non-dictionary values (strings, numbers, booleans, flat arrays) are replaced entirely.

**Requirement:** PHP must be available on the system `PATH`. The tool invokes `php` to parse the PHP array files and convert them to JSON for merging.

**Example:**

`env.php.default`:
```php
<?php
return [
    'db' => [
        'connection' => [
            'default' => [
                'host' => 'localhost',
                'dbname' => 'magento',
                'username' => 'root',
                'password' => '',
            ],
        ],
    ],
    'cache' => [
        'frontend' => [
            'default' => [
                'backend' => 'Cm_Cache_Backend_File',
            ],
        ],
    ],
];
```

`env.php.production`:
```php
<?php
return [
    'db' => [
        'connection' => [
            'default' => [
                'host' => 'db.internal',
                'password' => 's3cret',
            ],
        ],
    ],
];
```

**Merged result (`env.php`):**
```php
<?php
return [
    'cache' => [
        'frontend' => [
            'default' => [
                'backend' => 'Cm_Cache_Backend_File',
            ],
        ],
    ],
    'db' => [
        'connection' => [
            'default' => [
                'dbname' => 'magento',
                'host' => 'db.internal',
                'password' => 's3cret',
                'username' => 'root',
            ],
        ],
    ],
];
```

The `cache` section is kept intact from the default. The `db.connection.default.host` and `password` are overridden while `dbname` and `username` are preserved.

## Configuration

Extend mode is configured through two layers. Project settings override global settings.

### Global Config (`~/.config/switch/.switchrc`)

Run `switch config` to create or update the global configuration file. The following fields control extend mode:

```json
{
  "default_environments": ["local", "staging", "production"],
  "default_files": [".env"],
  "mode": "replace",
  "extend_enabled": false,
  "extend_whitelist": [],
  "file_modes": {}
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `mode` | `string` | `"replace"` | Default mode for all files: `"replace"` or `"extend"` |
| `extend_enabled` | `bool` | `false` | Master toggle -- extend mode is inactive unless this is `true` |
| `extend_whitelist` | `[string]` | `[]` | Files allowed to use extend mode (matched by name or suffix) |
| `file_modes` | `{string: string}` | `{}` | Per-file mode overrides, e.g. `{".env": "extend", "config.json": "replace"}` |

### Project Config (`.switchrc`)

The same four fields can be set per project. All are optional -- when omitted, the global value is used.

```json
{
  "current_environment": "local",
  "default_files": [".env", "env.php"],
  "environments": {
    "local": { "files": [] },
    "staging": { "files": [] },
    "production": { "files": [] }
  },
  "mode": "extend",
  "extend_enabled": true,
  "extend_whitelist": [".env", "env.php"],
  "file_modes": {
    ".env": "extend",
    "env.php": "extend"
  }
}
```

### Resolution Priority

When determining how to switch a specific file, the tool resolves the mode in this order (first match wins):

1. **Project `file_modes`** -- per-file override in `.switchrc`
2. **Global `file_modes`** -- per-file override in global config
3. **Project `mode`** -- project-wide mode in `.switchrc`
4. **Global `mode`** -- global default mode

After resolving the mode, extend will only activate if `extend_enabled` is true, the file is in the `extend_whitelist`, and the file type has a supported handler. Otherwise, the file falls back to replace.

## Setup via `switch init`

When initializing a new project with `switch init`, you will be prompted to configure extend mode after choosing your environments and files:

```
Do you want to configure extend mode for this project? (y/n, default: n)
> y
```

If you answer `y`, the following prompts appear:

1. **Project mode override** -- set the default mode for this project (`replace` or `extend`), or press Enter to inherit from global config
2. **Extend enabled override** -- enable or disable extend for this project, or press Enter to inherit
3. **Extend whitelist override** -- comma-separated list of files allowed to use extend, or press Enter to inherit
4. **Files that should always use extend** -- pick from your selected files to force extend mode on specific files
5. **Files that should always use replace** -- pick from your selected files to force replace mode on specific files

When file creation is offered, the tool also creates `.default` files for any file that resolves to extend mode (copying the content from the original file if it exists).

## Manual Setup

To add extend mode to an existing project:

1. **Edit your global config** (optional, for defaults across projects):

```bash
switch config
```

Then edit `~/.config/switch/.switchrc`:

```json
{
  "default_environments": ["local", "staging", "production"],
  "default_files": [".env"],
  "mode": "replace",
  "extend_enabled": true,
  "extend_whitelist": [".env"]
}
```

2. **Edit your project `.switchrc`** to enable extend for specific files:

```json
{
  "current_environment": "local",
  "default_files": [".env"],
  "environments": {
    "local": { "files": [] },
    "staging": { "files": [] },
    "production": { "files": [] }
  },
  "extend_enabled": true,
  "extend_whitelist": [".env"],
  "file_modes": {
    ".env": "extend"
  }
}
```

3. **Create the `.default` base file** with your shared configuration:

```bash
cp .env .env.default
```

4. **Trim your environment files** to only contain overrides:

`.env.local`:
```
APP_ENV=local
APP_URL=http://localhost
```

`.env.production`:
```
APP_ENV=production
APP_URL=https://myapp.com
DEBUG=false
```

5. **Switch and verify**:

```bash
switch production
```

The active `.env` will now be the merged result of `.env.default` + `.env.production`.

## Practical Examples

### Dotenv Project

A Node.js project with a shared base config and minimal per-environment overrides.

`.env.default`:
```
APP_NAME=MyApp
APP_PORT=3000
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=myapp
DB_USER=postgres
DB_PASS=
LOG_LEVEL=info
CACHE_TTL=3600
```

`.env.local`:
```
DB_PASS=localpass
LOG_LEVEL=debug
CACHE_TTL=0
```

`.env.staging`:
```
DB_HOST=staging-db.internal
DB_PASS=stg_secret
```

`.env.production`:
```
DB_HOST=prod-db.internal
DB_PASS=prod_secret
LOG_LEVEL=warn
```

After `switch staging`, the active `.env` contains all 9 keys from the default, with `DB_HOST` and `DB_PASS` overridden by the staging values.

### Magento Project

A Magento 2 project using `env.php` with complex nested PHP arrays.

`.switchrc`:
```json
{
  "current_environment": "local",
  "default_files": ["app/etc/env.php"],
  "environments": {
    "local": { "files": [] },
    "staging": { "files": [] },
    "production": { "files": [] }
  },
  "extend_enabled": true,
  "extend_whitelist": ["env.php"],
  "file_modes": {
    "app/etc/env.php": "extend"
  }
}
```

`app/etc/env.php.default` contains the full Magento configuration. Each environment file only overrides what changes (database credentials, cache backend, admin URL, etc.). The deep merge ensures nested arrays are handled correctly.

## Limitations

- **ALPHA status** -- the feature may produce unexpected results in edge cases. Review merged output after switching.
- **Unsupported file types fall back to replace** -- only `.env` and `env.php` have merge handlers. Files like `config.json`, `config.yaml`, or others will use replace mode regardless of configuration.
- **PHP required for `env.php`** -- the `php` binary must be in your system `PATH`. If PHP is not available, `env.php` merge will fail.
- **`.default` file is required** -- if the `.default` file is missing when extend mode tries to merge, the operation will fail with an error. Make sure to create it before switching.
- **Key ordering** -- dotenv merge preserves the line order from the `.default` file. New keys from the environment file are appended at the end. PHP array output uses sorted keys.
- **No partial merge for flat values** -- in `env.php`, non-dictionary values (strings, numbers, arrays) are replaced entirely, not merged. Only associative arrays are recursively merged.
