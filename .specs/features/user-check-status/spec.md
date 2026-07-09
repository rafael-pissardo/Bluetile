# Spec: User Check Status API

## Overview

POST `/v1/user/check_status` — security check chain returning `{ "ban_status": "banned" | "not_banned" }`.

## Acceptance Criteria

### Endpoint (AC-EP)

- **AC-EP-01**: `POST /v1/user/check_status` accepts JSON `{ "idfa": "<uuid>", "rooted_device": <boolean> }` and returns `200` with `{ "ban_status": "not_banned" }` when all checks pass.
- **AC-EP-02**: Returns `{ "ban_status": "banned" }` when country not in Redis whitelist (CF-IPCountry header).
- **AC-EP-03**: Returns `{ "ban_status": "banned" }` when `rooted_device` is `true`.
- **AC-EP-04**: Returns `{ "ban_status": "banned" }` when VPNAPI reports `security.vpn` or `security.tor` true.
- **AC-EP-05**: VPNAPI errors (5xx, 429, timeout) → check passes (fail-open); user not banned solely due to API failure.
- **AC-EP-06**: Missing CF-IPCountry → banned (not whitelisted).

### User persistence (AC-USER)

- **AC-USER-01**: Create user when IDFA not found; update when exists.
- **AC-USER-02**: Existing banned user → return `"banned"` immediately, skip check chain.
- **AC-USER-03**: Existing not_banned user → re-run checks, update status if changed.

### Integrity log (AC-LOG)

- **AC-LOG-01**: Log on new user creation with fields: idfa, ban_status, ip, rooted_device, country, proxy, vpn, created_at.
- **AC-LOG-02**: Log when ban_status changes on existing user.
- **AC-LOG-03**: No log when status unchanged; no log when already-banned user hits endpoint.

### Validation (AC-VAL)

- **AC-VAL-01**: Invalid UUID → 422.
- **AC-VAL-02**: Missing required field → 400.
- **AC-VAL-03**: Malformed JSON → 400.

### Future-proofing (AC-FP)

- **AC-FP-01**: IntegrityLogger service with swappable adapter (PostgreSQL default).
- **AC-FP-02**: User ban_status as extensible enum (banned, not_banned).

### Infrastructure (AC-INF)

- **AC-INF-01**: Rails 8 API-only, PostgreSQL, Redis.
- **AC-INF-02**: VPNAPI responses cached in Redis 24h.
- **AC-INF-03**: Docker Compose for local Postgres + Redis.

### Testing (AC-TEST)

- **AC-TEST-01**: Request spec covers all AC-EP, AC-USER, AC-LOG, AC-VAL scenarios.
- **AC-TEST-02**: VpnApiCheck service spec: fail-open + cache hit.
