#!/usr/bin/env python3
import os
import configparser as cp
import subprocess as sp

ini_file = os.environ['MULTI_CERTIFICATES_INI_FILE']
# check if the file exists because the config parser ignores any errors
# when opening and reading a file respectively
if not os.path.exists(ini_file):
    raise FileNotFoundError(f'{ini_file} not exists')

config_parser = cp.ConfigParser()
# prevent config parser from making strings to lowercase
config_parser.optionxform = str
config_parser.read(ini_file)

for section in config_parser.sections():
    # map ItemsView to dictionary
    opts = os.environ.copy()
    for key, val in config_parser.items(section):
        opts[key] = val

    sp.run(['./scripts/certbot-certonly.sh'], stderr=sp.STDOUT, env=opts)

    # run configure-crontab.sh if the RUN_ONCE environment variable is undefined
    if opts.get('RUN_ONCE', '') == '':
        # prepare existing renew options
        renew_opts = opts.copy()
        # if the CERT_NAME environment variable is undefined,
        # we have to set the first value in the DOMAINS environment variable as its value
        # to keep the renew individual
        if renew_opts.get('CERT_NAME', '') == '':
            renew_opts['CERT_NAME'] = renew_opts['DOMAINS'].split(',')[0]

        # collect existing renew options in a list
        # where each element is passed as argument to the renew script
        renew_opts_args = [f'--cert-name "{renew_opts["CERT_NAME"]}"']
        if renew_opts.get('QUIET', '') != '':
            renew_opts_args += ['-q']

        if renew_opts.get('PRE_HOOK_CMD', '') != '':
            renew_opts_args += [f'--pre-hook "{renew_opts["PRE_HOOK_CMD"]}"']

        if renew_opts.get('POST_HOOK_CMD', '') != '':
            renew_opts_args += [f'--post-hook "{renew_opts["POST_HOOK_CMD"]}"']

        if renew_opts.get('DEPLOY_HOOK_CMD', '') != '':
            renew_opts_args += [
                f'--deploy-hook "{renew_opts["DEPLOY_HOOK_CMD"]}"']

        if renew_opts.get('CERTBOT_RENEW_FLAGS', '') != '':
            renew_opts_args += [
                f'--certbot-renew-flags {renew_opts["CERTBOT_RENEW_FLAGS"]}']

        renew_args = ['./scripts/configure-crontab.sh']
        renew_args.extend(renew_opts_args)
        sp.run(renew_args, stderr=sp.STDOUT, env=renew_opts)

if config_parser.defaults().get('RUN_ONCE', '') == '':
    os.execvp('crond', ['crond', '-f', '-L', '/var/log/letsencrypt/cron.log'])
