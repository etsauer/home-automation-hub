# Home automation hub

Config-as-code for a home automation and security hub running on a Raspberry Pi.
Services are packaged as Podman containers and managed with systemd Quadlets via Ansible.

The deployment entrypoint is [`ansible/site.yml`](ansible/site.yml).

## Architecture

| Service | Role |
| --- | --- |
| **Caddy** | TLS reverse proxy for `hass.mre.coffee` and `mre.coffee` |
| **GoDaddy DDNS** | Keeps public A records for `hass.mre.coffee` and apex `mre.coffee` pointed at the home IP |
| **Home Assistant** | Home automation core and UI |
| **Frigate** | NVR / camera detection for the security side of the hub |
| **Mosquitto** | MQTT broker shared by Home Assistant and Frigate |
| **mre.coffee** | Static site Quadlet (`coffee_site`); Caddy proxies `mre.coffee` → localhost:8080 |
| **Podman** | Container runtime underneath the Quadlet units |

```mermaid
flowchart LR
  Internet((Internet))
  DDNS[GoDaddy DDNS]
  DNS["DNS hass + apex mre.coffee"]
  Caddy[Caddy]
  HA[Home Assistant]
  Site[coffee-site]
  Frigate[Frigate]
  MQTT[Mosquitto]
  Cams[Cameras]

  DDNS -->|updates A record| DNS
  Internet -->|HTTPS| DNS
  DNS --> Caddy
  Caddy -->|localhost:8123| HA
  Caddy -->|localhost:8080| Site
  Cams -->|RTSP| Frigate
  Frigate <-->|MQTT| MQTT
  HA <-->|MQTT| MQTT
```

## Deploy

1. Copy [`ansible/group_vars/all/secrets.yml.example`](ansible/group_vars/all/secrets.yml.example) to `ansible/group_vars/all/secrets.yml` and fill in real values (keep that file encrypted and out of git).
2. Confirm the Pi is reachable from [`ansible/hosts`](ansible/hosts).
3. Run:

```bash
ansible-playbook -i ansible/hosts ansible/site.yml
```

One service (tag matches the role name):

```bash
ansible-playbook -i ansible/hosts ansible/site.yml --tags caddy --check --diff
ansible-playbook -i ansible/hosts ansible/site.yml --tags caddy
```

Only roles that have been validated against the live host are enabled in `site.yml`. Details for rehearsal, tags, and secrets live in [`ansible/README.md`](ansible/README.md).
