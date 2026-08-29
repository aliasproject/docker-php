# docker-php

Docker images for PHP 7.4 through 8.5, built and published to `ghcr.io/aliasproject/php`. Each PHP version comes in the variants that make sense for it — a bare CLI image, PHP-FPM alone, FPM behind nginx, and for 8.2+ a [FrankenPHP](https://frankenphp.dev/) (Caddy + PHP) image with `dev` and hardened `wordpress` flavors.

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

Tags follow `<version>-<variant>` (e.g. `8.4-frankenphp-wordpress`), each also published as `-latest` and pinned to the commit as `-<sha>`. Pull with:

```sh
docker pull ghcr.io/aliasproject/php:8.4-frankenphp
```

`php/8.4/cli/Dockerfile.wordpress` (a WP-CLI-ready image built `FROM` the 8.4 CLI base) also lives in the repo but isn't yet wired into the CI build matrix.

## Variants

- **cli** — Alpine + the PHP CLI SAPI and a minimal extension set (Tier 1: `pdo_mysql`, `bcmath`, `pcntl`, `posix`, etc.), unlimited execution time, runs as an unprivileged `appuser` in group `0`.
- **fpm** — PHP-FPM under [s6-overlay](https://github.com/just-containers/s6-overlay), configurable pool sizing via `PHP_PM_*` env vars.
- **fpm-nginx** — the `fpm` image plus nginx in front of it, still supervised by s6.
- **frankenphp** — PHP-FPM-free: FrankenPHP serves PHP directly through Caddy. Ships only Tier 1 extensions; runs as non-root, ports 80/443 bound via `setcap` rather than root, mail sent through `msmtp`, Composer baked in, and a `HEALTHCHECK` against Caddy's admin API.
- **frankenphp (dev)** — the FrankenPHP base with extra Tier 2 extensions for local development.
- **frankenphp (wordpress)** — the FrankenPHP base plus WordPress's required extensions (`mysqli`, `gd`, `exif`, `imagick`, `redis`, `igbinary`, `soap`) and a hardening policy layered on top (see below).

### WordPress hardening

The `frankenphp` base only supplies the *mechanism*; the `wordpress` variant supplies the *policy*, all rendered into a Caddy snippet by `docker-configure` at container boot:

- `PHP_NO_EXEC_PATHS` — writable directories (uploads, cache, upgrade) can never execute PHP, closing the classic upload-a-webshell path.
- `PHP_DENY_PATHS` / `PHP_DENY_EXTENSIONS` — `.env`, `.git`, `wp-config.php`, `readme.html`/`license.txt` (version fingerprinting), and backup/dump/log files are never served, at any depth.
- `PHP_DISABLE_FUNCTIONS` — disables `exec`, `passthru`, `shell_exec`, `system`, `pcntl_exec`, `dl` (the functions webshells rely on most).
- Runs as a non-root `appuser` (UID configurable via `--build-arg APP_UID`) in group `0`, with app directories group-writable so an alternate UID still works.

All of the above are configurable per image via environment variables (`PHP_MEMORY_LIMIT`, `PHP_OPCACHE_*`, `PHP_NO_EXEC_PATHS`, `PHP_DENY_PATHS`, `PHP_DENY_EXTENSIONS`, `PHP_DISABLE_FUNCTIONS`, `MSMTP_RELAY_SERVER_*`, etc.) — see each Dockerfile's `ENV` block for defaults.

## CI/CD

`.github/workflows/build-and-push.yml` builds and pushes every image on push to `main`:

- Only rebuilds images whose Dockerfile (or, for FPM-based images, their parent Dockerfile) actually changed, via `tj-actions/changed-files`.
- `workflow_dispatch` inputs let you force a full rebuild or force just one PHP version.
- Everything builds for `linux/amd64,linux/arm64` (QEMU-emulated where needed).
- FrankenPHP images are the exception: they build natively on per-arch runners and are pushed by digest, then merged into a single multi-arch manifest, because emulated `arm64` extension installs there were measured at ~9x slower than native.
- A newer push to `main` cancels any still-running build for an older commit.

## Local builds

`.zed/tasks.json` has ready-made `docker buildx build --push` tasks for the FrankenPHP and CLI images if you want to build/push a version manually without triggering CI.

## Secret scanning

Every push/PR is scanned by [gitleaks](https://github.com/gitleaks/gitleaks) in CI (`.github/workflows/secret-scan.yml`). To also catch a leak locally before it's even committed:

```sh
git config core.hooksPath .githooks
```

Requires the gitleaks CLI ([install instructions](https://github.com/gitleaks/gitleaks#installing)) — the hook no-ops with a reminder if it's missing, so it won't block a commit for anyone who hasn't installed it. CI is the real backstop either way.
