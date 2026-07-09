# Validation Report: user-check-status

**Verifier run:** 2026-07-09  
**Gate command:** `bundle exec rspec --format progress`  
**Gate exit code:** `0` (18 examples, 0 failures)

## Verdict: PASS (with gaps)

Implementation satisfies all acceptance criteria that have spec-anchored assertions. Discrimination sensor confirms fail-open behavior is exercised by tests. Several ACs rely on structural/code evidence only; noted below.

---

## Spec-anchored AC coverage

### Endpoint (AC-EP)

| AC | Status | Evidence |
|----|--------|----------|
| AC-EP-01 | PASS | `spec/requests/v1/user/check_status_spec.rb:38` `have_http_status(:ok)`; `:39` `eq("ban_status" => "not_banned")` |
| AC-EP-02 | PASS | `spec/requests/v1/user/check_status_spec.rb:56` `eq("ban_status" => "banned")` (CF-IPCountry `XX`) |
| AC-EP-03 | PASS | `spec/requests/v1/user/check_status_spec.rb:68` `eq("ban_status" => "banned")` (`rooted_device: true`) |
| AC-EP-04 | PASS | `spec/requests/v1/user/check_status_spec.rb:76` vpn ban; `:84` tor ban |
| AC-EP-05 | PARTIAL | `spec/requests/v1/user/check_status_spec.rb:163` fail-open on 500 only; `spec/services/vpn_api_check_spec.rb:18` unit fail-open. **Gap:** no spec for 429 or timeout (impl rescues `VpnApiClient::Error`, `Faraday::Error` at `app/services/checks/vpn_api_check.rb:22-23`) |
| AC-EP-06 | PASS | `spec/requests/v1/user/check_status_spec.rb:62` `eq("ban_status" => "banned")` (missing CF-IPCountry) |

### User persistence (AC-USER)

| AC | Status | Evidence |
|----|--------|----------|
| AC-USER-01 | PARTIAL | Create: `spec/requests/v1/user/check_status_spec.rb:36` `change(User, :count).by(1)`. Update-on-exists implied by `:100-107` (existing user status change) but **no explicit assertion** that `User.count` unchanged on re-hit with same status |
| AC-USER-02 | PASS | `spec/requests/v1/user/check_status_spec.rb:96` `eq("ban_status" => "banned")`; `:97` VPNAPI not called |
| AC-USER-03 | PASS | Re-run + update: `:100-107`; unchanged no log: `:110-115` |

### Integrity log (AC-LOG)

| AC | Status | Evidence |
|----|--------|----------|
| AC-LOG-01 | PARTIAL | `spec/requests/v1/user/check_status_spec.rb:36` log created; `:45-48` asserts idfa, ban_status, country, rooted_device. **Gap:** ip, proxy, vpn, created_at not asserted (impl writes all at `app/services/integrity_logging/postgres_adapter.rb:4-12`) |
| AC-LOG-02 | PASS | `spec/requests/v1/user/check_status_spec.rb:103-105` `change(IntegrityLog, :count).by(1)` on status change |
| AC-LOG-03 | PASS | No log unchanged: `:113-115`; already-banned: `:92-94` |

### Validation (AC-VAL)

| AC | Status | Evidence |
|----|--------|----------|
| AC-VAL-01 | PASS | `spec/requests/v1/user/check_status_spec.rb:123` `have_http_status(:unprocessable_entity)` |
| AC-VAL-02 | PASS | `:129` missing idfa → 400; `:135` missing rooted_device → 400 |
| AC-VAL-03 | PASS | `:147` malformed JSON → 400 |

### Future-proofing (AC-FP)

| AC | Status | Evidence |
|----|--------|----------|
| AC-FP-01 | CODE-ONLY | `app/services/integrity_logger.rb:2` injectable `adapter:`; default `PostgresAdapter`. **No spec** asserting adapter swap |
| AC-FP-02 | CODE-ONLY | `app/models/user.rb:2` enum `ban_status: { not_banned, banned }`. **No dedicated spec** |

### Infrastructure (AC-INF)

| AC | Status | Evidence |
|----|--------|----------|
| AC-INF-01 | CODE-ONLY | `Gemfile:5-8` Rails 8.1, pg, redis; `config/application.rb:42` `api_only = true` |
| AC-INF-02 | PASS | `spec/services/vpn_api_check_spec.rb:21-30` cache hit (no second HTTP); impl `app/services/checks/vpn_api_check.rb:4` TTL 86400 |
| AC-INF-03 | CODE-ONLY | `docker-compose.yml:1-18` postgres + redis services |

### Testing (AC-TEST)

| AC | Status | Evidence |
|----|--------|----------|
| AC-TEST-01 | PASS | Request spec covers EP/USER/LOG/VAL scenarios (16 examples) |
| AC-TEST-02 | PASS | `spec/services/vpn_api_check_spec.rb:13-18` fail-open; `:21-30` cache |

---

## Discrimination sensor

| Field | Value |
|-------|-------|
| Fault injected | `app/services/checks/vpn_api_check.rb:23` — rescue branch `passed: true` → `passed: false` (fail-open → fail-closed) |
| Specs run | `spec/services/vpn_api_check_spec.rb`, `spec/requests/v1/user/check_status_spec.rb` |
| Sensor exit code | `1` (2 failures — **sensor PASS**: tests discriminate the fault) |
| Failures observed | `vpn_api_check_spec.rb:18` `expect(result.passed).to be(true)`; `check_status_spec.rb:163` `eq("ban_status" => "not_banned")` |
| Revert | Restored `passed: true`; gate re-run clean |

---

## Gate summary

```
18 examples, 0 failures
GATE_EXIT=0
```

---

## Gaps for orchestrator

1. **AC-EP-05 partial:** Only HTTP 500 fail-open tested at request level; add 429 and timeout examples.
2. **AC-LOG-01 partial:** Happy-path log assertion missing ip, proxy, vpn, created_at.
3. **AC-USER-01 partial:** No explicit update-without-create example for existing IDFA.
4. **AC-FP-01/02, AC-INF-01/03:** Satisfied by code structure only — no spec anchors (acceptable for infra/FP if policy allows CODE-ONLY).
