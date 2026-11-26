#!/usr/bin/env bash
# Boots a built image and checks it does what its README promises, so a broken
# image never gets a floating tag. Run by build-and-push.yml between pushing an
# image by digest and tagging it; also runnable by hand:
#
#   .github/scripts/smoke-test.sh <variant> <image> <php-version> [<platform>]
#   .github/scripts/smoke-test.sh wordpress ghcr.io/aliasproject/php:8.4-frankenphp-wordpress 8.4
#   .github/scripts/smoke-test.sh cli ghcr.io/aliasproject/php:8.4-cli 8.4 linux/arm64
#
# variant: cli | base | dev | wordpress | wordpress-dev
#   cli                      runs php; no server
#   base, dev                the frankenphp Tier 1 extensions
#   wordpress, wordpress-dev Tier 1 plus the WordPress extension set
# The frankenphp variants are booted and served over HTTP, so the PHP that is
# checked is the one embedded in the server (not the separate `php` binary).
# platform (optional, linux/amd64 or linux/arm64) is passed to every docker run
# as --platform, and the container's architecture is checked against it. Without
# it, docker runs the image for the host's own architecture. A platform other
# than the host's needs QEMU (binfmt) set up on the host.
set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "usage: $0 <cli|base|dev|wordpress|wordpress-dev> <image> <php-version> [<platform>]" >&2
    exit 2
fi
variant=$1
image=$2
php_version=$3
platform=${4:-}

expected_arch=
case "$platform" in
    "") ;;
    linux/amd64) expected_arch=x86_64 ;;
    linux/arm64) expected_arch=aarch64 ;;
    *) echo "unknown platform: $platform (expected linux/amd64 or linux/arm64)" >&2; exit 2 ;;
esac

tier1="pdo_mysql zip intl bcmath pcntl posix"
wordpress_ext="mysqli gd exif imagick redis igbinary soap"
case "$variant" in
    cli)                      extensions="pdo_mysql zip intl bcmath pcntl" ;;
    base | dev)               extensions="$tier1" ;;
    wordpress | wordpress-dev) extensions="$tier1 $wordpress_ext" ;;
    *) echo "unknown variant: $variant" >&2; exit 2 ;;
esac

fail() { echo "SMOKE TEST FAILED ($variant, $image${platform:+, $platform}): $*" >&2; exit 1; }

# docker run, with --platform when a platform was given. A function rather
# than an array of extra arguments: bash before 4.4 (macOS's /bin/bash) treats
# an empty array as unset under set -u.
drun() {
    if [ -n "$platform" ]; then
        docker run --platform "$platform" "$@"
    else
        docker run "$@"
    fi
}

# With a platform, pull that platform's image first. Without this, a docker
# engine that keeps one image per name (the classic image store) can find the
# other architecture's image, pulled for an earlier run of this script, under
# the same name. The check_arch below would then fail. A failed pull is fatal
# unless the image is already present locally (a locally built image that was
# never pushed, say).
if [ -n "$platform" ]; then
    if ! docker pull --quiet --platform "$platform" "$image" >/dev/null; then
        docker image inspect "$image" >/dev/null 2>&1 \
            || fail "could not pull the $platform image"
        echo "pull failed; using the local image" >&2
    fi
fi

# uname -m inside the container ($1) against the requested platform.
check_arch() {
    [ -n "$expected_arch" ] || return 0
    [ "$1" = "$expected_arch" ] || fail "architecture is '$1', expected $expected_arch for $platform"
}

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
    version=$(drun --rm "$image" php -r 'echo PHP_VERSION;') || fail "php did not run"
    loaded=$(drun --rm "$image" php -m | tr '\n' ' ') || fail "php -m did not run"
    check_php "$version" "$loaded"
    uid=$(drun --rm "$image" id -u) || fail "id did not run"
    [ "$uid" != 0 ] || fail "runs as root"
    arch=$(drun --rm "$image" uname -m) || fail "uname did not run"
    check_arch "$arch"
    # Only cli/Dockerfile.wordpress carries the WORDPRESS_VCS_CHECKOUT prepend
    # file (see the frankenphp checks below). CI doesn't build that image, so
    # this runs only by hand. A docker run that fails fails the check, rather
    # than reading as "no file".
    has_vcs=$(drun --rm "$image" sh -c \
        'if test -f /usr/local/share/php-prepend/wordpress-vcs-checkout.php; then echo yes; else echo no; fi') \
        || fail "the WORDPRESS_VCS_CHECKOUT file check did not run"
    case "$has_vcs" in
        yes | no) ;;
        *) fail "the WORDPRESS_VCS_CHECKOUT file check printed '$has_vcs'" ;;
    esac
    if [ "$has_vcs" = yes ]; then
        seeded='{"automatic_updates_is_vcs_checkout":{"10":[{"function":"__return_true","accepted_args":1}]}}'
        check='echo "<?php echo isset(\$GLOBALS[\"wp_filter\"]) ? json_encode(\$GLOBALS[\"wp_filter\"]) : \"none\";" > /tmp/vcs.php && php /tmp/vcs.php'
        out=$(drun --rm "$image" sh -c "$check") || fail "vcs check did not run"
        [ "$out" = none ] || fail "WORDPRESS_VCS_CHECKOUT unset, but the filter was seeded: $out"
        out=$(drun --rm -e WORDPRESS_VCS_CHECKOUT=1 "$image" sh -c "$check") || fail "vcs check did not run"
        [ "$out" = "$seeded" ] || fail "WORDPRESS_VCS_CHECKOUT=1 did not seed the filter: $out"
    fi
    echo "ok: $image (PHP $version, uid $uid, $arch)"
    exit 0
fi

fixture=$(mktemp -d)
name="smoke-$$"
containers=()
cleanup() {
    local c
    for c in "${containers[@]}"; do
        docker rm -f "$c" >/dev/null 2>&1 || true
    done
    rm -rf "$fixture"
}
trap cleanup EXIT

# A page that reports what the server's own PHP looks like. The container user
# is not the runner's, so the fixture must be world-readable.
mkdir -p "$fixture/public/storage/idx"
# A script an attacker could drop under /storage/ (Livewire GHSA-29cq-5w36-x7w3),
# and an ordinary upload next to it.
echo '<?php echo "STORAGE-PHP-EXECUTED";' > "$fixture/public/storage/shell.php"
echo '<?php echo "STORAGE-PHP-EXECUTED";' > "$fixture/public/storage/idx/index.php"
echo 'upload' > "$fixture/public/storage/hello.txt"
cat > "$fixture/public/index.php" <<'PHP'
<?php
echo "VERSION=", PHP_VERSION, "\n";
echo "SAPI=", php_sapi_name(), "\n";
echo "EXTENSIONS=", implode(' ', get_loaded_extensions()), "\n";
PHP
# What the WORDPRESS_VCS_CHECKOUT prepend file did to this request.
cat > "$fixture/public/vcs.php" <<'PHP'
<?php
echo isset($GLOBALS['wp_filter']) ? json_encode($GLOBALS['wp_filter']) : 'none';
PHP
chmod -R a+rX "$fixture"

# Boots the image as container $1 (extra docker run arguments after it) with
# the fixture at /app, waits for it to be healthy and sets $port.
boot() {
    local cname=$1 state health=starting
    shift
    containers+=("$cname")
    # Short health interval: the image's own HEALTHCHECK (30s) would make the
    # wait below much longer than it needs to be.
    drun -d --name "$cname" -p 127.0.0.1::80 -v "$fixture:/app:ro" \
        --health-interval 2s --health-timeout 5s --health-retries 5 --health-start-period 30s \
        "$@" "$image" >/dev/null

    for _ in $(seq 1 60); do
        state=$(docker inspect -f '{{.State.Status}}' "$cname")
        if [ "$state" != running ]; then
            docker logs "$cname" >&2 || true
            fail "container is '$state', not running (${*:-no extra arguments})"
        fi
        health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cname")
        [ "$health" = healthy ] && break
        sleep 2
    done
    if [ "$health" != healthy ]; then
        docker logs "$cname" >&2 || true
        fail "not healthy after 120s (health: $health; ${*:-no extra arguments})"
    fi

    port=$(docker port "$cname" 80/tcp | head -n1 | sed 's/.*://')
}

boot "$name"
body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/") \
    || fail "GET / did not return 2xx"

version=$(printf '%s\n' "$body" | sed -n 's/^VERSION=//p')
sapi=$(printf '%s\n' "$body" | sed -n 's/^SAPI=//p')
loaded=$(printf '%s\n' "$body" | sed -n 's/^EXTENSIONS=//p')
[ "$sapi" = frankenphp ] || fail "SAPI is '$sapi', expected frankenphp"
check_php "$version" "$loaded"

uid=$(docker exec "$name" id -u)
[ "$uid" != 0 ] || fail "runs as root"
arch=$(docker exec "$name" uname -m) || fail "uname did not run"
check_arch "$arch"

# PHP under /storage/ never executes, but ordinary files there are still served
# and other /storage/ URLs still reach the app (Laravel's local-disk serve route).
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$port/storage/shell.php") || true
[ "$code" = 404 ] || fail "GET /storage/shell.php returned '$code', expected 404"
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$port/storage/shell.php/foo") || true
[ "$code" = 404 ] || fail "GET /storage/shell.php/foo returned '$code', expected 404"
# A directory URL makes the server run that directory's index.php.
for path in /storage/ /storage/idx/; do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:$port$path") || true
    [ "$code" = 404 ] || fail "GET $path returned '$code', expected 404 (directory index.php must not run)"
done
body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/storage/hello.txt") \
    || fail "GET /storage/hello.txt did not return 2xx"
[ "$body" = upload ] || fail "GET /storage/hello.txt returned '$body', expected the file"
body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/storage/private/report.pdf") \
    || fail "GET /storage/private/report.pdf (no such file) did not reach the app"
printf '%s\n' "$body" | grep -q '^VERSION=' || fail "a non-file /storage/ URL did not reach the app"

# docker-configure ran at boot and rendered its snippets.
docker exec "$name" test -f /config/caddy/site.d/00-hardening.caddyfile \
    || fail "docker-configure did not render /config/caddy/site.d/00-hardening.caddyfile"
docker exec "$name" test -s /usr/local/etc/php/conf.d/app.ini \
    || fail "docker-configure did not render conf.d/app.ini"

# Composer is baked into every frankenphp image.
docker exec "$name" composer --version >/dev/null 2>&1 || fail "composer is not runnable"

# WORDPRESS_VCS_CHECKOUT (see the frankenphp Dockerfile). Unset, the prepend
# file does nothing; the exact value 1 seeds WordPress's
# automatic_updates_is_vcs_checkout filter; with PHP_OPEN_BASEDIR set,
# docker-configure lets the prepend file in, or every request would fail;
# with getenv disabled the file must not fatal.
seeded='{"automatic_updates_is_vcs_checkout":{"10":[{"function":"__return_true","accepted_args":1}]}}'
docker exec "$name" test -f /usr/local/share/php-prepend/wordpress-vcs-checkout.php \
    || fail "the WORDPRESS_VCS_CHECKOUT prepend file is missing"
body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/vcs.php") \
    || fail "GET /vcs.php did not return 2xx"
[ "$body" = none ] || fail "WORDPRESS_VCS_CHECKOUT unset, but the filter was seeded: $body"
docker rm -f "$name" >/dev/null

vcs_case() { # expected, then extra docker run arguments
    local expected=$1 cname="$name-vcs-${#containers[@]}"
    shift
    boot "$cname" "$@"
    body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/vcs.php") \
        || fail "GET /vcs.php did not return 2xx ($*)"
    [ "$body" = "$expected" ] || fail "GET /vcs.php returned '$body', expected '$expected' ($*)"
    body=$(curl -fsS --max-time 10 "http://127.0.0.1:$port/") \
        || fail "GET / did not return 2xx ($*)"
    printf '%s\n' "$body" | grep -q '^VERSION=' || fail "GET / did not run the app ($*)"
    docker rm -f "$cname" >/dev/null
}
vcs_case "$seeded" -e WORDPRESS_VCS_CHECKOUT=1
vcs_case "$seeded" -e WORDPRESS_VCS_CHECKOUT=1 -e PHP_OPEN_BASEDIR=/app:/tmp
vcs_case none -e WORDPRESS_VCS_CHECKOUT=1 -e PHP_DISABLE_FUNCTIONS=getenv

echo "ok: $image (PHP $version, uid $uid, $arch, healthy, WORDPRESS_VCS_CHECKOUT)"
