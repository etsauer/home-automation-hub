# frigate role

Deploys the Frigate Podman Quadlet unit. **Does not manage** `config.yaml` or
other files under the config directory — those live on the host.

## Current shape (matches pre-incident Pi unit)

- Image `ghcr.io/blakeblackshear/frigate:stable`
- `FRIGATE_RTSP_PASSWORD` from `secrets.yml`
- Hailo + USB device passthrough, `--privileged`, `ShmSize=256mb`
- Ports: `8971`, `5000`, `8554`, `8555/tcp`, `8555/udp`
- Volumes:
  - `/opt/frigate/config` → `/config:Z`
  - `/mnt/lacie/frigate_media` → `/media/frigate:Z`

## Safety

- Default is write-only (`frigate_manage_service: false`)
- Asserts recovered `config.yaml` exists and is non-empty
- Asserts `/dev/hailo0` exists before deploy (non-rehearsal)
- Never templates over `config.yaml` (skeleton config template removed)

## Variables of interest

- `frigate_config_dir` / `frigate_media_dir` / `frigate_image`
- `frigate_rtsp_password` (required secret)
- `frigate_manage_service` / `frigate_rehearsal_mode`

## Future work

- Rotate the RTSP password (live value was weak) and update camera URLs /
  `FRIGATE_RTSP_PASSWORD` together
- Optionally manage selected Frigate YAML once secrets and cameras are
  inventoried safely
