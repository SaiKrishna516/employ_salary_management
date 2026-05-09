# DECISIONS.md

## Database
- **PostgreSQL** (dev, test, production) — chosen over SQLite for production-readiness and performance with 10k+ employees.

## Backend Framework
- **Rails 7.1 API-only** — matches job description requirement; API-only mode strips view/asset pipeline overhead.

## Testing
- **Strict TDD** — every line of production code is preceded by a failing RSpec test.
- **RSpec + FactoryBot + Faker + shoulda-matchers** — industry standard Rails testing stack.

## Serialization
- **jsonapi-serializer** — fast, explicit field control, no N+1 by default.

## Pagination
- **Kaminari** — Rails-native, scope-based pagination; default 25 per page, configurable via `?page=` and `?per_page=`.

## CORS
- `rack-cors` with `origins "*"` in development. **Must be tightened to the frontend URL before production deployment.**

## Indexes
- Composite index on `[country, job_title]` — most-used filter in insights queries. Prevents full table scans on 10k rows.
