# Tasks: User Check Status API

## Gate Check Commands

| Level | Command |
| ----- | ------- |
| quick | `bundle exec rspec spec/services --format progress` |
| full | `bundle exec rspec --format progress` |
| build | `bundle exec rails db:migrate RAILS_ENV=test && bundle exec rspec --format progress` |

## Test Coverage Matrix

| Layer | File | ACs covered |
| ----- | ---- | ----------- |
| Request | `spec/requests/v1/user/check_status_spec.rb` | AC-EP-*, AC-USER-*, AC-LOG-*, AC-VAL-* |
| Service | `spec/services/vpn_api_check_spec.rb` | AC-EP-05, AC-INF-02 |

## Execution Plan (3 phases)

### Phase 1: Foundation

| ID | Task | Done when | Gate |
| ---- | ---- | --------- | ---- |
| T1 | Docker Compose + project config | `docker compose up -d` starts postgres + redis | build |
| T2 | Rails 8 API scaffold + pinned gems | `bundle install` succeeds, `rails -v` shows 8.x | build |

### Phase 2: Domain & API

| ID | Task | Done when | Gate |
| ---- | ---- | --------- | ---- |
| T3 | User + IntegrityLog models | migrations run, models have required fields | build |
| T4 | Check services + VpnApiClient | services callable in console | build |
| T5 | Orchestrator + IntegrityLogger + controller | route exists, manual curl works | build |

### Phase 3: Tests & Docs

| ID | Task | Done when | Gate |
| ---- | ---- | --------- | ---- |
| T6 | Request specs | all AC-EP/USER/LOG/VAL pass | full |
| T7 | VpnApiCheck service spec + README | AC-TEST-02 pass, README documents setup | full |

## Status

- [ ] T1
- [ ] T2
- [ ] T3
- [ ] T4
- [ ] T5
- [ ] T6
- [ ] T7
