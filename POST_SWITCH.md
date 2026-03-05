# Post-Switch Commands

## Overview

Post-switch commands allow you to automatically run scripts or commands after switching environments. Each environment can define its own set of commands, making it easy to trigger environment-specific setup tasks like clearing caches, restarting services, or running migrations.

## Configuration

Add a `post_switch` array to any environment in your project `.switchrc`. Each entry is a command string that will be executed via `/bin/sh` in the project directory.

```json
{
  "current_environment": "local",
  "default_files": [".env"],
  "environments": {
    "local": {
      "files": [],
      "post_switch": [
        "/usr/local/bin/clear-cache"
      ]
    },
    "staging": {
      "files": [],
      "post_switch": [
        "/usr/local/bin/clear-cache",
        "/usr/local/bin/sync-assets --env staging"
      ]
    },
    "production": {
      "files": []
    }
  }
}
```

In this example:
- Switching to **local** runs one command
- Switching to **staging** runs two commands sequentially
- Switching to **production** runs no post-switch commands (the key is omitted)

## How It Works

1. The environment switch completes normally (backup, file copy, config update)
2. If the target environment has a `post_switch` array with at least one entry, an **INFO** banner is printed
3. Each command is executed sequentially using `/bin/sh -c "<command>"` in the current working directory
4. A status line is printed per command showing **RUNNING**, **DONE**, or **FAILED**
5. If a command fails (non-zero exit code or launch error), it is marked as **FAILED** and the next command runs -- the sequence is not aborted

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

When post-switch commands are configured, the output during a switch looks like this:

```
 INFO  Switching to the staging environment.

  Copying file (backup) [.env] to [.env.backup] ..................... DONE
  Applying replace strategy [.env.staging] to [.env] ............... DONE
  Updating configuration file [.switchrc] .......................... DONE

 INFO  Running post-switch commands

  Executing [/usr/local/bin/clear-cache] ........................... DONE
  Executing [/usr/local/bin/sync-assets --env staging] ............. DONE
```

If no `post_switch` is defined for the target environment, this section is silently skipped.

## Notes

- Commands run in the current working directory (the project root where `.switchrc` lives).
- Use full paths for executables to avoid `PATH` resolution issues.
- `post_switch` is optional -- environments without it behave exactly as before.
- Existing `.switchrc` files without `post_switch` are fully backwards-compatible; no changes are needed.
