# docker-php

Docker images for PHP, published to `ghcr.io/aliasproject/php`. The primary offering is [FrankenPHP](https://frankenphp.dev/) (Caddy + PHP) for 8.2–8.5, plus CLI images for 8.3–8.5. Images for PHP versions past end of life (8.1 and older) are no longer built; their last `7.4/8.0/8.1-cli-latest` tags are left in the registry but get no updates.

## Image matrix

| PHP  | CLI | FrankenPHP | FrankenPHP (dev) | FrankenPHP (WordPress) |
|------|:---:|:----------:|:-----------------:|:------------------------:|
| 8.2  |     | ✅         | ✅                 | ✅                       |
| 8.3  | ✅  | ✅         | ✅                 | ✅                       |
| 8.4  | ✅  | ✅         | ✅                 | ✅                       |
| 8.5  | ✅  | ✅         | ✅                 | ✅                       |

Tags follow `<version>-<variant>` (e.g. `8.4-frankenphp-wordpress`), each also published as `-latest` and as `-<sha>` for the commit it was built from. Every image is rebuilt weekly (Mondays 10:00 UTC) to pick up base-image and Alpine package updates, which also refreshes the `-<sha>` tag of the current commit; pin by digest (`@sha256:…`) for a byte-for-byte fixed image. The frankenphp images stay on their pinned FrankenPHP version, so a new FrankenPHP release (and the PHP version it ships) still needs `FRANKENPHP_VERSION` bumped in their Dockerfiles.

```sh
docker pull ghcr.io/aliasproject/php:8.4-frankenphp
```

## Variants

- **cli** — the PHP CLI with unlimited execution time. 8.3–8.5 are built on the official `php:<version>-cli-alpine` images, so a rebuild picks up the latest php.net patch release. 8.3–8.5 are also rebuilt weekly (Mondays 10:00 UTC), so they pick up new PHP patch releases without a Dockerfile change. PHP's ini files are in `/usr/local/etc/php` (`conf.d/` for overrides). 8.3–8.5 are identical apart from the PHP version: a minimal extension set (`pdo_mysql`, `bcmath`, `intl`, `pcntl`, `zip`, etc.), a 512M memory limit, and an unprivileged `appuser` in group `0`. Backend and library extensions (`mysqli`, `gd`, `imagick`, `redis`, `igbinary`, …) belong in a derived image such as `php/8.4/cli/Dockerfile.wordpress`.
- **frankenphp** — FrankenPHP serves PHP directly through Caddy; no separate web server. Minimal extension set, non-root by default, mail sent through `msmtp`, Composer baked in, `HEALTHCHECK` against Caddy's admin API.
- **frankenphp (dev)** — the FrankenPHP base with extra extensions (`mysqli`, `gd`, `exif`, `imagick`, `redis`, `igbinary`, `soap`) for local development.
- **frankenphp (wordpress)** — the FrankenPHP base with the same extensions as `dev`, plus a hardening policy suited to running WordPress (see below).

Every frankenphp image is configurable via environment variables — `PHP_MEMORY_LIMIT`, `PHP_OPCACHE_*`, `PHP_UPLOAD_MAX_FILESIZE`, etc. — see each Dockerfile's `ENV` block for the defaults. The cli images have no such variables; override PHP settings with an ini file in `/usr/local/etc/php/conf.d/` or `php -d`.

## Static asset caching

Caddy's `file_server` sends no `Cache-Control` by default, so browsers revalidate every asset on every visit and a CDN in front (Cloudflare, etc.) falls back to a short edge TTL and revalidates against the origin from every PoP. Every `frankenphp` variant can render a Caddy snippet at boot that fixes this. Nothing is emitted unless at least one path list is set, so the base image is unaffected until you opt in:

- `CADDY_IMMUTABLE_ASSET_PATHS` — space-separated path prefixes whose files are content-hashed or carry a version in the URL (a Vite/Mix build dir, `?ver=` assets, minifier output). A change always means a new URL, so they are served with `public, max-age=31536000, immutable` (`CADDY_IMMUTABLE_ASSET_MAX_AGE`).
- `CADDY_MEDIA_PATHS` — user uploads, which keep their filename when replaced in place. Served with `public, max-age=2592000` (`CADDY_MEDIA_MAX_AGE`) so a stale copy is bounded.
- `CADDY_IMMUTABLE_ASSET_EXTENSIONS` / `CADDY_MEDIA_EXTENSIONS` — space-separated, no dots; sensible defaults for CSS/JS/fonts/images and for images/video/PDF respectively.

`*` in a prefix matches a single path segment. The header is only applied when the file exists on disk, so 404s are never cached long-term, and HTML, PHP and JSON responses are untouched.

```sh
# Laravel with a Vite build and user uploads on the public disk
docker run -e CADDY_IMMUTABLE_ASSET_PATHS="/build/" \
           -e CADDY_MEDIA_PATHS="/storage/" \
           ghcr.io/aliasproject/php:8.4-frankenphp
```

The `wordpress` variant sets both lists out of the box (see below).

## WordPress hardening

The `frankenphp:wordpress` variant renders a Caddy hardening snippet at container boot:

- `PHP_NO_EXEC_PATHS` — writable directories (uploads, cache, upgrade) can never execute PHP.
- `PHP_DENY_PATHS` / `PHP_DENY_EXTENSIONS` — `.env`, `.git`, `wp-config.php`, `readme.html`/`license.txt`, and backup/dump/log files are never served, at any depth.
- `PHP_DISABLE_FUNCTIONS` — disables `exec`, `passthru`, `shell_exec`, `system`, `pcntl_exec`, `dl`.
- Runs as a non-root user (UID configurable via `--build-arg APP_UID`) in group `0`.

All of the above are overridable via environment variables if a site needs different values.

The `wordpress` variant also ships defaults for the [static asset caching](#static-asset-caching) snippet covering both the Bedrock (`/app/...`, `/wp/...`) and stock (`/wp-content/...`, `/wp-includes/...`) layouts, including cache-plugin output and Avada's compiled `fusion-styles` / `fusion-scripts` directories.
