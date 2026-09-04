# Configuration

Configure the image with environment variables. See Certbot's [command-line
options](https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options)
for additional context. Most options are empty by default; an empty value
usually means false. Any non-empty value, such as `1`, enables a boolean option.
String and numeric options must use the format expected by Certbot.

## Required variables

| Variable | Description |
| --- | --- |
| `EMAIL` | One or more comma-separated email addresses for account registration and important notifications. |
| `DOMAINS` | Comma-separated domains to protect. The first domain is the subject CN (Common Name), all domains are SANs (Subject Alternative Names), and the first domain determines the certificate filename. A collision adds a suffix such as `0001`; use `CERT_NAME` to choose another filename. |

## Optional variables

### Certificate management

| Variable | Description |
| --- | --- |
| `CERT_NAME` | Certificate filename. This does not change the certificate contents. |
| `PREFERRED_CHALLENGES` | Sorted, comma-separated preferred [challenge types](https://letsencrypt.org/docs/challenge-types/). Each challenge has a version; for example, `http` lets Certbot select the latest HTTP challenge version. If unset, the value is detected from `AUTHENTICATOR`. |
| `ISSUANCE_TIMEOUT` | Seconds Certbot waits for issuance. The default is `90`. |
| `MAX_LOG_BACKUPS` | Maximum number of Certbot log backups. `0` disables rotation and reuses one log file, which can be useful with external log rotation such as [`logrotate`](https://linux.die.net/man/8/logrotate). |
| `FORCE_RENEWAL` | Forces renewal even when an existing certificate is not near expiry. |
| `QUIET` | Suppresses all output except errors. |

The default preferred challenge depends on the authenticator:

| Authenticator | Default challenge |
| --- | --- |
| [`webroot`](https://eff-certbot.readthedocs.io/en/stable/using.html#webroot) | `http-01` |
| [`standalone`](https://eff-certbot.readthedocs.io/en/stable/using.html#standalone) | `http-01` |
| [`dns-*`](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) | `dns-01` |

### Authenticators

| Variable | Description |
| --- | --- |
| `AUTHENTICATOR` | Authenticator name. The default is `standalone`. |
| `HTTP01_ADDRESS` | Address on which the standalone HTTP-01 server listens. |
| `HTTP01_PORT` | Port on which the standalone HTTP-01 server listens. |
| `WEBROOT_PATH` | Top-level directory served by the web server. Required when `AUTHENTICATOR=webroot`. |
| `DNS_AUTHENTICATOR_CREDENTIALS` | DNS provider credentials INI file. Used by DNS authenticators. |
| `DNS_PROPAGATION_SECONDS` | Seconds to wait for DNS propagation before asking the ACME server to verify the record. |
| `DNS_PLUGIN_FLAGS` | Additional command-line options for the DNS plugin. |

### Testing and debugging

| Variable | Description |
| --- | --- |
| `STAGING` | Uses the Let's Encrypt staging server for obtaining or revoking test (invalid) certificates. Equivalent to `SERVER=https://acme-staging-v02.api.letsencrypt.org/directory`. |
| `VERBOSE` | Enables verbose Certbot output. |
| `DEBUG` | Shows tracebacks when errors occur. |

### Key and server options

| Variable | Description |
| --- | --- |
| `RSA_KEY_SIZE` | RSA key size. The default is `2048`. |
| `KEY_TYPE` | Key type: `rsa` or `ecdsa`. |
| `ELLIPTIC_CURVE` | SECG elliptic-curve name, as defined by [RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446#section-7.4.2). The default is `secp256r1`. |
| `SERVER` | ACME Directory Resource URI. The default is `https://acme-v02.api.letsencrypt.org/directory`. |

### Renewal hooks

| Variable | Description |
| --- | --- |
| `PRE_HOOK_CMD` | Shell command run before obtaining or renewing certificates. It can temporarily stop a web server that conflicts with the standalone authenticator. It runs only when an obtain/renew attempt occurs; identical pre-hooks run only once. |
| `POST_HOOK_CMD` | Shell command run after an obtain/renew attempt. It can deploy certificates or restart a server stopped by `PRE_HOOK_CMD`. It runs only when an attempt occurs; identical post-hooks run only once. |
| `DEPLOY_HOOK_CMD` | Shell command run once per successfully issued certificate. `$RENEWED_LINEAGE` points to its `/etc/letsencrypt/live/...` directory (for example, `/etc/letsencrypt/live/example.com`), and `$RENEWED_DOMAINS` contains its space-separated domains (for example, `example.com www.example.com`). |

### Custom options and scheduling

| Variable | Description |
| --- | --- |
| `CERTBOT_CERTONLY_FLAGS` | Additional options for Certbot's `certonly` command. |
| `CERTBOT_RENEW_FLAGS` | Additional options for Certbot's `renew` command. |
| `DNS_PLUGINS` | Comma-separated DNS plugin names installed with pip at container startup. |
| `RUN_ONCE` | Runs Certbot once and ignores `CRON` when set. |
| `CRON` | [Cron](https://crontab.guru/crontab.5.html) expression for automatic renewal. The default is `0 0,12 * * *`. Use [crontab guru](https://crontab.guru/) if needed. |

### Multiple certificates

| Variable | Description |
| --- | --- |
| `ENABLE_MULTI_CERTIFICATES` | Enables multi-certificate mode when set. It is disabled by default. |
| `MULTI_CERTIFICATES_INI_FILE` | Overrides the INI file path. The default is `/etc/certbot/multi-certificates.ini`; this option is ignored when multi-certificate mode is disabled. |
