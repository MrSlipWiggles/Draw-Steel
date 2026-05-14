# Draw-Steel

Encounter builder for the TTRPG Draw Steel.

## Development Environment Setup

### Prerequisites Installed
- **Node.js** v24.15.0 LTS
- **Yarn** v4 (via Corepack)
- **Docker Desktop** with WSL 2 backend
- **WSL 2** with Ubuntu distribution

### Project Structure
Monorepo using Yarn workspaces and Turbo:
```
draw-steel/
├── apps/
│   ├── api/              # NestJS backend
│   └── web/              # Next.js + React + MUI frontend
├── packages/
│   └── common/           # Shared TypeScript types & utilities
├── package.json          # Root workspace config
├── turbo.json            # Turbo monorepo config
└── tsconfig.json         # Base TypeScript config
```

### Current Status
✅ Monorepo scaffolding complete
✅ Root `package.json` with workspaces configured
✅ Turbo pipeline configured
✅ Base `tsconfig.json` created
✅ `.gitignore` set up
✅ Dependencies installed (`yarn install`)

### Next Steps
- [ ] Set up NestJS backend (`apps/api`)
- [ ] Set up Next.js frontend (`apps/web`)
- [ ] Set up shared types package (`packages/shared`)
- [ ] Create `docker-compose.yml` for PostgreSQL
- [ ] Initialize local development environment

## Getting Started

```bash
# Install dependencies
yarn install

# Run all dev servers (when configured)
yarn dev

# Build all packages
yarn build
```