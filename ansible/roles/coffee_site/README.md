# coffee_site role

Deploys the mre.coffee static site as a Podman Quadlet unit. The image is built
in [etsauer/coffee-site](https://github.com/etsauer/coffee-site) and pushed to
Quay.

This role is **not** enabled in `site.yml` until a known-good cutover on the Pi.

## Networking

The container publishes **only** on localhost (`127.0.0.1:8080` → container 80)
so it is not reachable from the LAN or internet until Caddy proxies it. Do not
publish Frigate or MQTT on this hostname.

Caddy still only terminates `hass.mre.coffee`. A later change adds an
`mre.coffee` site block pointing at this port.

## Variables of interest

- `coffee_site_image` (default `quay.io/etsauer/coffee-site:latest`)
- `coffee_site_container_name`
- `coffee_site_publish_ip` / `coffee_site_publish_port` / `coffee_site_container_port`
- `coffee_site_manage_service` (default `false`: write files only)
- `coffee_site_rehearsal_mode`

## Templates

- `coffee-site.container.j2`

## Safety

Default is write-only. Rehearse with `ansible/test-coffee-site.yml`, preview on
the Pi with `ansible/fix-coffee-site.yml --check --diff`, then cut over with
`-e coffee_site_manage_service=true`. Enable the role in `site.yml` only after
that is known-good.

If the Quay repository is private, the Pi needs a pull credential (not handled
by this role yet). Public is simpler.
