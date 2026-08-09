# frigate role

Deploys the Frigate Podman Quadlet unit and the storage-capacity monitor.
**Does not manage** `config.yaml` or other files under the config directory —
those live on the host.

## Current shape (matches pre-incident Pi unit)

- Image `ghcr.io/blakeblackshear/frigate:stable`
- `FRIGATE_RTSP_PASSWORD` from `secrets.yml`
- Hailo + USB device passthrough, `--privileged`, `ShmSize=256mb`
- Ports: `8971`, `5000`, `8554`, `8555/tcp`, `8555/udp`
- Volumes:
  - `/opt/frigate/config` → `/config:Z`
  - `/mnt/lacie/frigate_media` → `/media/frigate:Z`

## Storage monitor

When `frigate_manage_storage_monitor` is true (default):

- Script: `/usr/local/bin/frigate-storage-monitor.sh`
- Env (mode `0600`): `/etc/frigate-monitor.env`
- Root cron every 15 minutes
- On threshold breach, notifies Home Assistant via
  `notify.<ha_notify_service>` using `ha_bearer_token`

Required secrets: `ha_url`, `ha_notify_service`, `ha_bearer_token`.

## Safety

- Default Quadlet apply is write-only (`frigate_manage_service: false`)
- Asserts recovered `config.yaml` exists and is non-empty
- Asserts `/dev/hailo0` exists before deploy (non-rehearsal)
- Never templates over `config.yaml`

## Variables of interest

- `frigate_config_dir` / `frigate_media_dir` / `frigate_image`
- `frigate_rtsp_password` (required secret)
- `frigate_manage_service` / `frigate_rehearsal_mode`
- `frigate_manage_storage_monitor` / `frigate_monitor_threshold`

## Future work

- Rotate the RTSP password (live value was weak) and update camera URLs /
  `FRIGATE_RTSP_PASSWORD` together
- Optionally manage selected Frigate YAML once secrets and cameras are
  inventoried safely
