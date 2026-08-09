# homeassistant role

Deploys the Home Assistant Podman Quadlet unit. **Does not manage**
`configuration.yaml` or other files under the config directory — those live on
the host and were recovered separately.

## Current shape (matches pre-incident Pi unit)

- Image `ghcr.io/home-assistant/home-assistant:stable`
- `PublishPort=8123:8123`
- `Environment=TZ=US/Eastern`
- `PodmanArgs=--privileged` plus `CAP_NET_ADMIN` / `CAP_NET_RAW`
- Volumes:
  - `/opt/homeassistant/config` → `/config`
  - `/mnt/lacie/ha_db/home-assistant_v2.db` → `/config/home-assistant_v2.db:Z`
  - `/etc/localtime` (ro), `/run/dbus` (ro)

## Safety

- Default is write-only (`ha_manage_service: false`)
- Asserts that `configuration.yaml` and the external DB file exist and are
  non-empty before writing the unit
- Never templates over `configuration.yaml` (the old skeleton task is gone)

## Variables of interest

- `ha_config_dir` / `ha_db_file` / `ha_image`
- `ha_publish_port` / `ha_timezone` / `ha_container_name`
- `ha_manage_service` / `ha_rehearsal_mode`

## Future work

Optionally manage selected YAML snippets via Ansible once the live config is
fully inventoried and secrets are handled safely — not required for Quadlet
recovery.
