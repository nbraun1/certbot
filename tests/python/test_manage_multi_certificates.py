import importlib.util
from pathlib import Path

import pytest


MODULE_PATH = (
    Path(__file__).parents[2] / 'scripts' / 'manage-multi-certificates.py'
)


@pytest.fixture
def manager():
    spec = importlib.util.spec_from_file_location(
        'manage_multi_certificates',
        MODULE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_read_config_preserves_option_case(manager, tmp_path):
    ini_file = tmp_path / 'certificates.ini'
    ini_file.write_text(
        '[DEFAULT]\nEMAIL=default@example.invalid\n\n'
        '[certificate]\nDOMAINS=example.invalid\n',
        encoding='utf-8',
    )

    config = manager.read_config(str(ini_file))

    assert config.defaults()['EMAIL'] == 'default@example.invalid'
    assert config['certificate']['DOMAINS'] == 'example.invalid'


def test_read_config_reports_missing_file(manager, tmp_path):
    missing_file = tmp_path / 'missing.ini'

    with pytest.raises(FileNotFoundError, match='missing.ini not exists'):
        manager.read_config(str(missing_file))


def test_renewal_arguments_use_first_domain_as_certificate_name(manager):
    options = {
        'DOMAINS': 'first.example.invalid,second.example.invalid',
        'QUIET': '1',
        'PRE_HOOK_CMD': 'echo before',
        'POST_HOOK_CMD': 'echo after',
        'DEPLOY_HOOK_CMD': 'echo deploy',
        'CERTBOT_RENEW_FLAGS': '--dry-run --foo',
    }

    assert manager.renewal_arguments(options) == [
        '--cert-name "first.example.invalid"',
        '-q',
        '--pre-hook "echo before"',
        '--post-hook "echo after"',
        '--deploy-hook "echo deploy"',
        '--certbot-renew-flags --dry-run --foo',
    ]


def test_main_runs_certbot_for_each_section_without_starting_crond(
    manager,
    tmp_path,
):
    ini_file = tmp_path / 'certificates.ini'
    ini_file.write_text(
        '[DEFAULT]\n'
        'EMAIL=default@example.invalid\n'
        'RUN_ONCE=1\n'
        '\n'
        '[first]\n'
        'DOMAINS=first.example.invalid\n'
        '\n'
        '[second]\n'
        'DOMAINS=second.example.invalid\n',
        encoding='utf-8',
    )
    calls = []

    def runner(args, stderr, env):
        calls.append((args, env.copy()))

    def unexpected_execvp(*args):
        raise AssertionError('crond should not be started for RUN_ONCE')

    manager.main(
        {
            'MULTI_CERTIFICATES_INI_FILE': str(ini_file),
            'AUTHENTICATOR': 'standalone',
        },
        runner=runner,
        execvp=unexpected_execvp,
    )

    assert [call[0] for call in calls] == [
        ['./scripts/certbot-certonly.sh'],
        ['./scripts/certbot-certonly.sh'],
    ]
    assert calls[0][1]['EMAIL'] == 'default@example.invalid'
    assert calls[0][1]['DOMAINS'] == 'first.example.invalid'
    assert calls[1][1]['DOMAINS'] == 'second.example.invalid'


def test_main_configures_cron_and_starts_scheduler_when_run_once_is_unset(
    manager,
    tmp_path,
):
    ini_file = tmp_path / 'certificates.ini'
    ini_file.write_text(
        '[DEFAULT]\n'
        'EMAIL=default@example.invalid\n'
        '\n'
        '[certificate]\n'
        'DOMAINS=example.invalid,www.example.invalid\n',
        encoding='utf-8',
    )
    calls = []
    exec_calls = []

    def runner(args, stderr, env):
        calls.append((args, env.copy()))

    def fake_execvp(file, args):
        exec_calls.append((file, args))

    manager.main(
        {'MULTI_CERTIFICATES_INI_FILE': str(ini_file)},
        runner=runner,
        execvp=fake_execvp,
    )

    assert calls[0][0] == ['./scripts/certbot-certonly.sh']
    assert calls[1][0] == [
        './scripts/configure-crontab.sh',
        '--cert-name "example.invalid"',
    ]
    assert calls[1][1]['CERT_NAME'] == 'example.invalid'
    assert exec_calls == [
        ('crond', ['crond', '-f', '-L', '/var/log/letsencrypt/cron.log'])
    ]
