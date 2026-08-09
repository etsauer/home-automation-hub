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
  - `ansible/extracted/`, collected tarballs, `.rehearsal/`, `.ansible-tmp/`
- Do **not** paste API keys, PATs, or passwords into commits, PRs, or handoffs.
- Do **not** enable an unvalidated role in `site.yml`. Skeleton / unrecovered
  roles can overwrite live configs and leave Quadlet “zombie” units
  (`Loaded: not-found`, `Active: running`).
- Prefer `--check --diff` before any apply that touches the Pi.
- Never run destructive git commands unless the user explicitly asks.

## `site.yml` vs `fix-*` playbooks

- **`site.yml`** is the intended steady-state entrypoint. As each service is
  recovered and validated, enable that role there (with
  `*_manage_service: true` for production manage/restart behavior).
- **`fix-<service>.yml`** playbooks are **temporary** catch-up tools while the
  repo converges on live server state. They default to write-only
  (`*_manage_service: false`) so agents can render config with backups before
  a deliberate cutover.
- Do not treat `fix-*` as the long-term UX; fold learnings back into the role
  and enable the service in `site.yml`, then retire the fix playbook when it
  no longer adds safety.

## Recovery pattern (per unrecovered service)

1. Capture live unit + config from the Pi (or trusted recovered files) before
   overwriting templates.
2. Harden the role like Caddy / GoDaddy DDNS: asserts against placeholders,
   `backup: true`, write-only default, local rehearsal playbook, optional
   managed restart handler.
3. Rehearse locally (`ansible/test-<service>.yml` → inspect `.rehearsal/`).
4. Preview on the Pi with the fix playbook: `--check --diff`.
5. Apply write-only, inspect rendered files, then cut over (manual restart or
   `-e <role>_manage_service=true`).
6. Enable the role in `site.yml` once the live cutover is known-good.
7. Keep other unrecovered roles commented/disabled in `site.yml`.

## Currently enabled in `site.yml`

- `podman` (package prerequisite only; does not manage `podman.socket`)
- `caddy`
- `godaddy_ddns`
- `mosquitto`
- `homeassistant`
- `frigate`

## Secrets

- Start from `ansible/group_vars/all/secrets.yml.example`.
- Assert only the secrets required by **enabled** roles in `site.yml`.
- GoDaddy PATs expire; see future work in
  [`ansible/roles/godaddy_ddns/README.md`](ansible/roles/godaddy_ddns/README.md).

## Handoffs

When switching agents, use the repo `handoff` / `pickup` skills. Redact
credentials. Point at paths and PR URLs instead of pasting large diffs.
