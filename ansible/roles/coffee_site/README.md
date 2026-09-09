# coffee_site role

Deploys the mre.coffee static site as a Podman Quadlet unit. The image is built
in [etsauer/coffee-site](https://github.com/etsauer/coffee-site) and pushed to
Quay.

Enabled in `site.yml` with tag `coffee_site`. Preview with `--tags coffee_site --check --diff`.

## Networking

The container publishes **only** on localhost (`127.0.0.1:8080` → container 80)
so it is not reachable from the LAN or internet until Caddy proxies it. Do not
publish Frigate or MQTT on this hostname.

Caddy proxies `mre.coffee` → this port (`localhost:8080`).

## Variables of interest

- `coffee_site_image` (default `quay.io/etsauer/coffee-site:latest`)
- `coffee_site_container_name`
- `coffee_site_publish_ip` / `coffee_site_publish_port` / `coffee_site_container_port`
- `coffee_site_manage_service` (default `false`: write files only)
- `coffee_site_rehearsal_mode`

## Templates

- `coffee-site.container.j2`

## Safety

Role default is write-only; `site.yml` sets `coffee_site_manage_service: true`.
Rehearse with `ansible/test-coffee-site.yml`, then apply on the Pi with
`ansible/site.yml --tags coffee_site`. Write files without restarting:
`-e coffee_site_manage_service=false`.

If the Quay repository is private, the Pi needs a pull credential (not handled
by this role yet). Public is simpler.
