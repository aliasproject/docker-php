# docker-php

Docker images for PHP, published to `ghcr.io/aliasproject/php`. The primary offering is [FrankenPHP](https://frankenphp.dev/) (Caddy + PHP) for 8.2–8.5, plus CLI images for the same versions. Older FPM-based images (7.4–8.2) remain published for existing consumers but are being phased out in favor of FrankenPHP.

## Image matrix

| PHP  | CLI | FPM              | FPM + nginx | FrankenPHP | FrankenPHP (dev) | FrankenPHP (WordPress) |
|------|:---:|:----------------:|:-----------:|:----------:|:-----------------:|:------------------------:|
| 7.4  | ✅  | ✅               | ✅          |            |                    |                          |
| 8.0  | ✅  | ✅ alpine/ubuntu | ✅          |            |                    |                          |
| 8.1  | ✅  | ✅               | ✅          |            |                    |                          |
| 8.2  |     | ✅               | ✅          | ✅         | ✅                 | ✅                       |
| 8.3  | ✅  |                  |             | ✅         | ✅                 | ✅                       |
| 8.4  | ✅  |                  |             | ✅         | ✅                 | ✅                       |
| 8.5  | ✅  |                  |             | ✅         | ✅                 | ✅                       |

Tags follow `<version>-<variant>` (e.g. `8.4-frankenphp-wordpress`), each also published as `-latest` and pinned to a commit as `-<sha>`.

```sh
docker pull ghcr.io/aliasproject/php:8.4-frankenphp
```

## Variants

- **cli** — Alpine + the PHP CLI SAPI and a minimal extension set (`pdo_mysql`, `bcmath`, `pcntl`, `posix`, etc.), unlimited execution time, runs as an unprivileged `appuser` in group `0`.
- **fpm** *(legacy)* — PHP-FPM under s6-overlay, configurable pool sizing via `PHP_PM_*` env vars.
- **fpm-nginx** *(legacy)* — the `fpm` image plus nginx in front of it.
- **frankenphp** — FrankenPHP serves PHP directly through Caddy; no separate web server. Minimal extension set, non-root by default, mail sent through `msmtp`, Composer baked in, `HEALTHCHECK` against Caddy's admin API.
- **frankenphp (dev)** — the FrankenPHP base with extra extensions (`mysqli`, `gd`, `exif`, `imagick`, `redis`, `igbinary`, `soap`) for local development.
- **frankenphp (wordpress)** — the FrankenPHP base with the same extensions as `dev`, plus a hardening policy suited to running WordPress (see below).

Every image is configurable via environment variables — `PHP_MEMORY_LIMIT`, `PHP_OPCACHE_*`, `PHP_UPLOAD_MAX_FILESIZE`, etc. — see each Dockerfile's `ENV` block for the defaults.

## WordPress hardening

The `frankenphp:wordpress` variant renders a Caddy hardening snippet at container boot:

- `PHP_NO_EXEC_PATHS` — writable directories (uploads, cache, upgrade) can never execute PHP.
- `PHP_DENY_PATHS` / `PHP_DENY_EXTENSIONS` — `.env`, `.git`, `wp-config.php`, `readme.html`/`license.txt`, and backup/dump/log files are never served, at any depth.
- `PHP_DISABLE_FUNCTIONS` — disables `exec`, `passthru`, `shell_exec`, `system`, `pcntl_exec`, `dl`.
- Runs as a non-root user (UID configurable via `--build-arg APP_UID`) in group `0`.

All of the above are overridable via environment variables if a site needs different values.
