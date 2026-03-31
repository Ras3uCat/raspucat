# Flutter Development Skill
**Scope:** `/lib/`
**Purpose:** Build production-grade Flutter applications with clean architecture and distinctive, memorable UI design.

## Architectural Blueprint
- **State:** GetX (Controllers + Bindings).
- **Organization:** Feature-First (`features/<name>/`).
- **Layers:** - `screens/`: UI only.
    - `controllers/`: Reactive logic + State.
    - `models/`: Data structures.
    - `widgets/`: Local components.
- **Shared:** `common/widgets/` for cross-feature components.
- **Data Layer:** `data/repositories/` (all API/data flow goes here)

## Implementation Rules
- **Pure Widgets:** Zero business logic. Use `GetView<TController>`.
- **E-Constants:** Use `EColors`, `ESizes`, `EImages`, `EText` strictly.
- **The 300 Rule:** If a file exceeds 300 lines, extract widgets/logic to new files immediately.
- **Repositories:** All data fetching must go through `data/repositories/`.
- **Controller Responsibility:** Business logic, validation, formatting, state.

## Naming & Style
- Class: `UpperCamelCase`
- Variables: `lowerCamelCase`
- Suffixes: `...Controller`, `...Widget` (if reusable), `...Repository`.

## Usage
Trigger this skill for any task involving UI, State, or Flutter-specific refactoring.