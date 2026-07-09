# Bluetile User Check Status API

Rails 8.1 API-only application that evaluates user ban status via security checks.

## Requirements

- Ruby 3.4.9
- Docker (PostgreSQL 18 + Redis 8)

## Setup

```bash
cp .env.example .env   # set API_KEY and VPNAPI_KEY
bin/setup --skip-server
```

Or manually:

```bash
docker compose up -d
bundle install
bundle exec rails db:create db:migrate db:seed
```

## Environment

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_PORT` | `5433` | PostgreSQL port |
| `DATABASE_USERNAME` | `bluetile` | PostgreSQL user |
| `DATABASE_PASSWORD` | `bluetile` | PostgreSQL password |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection |
| `API_KEY` | — | Required `X-API-Key` header value |
| `RATE_LIMIT_PER_MINUTE` | `60` | Per-IP limit for check_status |
| `VPNAPI_KEY` | — | VPNAPI.io API key |

**Redis unavailable:** returns `500 Internal Server Error`.

## Run

```bash
bundle exec rails server
```

## Test

```bash
bundle exec rspec
```

With coverage:

```bash
COVERAGE=true bundle exec rspec
```

## API

### Authentication

All `/v1/*` endpoints require header:

```
X-API-Key: <API_KEY>
```

### `POST /v1/user/check_status`

**Headers:** `Content-Type: application/json`, `CF-IPCountry`, `X-API-Key`

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

### Health

- `GET /health` — liveness
- `GET /health/deep` — postgres + redis checks

## Security checks (in order)

1. Country whitelist (`CF-IPCountry` vs Redis set)
2. Rooted device (`rooted_device: true` → ban)
3. Tor/VPN via [VPNAPI](https://vpnapi.io) (24h Redis cache; fail-open on API errors)

## Architecture

- `CheckStatus::Handler` — request parsing, validation, orchestration entry
- `CheckStatusOrchestrator` — check chain, persistence, logging
- `IntegrityLogger` — swappable adapter (PostgreSQL default)
- `Checks::*` — individual security check services
- `RedisGateway` — Redis access with connection error handling

## Operations

See [docs/OPERATIONS.md](docs/OPERATIONS.md) for monitoring and rollback.
