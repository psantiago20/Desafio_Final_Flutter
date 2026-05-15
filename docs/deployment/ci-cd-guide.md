# CI/CD Guide

## 1. Objective

Document the Continuous Integration and Continuous Deployment pipeline for the Pitaya platform, including build, test, security scan, and deployment stages.

## 2. Pipeline Overview

```
Git Push → Build → Test → Security Scan → Package → Deploy
                              │
                              ▼
                         Image Registry
                              │
                              ▼
                        Production
```

## 3. CI/CD Tools

| Stage | Tool |
|-------|------|
| Version Control | GitHub |
| CI Server | GitHub Actions |
| Build | Maven + Docker |
| Code Quality | SonarQube |
| Security Scan | Trivy, OWASP Dependency Check |
| Container Registry | Docker Hub / GitHub Container Registry |
| Deployment | Docker Compose / Kubernetes |
| Monitoring | Prometheus + Grafana |

## 4. GitHub Actions Workflow

### 4.1 Build & Test

```yaml
name: Pitaya CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: pitaya
          POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
          POSTGRES_DB: test_db
        ports:
          - 5432:5432

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: maven

      - name: Build and test
        run: mvn clean verify -Dspring.profiles.active=ci
        working-directory: backend
```

### 4.2 Docker Build & Push

```yaml
  docker-build:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    strategy:
      matrix:
        service:
          - auth-service
          - user-service
          - post-service
          - group-service
          - library-service
          - mentorship-service
          - gamification-service
          - notification-service

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: backend/services/${{ matrix.service }}
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/${{ matrix.service }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/${{ matrix.service }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 4.3 Deploy to Production

```yaml
  deploy:
    needs: docker-build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /opt/pitaya
            docker-compose pull
            docker-compose up -d --remove-orphans
            docker system prune -f

      - name: Health check
        run: |
          sleep 30
          curl -f http://${{ secrets.PROD_HOST }}:8080/actuator/health
          curl -f http://${{ secrets.PROD_HOST }}:8761/actuator/health
```

## 5. Branch Strategy

```
main ──────────────────────────────────────────► (production)
   \                                        ▲
    develop ────────────────────────────────┤
       \                                    │
        feature/auth-jwt-refresh ───────────┤
        feature/user-profile-edit ──────────┤
       /                                    │
    develop ────────────────────────────────┤
   /
main ──────────────────────────────────────────►

release/v1.0.0 ──► (tag)
hotfix/critical-bug ──► (direct to main)
```

| Branch | Purpose | CI | Deploy |
|--------|---------|----|--------|
| `main` | Production-ready code | Full build + test | Automatic |
| `develop` | Integration branch | Build + test | — |
| `feature/*` | Feature development | Build + lint | — |
| `fix/*` | Bug fixes | Build + test | — |
| `release/*` | Release preparation | Full pipeline | Staging |
| `hotfix/*` | Emergency fixes | Full pipeline | Automatic |

## 6. Commit Convention

```
<type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, test, chore, ci
Scope: auth, user, post, group, gateway, infra
```

Examples:
```
feat(auth): add JWT refresh token rotation
fix(post): correct trending topics calculation
docs(api): update auth endpoint documentation
ci(gateway): add rate limiting configuration
```

## 7. Versioning

Follow [Semantic Versioning](https://semver.org/):

```
v{major}.{minor}.{patch}-{suffix}
v1.0.0
v1.1.0
v1.1.1
v2.0.0-rc.1
```

| Change | Version Bump |
|--------|-------------|
| Breaking API changes | Major |
| New feature (backward compatible) | Minor |
| Bug fix | Patch |

## 8. Quality Gates

| Gate | Threshold |
|------|-----------|
| Test coverage | > 80% |
| Code duplication | < 5% |
| SonarQube quality gate | PASS |
| Security vulnerabilities | 0 CRITICAL/HIGH |
| Build time | < 15 minutes |

## 9. Local Development

```bash
# Build
mvn clean install -DskipTests

# Run tests
mvn test

# Run specific service
mvn spring-boot:run -pl services/auth-service \
  -Dspring-boot.run.profiles=dev

# Build Docker image locally
docker build -t pitaya-auth-service:local ./services/auth-service
```

## 10. Rollback Strategy

```bash
# Rollback to previous version
docker-compose pull auth-service:<previous-version>
docker-compose up -d auth-service

# Or using tags
docker-compose -f docker-compose.rollback.yml up -d
```
