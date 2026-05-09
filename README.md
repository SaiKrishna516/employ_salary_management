# Salary Management Tool

HR salary management tool supporting 10,000 employees.

## Stack

| Layer    | Technology                            |
|----------|---------------------------------------|
| Backend  | Rails 7.1 API-only, PostgreSQL        |
| Testing  | RSpec, FactoryBot, Faker, shoulda-matchers |
| Frontend | React 18 + Vite + TypeScript          |
| UI       | shadcn/ui + Tailwind CSS              |
| Table    | TanStack Table v8                     |
| Data     | TanStack Query                        |

## Getting Started

### Backend

```bash
cd backend
bundle install
rails db:create db:migrate db:seed
rails s -p 3001
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## Project Structure

```
salary-tool/
├── backend/        # Rails 7 API-only
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   ├── models/
│   │   ├── queries/
│   │   └── serializers/
│   ├── db/
│   └── spec/
├── frontend/       # React 18 + Vite
├── DECISIONS.md
└── README.md
```

## Development Approach

**Strict TDD** — failing test → implementation → refactor. No production code without a prior test.
