[1]: https://certbot.eff.org/
[2]: https://letsencrypt.org/
[3]: https://pip.pypa.io/en/stable/

![Docker Pulls](https://img.shields.io/docker/pulls/nbraun1/certbot)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/nbraun1/certbot/latest)

# Certbot for Docker
Open Source and free to use [certbot][1] for Docker environments to automate the [Let's Encrypt's][2] certificate issuing and renewal. The Docker image is based on [Alpine Linux](https://hub.docker.com/_/alpine) and uses [certbot][1] under the hood.

## Features
- Obtain certificates from [Let's Encrypt][2]
- Renew obtained certificates with configurable cronjobs
- [Renewal hooks](https://eff-certbot.readthedocs.io/en/stable/using.html#renewing-certificates) (pre, post and deploy hooks are supported out-of-the-box)
- Install [certbot's DNS plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) with [pip][3] when starting the Docker container
- Efficient signal handling with [Tini](https://github.com/krallin/tini)
- Highly configurable with [environment variables](#environment-variables)
- Capable to obtain and automatically renew [multiple certificates](#multiple-certificates) (since version 1.1.0)

# Table of Contents
- [Getting Started](#getting-started)
  - [Run with docker run](#run-with-docker-run)
  - [Run with docker compose](#run-with-docker-compose)
- [Multiple Certificates](#multiple-certificates)
  - [Basic Setup](#basic-setup)
  - [INI File](#ini-file)
  - [Technical Background Knowledge](#technical-background-knowledge)
- [Environment Variables](#environment-variables)
  - [Required](#required)
  - [Optional](#optional)
- [Volumes](#volumes)
- [Exposed Ports](#exposed-ports)
- [Building from Source](#building-from-source)
- [Reporting Issues](#reporting-issues)
- [License](#license)

# Getting Started
Ensure that your domain points to an valid IP address before you start.

## Run with `docker run`
Run [certbot][1] once:
```bash
docker run -it -p 80:80 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e RUN_ONCE=1 \
--name certbot nbraun1/certbot
```

Run [certbot][1] with cronjobs:
```bash
docker run -it -p 80:80 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e CRON="0 0,12 * * *" \
--name certbot nbraun1/certbot
```

Run [certbot][1] listens to another port for http-01 challenge:
```bash
docker run -it -p 80:81 -v $(pwd)/data/certbot:/etc/letsencrypt \
-e EMAIL=your@email.com \
-e DOMAINS=example.com,www.example.com \
-e RUN_ONCE=1 \
-e HTTP01_PORT=81 \
--name certbot nbraun1/certbot
```
[Certbot][1] listens to port 81 in the Docker container but is mapped as port 80 to the host in order to be reachable for a ACME server.

Run [certbot][1] for multiple certificates:
```bash
docker run -it -p 80:80 \
-v $(pwd)/data/certbot:/etc/letsencrypt \
-v $(pwd)/example.ini:/etc/certbot/multi-certificates.ini \
-e ENABLE_MULTI_CERTIFICATES=1 \
--name certbot nbraun1/certbot
```
For detailed information how the multi-certificates feature works, read the [multiple certificates](#multiple-certificates) section.

## Run with `docker compose`
For an example to run [certbot][1] in Docker Compose consult our [docker-compose.yml](./examples/docker-compose.yml). In order to start the [certbot][1] run `docker compose up` in your command line. More examples can be found in the [examples directory](./examples/).
> Note that we use [Docker Compose V2](https://docs.docker.com/compose/#compose-v2-and-the-new-docker-compose-command) for this example.

# Multiple Certificates
Are you tired of running multiple `docker run` commands for the same [certbot][1] Docker image to obtain or renew multiple certificates? Or repeat your [certbot][1] service in your docker-compose.yml where each of them manage a separate domain? Or write the ugly configuration for one [certbot][1] service to force a semi multi-certificates feature? Our [Docker image](https://hub.docker.com/r/nbraun1/certbot) provides a much simpler and more pleasant way!

## Basic Setup
Our multi-certificates feature is based on an INI file which is written by you. For an simple example have a look at our pre-defined [example.ini](./examples/multi-certificates/example.ini) file. This whole feature is optional, means that you can decide with the `ENABLE_MULTI_CERTIFICATES` environment variable if you enable or disable it. In the [run with docker run](#run-with-docker-run) section you safely noticed that an additional volume is used when running with an defined `ENABLE_MULTI_CERTIFICATES` environment variable. This volume only contains the INI file and is located at `/etc/certbot/multi-certificates.ini` in the Docker container by default. That location can be changed with the `MULTI_CERTIFICATES_INI_FILE` environment variable.

## INI File
The INI file contains one optional *DEFAULT* section and one or more domain specific sections. Each option defined in the *DEFAULT* section is applied to the domain specific section options. If a *DEFAULT* option is the same as the domain specific one, the domain specific one overrides the *DEFAULT* one and is used. Possible options and its values are the environment variables defined in the corresponding [section](#environment-variables).

## Technical Background Knowledge
Reading this section is not mandatory to understand the multi-certificates feature but might be helpfully if you are interested in general technical background knowledge.

To parse the INI file we use Python and **not** Bash! You might be wondering: "Why using Python to parse a file in a Docker container which uses Bash by default?!". The answer is really simple. There are a handful existing INI file parsers available in GitHub but most of these are either a (dirty) hack, incomplete, do not work or do not meet our requirements. The alternatives are e.g *awk* or *sed* scripts but we think this kind of solution is not maintainable, not really smart and above all error prone. So we decided to use Python and its [config parser](https://docs.python.org/3/library/configparser.html) module to parse the INI file.

# Environment Variables
This section is partially based on the official [certbot command line options](https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options) documentation. Most of the environment variables defaults to an empty string which is in most cases equivalent to a boolean `false`. If you wish to set this environment variable to a boolean `true`, leave its value to `1` or any other non-empty string. There are also some environment variables wish require a string or number but each of them have a well documentation to describe its expectation.

## Required
`EMAIL`
> One or more email addresses separated by commas used for account registration and important notifications.
---
`DOMAINS`
> Comma separated list of domains which should be protected by the obtained certificate. The first domain in this list will be always the subject CN (Common Name) and all domains will be the SANs (Subject Alternative Names) in this certificate. In addition to that the first domain is used for the file name of the obtained certificate. In the case of a name collision it will append a number like 0001 to the file name. If you want to use another value for the file name use the `CERT_NAME` environment variable.

## Optional
`CERT_NAME`
> The name of the obtained certificate used for its file name. This value does not effect the certificate's content itself.
---
`PREFERRED_CHALLENGES`
> Sorted, comma separated list of preferred [challenges](https://letsencrypt.org/docs/challenge-types/) used for authorization. Each challenge has a version but if you set e.g "http" as `PREFERRED_CHALLENGES`, [certbot][1] will select the latest version automatically. If no value is set for this environment variable, we try to auto-detect this value based on the configured `AUTHENTICATOR` environment variable. The table below shows each `PREFERRED_CHALLENGES` which is used by an `AUTHENTICATOR` by default:

| AUTHENTICATOR                                                                    | PREFERRED_CHALLENGES   |
|----------------------------------------------------------------------------------|------------------------|
| [webroot](https://eff-certbot.readthedocs.io/en/stable/using.html#webroot)       | http-01                |
| [standalone](https://eff-certbot.readthedocs.io/en/stable/using.html#standalone) | http-01                |
| [dns](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)       | dns-01                 |

---
`ISSUANCE_TIMEOUT`
> The duration in seconds how long [certbot][1] will wait for the ACME server to issue a certificate. Default is 90 seconds.
---
`MAX_LOG_BACKUPS`
> The maximum number of backup logs which should be kept by [certbot's][1] built-in log rotation. If set this value to 0, log rotation is disabled and [certbot][1] will always write to the same log file. It might be useful to set this value to 0 if you want to use external log rotation software like [logrotate](https://linux.die.net/man/8/logrotate).
---
`FORCE_RENEWAL`
> Force [certbot][1] to renew a certificate if exists and regardless of whether it is near expiry.
---
`QUIET`
> Silence all output except errors.
---
`AUTHENTICATOR`
> Name of the authenticator plugin. Default is standalone.
---
`HTTP01_ADDRESS`
> The address the server listens to during http-01 challenge. Applied if `AUTHENTICATOR` is standalone.
---
`HTTP01_PORT`
> Port used in the http-01 challenge. Applied if `AUTHENTICATOR` is standalone.
---
`WEBROOT_PATH`
> Path to the top-level directory containing the files served by your webserver. Applied if `AUTHENTICATOR` is webroot and `WEBROOT_PATH` is required in this case.
---
`DNS_AUTHENTICATOR_CREDENTIALS`
> DNS provider credentials INI file. Applied if `AUTHENTICATOR` is from type dns.
---
`DNS_PROPAGATION_SECONDS`
> The number of seconds to wait for DNS to propagate before asking the ACME server to verify the DNS record. Applied if `AUTHENTICATOR` is from type dns.
---
`DNS_PLUGIN_FLAGS`
> Additional command line options for the DNS plugin.
---
`STAGING`
> Use the staging server to obtain or revoke test (invalid) certificates; equivalent to set the environment variable `SERVER` to `https://acme-staging-v02.api.letsencrypt.org/directory`.
---
`VERBOSE`
> Make [certbot's][1] output verbose.
---
`DEBUG`
> Show tracebacks in case of errors.
---
`RSA_KEY_SIZE`
> Size of the RSA key. Default is 2048.
---
`KEY_TYPE`
> Type of generated private key. Can be either `rsa` or `ecdsa`.
---
`ELLIPTIC_CURVE`
> The SECG [elliptic curve](https://datatracker.ietf.org/doc/html/rfc8446#section-7.4.2) name to use. Default is secp256r1.
---
`SERVER`
> ACME Directory Resource URI. Default is `https://acme-v02.api.letsencrypt.org/directory`.
---
`PRE_HOOK_CMD`
> Command to be run in a shell before obtaining any certificates. Can be used for renewal to temporarily shutdown your webserver that might conflict with the standalone plugin. This will only be called if a certificate is actually to be obtained/renewed. When renewing several certificates that have identical pre-hooks, only the first will be executed.
---
`POST_HOOK_CMD`
> Command to be run in a shell after attempting to obtain/renew certificates. Can be used to deploy renewed certificates or to restart any servers that were stopped by `PRE_HOOK_CMD`. This is only run if an attempt was made to obtain/renew a certificate. If multiple renewed certificates have identical post-hooks, only one will be run.
---
`DEPLOY_HOOK_CMD`
> Command to be run in a shell once for each successfully issued certificate. For this command, the shell variable *$RENEWED_LINEAGE* will point to the `/etc/letsencrypt` live subdirectory (for example, "/etc/letsencrypt/live/example.com") containing the new certificates and keys; the shell variable *$RENEWED_DOMAINS* will contain a space separated list of renewed certificate domains (for example, "`example.com www.example.com`").
---
`CERTBOT_CERTONLY_FLAGS`
> Additional command line options for [certbot's][1] certonly command.
---
`CERTBOT_RENEW_FLAGS`
> Additional command line options for [certbot's][1] renew command.
---
`DNS_PLUGINS`
> Comma separated list of DNS plugin names which will be installed with [pip][3].
---
`RUN_ONCE`
> If defined, the `CRON` environment variable is ignored and [certbot][1] runs only once.
---
`CRON`
> [Cron](https://crontab.guru/crontab.5.html) expression for [certbot's][1] automatically renewal. If you have no idea of how to write such an cron expression, use [crontab guru](https://crontab.guru/) to generate one.
---
`ENABLE_MULTI_CERTIFICATES`
> If defined, the [multi-certificates](#multiple-certificates) feature is enabled. Disabled by default.
---
`MULTI_CERTIFICATES_INI_FILE`
> Change the default INI file location from `/etc/certbot/multi-certificates.ini` to another one. Ignored if `ENABLE_MULTI_CERTIFICATES` is undefined.

# Volumes
- `/etc/letsencrypt` - stores the obtained certificates.
- `/etc/certbot/multi-certificates.ini` - the INI file for the [multi-certificates](#multiple-certificates) feature. Must be mounted manually and is optional, i.e is not exposed by the Dockerfile.

# Exposed Ports
- 80

# Building from Source
Checkout this repository and run `docker build -t nbraun1/certbot .` in the project's root directory. You can use any arbitrary Docker tag. Use the built tag in your [docker run](#run-with-docker-run) command or in your [docker-compose.yml](#run-with-docker-compose) to apply your modifications.

# Reporting Issues
If you found a bug or miss a feature, feel free to create an issue in GitHub's integrated [issue tracker](https://github.com/nbraun1/certbot/issues). But before doing so, please check if there is already an issue which describes your bug or feature in a similar fashion.

# License
This [certbot][1] is Open Source software released under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0.html).