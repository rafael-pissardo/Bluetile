# Project State

## Decisions

| ID | Decision | Rationale |
| ---- | -------- | --------- |
| AD-001 | Ruby 3.4.9 (not 4.0.5) | Latest available via RVM; Rails 8.1 compatible |
| AD-002 | Missing CF-IPCountry → ban | Not in whitelist |
| AD-003 | Already-banned user → no new integrity log | No state change |
| AD-004 | VPNAPI fail-open on errors | Per PDF spec |
| AD-005 | Fundamental RSpec only | Request specs + VpnApiCheck service spec |

## Handoff

Feature: user-check-status — in progress (Execute phase)
