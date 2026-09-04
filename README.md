[![Docker Pulls](https://img.shields.io/docker/pulls/nbraun1/certbot)](https://hub.docker.com/r/nbraun1/certbot)
[![Docker Image Size](https://img.shields.io/docker/image-size/nbraun1/certbot/latest)](https://hub.docker.com/r/nbraun1/certbot)

# Certbot for Docker

This image packages the free and open-source [Certbot](https://certbot.eff.org/)
client for automating [Let's Encrypt](https://letsencrypt.org/) certificate
issuance and renewal. It is based on [Alpine Linux](https://hub.docker.com/_/alpine)
and installs Certbot with [pip](https://pip.pypa.io/en/stable/).

## Features

- Obtain certificates from Let's Encrypt.
- Renew certificates with configurable cron jobs.
- Run [renewal pre-, post-, and deploy hooks](https://eff-certbot.readthedocs.io/en/stable/using.html#renewing-certificates).
- Install Certbot [DNS plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) with pip at startup.
- Handle signals with [Tini](https://github.com/krallin/tini).
- Configure the image with environment variables.
- Obtain and renew multiple certificates from one INI file (since version 1.1.0).

## Quick Start

Ensure that your domain points to a valid IP address, then run Certbot once:

```bash
docker run -it -p 80:80 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e RUN_ONCE=1 \
--name certbot nbraun1/certbot
```

See the [usage guide](docs/usage.md) for automatic renewal, alternate ports,
Docker Compose, volumes, ports, and published image tags.

## Documentation

- [Usage](docs/usage.md)
- [Configuration reference](docs/configuration.md)
- [Multiple certificates](docs/multiple-certificates.md)
- [Development](docs/development.md)

## License

This project is open source under the
[Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0.html).
