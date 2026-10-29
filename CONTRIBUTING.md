# Contributing

Thanks for helping. Bug reports, fixes, docs improvements and new services are all welcome. Please open an [issue](https://github.com/madalinpopa/ubuntu-server-automation/issues) first for larger changes, so we can agree on the approach before you spend time on it.

## Set up

```bash
git clone https://github.com/<your-username>/ubuntu-server-automation.git
cd ubuntu-server-automation
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
git checkout -b my-change
```

Use Python 3.12, 3.13 or 3.14.

## Checks to run before a pull request

These three run in GitHub Actions on every pull request (`.github/workflows/ci.yml`). Run them locally first. None of them needs a server or a vault password.

**Syntax check** of every playbook:

```bash
for p in playbooks/*.yml; do ansible-playbook -i inventory/hosts.example.yml --syntax-check "$p"; done
```

Each one prints `playbook: playbooks/<name>.yml` when it parses.

**Lint** the whole repository:

```bash
ansible-lint
```

It must pass with the `production` profile and no warnings.

**Docs check** for em dashes and broken relative links in Markdown files:

```bash
python3 .github/scripts/check_docs.py
```

It checks files tracked by git, so `git add` new Markdown files first.

## Integration test

If you change anything in `playbooks/`, `tasks/`, `services/`, `handlers/` or the templates, also run the Lima test. It needs a Mac or Linux machine with [Lima](https://lima-vm.io/) and takes about 6 minutes:

```bash
tests/run.sh
```

See [Run the tests in Lima VMs](docs/how-to/test-with-lima.md). CI cannot run it, so please say in the pull request whether you ran it, and on which releases.

## Guidelines

- Keep it simple. Plain playbooks and task files, no roles, no extra tools unless they clearly help.
- Use built-in modules with their full names (`ansible.builtin.apt`, not `apt`) and give every task a descriptive name.
- Tasks must be idempotent: a second run reports `changed=0`. The Lima test checks this.
- New settings go in `inventory/group_vars/all/vars.yml` or `services.yml` with a comment and a safe default. Document them in [docs/reference/variables.md](docs/reference/variables.md).
- Secrets come from the vault as `vault_*` variables, with a placeholder in `inventory/vault.example.yml`. Use `no_log: true` on tasks that handle them.
- A new service must be off by default, publish its port on `127.0.0.1` only, pin its image tag, create its admin account before it is reachable, and publish its Caddy site with `tasks/caddy_site.yml` as its last task. Add its name to the list in the last task of `playbooks/services.yml`. Follow an existing file in `services/`.
- Write docs in plain English with short sentences, no em dashes, and commands that can be copied as they are.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with the area as the scope, for example `fix(firewall): allow IPv6 SSH rule` or `docs(readme): fix quick start`. Keep one logical change per commit.

## Code of conduct

Be kind and constructive. This project follows the [Contributor Covenant](https://www.contributor-covenant.org/).
