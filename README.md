# docker-php

Docker images for PHP, published to `ghcr.io/aliasproject/php`. The primary offering is [FrankenPHP](https://frankenphp.dev/) (Caddy + PHP) for 8.2–8.5, plus CLI images for 8.3–8.5. Images for PHP versions past end of life (8.1 and older) are no longer built. Their last `7.4/8.0/8.1-cli-latest` tags are left in the registry, but they're unpatched (including for CVE-2026-109618/109619); move to `8.3-cli` or newer.

## Image matrix

| PHP  | CLI | FrankenPHP | FrankenPHP (dev) | FrankenPHP (WordPress) |
|------|:---:|:----------:|:-----------------:|:------------------------:|
| 8.2  |     | ✅         | ✅                 | ✅                       |
| 8.3  | ✅  | ✅         | ✅                 | ✅                       |
| 8.4  | ✅  | ✅         | ✅                 | ✅                       |
| 8.5  | ✅  | ✅         | ✅                 | ✅                       |

Tags follow `<version>-<variant>` (e.g. `8.4-frankenphp-wordpress`), each also published as `-latest` and as `-<sha>` for the commit it was built from. Every image is rebuilt weekly (Mondays 10:00 UTC) to pick up base-image and Alpine package updates, which also refreshes the `-<sha>` tag of the current commit; pin by digest (`@sha256:…`) for a byte-for-byte fixed image. The amd64 image of every variant is booted and checked (PHP version, extensions, non-root, healthy and serving PHP for the frankenphp images) before it gets any tag, so a build that doesn't start never replaces `-latest`; the check is `.github/scripts/smoke-test.sh`. The arm64 images are built and published but not booted. The frankenphp images stay on their pinned FrankenPHP version, so a new FrankenPHP release (and the PHP version it ships) still needs `FRANKENPHP_VERSION` bumped in their Dockerfiles.

```sh
docker pull ghcr.io/aliasproject/php:8.4-frankenphp
```

## Variants

- **cli** — the PHP CLI with unlimited execution time, built on the official `php:<version>-cli-alpine` images, so each rebuild (including the weekly one) picks up the latest php.net patch release. PHP's ini files are in `/usr/local/etc/php` (`conf.d/` for overrides). The versions are identical apart from PHP itself: a minimal extension set (`pdo_mysql`, `bcmath`, `intl`, `pcntl`, `zip`, etc.), a 512M memory limit, and an unprivileged `appuser` in group `0`. Backend and library extensions (`mysqli`, `gd`, `imagick`, `redis`, `igbinary`, …) belong in a derived image such as `php/8.4/cli/Dockerfile.wordpress`.
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

## Laravel hardening

Laravel's `storage` directory holds user-controlled files, and the Livewire upload vulnerability ([GHSA-29cq-5w36-x7w3](https://github.com/livewire/livewire/security/advisories/GHSA-29cq-5w36-x7w3)) was exploited in the wild by dropping a `.php` file there and requesting `/storage/....php`. Every frankenphp image therefore refuses, with a 404, any URL under `/storage/` that names a `.php` file (any case such as `shell.PHP`, any depth, with or without trailing path info such as `shell.php/foo`, however the path is encoded) and any directory URL (`/storage/` or `/storage/dir/`), because the server would answer a directory by running its `index.php`. This is on by default; set `PHP_DENY_STORAGE_PHP=off` (or `0`, `false`, `no`) for an app that really does serve PHP from a `/storage/` URL. Any other value leaves the rule on.

Only those URLs are refused. Everything else under `/storage/` is handled as usual: uploads in `public/storage` are served as static files, and a PHP route at `/storage/{path}` still works, such as Laravel 11+'s local-disk `serve` route for signed `Storage::disk('local')->temporaryUrl()` links.

The rule covers only the URL path `/storage/`. For other directories the app can write to, `PHP_NO_EXEC_PATHS` goes further: nothing under those prefixes can ever reach the PHP handler, so a request for a path with no file behind it gets a 404 rather than falling through to the app (which is why it is not the default for `/storage/`).

```sh
docker run -e PHP_NO_EXEC_PATHS="/uploads/*" \
           -e CADDY_IMMUTABLE_ASSET_PATHS="/build/" \
           -e CADDY_MEDIA_PATHS="/storage/" \
           ghcr.io/aliasproject/php:8.4-frankenphp
```

Requests for PHP source under a `PHP_NO_EXEC_PATHS` prefix (any case, or with trailing path info) never execute: they return 404 or 400, or (with a trailing slash) redirect to a URL that returns 404. Images and other files in the directory are still served. Add more prefixes space-separated (`PHP_NO_EXEC_PATHS="/uploads/* /files/*"`). `PHP_NO_EXEC_PATHS` replaces the default rather than appending, so a derived image or `docker run` that sets it must list every path it wants protected.

## WordPress hardening

The `frankenphp:wordpress` variant renders a Caddy hardening snippet at container boot:

- `PHP_NO_EXEC_PATHS` — writable directories (uploads, cache, upgrade) can never execute PHP.
- `PHP_DENY_PATHS` / `PHP_DENY_EXTENSIONS` — `.env`, `.git`, `wp-config.php`, `readme.html`/`license.txt`, and backup/dump/log files are never served, at any depth.
- `PHP_DISABLE_FUNCTIONS` — disables `exec`, `passthru`, `shell_exec`, `system`, `pcntl_exec`, `dl`.
- Runs as a non-root user (UID configurable via `--build-arg APP_UID`) in group `0`.

All of the above are overridable via environment variables if a site needs different values.

The `wordpress` variant also ships defaults for the [static asset caching](#static-asset-caching) snippet covering both the Bedrock (`/app/...`, `/wp/...`) and stock (`/wp-content/...`, `/wp-includes/...`) layouts, including cache-plugin output and Avada's compiled `fusion-styles` / `fusion-scripts` directories.
