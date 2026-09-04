# Multiple Certificates

The multi-certificate feature obtains and renews multiple certificates from a
single INI configuration instead of requiring repeated `docker run` commands
or duplicated Compose services.

## Basic Setup

The feature is optional and is enabled with `ENABLE_MULTI_CERTIFICATES`. Write
the INI file yourself or start with the predefined
[`example.ini`](../examples/multi-certificates/example.ini).
Mount that file at `/etc/certbot/multi-certificates.ini`, or change the path
with `MULTI_CERTIFICATES_INI_FILE`.

See the [usage guide](usage.md#run-with-docker-run) for the complete Docker
command.

## INI File

The INI file may contain an optional `DEFAULT` section and one or more
domain-specific sections. Options in `DEFAULT` apply to every domain section.
An option in a domain section overrides the same default. Use the environment
variables listed in the [configuration reference](configuration.md).

## Technical Background

This background is optional. The INI file is parsed with Python's
[`configparser`](https://docs.python.org/3/library/configparser.html), not Bash.
Several GitHub INI parsers were dirty hacks, incomplete, non-working, or did
not meet the feature's requirements. `awk` and `sed` alternatives were
considered difficult to maintain, unintuitive, and error-prone.
