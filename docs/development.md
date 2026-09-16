# Development

## Build from Source

Check out this repository and build the image from its root:

```bash
docker buildx build --load -t nbraun1/certbot .
```

Any Docker tag can be used. Use the resulting tag with `docker run` or in a
Compose file to test local changes.

## Makefile Commands

The repository uses separate Makefiles for production image operations and
tests. There is no default root `Makefile`, so select the intended workflow
explicitly.

Production image commands:

```bash
make -f Makefile.production build
make -f Makefile.production run \
  DOCKER_RUN_ARGS='-e EMAIL=your@email.com -e DOMAINS=example.com -e RUN_ONCE=1'
make -f Makefile.production dive
make -f Makefile.production clean
```

Create and push a release tag interactively, or provide the version for
automation:

```bash
make -f Makefile.production git-release-tag
make -f Makefile.production git-release-tag RELEASE_VERSION=1.2.3
```

The release target creates and pushes the `v1.2.3` tag. The tag push triggers
the release image workflow.

Test commands:

```bash
make -f Makefile.test test-unit
make -f Makefile.test test-image
make -f Makefile.test test
make -f Makefile.test clean
```

`test-unit` runs the pytest unit suite. `test-image` builds the local
`nbraun1/certbot:test` image to validate the Dockerfile. `test` runs the
complete local suite. Pytest, Docker with Buildx, and GNU Make must be
installed; Python test dependencies can be installed with:

```bash
python3 -m pip install -r tests/requirements.txt
```

The test suite does not issue certificates or contact an ACME server.

## Reporting Issues

Before opening an issue, check whether a similar issue already exists. Report
bugs and feature requests in the [GitHub issue tracker](https://github.com/nbraun1/certbot/issues).
