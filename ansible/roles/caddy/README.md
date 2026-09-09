# caddy role

Deploys a Podman Quadlet unit and Caddyfile. Caddy terminates TLS for public
hostnames and reverse-proxies to localhost Quadlets.

## Networking (current)

Caddy uses `Network=host` and the Caddyfile proxies to `localhost` ports
(`PublishPort` is omitted because host networking already binds 80/443).

Current sites:

- `hass.mre.coffee` → `localhost:8123` (Home Assistant)
- `mre.coffee` → `localhost:8080` (coffee-site Quadlet)

Do not publish Frigate or MQTT on a public hostname. Do not add `www.mre.coffee`
until an A record points at the Pi — otherwise Let’s Encrypt challenges fail
and retry (the HA site should keep serving). `hass.mre.coffee` must stay in
`caddy_sites`.

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
- `caddy_sites` (list of `{names, upstream}` or `{names, redir}`)
- `caddy_manage_service` (default `false`: write files only; `site.yml` sets `true`)
- `caddy_rehearsal_mode`

The role asserts `hass.mre.coffee` stays in `caddy_sites`. `mre.coffee` must
match `coffee_site` publish port `8080`.

## Deploy

Tag: `caddy`. Rehearse with `ansible/test-caddy.yml`. Preview on the Pi with
`ansible/site.yml --tags caddy --check --diff`. The Caddyfile is bind-mounted,
so writing it can make running Caddy reload without a systemd restart.
Write-only: `-e caddy_manage_service=false`. After apply, confirm
`hass.mre.coffee` still loads and `https://mre.coffee/` returns 200.

## Templates

- `caddy.Caddyfile.j2`
- `caddy.container.j2`
