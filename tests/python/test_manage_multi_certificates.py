import importlib.util
import subprocess
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

    def runner(args, stderr, env, check=False):
        calls.append((args, env.copy()))
        return subprocess.CompletedProcess(args, 0)

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

    def runner(args, stderr, env, check=False):
        calls.append((args, env.copy()))
        return subprocess.CompletedProcess(args, 0)

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
        ('./scripts/run-crond.sh', ['./scripts/run-crond.sh'])
    ]


@pytest.mark.parametrize(
    ('failed_command', 'expected_commands'),
    [
        (
            './scripts/certbot-certonly.sh',
            ['./scripts/certbot-certonly.sh'],
        ),
        (
            './scripts/configure-crontab.sh',
            ['./scripts/certbot-certonly.sh', './scripts/configure-crontab.sh'],
        ),
    ],
)
def test_main_stops_on_failed_command(
    manager,
    tmp_path,
    capsys,
    failed_command,
    expected_commands,
):
    ini_file = tmp_path / 'certificates.ini'
    ini_file.write_text(
        '[DEFAULT]\nEMAIL=default@example.invalid\n'
        '[first]\nDOMAINS=first.example.invalid\n'
        '[second]\nDOMAINS=second.example.invalid\n',
        encoding='utf-8',
    )
    calls = []
    exec_calls = []

    def runner(args, stderr, env, check=False):
        calls.append(args[0])
        result = subprocess.CompletedProcess(
            args, 42 if args[0] == failed_command else 0,
        )
        if check:
            result.check_returncode()
        return result

    with pytest.raises(SystemExit) as error:
        manager.main(
            {'MULTI_CERTIFICATES_INI_FILE': str(ini_file)},
            runner=runner,
            execvp=lambda *args: exec_calls.append(args),
        )

    assert error.value.code == 42
    assert calls == expected_commands
    assert exec_calls == []
    stderr = capsys.readouterr().err
    assert 'first' in stderr
    assert Path(failed_command).name in stderr
    assert '42' in stderr


@pytest.mark.parametrize(
    ('environment', 'default_options', 'first_options', 'second_options',
     'scheduled_domains'),
    [
        ({'RUN_ONCE': '1'}, '', '', '', []),
        ({}, '', 'RUN_ONCE=1\n', 'RUN_ONCE=1\n', []),
        ({}, 'RUN_ONCE=1\n', '', 'RUN_ONCE=\n', ['second.example.invalid']),
        ({}, '', 'RUN_ONCE=1\n', '', ['second.example.invalid']),
    ],
    ids=['environment', 'all-sections', 'empty-override', 'mixed-sections'],
)
def test_main_starts_scheduler_only_for_effective_renewal_sections(
    manager,
    tmp_path,
    environment,
    default_options,
    first_options,
    second_options,
    scheduled_domains,
):
    ini_file = tmp_path / 'certificates.ini'
    ini_file.write_text(
        '[DEFAULT]\nEMAIL=default@example.invalid\n'
        f'{default_options}'
        '[first]\nDOMAINS=first.example.invalid\n'
        f'{first_options}'
        '[second]\nDOMAINS=second.example.invalid\n'
        f'{second_options}',
        encoding='utf-8',
    )
    calls = []
    exec_calls = []

    def runner(args, stderr, env, check=False):
        calls.append((args[0], env['DOMAINS']))
        return subprocess.CompletedProcess(args, 0)

    manager.main(
        dict(environment, MULTI_CERTIFICATES_INI_FILE=str(ini_file)),
        runner=runner,
        execvp=lambda *args: exec_calls.append(args),
    )

    assert [domain for command, domain in calls
            if command == './scripts/certbot-certonly.sh'] == [
        'first.example.invalid', 'second.example.invalid',
    ]
    assert [domain for command, domain in calls
            if command == './scripts/configure-crontab.sh'] == scheduled_domains
    assert len(exec_calls) == (1 if scheduled_domains else 0)
