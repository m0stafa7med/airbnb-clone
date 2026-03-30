# Airbnb Clone

A full-stack Airbnb-like property rental platform built with Spring Boot and Angular. Supports two roles — **Landlords** who list properties and **Tenants** who search and book them.

🌐 **Live:** [airbnb.mostafadarwesh.com](https://airbnb.mostafadarwesh.com)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Java 17, Spring Boot 3.3.5 |
| Frontend | Angular 18, PrimeNG |
| Database | PostgreSQL 16 |
| Auth | Auth0 / Okta OAuth2 |
| Reverse Proxy | Traefik |
| CI/CD | GitHub Actions → GHCR |

---

## Repositories

| Repo | Description |
|------|-------------|
| [`airbnb-backend`](https://github.com/m0stafa7med/airbnb-backend) | Spring Boot REST API |
| [`airbnb-frontend`](https://github.com/m0stafa7med/airbnb-frontend) | Angular SPA |

---

## Features

- OAuth2 login via Auth0
- Property listings with image uploads
- Map-based search with Leaflet
- Booking system with availability calendar
- Role-based access (Landlord / Tenant)
- Auto SSL via Traefik + Let's Encrypt
- CI/CD: push to `master` → builds Docker images → deploys to VPS

---

## Project Structure

```
airbnb-clone/
├── airbnb-backend/          # Spring Boot API (submodule)
├── airbnb-frontend/         # Angular app (submodule)
├── postgres/
│   └── init.sql             # Creates airbnb_backend schema on first boot
├── docker-compose.prod.yml  # Production services
├── .env.example             # Environment variable template
└── .github/
    └── workflows/
        └── deploy.yml       # CI/CD pipeline
```

---

## Running Locally

### Prerequisites
- Java 17, Maven
- Node.js 20, npm
- Docker (for PostgreSQL)

```bash
git clone --recurse-submodules https://github.com/m0stafa7med/airbnb-clone.git
cd airbnb-clone
```

**Start the database:**
```bash
cd airbnb-backend
docker compose -f compose.yaml up -d
```

**Start the backend:**
```bash
./mvnw spring-boot:run
# Runs on http://localhost:8081
```

**Start the frontend (new terminal):**
```bash
cd airbnb-frontend
npm install
npm start
# Runs on http://localhost:4200
```

---

## Production Deployment

### 1. Add GitHub Secrets

Go to **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `VPS_HOST` | Server IP or hostname |
| `VPS_USER` | SSH username |
| `VPS_SSH_KEY` | Private SSH key content |

### 2. Create `.env` on the server

```bash
mkdir -p /opt/airbnb
nano /opt/airbnb/.env
```

```env
POSTGRES_DB=airbnb_backend
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_strong_password

OKTA_OAUTH2_ISSUER=https://airbnb-backend.us.auth0.com/
OKTA_OAUTH2_CLIENT_ID=your_client_id
OKTA_OAUTH2_CLIENT_SECRET=your_client_secret
AUTH0_ROLE_LANDLORD_ID=your_role_id
```

### 3. Push to master

The pipeline automatically:
1. Builds and pushes Docker images to `ghcr.io/m0stafa7med/`
2. SCPs `docker-compose.prod.yml` to the server
3. Pulls new images and restarts services

---

## CI/CD Pipeline

```
push to master
    │
    ├── build-backend   →  ghcr.io/m0stafa7med/airbnb-backend:latest
    ├── build-frontend  →  ghcr.io/m0stafa7med/airbnb-frontend:latest
    │
    └── deploy  →  SCP compose file  →  SSH pull & restart
```
