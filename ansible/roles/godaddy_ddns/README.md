# godaddy_ddns role

Deploys the GoDaddy DDNS shell script and a Podman Quadlet unit that runs it
in `docker.io/alpine:latest` (installs `curl`/`jq` at container start).

## Current shape

- Script at `/etc/godaddy-ddns/godaddy-ddns.sh` (service config dir, not host PATH),
  mounted read-only into the container as `/godaddy-ddns.sh`
- Quadlet `[Container]` with `Environment=` for `GD_KEY`, `GD_SECRET`, `GD_DOMAIN`,
  `GD_SUBDOMAIN` and `Exec=/godaddy-ddns.sh`
- Loop polls public IP and upserts the `hass` A record via GoDaddy's v3 zones API
- Legacy `/usr/local/bin/godaddy-ddns.sh` is removed on deploy when present

## Variables of interest

- `gd_domain` / `gd_subdomain` (defaults: `mre.coffee` / `hass`)
- `gd_key` / `gd_secret` (from `group_vars/all/secrets.yml`, required)
- `gd_image`
- `gd_script_path` (default `/etc/godaddy-ddns/godaddy-ddns.sh`)
- `gd_legacy_script_path` / `gd_systemd_dir`
- `gd_manage_service` (default `false`: write files only; `true` daemon-reloads + restarts)
- `gd_rehearsal_mode`
- `gd_sleep_seconds`

## Templates

- `godaddy-ddns.sh.j2`
- `godaddy-ddns.container.j2`

## Safety

Default is write-only. Cut over only after reviewing the rendered script and
`.container` on the Pi, then either restart manually or re-run with
`-e gd_manage_service=true`.

## Future work: PAT expiry

GoDaddy personal access tokens appear to require an expiry date, so `gd_secret`
will eventually stop working unless it is rotated. Before relying on this service
unattended, investigate:

1. **Automated refresh** — whether GoDaddy offers an API or OAuth flow that can
   mint/rotate a PAT (or equivalent credentials) without manual portal work. If
   so, wire that into this role or a companion job and update `secrets.yml` /
   the Quadlet env safely.
2. **Expiry alerting via Home Assistant** — if refresh cannot be automated, track
   the token's expiry date (variable or companion sensor) and notify through HA
   with enough lead time that DNS updates do not silently fail while unattended.

Until one of those is in place, treat PAT rotation as a manual operational task
and prefer shorter calendar reminders over discovering a 404 loop in the logs.
