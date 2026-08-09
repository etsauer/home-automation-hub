# Ansible inventory collection and safe testing guide

## Inventory collection

Usage:

1. Edit [ansible/hosts](hosts) and set the Pi host IP and user.
2. Ensure SSH key or passwordless access for the ansible_user.
3. Run:
   ansible-playbook -i ansible/hosts ansible/collect_inventory.yml

Collected tarball will be placed in [ansible/collected](collected/).

## Safe testing workflow

### Local rehearsal for a single role

For local validation of a role or template, use a rehearsal playbook instead of the production deployment playbooks. Current examples:

- [ansible/test-caddy.yml](test-caddy.yml)
- [ansible/test-godaddy-ddns.yml](test-godaddy-ddns.yml)
- [ansible/test-mosquitto.yml](test-mosquitto.yml)
- [ansible/test-homeassistant.yml](test-homeassistant.yml)
- [ansible/test-frigate.yml](test-frigate.yml)

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

It enables only roles that have been validated against the live host. As each
service is recovered, enable it there (see root [AGENTS.md](../AGENTS.md)).

### Temporary recovery playbooks (`fix-*`)

While catching up to live server state, single-role fix playbooks are useful:

- [ansible/fix-caddy.yml](fix-caddy.yml)
- [ansible/fix-godaddy-ddns.yml](fix-godaddy-ddns.yml)
- [ansible/fix-mosquitto.yml](fix-mosquitto.yml)
- [ansible/fix-homeassistant.yml](fix-homeassistant.yml)
- [ansible/fix-frigate.yml](fix-frigate.yml)

These default to write-only (`*_manage_service=false`) with Ansible backups.
They are temporary necessities — fold each service into `site.yml` once cutover
is known-good, rather than treating `fix-*` as the long-term workflow.

Suggested recovery flow (per unrecovered service):

1. Rehearse locally with the matching `test-*.yml` playbook and inspect `.rehearsal/`.
2. Preview on the Pi: `ansible-playbook -i ansible/hosts ansible/fix-<service>.yml --check --diff`
3. Apply write-only, inspect rendered files, then cut over with
   `-e <role>_manage_service=true` (or an equivalent deliberate restart).
4. Enable the role in [site.yml](site.yml).

### Dry-run usage

The check-mode playbook is:

- [ansible/dry-run.yml](dry-run.yml)

It targets `pi` with `check_mode: true` and **refuses** to run if check mode is not active.

## Security

- Do not store unencrypted secrets in this repo.
- The inventory collection workflow and extracted inventory are temporary operational artifacts. Keep them out of the final deployment repo state.

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

Do NOT commit [ansible/extracted](extracted/) or collected tarballs; these are temporary and may contain secrets.
