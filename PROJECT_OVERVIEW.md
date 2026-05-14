# Draw Steel Encounter Builder

## Project Vision

An encounter builder application for the TTRPG **Draw Steel**. This tool allows users to create, configure, and manage combat encounters locally.

## Tech Stack

- **Monorepo**: Turbo + Yarn workspaces
- **Backend**: NestJS + PostgreSQL
- **Frontend**: Next.js + React + Material-UI (MUI)
- **Language**: TypeScript (end-to-end)
- **Containerization**: Docker + docker-compose

## Architecture

### Monorepo Structure
```
draw-steel/
├── apps/
│   ├── api/          (NestJS backend)
│   └── web/          (Next.js frontend)
├── packages/
│   └── common/       (TypeScript shared types & utilities)
├── docker-compose.yml
├── turbo.json
├── package.json
└── yarn.lock
```

## Deployment Model

- **Primary**: Local development on single machine
- **Secondary**: Distribute to friends for local execution (Docker simplifies setup)

## Next Steps

1. Initialize the monorepo structure
2. Set up Yarn workspaces and Turbo
3. Bootstrap NestJS backend (`apps/api`)
4. Bootstrap Next.js frontend (`apps/web`)
5. Create shared types package (`packages/shared`)
6. Configure Docker & docker-compose for PostgreSQL
7. First run: `yarn install` → `yarn dev` (start all services)

---

**Status**: Architecture defined. Ready for implementation.
