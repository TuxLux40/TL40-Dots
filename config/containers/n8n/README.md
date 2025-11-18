n8n on Synology (MariaDB10)

This folder contains a Docker Compose setup for running n8n on a Synology NAS and connecting it to the Synology MariaDB10 service. It prefers the NAS NetBIOS name `os93-nas` and includes a fallback IP mapping `192.168.178.2`.

Files

- docker-compose.yml: n8n service wired for MariaDB10 on Synology
- .env.example: template for environment variables — copy to `.env` and edit

Quick start (fish shell)

1. Copy the env file and edit values

```
cp .env.example .env
```

2. Generate a strong encryption key and paste it into `.env`

```
openssl rand -base64 32 | tr -d '\n'
```

3. Create the data directory on Synology (adjust path if needed)

```
mkdir -p /volume1/docker/n8n
```

4. Optional: verify DB connectivity (NetBIOS and fallback IP)

```
nc -zv os93-nas 3306
nc -zv 192.168.178.2 3306
```

5. Start n8n

```
docker compose up -d
```

Reverse proxy (Synology)

- If you plan to publish via a subdomain under `olips.cloud` (e.g., `n8n.olips.cloud`), set `N8N_HOST`, `N8N_PROTOCOL=https`, and `WEBHOOK_URL` in `.env` accordingly.
- Configure Synology Control Panel → Login Portal → Reverse Proxy: point your subdomain to this container on port `5678`.
- You can keep the port mapping in compose for local access, or remove the `ports:` section once the reverse proxy is working.

Database notes

- Ensure a database and user exist in MariaDB10 and grant privileges, e.g. in `mysql`:

```
CREATE DATABASE n8n CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'n8n'@'%' IDENTIFIED BY 'STRONG_PASSWORD_HERE';
GRANT ALL PRIVILEGES ON n8n.* TO 'n8n'@'%';
FLUSH PRIVILEGES;
```

Permissions

- If you hit file permission issues on Synology, set the `user:` in `docker-compose.yml` to your Synology account’s UID:GID (common example: `1026:100`) and ensure the data dir ownership matches.

Updates

- To update n8n:

```
docker compose pull
docker compose up -d
```
