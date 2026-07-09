# Bluetile · User Check Status API

> **Real-time user integrity scoring** — country whitelist, device trust, and VPN/Tor detection in a single, hardened Rails 8 endpoint.

[![Ruby](https://img.shields.io/badge/Ruby-3.4.9-red?logo=ruby)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.3-red?logo=rubyonrails)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-blue?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-8-red?logo=redis)](https://redis.io/)
[![RSpec](https://img.shields.io/badge/RSpec-39_specs-brightgreen?logo=rspec)](spec/)
[![Coverage](https://img.shields.io/badge/Coverage-~96%25-brightgreen)](spec/)

Rails **8.1 API-only** service that evaluates whether a mobile user should be **banned** or **not banned** through a deterministic security check chain — with auth, rate limiting, caching, fail-open external calls, and full audit logging.

---

## Why this exists

Mobile apps need a fast, reliable gatekeeper before granting access. This API:

- Validates **device identity** (IDFA) and **trust signals** in one call
- Runs checks in **strict order** with early exit (no wasted VPNAPI calls)
- **Persists** user state and **logs every integrity event** for forensics
- **Fails open** on VPNAPI outages (availability over false positives)
- **Fails closed** on infrastructure failure (Redis down → `500`)

Built for production-minded defaults: API key auth, per-IP throttling, health probes, and CI with security scans.

---

## Quick start

```bash
git clone git@github.com:rafael-pissardo/Bluetile.git
cd Bluetile

cp .env.example .env          # set API_KEY and VPNAPI_KEY
bin/setup --skip-server       # docker + bundle + db + seed

bundle exec rails server
```

**Manual setup**

```bash
docker compose up -d
bundle install
bundle exec rails db:create db:migrate db:seed
```

---

## The endpoint

### `POST /v1/user/check_status`

| | |
|---|---|
| **Auth** | `X-API-Key: <API_KEY>` |
| **Headers** | `Content-Type: application/json`, `CF-IPCountry` (Cloudflare) |
| **Body** | `{ "idfa": "<uuid>", "rooted_device": <boolean> }` |
| **Success** | `200` → `{ "ban_status": "not_banned" \| "banned" }` |

**Example — clean user**

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -H "CF-IPCountry: US" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":false}'
```

```json
{ "ban_status": "not_banned" }
```

**Example — banned (rooted device)**

```bash
curl -X POST http://localhost:3000/v1/user/check_status \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -H "CF-IPCountry: US" \
  -d '{"idfa":"8264148c-be95-4b2b-b260-6ee98dd53bf6","rooted_device":true}'
```

```json
{ "ban_status": "banned" }
```

### Health (no auth)

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Liveness |
| `GET /health/deep` | Postgres + Redis connectivity |

---

## Security check chain

Checks run **in order**. First failure stops the chain — no unnecessary external calls.

```mermaid
flowchart TD
    A[POST /v1/user/check_status] --> B{Already banned?}
    B -->|yes| Z[Return banned — no new log]
    B -->|no| C[Country whitelist]
    C -->|fail| BAN[banned]
    C -->|pass| D[Rooted device?]
    D -->|true| BAN
    D -->|false| E[VPNAPI Tor/VPN check]
    E -->|vpn or tor| BAN
    E -->|clean| OK[not_banned]
    E -->|API error| FO[fail-open → pass]
    BAN --> P[Persist user + integrity log]
    OK --> P
    FO --> P
```

| # | Check | Source | On fail |
|---|-------|--------|---------|
| 1 | Country whitelist | `CF-IPCountry` vs Redis set | `banned` |
| 2 | Rooted device | Request body | `banned` |
| 3 | Tor / VPN | [VPNAPI.io](https://vpnapi.io) (24h Redis cache) | `banned` |
| — | VPNAPI down (5xx, 429, timeout) | — | **fail-open** → `not_banned` |
| — | Redis unavailable | — | **500** |

**Short-circuits**

- Already-banned user → immediate `banned`, chain skipped, no duplicate log
- Country or rooted fails → VPNAPI never called
- Status unchanged on re-check → no new integrity log

---

## Architecture

```
app/
├── controllers/
│   ├── concerns/api_authenticatable.rb   # X-API-Key gate
│   ├── health_controller.rb              # /health, /health/deep
│   └── v1/user/check_status_controller.rb  # thin — delegates to Handler
└── services/
    ├── check_status/handler.rb           # parse → validate → orchestrate
    ├── check_status_orchestrator.rb      # chain + DB transaction
    ├── check_status_params.rb            # strong params + UUID validation
    ├── checks/                           # CountryWhitelist, RootedDevice, VpnApi
    ├── integrity_logger.rb               # swappable adapter pattern
    ├── integrity_logging/postgres_adapter.rb
    ├── redis_gateway.rb                  # Redis with infra error mapping
    └── vpn_api_client.rb                 # Faraday client + cache layer
```

**Design choices**

- **Handler pattern** — controller stays ~10 lines; all request logic is testable in isolation
- **Adapter-based logging** — swap PostgreSQL for Kafka/S3 without touching orchestrator
- **DB transaction** — user update + integrity log are atomic
- **Cloudflare trusted proxies** — correct client IP behind CDN
- **Rack::Attack** — configurable rate limit (default 60 req/min/IP)

---

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Ruby 3.4.9 |
| Framework | Rails 8.1.3 (API-only) |
| Database | PostgreSQL 18 |
| Cache / whitelist | Redis 8 |
| HTTP client | Faraday |
| Security | rack-attack, Brakeman, bundler-audit |
| Tests | RSpec 8, FactoryBot, WebMock, SimpleCov |

---

## Environment

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_HOST` | `localhost` | PostgreSQL host |
| `DATABASE_PORT` | `5433` | PostgreSQL port (host mapping) |
| `DATABASE_USERNAME` | `bluetile` | DB user |
| `DATABASE_PASSWORD` | `bluetile` | DB password |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection |
| `API_KEY` | — | **Required** — `X-API-Key` header value |
| `RATE_LIMIT_PER_MINUTE` | `60` | Per-IP throttle for check_status |
| `VPNAPI_KEY` | — | VPNAPI.io API key |
| `VPNAPI_CACHE_TTL` | `86400` | VPN response cache (seconds) |
| `VPNAPI_TIMEOUT_MS` | `5000` | VPNAPI request timeout |

---

## Testing

```bash
bundle exec rspec                  # 39 examples — documentation format
COVERAGE=true bundle exec rspec    # SimpleCov report (~96% line coverage)
```

**What's covered**

- Happy path + every ban trigger (country, missing header, rooted, VPN, Tor)
- Auth (`401`) and rate limiting (`429`)
- Validation errors (`400`, `422`)
- VPNAPI fail-open (500, 429, timeout)
- Redis down → `500`
- Chain short-circuit (no VPNAPI when country/rooted fails)
- Integrity log fields and idempotency rules
- Health endpoints

---

## CI

GitHub Actions on every push/PR:

- **Brakeman** + **bundler-audit** security scans
- **RuboCop** lint
- **RSpec** full suite with Postgres + Redis services

---

## HTTP status reference

| Code | When |
|------|------|
| `200` | Check completed |
| `400` | Missing field / malformed JSON |
| `401` | Missing or invalid API key |
| `422` | Invalid UUID format |
| `429` | Rate limit exceeded |
| `500` | Redis or other infrastructure failure |

---

## License

Built as the **Bluetile RoR technical assessment** — Ruby on Rails, PostgreSQL, Redis, and production-grade API design.
