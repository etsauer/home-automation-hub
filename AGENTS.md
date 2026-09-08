# Agent guidelines

Guidance for AI agents working in this repository. Keep the human-facing
[`README.md`](README.md) short; put operational caution and recovery detail here.

## Goal

Maintain Ansible-managed config-as-code for a Podman + systemd Quadlet home
automation / security hub. The long-term single entrypoint is
[`ansible/site.yml`](ansible/site.yml).

## Hard rules

- Do **not** commit secrets, inventory dumps, or rehearsal output:
  - `ansible/group_vars/all/secrets.yml` (gitignored)
  - `ansible/extracted/`, `ansible/collected/`, `.rehearsal/`, `.ansible-tmp/`
- Do **not** paste API keys, PATs, or passwords into commits, PRs, or handoffs.
- Do **not** enable an unvalidated role in `site.yml`. A bad Quadlet can leave
  “zombie” units (`Loaded: not-found`, `Active: running`).
- Prefer `--check --diff` before any apply that touches the Pi.
- Never run destructive git commands unless the user explicitly asks.

## `site.yml` and tags

- **`site.yml`** is the only Pi deploy entrypoint. Enabled roles run with
  `*_manage_service: true`.
- Apply one service with `--tags <role>` (role name is the tag: `caddy`,
  `godaddy_ddns`, `mosquitto`, `homeassistant`, `frigate`, `coffee_site`,
  `podman`). Secret asserts are tagged with the role that needs them
  (`godaddy_ddns`, `frigate`), not `always`.
- Preview: `ansible-playbook -i ansible/hosts ansible/site.yml --tags caddy --check --diff`
- Write files without restarting: add `-e caddy_manage_service=false` (same
  pattern for other `*_manage_service` vars).
- Rehearse templates locally with `ansible/test-<service>.yml`; do not add
  one-off Pi playbooks per service.

## Currently enabled in `site.yml`

- `podman` (package prerequisite only; does not manage `podman.socket`)
- `caddy`
- `godaddy_ddns`
- `mosquitto`
- `homeassistant`
- `frigate`
- `coffee_site` (localhost-only until Caddy grows an `mre.coffee` site)

## Secrets

- Start from `ansible/group_vars/all/secrets.yml.example`. Ansible loads
  `group_vars/all/secrets.yml` automatically when that file exists (inventory
  `ansible/hosts`). Do not add a play-level `vars_files` for it — that would
  make every tagged run require the file.
- Assert secrets on the role that needs them (`godaddy_ddns`, `frigate`),
  including matching `site.yml` pre_tasks so a full apply fails before writing
  other roles. `--tags coffee_site` / `caddy` / `podman` / `mosquitto` /
  `homeassistant` do not require those keys.
- GoDaddy PATs expire; see future work in
  [`ansible/roles/godaddy_ddns/README.md`](ansible/roles/godaddy_ddns/README.md).

## Handoffs

When switching agents, use the repo `handoff` / `pickup` skills. Redact
credentials. Point at paths and PR URLs instead of pasting large diffs.
