# Usage

Ensure that each domain points to a valid IP address before starting Certbot.

## Run with `docker run`

Run Certbot once:

```bash
docker run -it -p 80:80 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e RUN_ONCE=1 \
--name certbot nbraun1/certbot
```

Run Certbot with automatic renewal:

```bash
docker run -it -p 80:80 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e CRON="0 0,12 * * *" \
--name certbot nbraun1/certbot
```

Run the HTTP-01 challenge on another container port:

```bash
docker run -it -p 80:81 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e RUN_ONCE=1 \
-e HTTP01_PORT=81 \
--name certbot nbraun1/certbot
```

Certbot listens on port 81 inside the container and is mapped to port 80 on
the host so that the ACME server can reach the challenge.

For multiple certificates, mount an INI file and enable the feature:

```bash
docker run -it -p 80:80 \
-v $(pwd)/data/certbot:/etc/letsencrypt \
-v $(pwd)/example.ini:/etc/certbot/multi-certificates.ini \
-e ENABLE_MULTI_CERTIFICATES=1 \
--name certbot nbraun1/certbot
```

See the [multiple-certificates guide](multiple-certificates.md) for details.

## Run with Docker Compose

See [`examples/docker-compose.yml`](../examples/docker-compose.yml) for a
ready-to-run configuration. More examples are available in the
[`examples/`](../examples/) directory. Start it with:

```bash
docker compose up
```

The example uses [Docker Compose V2](https://docs.docker.com/compose/#compose-v2-and-the-new-docker-compose-command).

## Published Images

Images are published to [Docker Hub](https://hub.docker.com/r/nbraun1/certbot)
and [GitHub Container Registry](https://ghcr.io/nbraun1/certbot) for both
`linux/amd64` and `linux/arm64`:

- `v1.2.3` and `latest` are published for releases created from tags such as `v1.2.3`.
- `edge` is published for commits on `master`.
- `edge-dev` is published for commits on `development`.

## Volumes

- `/etc/letsencrypt` stores the obtained certificates.
- `/etc/certbot/multi-certificates.ini` stores the optional multi-certificate INI file. The volume contains only this file, must be mounted manually, and is not exposed by the Dockerfile.

## Exposed Ports

- `80`
