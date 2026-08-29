# docker-php
PHP Docker Container

## Secret scanning

Every push/PR is scanned by [gitleaks](https://github.com/gitleaks/gitleaks) in CI (`.github/workflows/secret-scan.yml`). To also catch a leak locally before it's even committed:

```sh
git config core.hooksPath .githooks
```

Requires the gitleaks CLI ([install instructions](https://github.com/gitleaks/gitleaks#installing)) — the hook no-ops with a reminder if it's missing, so it won't block a commit for anyone who hasn't installed it. CI is the real backstop either way.
