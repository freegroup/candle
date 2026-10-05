# Candle server deployment

Ansible playbooks for the Candle API (`server/`, Node + TypeScript) on a Hetzner Cloud
server (Ubuntu 26.04): nginx in front, the API as pm2 process `candle-api`,
certificate from Let's Encrypt.

The server keeps **no data**: all state is in the tokens the apps hold. A server can be
rebuilt at any time from these playbooks plus `secrets.env`; with a new `JWT_SECRET`
the apps simply register again.

## Create the server (once, in the Hetzner console)

1. SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/hetzner_candle` and add
   `~/.ssh/hetzner_candle.pub` in the console.
2. Create the server: CPX12, Falkenstein, Ubuntu 26.04, IPv4 + IPv6, with that SSH key.
3. Put the IP into `inventory.ini`; `candle_domain` is `<ip-with-dashes>.sslip.io` (no own domain needed).
4. Update `apiUrl` in `docs/api.json` - the app reads the server address from there.
5. `cp secrets.env.example secrets.env` and fill in `JWT_SECRET`.
   For Android also save the Google service account key as `google-service-account.json`.

## Playbooks

Run from the repository root:

```sh
ansible-galaxy collection install community.general   # once

ansible-playbook -i ./ansible/inventory.ini ./ansible/01_playbook_setup.yaml
ansible-playbook -i ./ansible/inventory.ini ./ansible/02_playbook_deploy.yaml
ansible-playbook -i ./ansible/inventory.ini ./ansible/03_playbook_letsencrypt.yaml
ansible-playbook -i ./ansible/inventory.ini ./ansible/04_playbook_places.yaml -e places_file=gis-test/dach.sqlite  # places data, see server/tools/README.md
```

- `01` - node (nodesource), pm2, user, firewall (22/80/443 only), SSH key-only, automatic security updates, nginx
- `02` - checkout from GitHub, `npm ci`, secrets, (re)start via pm2 (also after reboots); run it for every deployment
- `03` - certificate and HTTPS; renewal runs automatically on the server

## On the server

```sh
ssh -i ~/.ssh/hetzner_candle root@<IP>
su - candle -c "pm2 logs candle-api"
su - candle -c "pm2 status"
curl https://<domain>/health
```
