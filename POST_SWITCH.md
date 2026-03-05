# Post-Switch Commands

## Overview

Post-switch commands allow you to automatically run scripts or commands after switching environments. Commands can be defined at three levels -- global user config, project root, and per-environment -- giving you fine-grained control over what runs and when.

## Execution Order

When a switch completes, post-switch commands are collected and executed in this order:

1. **Global config** (`~/.config/switch/.switchrc`) -- runs first, applies to every project
2. **Project root** (`.switchrc` top-level `post_switch`) -- runs second, applies to every environment in the project
3. **Environment-level** (`.switchrc` per-environment `post_switch`) -- runs last, only for the target environment

Each level is independent. If a level has no commands, it is silently skipped.

## Configuration

### Global config (`~/.config/switch/.switchrc`)

Add a `post_switch` array to your global config. These commands run after every switch in every project.

```json
{
  "default_environments": ["local", "staging", "production"],
  "default_files": [".env"],
  "post_switch": [
    "/usr/local/bin/notify-switch"
  ]
}
```

### Project root (`.switchrc`)

Add a top-level `post_switch` array alongside `environments` and `default_files`. These commands run after every switch within this project, regardless of the target environment.

```json
{
  "current_environment": "local",
  "default_files": [".env"],
  "post_switch": [
    "/usr/local/bin/clear-cache"
  ],
  "environments": {
    "local": {
      "files": []
    },
    "staging": {
      "files": []
    },
    "production": {
      "files": []
    }
  }
}
```

### Environment-level (`.switchrc` per-environment)

Add a `post_switch` array inside a specific environment. These commands only run when switching to that particular environment.

```json
{
  "current_environment": "local",
  "default_files": [".env"],
  "post_switch": [
    "/usr/local/bin/clear-cache"
  ],
  "environments": {
    "local": {
      "files": [],
      "post_switch": [
        "/usr/local/bin/seed-database"
      ]
    },
    "staging": {
      "files": [],
      "post_switch": [
        "/usr/local/bin/sync-assets --env staging"
      ]
    },
    "production": {
      "files": []
    }
  }
}
```

In this example, switching to **staging** would run:
1. `/usr/local/bin/clear-cache` (project root)
2. `/usr/local/bin/sync-assets --env staging` (environment-level)

## How It Works

1. The environment switch completes normally (backup, file copy, config update)
2. Global config `post_switch` commands are executed first (if any)
3. Project root `post_switch` commands are executed next (if any)
4. Environment-level `post_switch` commands are executed last (if any)
5. Each group prints its own **INFO** banner before executing
6. Each command is executed sequentially using `/bin/sh -c "<command>"` in the current working directory
7. A status line is printed per command showing **RUNNING**, **DONE**, or **FAILED**
8. If a command fails (non-zero exit code or launch error), it is marked as **FAILED** and the next command runs -- the sequence is not aborted

## Examples

### Clear application cache after switching

```json
"post_switch": [
  "/usr/bin/php artisan cache:clear"
]
```

### Run a setup script and restart a local service

```json
"post_switch": [
  "/bin/bash ./scripts/setup-env.sh",
  "/usr/bin/brew services restart nginx"
]
```

### Pipe and shell features

Commands are passed to `/bin/sh -c`, so shell features like pipes and chaining work:

```json
"post_switch": [
  "/bin/echo 'Switched to production' | /usr/bin/tee -a switch.log"
]
```

## Output

When post-switch commands are configured at multiple levels, the output during a switch looks like this:

```
 INFO  Switching to the staging environment.

  Copying file (backup) [.env] to [.env.backup] ..................... DONE
  Applying replace strategy [.env.staging] to [.env] ............... DONE
  Updating configuration file [.switchrc] .......................... DONE

 INFO  Running global post-switch commands

  Executing [/usr/local/bin/notify-switch] ......................... DONE

 INFO  Running project post-switch commands

  Executing [/usr/local/bin/clear-cache] ........................... DONE

 INFO  Running environment post-switch commands

  Executing [/usr/local/bin/sync-assets --env staging] ............. DONE
```

If no `post_switch` is defined at any level, all sections are silently skipped.

## Notes

- Commands run in the current working directory (the project root where `.switchrc` lives).
- Use full paths for executables to avoid `PATH` resolution issues.
- `post_switch` is optional at every level -- omitting it has no effect.
- Existing `.switchrc` files without `post_switch` are fully backwards-compatible; no changes are needed.
