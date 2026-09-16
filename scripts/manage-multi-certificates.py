#!/usr/bin/env python3
import configparser as cp
import os
import subprocess

DEFAULT_INI_FILE = '/etc/certbot/multi-certificates.ini'


def read_config(ini_file):
    """Read the multi-certificate configuration without changing option case."""
    if not os.path.exists(ini_file):
        raise FileNotFoundError(f'{ini_file} not exists')

    config_parser = cp.ConfigParser()
    config_parser.optionxform = str
    config_parser.read(ini_file)
    return config_parser


def section_options(config_parser, section, environment):
    """Merge process environment values with one INI section."""
    opts = environment.copy()
    for key, val in config_parser.items(section):
        opts[key] = val
    return opts


def renewal_options(options):
    """Prepare renewal options, including the fallback certificate name."""
    renew_options = options.copy()
    if renew_options.get('CERT_NAME', '') == '':
        renew_options['CERT_NAME'] = renew_options['DOMAINS'].split(',')[0]
    return renew_options


def renewal_arguments(options):
    """Build the configure-crontab arguments for one certificate."""
    renew_options = renewal_options(options)

    renew_args = [f'--cert-name "{renew_options["CERT_NAME"]}"']
    if renew_options.get('QUIET', '') != '':
        renew_args += ['-q']

    if renew_options.get('PRE_HOOK_CMD', '') != '':
        renew_args += [f'--pre-hook "{renew_options["PRE_HOOK_CMD"]}"']

    if renew_options.get('POST_HOOK_CMD', '') != '':
        renew_args += [f'--post-hook "{renew_options["POST_HOOK_CMD"]}"']

    if renew_options.get('DEPLOY_HOOK_CMD', '') != '':
        renew_args += [f'--deploy-hook "{renew_options["DEPLOY_HOOK_CMD"]}"']

    if renew_options.get('CERTBOT_RENEW_FLAGS', '') != '':
        renew_args += [
            f'--certbot-renew-flags {renew_options["CERTBOT_RENEW_FLAGS"]}']

    return renew_args


def main(environment=None, runner=subprocess.run, execvp=os.execvp):
    """Obtain and optionally schedule every certificate in the INI file."""
    if environment is None:
        environment = os.environ.copy()

    ini_file = environment.get('MULTI_CERTIFICATES_INI_FILE', DEFAULT_INI_FILE)
    config_parser = read_config(ini_file)

    for section in config_parser.sections():
        opts = section_options(config_parser, section, environment)

        runner(
            ['./scripts/certbot-certonly.sh'],
            stderr=subprocess.STDOUT,
            env=opts,
        )

        # Run configure-crontab.sh if RUN_ONCE is undefined for this section.
        if opts.get('RUN_ONCE', '') == '':
            renew_opts = renewal_options(opts)
            renew_args = ['./scripts/configure-crontab.sh']
            renew_args.extend(renewal_arguments(renew_opts))
            runner(renew_args, stderr=subprocess.STDOUT, env=renew_opts)

    if config_parser.defaults().get('RUN_ONCE', '') == '':
        execvp('crond', ['crond', '-f', '-L', '/var/log/letsencrypt/cron.log'])


if __name__ == '__main__':
    main()
