# VoteSecured Docker Container Architecture

## 🐳 Container-Based Security Architecture

VoteSecured implements a containerized microservices architecture where each component runs in an isolated Docker container with cryptographically verifiable images to ensure tamper-evident deployment.

## 🏗️ Container Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        VoteSecured Platform                     │
├─────────────────────────────────────────────────────────────────┤
│                     Load Balancer / API Gateway                │
│                    (NGINX + Authentication)                    │
├─────────────────────┬───────────────────┬───────────────────────┤
│   Frontend Services │   Backend Services│   Infrastructure      │
├─────────────────────┼───────────────────┼───────────────────────┤
│ • Voter Interface   │ • Voting Engine   │ • PostgreSQL          │
│ • Admin Dashboard   │ • Crypto Service  │ • Redis Cache         │
│ • Observer Portal   │ • Receipt Service │ • Monitoring Stack    │
│ • Security FAQ      │ • Audit Logger    │ • Secret Management   │
└─────────────────────┴───────────────────┴───────────────────────┘
```

## 📦 Container Components

### Core Voting Services

#### 1. **voting-engine** - Core Voting Logic
```dockerfile
FROM node:18-alpine
USER 1000:1000
WORKDIR /app
COPY --chown=1000:1000 . .
RUN npm ci --only=production
EXPOSE 3001
CMD ["node", "server.js"]
```

**Security Features:**
- Read-only root filesystem
- Non-root user execution (UID 1000)
- Minimal Alpine Linux base image
- No shell access (distroless option)

#### 2. **cryptography-service** - zkSNARKs & Signatures
```dockerfile
FROM rust:1.70-alpine AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM alpine:3.18
RUN adduser -D -s /sbin/nologin -u 1000 crypto
USER 1000:1000
WORKDIR /app
COPY --from=builder --chown=1000:1000 /app/target/release/crypto-service .
EXPOSE 3002
CMD ["./crypto-service"]
```

**Security Features:**
- Multi-stage build to reduce attack surface
- No package manager in final image
- Dedicated non-root user
- Compiled binary only (no source code)

#### 3. **merkle-ledger** - Public Audit Trail
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o merkle-service

FROM scratch
COPY --from=builder /app/merkle-service /merkle-service
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 3003
USER 1000:1000
ENTRYPOINT ["/merkle-service"]
```

**Security Features:**
- Distroless scratch image
- No shell, package manager, or utilities
- Static binary compilation
- Minimal attack surface

### Frontend Services

#### 4. **voter-interface** - Voter Web Application
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.24-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
RUN adduser -D -s /sbin/nologin -u 1000 nginx-user
USER 1000:1000
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

#### 5. **admin-dashboard** - Election Management
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.24-alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY admin-nginx.conf /etc/nginx/nginx.conf
USER 1000:1000
EXPOSE 8081
```

### Infrastructure Services

#### 6. **database** - PostgreSQL with Encryption
```dockerfile
FROM postgres:15-alpine
ENV POSTGRES_DB=votesecured
ENV POSTGRES_USER=voteuser
ENV POSTGRES_PASSWORD_FILE=/run/secrets/db-password
COPY init-scripts/ /docker-entrypoint-initdb.d/
VOLUME ["/var/lib/postgresql/data"]
EXPOSE 5432
```

**Security Features:**
- Encrypted data at rest
- Password from Docker secrets
- Custom initialization scripts
- Persistent volume encryption

#### 7. **cache** - Redis Session Store
```dockerfile
FROM redis:7-alpine
COPY redis.conf /usr/local/etc/redis/redis.conf
RUN adduser -D -s /sbin/nologin -u 1000 redis-user
USER 1000:1000
EXPOSE 6379
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
```

#### 8. **monitoring** - Prometheus & Grafana
```dockerfile
FROM prom/prometheus:latest
COPY prometheus.yml /etc/prometheus/prometheus.yml
USER 1000:1000
EXPOSE 9090
```

## 🔐 Image Verification & Security

### Digital Signatures

All container images are signed using Docker Content Trust:

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Build and sign image
docker build -t votesecured/voting-engine:v1.0.0 .
docker push votesecured/voting-engine:v1.0.0

# Verify signature before deployment
docker trust inspect votesecured/voting-engine:v1.0.0
```

### SHA-256 Hash Verification

Each image includes verifiable SHA-256 hashes:

```bash
# Get image digest
docker images --digests votesecured/voting-engine

# Verify specific hash
docker pull votesecured/voting-engine@sha256:abcd1234...

# Automated verification script
./scripts/verify-images.sh
```

### Vulnerability Scanning

Continuous security scanning in CI/CD pipeline:

```yaml
# .github/workflows/security-scan.yml
name: Container Security Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: docker build -t test-image .
      - name: Security scan
        uses: anchore/scan-action@v3
        with:
          image: test-image
          fail-build: true
          severity-cutoff: high
```

## 🌐 Container Networking

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    External Network                         │
│                   (Internet Access)                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                 Frontend Network                           │
│         (Voter Interface, Admin Dashboard)                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                 Application Network                        │
│           (API Gateway, Business Logic)                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                 Backend Network                            │
│        (Cryptography, Voting Engine, Audit)               │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                 Database Network                           │
│            (PostgreSQL, Redis, Secrets)                   │
└─────────────────────────────────────────────────────────────┘
```

### Network Policies

```yaml
# network-policies.yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-isolation
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
```

## 🚀 Deployment Configuration

### Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  voting-engine:
    build: ./services/voting-engine
    image: votesecured/voting-engine:latest
    container_name: voting-engine
    networks:
      - backend-network
    environment:
      - NODE_ENV=development
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  cryptography-service:
    build: ./services/cryptography
    image: votesecured/crypto-service:latest
    networks:
      - backend-network
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
    security_opt:
      - apparmor:votesecured-crypto

  database:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: votesecured
      POSTGRES_USER: voteuser
      POSTGRES_PASSWORD_FILE: /run/secrets/db-password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - database-network
    secrets:
      - db-password

networks:
  frontend-network:
    driver: bridge
  backend-network:
    driver: bridge
    internal: true
  database-network:
    driver: bridge
    internal: true

volumes:
  db-data:
    driver: local
    driver_opts:
      type: none
      o: bind,rw
      device: /encrypted/db-data

secrets:
  db-password:
    file: ./secrets/db-password.txt
```

### Kubernetes Deployment (Production)

```yaml
# k8s/voting-engine-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voting-engine
  labels:
    app: voting-engine
    tier: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: voting-engine
  template:
    metadata:
      labels:
        app: voting-engine
        tier: backend
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: voting-engine
        image: votesecured/voting-engine@sha256:abcd1234...
        ports:
        - containerPort: 3001
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-run
        emptyDir: {}
      imagePullSecrets:
      - name: registry-credentials
```

## 🔍 Container Monitoring & Observability

### Health Checks

Each container implements comprehensive health checks:

```javascript
// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION,
    dependencies: {
      database: checkDatabaseConnection(),
      redis: checkRedisConnection(),
      cryptoService: checkCryptoService()
    }
  };
  
  const isHealthy = Object.values(health.dependencies)
    .every(dep => dep.status === 'ok');
  
  res.status(isHealthy ? 200 : 503).json(health);
});
```

### Metrics Collection

```yaml
# Prometheus monitoring
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'voting-engine'
      static_configs:
      - targets: ['voting-engine:3001']
      metrics_path: /metrics
    - job_name: 'crypto-service'
      static_configs:
      - targets: ['crypto-service:3002']
```

### Log Aggregation

```yaml
# Fluentd log collection
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  template:
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
```

## 🛡️ Security Hardening

### Container Security Policies

```yaml
# Pod Security Policy
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: votesecured-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### Image Scanning Pipeline

```bash
#!/bin/bash
# scripts/verify-images.sh

set -e

IMAGES=(
  "votesecured/voting-engine:v1.0.0"
  "votesecured/crypto-service:v1.0.0"
  "votesecured/merkle-ledger:v1.0.0"
  "votesecured/voter-interface:v1.0.0"
  "votesecured/admin-dashboard:v1.0.0"
)

for image in "${IMAGES[@]}"; do
  echo "Verifying image: $image"
  
  # Verify signature
  docker trust inspect "$image" || {
    echo "ERROR: Image signature verification failed for $image"
    exit 1
  }
  
  # Security scan
  trivy image --exit-code 1 --severity HIGH,CRITICAL "$image" || {
    echo "ERROR: Security vulnerabilities found in $image"
    exit 1
  }
  
  echo "✅ Image $image verified successfully"
done

echo "🎉 All images verified and secure"
```

## 📋 Deployment Checklist

### Pre-Deployment Verification

- [ ] All container images signed with Docker Content Trust
- [ ] SHA-256 hashes verified for all images
- [ ] Vulnerability scans pass with no HIGH/CRITICAL issues
- [ ] Network policies configured and tested
- [ ] Resource limits defined for all containers
- [ ] Health checks implemented and tested
- [ ] Security contexts configured (non-root, read-only filesystem)
- [ ] Secrets management configured
- [ ] Monitoring and logging configured
- [ ] Backup procedures tested

### Production Deployment Steps

1. **Image Registry Setup**
   ```bash
   # Deploy private registry with Harbor
   helm install harbor harbor/harbor
   ```

2. **Secrets Configuration**
   ```bash
   # Create Kubernetes secrets
   kubectl create secret generic db-credentials \
     --from-literal=username=voteuser \
     --from-literal=password=$(openssl rand -base64 32)
   ```

3. **Network Policy Deployment**
   ```bash
   kubectl apply -f k8s/network-policies/
   ```

4. **Application Deployment**
   ```bash
   kubectl apply -f k8s/deployments/
   kubectl apply -f k8s/services/
   kubectl apply -f k8s/ingress/
   ```

5. **Monitoring Setup**
   ```bash
   helm install prometheus prometheus-community/kube-prometheus-stack
   kubectl apply -f monitoring/grafana-dashboards/
   ```

This containerized architecture ensures that every component of the VoteSecured platform is isolated, verifiable, and secure, providing the foundation for a tamper-evident electronic voting system.