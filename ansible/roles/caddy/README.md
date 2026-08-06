# caddy role

Deploys a Podman Quadlet unit and Caddyfile for reverse-proxying Home Assistant.

## Networking (current)

Caddy uses `Network=host` and the Caddyfile proxies to `localhost:8123` (Home Assistant's
host-published port). `PublishPort` is omitted because host networking already binds
ports on the host.

## Future: bridge + user-defined network (option B)

Revisit moving Caddy off `Network=host` onto a user-defined Podman network shared with
Home Assistant (and possibly other services). In that model:

- Drop `Network=host`
- Add `PublishPort=80:80` and `PublishPort=443:443` so Caddy is reachable on the host
- Point the Caddyfile upstream at the HA container name/DNS on that network
  (e.g. `homeassistant:8123`) instead of `localhost`

Do not mix the two: bridge mode must not use `localhost` as the upstream.

## Variables of interest

- `caddy_config_dir`
- `caddy_image`
- `caddy_data_volume`
- `caddy_domain` / `caddy_upstream_host` / `caddy_upstream_port`
- `caddy_manage_service` (default `false`: write files only)
- `caddy_rehearsal_mode`

## Templates

- `caddy.Caddyfile.j2`
- `caddy.container.j2`
