# godaddy_ddns role

Deploys the GoDaddy DDNS shell script and a Podman Quadlet unit that runs it
in `docker.io/alpine:latest` (installs `curl`/`jq` at container start).

## Current shape

- Script at `/etc/godaddy-ddns/godaddy-ddns.sh` (service config dir, not host PATH),
  mounted read-only into the container as `/godaddy-ddns.sh`
- Quadlet `[Container]` with `Environment=` for `GD_KEY`, `GD_SECRET`, `GD_DOMAIN`,
  `GD_RECORD_NAMES` and `Exec=/godaddy-ddns.sh`
- Loop polls public IP and upserts A records via GoDaddy's v3 zones API
  (`PUT` when a `type=A` record exists, `POST` when it does not)
- Default names: `hass` (`hass.mre.coffee`) and `@` (apex `mre.coffee`)
- Legacy `/usr/local/bin/godaddy-ddns.sh` is removed on deploy when present

`www` is not managed here until you add a `www` A (or CNAME) and a Caddy site.

## Variables of interest

- `gd_domain` (default `mre.coffee`)
- `gd_record_names` (default `[hass, "@"]`; role asserts both stay present)
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

Role default is write-only; `site.yml` sets `gd_manage_service: true`.
Rehearse with `ansible/test-godaddy-ddns.yml`. Apply with
`ansible/site.yml --tags godaddy_ddns`. Write-only: `-e gd_manage_service=false`.

GET filters `type=A` so MX/TXT at the apex are not deleted. Extra A records
for the same name (for example a leftover S3 address) are removed after a
successful upsert.

Apex `recordId` values from GoDaddy can contain `[]`. curl treats those as
URL globs (exit 3) unless `--globoff` is set; the script URL-encodes IDs and
does not exit the loop if one name fails.

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
