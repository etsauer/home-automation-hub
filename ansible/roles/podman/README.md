# podman role

Ensures the Podman package (and Quadlet generator) are present so other roles
can deploy `.container` units.

## Scope

- Install `podman` (and any packages listed in `podman_packages`)
- Optionally create `podman_user` when set
- Verify `podman` CLI and `podman-system-generator` exist

## Out of scope

- **`podman.socket`** — not used by this hub; services are systemd Quadlets
- Starting/restarting application containers (owned by each service role)

## Variables

- `podman_packages` (default: `[podman]`)
- `podman_user` (default empty — unused)
- `podman_rehearsal_mode` (skips package install / host checks)

## site.yml

Runs first as a prerequisite before Caddy / DDNS / Mosquitto / HA / Frigate.
