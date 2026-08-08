# mosquitto role

Deploys Eclipse Mosquitto as a Podman Quadlet unit with config under
`/opt/mosquitto/`.

## Current shape (matches pre-incident Pi unit + live clients)

- Image `docker.io/library/eclipse-mosquitto:2`
- `PublishPort=1883:1883`
- Volumes for `config`, `data`, and `log` under `/opt/mosquitto/`
- `allow_anonymous true` — Home Assistant and Frigate currently connect with no
  MQTT username/password
- Data/log dirs owned by uid/gid `1883` (image user)

## Variables of interest

- `mosq_config_dir` / `mosq_data_dir` / `mosq_log_dir`
- `mosq_image` / `mosq_container_name`
- `mosq_publish_port` / `mosq_listener_port`
- `mosq_allow_anonymous` (default `true`)
- `mosq_persistence`
- `mosq_manage_service` (default `false`: write files only)
- `mosq_rehearsal_mode`

## Templates

- `mosquitto.conf.j2`
- `mosquitto.container.j2`

## Safety

Default is write-only. Cut over after reviewing rendered files, then restart
manually or re-run with `-e mosq_manage_service=true`.

## Future work: MQTT authentication

Anonymous MQTT on a published LAN port is convenient for this hub but weak.
When ready, flip `mosq_allow_anonymous` to `false`, manage a `passwords.txt`
from secrets (`mqtt_user` / `mqtt_password`), and update HA + Frigate clients.
