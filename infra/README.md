# SentinelForge Infrastructure

This directory contains the Docker Compose configuration and supporting files for running SentinelForge.

## Quick Start

### 1. Prerequisites

- Docker 24+
- Docker Compose 2.0+
- At least 8GB RAM and 4 CPU cores
- 50GB free disk space

### 2. Initial Setup

```bash
# Copy environment template
cp .env.example .env

# Generate secrets
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 64 | tr -d '\n')" >> .env
echo "AUTHENTIK_BOOTSTRAP_TOKEN=$(openssl rand -base64 32 | tr -d '\n')" >> .env

# Edit .env and set all passwords
vim .env

# Create required directories
mkdir -p traefik/letsencrypt
mkdir -p postgres
mkdir -p redis/data
mkdir -p authentik/templates
mkdir -p grafana/{provisioning,dashboards}
mkdir -p prometheus
mkdir -p loki
mkdir -p tempo
```

### 3. Configure Prometheus

Create `prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'sentinelforge-api'
    static_configs:
      - targets: ['api:8000']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']

  - job_name: 'minio'
    static_configs:
      - targets: ['minio:9000']
```

### 4. Configure Loki

Create `loki/loki.yml`:

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093
```

### 5. Configure Tempo

Create `tempo/tempo.yml`:

```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318

ingester:
  max_block_duration: 5m

compactor:
  compaction:
    block_retention: 48h

storage:
  trace:
    backend: local
    local:
      path: /tmp/tempo/traces
    wal:
      path: /tmp/tempo/wal
```

### 6. Configure Grafana Data Sources

Create `grafana/provisioning/datasources/datasources.yml`:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false

  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo:3200
    editable: false
```

### 7. Start Infrastructure

```bash
# Start all services
docker-compose up -d

# Watch logs
docker-compose logs -f

# Check service health
docker-compose ps
```

### 8. Initial Configuration

#### Authentik

1. Access: `https://auth.sentinelforge.local` (or your domain)
2. Login with `AUTHENTIK_BOOTSTRAP_PASSWORD` from `.env`
3. Create application for SentinelForge API
4. Create OAuth2 provider for Grafana
5. Note client IDs and secrets, update `.env`

#### MinIO

1. Access: `https://minio.sentinelforge.local`
2. Login with `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
3. Create bucket: `sentinelforge-audit`
4. Create access key for API service

#### Grafana

1. Access: `https://grafana.sentinelforge.local`
2. Login with `GRAFANA_ADMIN_USER` and `GRAFANA_ADMIN_PASSWORD`
3. Verify data sources are connected
4. Import dashboards from `grafana/dashboards/`

## Service Endpoints

| Service | Internal Port | External URL |
|---------|--------------|-------------|
| Traefik Dashboard | 8080 | http://localhost:8080 |
| Authentik | 9000 | https://auth.{DOMAIN} |
| SentinelForge API | 8000 | https://api.{DOMAIN} |
| Grafana | 3000 | https://grafana.{DOMAIN} |
| Prometheus | 9090 | https://prometheus.{DOMAIN} |
| MinIO Console | 9001 | https://minio.{DOMAIN} |
| Postgres | 5432 | localhost:5432 |
| Loki | 3100 | (internal) |
| Tempo | 3200 | (internal) |
| Redis | 6379 | (internal) |

## Security Checklist

- [ ] All passwords in `.env` are strong (32+ chars, random)
- [ ] `.env` is in `.gitignore` and never committed
- [ ] TLS certificates configured (Let's Encrypt or self-signed)
- [ ] Firewall rules restrict access to ports 80, 443 only
- [ ] Authentik MFA enabled for all users
- [ ] Grafana OAuth configured (not using default admin password)
- [ ] Postgres and Redis not exposed to public internet
- [ ] Regular backups configured for Postgres and MinIO

## Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs <service-name>

# Common issues:
# - Port conflicts (check with: netstat -tulpn)
# - Missing .env values
# - Insufficient disk space (check with: df -h)
```

### Can't access services

```bash
# Check if containers are running
docker-compose ps

# Check Traefik logs
docker-compose logs traefik

# Verify DNS/hosts file
ping auth.sentinelforge.local
```

### Authentik login fails

```bash
# Check Authentik logs
docker-compose logs authentik-server

# Verify environment variables
docker-compose exec authentik-server env | grep AUTHENTIK

# Reset admin password
docker-compose exec authentik-server ak bootstrap update
```

### Database connection errors

```bash
# Check Postgres health
docker-compose exec postgres pg_isready -U sentinelforge

# Test connection
docker-compose exec postgres psql -U sentinelforge -c '\l'

# Check DATABASE_URL in API service
docker-compose exec api env | grep DATABASE
```

## Backup & Restore

### Backup

```bash
# Postgres
docker-compose exec postgres pg_dump -U sentinelforge sentinelforge > backup.sql

# MinIO (use mc client)
mc mirror minio/sentinelforge-audit /backup/minio/

# Configuration
tar -czf sentinelforge-config-$(date +%Y%m%d).tar.gz .env infra/
```

### Restore

```bash
# Postgres
cat backup.sql | docker-compose exec -T postgres psql -U sentinelforge sentinelforge

# MinIO
mc mirror /backup/minio/ minio/sentinelforge-audit
```

## Updating

```bash
# Pull latest images
docker-compose pull

# Rebuild custom images
docker-compose build --no-cache

# Recreate containers
docker-compose up -d --force-recreate

# Clean up old images
docker image prune -a
```

## Production Considerations

### High Availability

- Use external managed Postgres (AWS RDS, Cloud SQL)
- Use object storage (S3, GCS) instead of MinIO
- Run multiple API replicas behind load balancer
- Use Redis Sentinel or Cluster

### Monitoring

- Set up Grafana alerts
- Configure Prometheus alertmanager
- Send logs to external SIEM
- Monitor disk usage and set up automatic cleanup

### Security Hardening

- Run containers as non-root users
- Use Docker secrets instead of env vars
- Enable network policies (requires Kubernetes)
- Regular security scans (Trivy, Grype)
- Implement rate limiting at Traefik level

## Phase Progression

### Phase 1 (Current)
- [x] Traefik ingress
- [x] Authentik authentication
- [x] Postgres database
- [x] MinIO object storage
- [x] Observability stack (Prometheus, Loki, Tempo, Grafana)
- [ ] SentinelForge API service

### Phase 2
- [ ] Agent orchestrator service
- [ ] Tool gateway service
- [ ] Model router service

### Phase 3
- [ ] OPA policy engine
- [ ] Auditor service

### Phase 4
- [ ] Multi-agent support
- [ ] Human-in-the-loop UI

### Phase 5
- [ ] Migrate to Kubernetes
- [ ] Add Vault for secrets
