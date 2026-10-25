# <component-name> — agentic SDLC component settings

This component is part of a monorepo/multi-repo workspace that uses the
agentic SDLC. The methodology itself (phases, gates, roles, loop caps)
lives in the hub's `CLAUDE.md` — this file only holds what's specific to
this one component.

- **Hub:** `<path to the hub repo's CLAUDE.md, e.g. ../service-api/CLAUDE.md>`
- **Layer:** `<database | service | web-admin | web-end-user | android | ios | browser-extension | shared-lib | other>`

Feature artefacts (spec, design, plan, progress, review report) live in the
hub, never in this repo. If you're working here as part of a feature, read
them from the hub's feature folder.

## Settings table

A `{{PLACEHOLDER}}` in a skill or agent means the Value in that row. An
empty Value means "not configured": stop and ask rather than guess.

| Placeholder | What it is | Example | Value |
|---|---|---|---|
| `{{STACK}}` | Primary language/framework | TypeScript + Next.js, Kotlin + Jetpack Compose, Swift + SwiftUI | |
| `{{PKG_MANAGER}}` | Dependency/script runner | `npm`, `gradle`, `swift package` | |
| `{{TEST_CMD}}` | Runs this component's full automated test suite | `npm test`, `./gradlew test`, `xcodebuild test` | |
| `{{LINT_CMD}}` | Static analysis / style check | `npm run lint`, `./gradlew ktlintCheck`, `swiftlint` | |
| `{{SCHEMA_CHECK_CMD}}` | Verifies this component's data-layer contract is consistent; `true` (a no-op) if it has no schema of its own | `npm run schema:check`, `true` | |
| `{{PRIMARY_DATASTORE}}` | What production data lives in (database/service components only) | Postgres | |
| `{{TEST_DATASTORE}}` | What tests run against (database/service components only) | SQLite, an in-memory fake | |
| `{{ISSUE_TRACKER}}` | Where requirements/bugs are tracked | Jira, Linear, GitHub Issues | |
| `{{ISSUE_PREFIX}}` | Ticket key prefix, if any | `PROJ-` | |
| `{{VCS_HOST}}` | Where this component's PRs are opened | GitHub, GitLab | |
| `{{DEPLOY_CMD}}` | How an approved change reaches users: a deploy for service/web, a store submission for mobile/extensions | `helm upgrade ...`, `fastlane ios release`, `web-ext sign` | |
| `{{MAIN_BRANCH}}` | The protected branch nothing commits to directly | `main` | |

## Layering override (optional)

The default task order within a component is **schema → service → api →
client**. If that doesn't fit this component's architecture, write its
order here, and `/implement plan` will use it instead. For example, a
mobile app might use: **data/network → domain → view-model → UI**.

Layer order for this component: `<leave blank to use the default>`
