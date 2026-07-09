# Bluetile User Check Status API

Rails 8.1 API-only application that evaluates user ban status via security checks.

## Requirements

- Ruby 3.4.9
- Docker (PostgreSQL 18 + Redis 8)

## Setup

```bash
docker compose up -d
bundle install
bundle exec rails db:create db:migrate
```

## Environment

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_PORT` | `5433` | PostgreSQL port |
| `DATABASE_USERNAME` | `bluetile` | PostgreSQL user |
| `DATABASE_PASSWORD` | `bluetile` | PostgreSQL password |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection |
| `VPNAPI_KEY` | — | VPNAPI.io API key (required in development/production) |

## Seed country whitelist (Redis)

```bash
bundle exec rails runner "REDIS.sadd('country_whitelist', %w[US CA GB])"
```

## Run

```bash
bundle exec rails server
```

## Test

```bash
bundle exec rspec
```

## API

### `POST /v1/user/check_status`

**Headers:** `Content-Type: application/json`, `CF-IPCountry` (from Cloudflare)

**Request:**

```json
{
  "idfa": "8264148c-be95-4b2b-b260-6ee98dd53bf6",
  "rooted_device": false
}
```

**Response:**

```json
{
  "ban_status": "not_banned"
}
```

## Security checks (in order)

1. Country whitelist (`CF-IPCountry` vs Redis set)
2. Rooted device (`rooted_device: true` → ban)
3. Tor/VPN via [VPNAPI](https://vpnapi.io) (24h Redis cache; fail-open on API errors)

## Architecture

- `CheckStatusOrchestrator` — runs check chain, persists user, triggers logging
- `IntegrityLogger` — swappable adapter (PostgreSQL default)
- `Checks::*` — individual security check services
