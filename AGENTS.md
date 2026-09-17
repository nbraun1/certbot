# Repository Guidelines

## Project Structure & Module Organization

This repository builds the `nbraun1/certbot` Alpine-based Docker image.

- `Dockerfile` installs the Alpine packages and Certbot virtual environment,
  copies the runtime scripts, declares the `/etc/letsencrypt` volume, exposes
  port 80, and starts the container through Tini. Runtime defaults are supplied
  by scripts, not baked into Dockerfile `ENV` instructions.
- `scripts/` contains runtime behavior. `entrypoint.sh` activates the virtual
  environment, installs optional DNS plugins, obtains certificates, and starts
  renewal. `certbot-certonly.sh`, `certbot-renew.sh`,
  `configure-crontab.sh`, and `install-dns-plugins.sh` provide the shell
  operations; `manage-multi-certificates.py` handles the multi-certificate INI
  file; and `defaults.sh` centralizes the defaults for `AUTHENTICATOR`, `CRON`,
  and `MULTI_CERTIFICATES_INI_FILE`.
- `examples/` contains Docker Compose scenarios and sample DNS and
  multi-certificate configuration.
- `README.md` is the concise project landing page. Detailed user documentation
  lives in `docs/`: `usage.md`, `configuration.md`,
  `multiple-certificates.md`, and `development.md`.
- `.github/workflows/docker-build.yml` builds and publishes multi-platform
  images. `.github/dependabot.yml` checks the Dockerfile base image weekly.
- `Makefile.common` contains shared Make variables and helper targets;
  `Makefile.production` provides local build, run, image inspection, cleanup,
  and release tag helpers; and `Makefile.test` provides Python unit tests and
  Dockerfile image-build validation. `LICENSE.txt` contains the project
  license.

Keep executable runtime additions in `scripts/`. Every runtime script that can
be invoked directly must preserve the defaults in `defaults.sh`; shell scripts
source it, and Python code must retain equivalent fallback behavior when it
reads the related environment variables. Explicitly supplied values, including
empty values, must not be overwritten by defaults.

## Build, Test, and Development Commands

- `make -f Makefile.production build` builds `nbraun1/certbot:latest` locally.
- `docker buildx build --load -t nbraun1/certbot .` is the equivalent direct
  build command.
- `make -f Makefile.production run` builds and starts the image; pass required
  environment variables through `DOCKER_RUN_ARGS` before using it for real
  certificate issuance.
- `docker compose -f examples/docker-compose.yml up` exercises the basic
  documented configuration. Use `RUN_ONCE=1` and Certbot staging settings for
  safe manual checks.
- `make -f Makefile.production dive` inspects image layers when
  [dive](https://github.com/wagoodman/dive) is installed.
- `make -f Makefile.production git-release-tag` creates and pushes a release
  tag; use `RELEASE_VERSION=1.2.3` for non-interactive automation.
- `make -f Makefile.production clean` removes the production image.
- `make -f Makefile.test test-unit` runs the pytest unit tests.
- `make -f Makefile.test test-image` builds the test image to validate the
  Dockerfile.
- `make -f Makefile.test test` runs the complete local test suite.
- `make -f Makefile.test clean` removes the test image.

Before submitting a change, run the narrowest relevant tests, for example:

```bash
make -f Makefile.test test-unit
make -f Makefile.test test
```

## Coding Style & Naming Conventions

- Use four-space indentation in Dockerfile continuations, shell blocks, and
  Python. Keep Docker package lists readable and sorted.
- Shell scripts use Bash, start with `#!/bin/bash` and `set -e`, source
  `scripts/defaults.sh`, and use uppercase names for environment variables.
  Keep shell filenames lowercase with hyphens.
- Quote variable expansions and use arrays when assembling command arguments.
  Preserve the distinction between an unset variable and an explicitly empty
  value where defaults are involved.
- Python uses descriptive `snake_case` identifiers and four-space indentation.
- Keep Dockerfile runtime configuration in the entrypoint and scripts rather
  than adding image-wide defaults unless a change requires otherwise.

## Docker Publishing

Keep the workflow small and limited to production requirements. It publishes
`linux/amd64` and `linux/arm64` images to both Docker Hub and GHCR:

- pushes to `main` publish `edge`;
- pushes to `development` publish `edge-dev`;
- version tags such as `v1.2.3` publish the release tag and `latest`.

Branch builds must not publish `latest`. Use the existing `DOCKERHUB_TOKEN`
secret and GitHub token permissions for registry authentication. Dependabot
updates the root Dockerfile base image weekly; merged updates should produce a
new branch edge build through the existing workflow.

## Commit & Pull Request Guidelines

Use brief, imperative commit subjects such as `Simplify Makefile` and
`Update docker-build workflow`. Keep each commit focused. Pull requests should
explain the runtime or image impact, identify affected environment variables,
examples, documentation, tags, and platforms, and include the build and test
commands and results. Update the relevant file in `docs/` and
`examples/` whenever user-facing configuration changes.

## Security & Configuration

Do not commit certificate material, DNS credentials, or INI files containing
secrets. Use mounted files and environment variables for operational
configuration. Use Certbot staging while testing certificate flows, and keep
registry credentials in GitHub secrets rather than repository files.
