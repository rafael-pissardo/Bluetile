# Monitoring & Rollback

## Monitoring

### Health endpoints

| Endpoint | Auth | Purpose |
| -------- | ---- | ------- |
| `GET /health` | No | Liveness probe |
| `GET /health/deep` | No | Postgres + Redis connectivity |
| `GET /up` | No | Rails default health check |

### Logs to watch

| Event | Log pattern | Action |
| ----- | ----------- | ------ |
| VPNAPI fail-open | `[VpnApiCheck] fail-open` | Investigate VPNAPI quota/downtime |
| Redis down | `[RedisUnavailable]` | Page on-call, check Redis cluster |
| Rate limit hit | Rack::Attack 429 responses | Review abuse or tune `RATE_LIMIT_PER_MINUTE` |
| Auth failures | 401 responses | Review invalid API keys |

### Suggested metrics (production)

- Request rate and latency (`POST /v1/user/check_status`)
- Ban rate by reason (country / rooted / vpn)
- VPNAPI cache hit ratio
- Redis and Postgres error rates
- 429 / 401 / 500 counts

## Rollback plan

### Triggers

| Signal | Threshold | Action |
| ------ | --------- | ------ |
| Error rate | > 5% for 5 min | Rollback deploy |
| Latency p95 | > 2s for 10 min | Investigate; rollback if external API related |
| Redis unavailable | Sustained 500s | Rollback; restore Redis first |

### Steps

1. Revert to previous application release (container image or git tag).
2. Verify `/health/deep` returns `healthy`.
3. Run smoke test: `POST /v1/user/check_status` with known-good IDFA.
4. Monitor error rate for 15 minutes.

### Database rollback

- User and integrity_log migrations are additive; down migrations only if schema rollback required.
- Take DB snapshot before production migrations.

### Feature toggles (future)

- Disable VPNAPI check via env flag (fail-open already default on API errors).
- Temporarily widen rate limit via `RATE_LIMIT_PER_MINUTE`.
