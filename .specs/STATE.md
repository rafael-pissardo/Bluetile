# Project State

## Decisions

| ID | Decision | Rationale |
| ---- | -------- | --------- |
| AD-001 | Ruby 3.4.9 (not 4.0.5) | Latest available via RVM; Rails 8.1 compatible |
| AD-002 | Missing CF-IPCountry → ban | Not in whitelist |
| AD-003 | Already-banned user → no new integrity log | No state change |
| AD-004 | VPNAPI fail-open on errors | Per PDF spec |
| AD-005 | Fundamental RSpec only | Request specs + VpnApiCheck service spec |
| AD-006 | PostgreSQL Docker port 5433 | Host 5432 already in use |
| AD-007 | Cloudflare trusted_proxies | Correct client IP behind CF |
| AD-008 | Orchestrator uses DB transaction | User + integrity log atomic |
| AD-009 | Redis down → HTTP 500 | No silent degrade on infrastructure failure |
| AD-010 | API key auth via X-API-Key | Protect check_status endpoint |
| AD-011 | Rate limit 60 req/min/IP | Rack::Attack on check_status |

## Handoff

Feature **user-check-status** — **complete**.

- All tasks T1–T7 done + hardening (auth, rate limit, monitoring, SimpleCov)
- 39 RSpec examples passing
- Verifier: PASS (see `.specs/features/user-check-status/validation.md`)
- Commits on `main`, ready for zip submission

**Run tests:** `docker compose up -d && bundle exec rspec`
