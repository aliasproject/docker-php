#!/usr/bin/env bash
# Boots a built image and checks it does what its README promises, so a broken
# image never gets a floating tag. Run by build-and-push.yml between pushing an
# image by digest and tagging it; also runnable by hand:
#
#   .github/scripts/smoke-test.sh <variant> <image> <php-version>
#   .github/scripts/smoke-test.sh wordpress ghcr.io/aliasproject/php:8.4-frankenphp-wordpress 8.4
#
# variant: cli | base | dev | wordpress | wordpress-dev
#   cli                      runs php; no server
#   base, dev                the frankenphp Tier 1 extensions
#   wordpress, wordpress-dev Tier 1 plus the WordPress extension set
# The frankenphp variants are booted and served over HTTP, so the PHP that is
# checked is the one embedded in the server (not the separate `php` binary).
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <cli|base|dev|wordpress|wordpress-dev> <image> <php-version>" >&2
    exit 2
fi
variant=$1
image=$2
php_version=$3

tier1="pdo_mysql zip intl bcmath pcntl posix"
wordpress_ext="mysqli gd exif imagick redis igbinary soap"
case "$variant" in
    cli)                      extensions="pdo_mysql zip intl bcmath pcntl" ;;
    base | dev)               extensions="$tier1" ;;
    wordpress | wordpress-dev) extensions="$tier1 $wordpress_ext" ;;
    *) echo "unknown variant: $variant" >&2; exit 2 ;;
esac

fail() { echo "SMOKE TEST FAILED ($variant, $image): $*" >&2; exit 1; }

# Shared checks on a PHP version string and a list of loaded extensions.
check_php() {
    local version=$1 loaded=$2 ext
    case "$version" in
        "$php_version".*) ;;
        *) fail "PHP version is '$version', expected $php_version.x" ;;
    esac
    for ext in $extensions; do
        # Whole-word match, case-insensitive (get_loaded_extensions() and
        # php -m disagree on case for some, e.g. "Zend OPcache").
        printf '%s\n' "$loaded" | tr ' ' '\n' | grep -qix "$ext" \
            || fail "extension '$ext' is not loaded"
    done
}

if [ "$variant" = cli ]; then
    version=$(docker run --rm "$image" php -r 'echo PHP_VERSION;')
    loaded=$(docker run --rm "$image" php -m | tr '\n' ' ')
    check_php "$version" "$loaded"
    uid=$(docker run --rm "$image" id -u)
    [ "$uid" != 0 ] || fail "runs as root"
    echo "ok: $image (PHP $version, uid $uid)"
    exit 0
fi

fixture=$(mktemp -d)
name="smoke-$$"
cleanup() {
    docker rm -f "$name" >/dev/null 2>&1 || true
    rm -rf "$fixture"
}
trap cleanup EXIT

# A page that reports what the server's own PHP looks like. The container user
# is not the runner's, so the fixture must be world-readable.
mkdir -p "$fixture/public"
cat > "$fixture/public/index.php" <<'PHP'
<?php
echo "VERSION=", PHP_VERSION, "\n";
echo "SAPI=", php_sapi_name(), "\n";
echo "EXTENSIONS=", implode(' ', get_loaded_extensions()), "\n";
PHP
chmod -R a+rX "$fixture"

# Short health interval: the image's own HEALTHCHECK (30s) would make the wait
# below much longer than it needs to be.
docker run -d --name "$name" -p 127.0.0.1::80 -v "$fixture:/app:ro" \
    --health-interval 2s --health-timeout 5s --health-retries 5 --health-start-period 30s \
    "$image" >/dev/null

health=starting
for _ in $(seq 1 60); do
    state=$(docker inspect -f '{{.State.Status}}' "$name")
    if [ "$state" != running ]; then
        docker logs "$name" >&2 || true
        fail "container is '$state', not running"
    fi
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$name")
    [ "$health" = healthy ] && break
    sleep 2
done
if [ "$health" != healthy ]; then
    docker logs "$name" >&2 || true
    fail "not healthy after 120s (health: $health)"
fi

port=$(docker port "$name" 80/tcp | head -n1 | sed 's/.*://')
body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/") \
    || fail "GET / did not return 2xx"

version=$(printf '%s\n' "$body" | sed -n 's/^VERSION=//p')
sapi=$(printf '%s\n' "$body" | sed -n 's/^SAPI=//p')
loaded=$(printf '%s\n' "$body" | sed -n 's/^EXTENSIONS=//p')
[ "$sapi" = frankenphp ] || fail "SAPI is '$sapi', expected frankenphp"
check_php "$version" "$loaded"

uid=$(docker exec "$name" id -u)
[ "$uid" != 0 ] || fail "runs as root"

# docker-configure ran at boot and rendered its snippets.
docker exec "$name" test -f /config/caddy/site.d/00-hardening.caddyfile \
    || fail "docker-configure did not render /config/caddy/site.d/00-hardening.caddyfile"
docker exec "$name" test -s /usr/local/etc/php/conf.d/app.ini \
    || fail "docker-configure did not render conf.d/app.ini"

# Composer is baked into every frankenphp image.
docker exec "$name" composer --version >/dev/null 2>&1 || fail "composer is not runnable"

echo "ok: $image (PHP $version, uid $uid, healthy)"
