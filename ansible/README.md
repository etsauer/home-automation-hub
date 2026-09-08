# Ansible safe testing and deployment guide

## Safe testing workflow

### Local rehearsal for a single role

For local validation of a role or template, use a rehearsal playbook instead of the production deployment playbooks. Current examples:

- [ansible/test-caddy.yml](test-caddy.yml)
- [ansible/test-godaddy-ddns.yml](test-godaddy-ddns.yml)
- [ansible/test-mosquitto.yml](test-mosquitto.yml)
- [ansible/test-homeassistant.yml](test-homeassistant.yml)
- [ansible/test-frigate.yml](test-frigate.yml)
- [ansible/test-podman.yml](test-podman.yml)
- [ansible/test-coffee-site.yml](test-coffee-site.yml)

These playbooks run locally against `localhost`, use temporary paths inside the repository, and skip real systemd/service activation so they do not modify the host machine.

### Why this is safe

The rehearsal flow avoids changing real system locations such as:

- `/etc/caddy`
- `/etc/containers/systemd`

Instead, it writes rendered files to temporary directories under the repository so you can inspect the output safely before applying anything to the Pi.

### Do not run production playbooks until secrets are ready

The deployment playbooks use variables from:

- [ansible/group_vars/all/secrets.yml](group_vars/all/secrets.yml)

Those values should be populated from a secure secret source before any production deployment. Placeholder values are not suitable for a real deployment.

### Production entrypoint

The steady-state deployment entrypoint is:

- [ansible/site.yml](site.yml)

Roles in `site.yml` run with `*_manage_service: true`. Apply one service with
`--tags <role>` (the tag matches the role name). Secrets asserts use the
`always` tag so they still run. See root [AGENTS.md](../AGENTS.md).

```bash
# Everything
ansible-playbook -i ansible/hosts ansible/site.yml

# One service
ansible-playbook -i ansible/hosts ansible/site.yml --tags caddy --check --diff
ansible-playbook -i ansible/hosts ansible/site.yml --tags caddy

# Write files without restarting that service
ansible-playbook -i ansible/hosts ansible/site.yml --tags caddy -e caddy_manage_service=false
```

Available tags: `podman`, `caddy`, `godaddy_ddns`, `mosquitto`, `homeassistant`,
`frigate`, `coffee_site`.

`--tags <role>` does not run other roles (including `podman`). Use
`--tags podman,<role>` if the runtime package also needs updating.

Suggested flow for a role change:

1. Rehearse locally with the matching `test-*.yml` playbook and inspect `.rehearsal/`.
2. Preview on the Pi: `ansible-playbook -i ansible/hosts ansible/site.yml --tags <role> --check --diff`
3. Apply, or write-only first with `-e <role>_manage_service=false`.

### Dry-run usage

The check-mode playbook is:

- [ansible/dry-run.yml](dry-run.yml)

It targets `pi` with `check_mode: true` and **refuses** to run if check mode is not active. Tags work the same way as on `site.yml`.

## Security

- Do not store unencrypted secrets in this repo.
- Do not commit local dumps under `extracted/`, `collected/`, or `.rehearsal/` — they may contain secrets.

## Secrets management (recommended)

- Use Mozilla SOPS (recommended) or Ansible Vault to encrypt runtime secrets before committing.
- Start from the example scaffold at [ansible/group_vars/all/secrets.yml.example](group_vars/all/secrets.yml.example) and copy it to [ansible/group_vars/all/secrets.yml](group_vars/all/secrets.yml) with your real values.
- Keep [ansible/group_vars/all/secrets.yml](group_vars/all/secrets.yml) encrypted at rest and out of version control.
- Suggested bootstrap flow:
  1. Copy the example file: "cp ansible/group_vars/all/secrets.yml.example ansible/group_vars/all/secrets.yml"
  2. Fill in the real values locally.
  3. Encrypt the file with your preferred tool before any shared commit or deployment.
- Quick SOPS example (age key):
  1. Generate an age keypair: "age-keygen -o key.txt"
  2. Encrypt: "sops --encrypt --age $(cat key.txt | sed -n '1p') secrets.yml > secrets.yml.enc"
  3. Decrypt for use at runtime: "sops --decrypt secrets.yml.enc > secrets.yml"
- If using Ansible Vault:
  ansible-vault create group_vars/all/vault.yml
