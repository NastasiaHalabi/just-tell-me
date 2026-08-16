# Just Tell Me — Cursor Starter Specification

This folder is a product + engineering specification for building the **Just Tell Me** Android/iOS personal action assistant with Cursor.

## Start here
Read the files in this order:

1. `DESCRIPTION.md` — what the product is
2. `REQUIREMENTS.md` — what it must do
3. `ADR.md` — architecture decisions
4. `PLAN.md` — build sequence
5. `CURSOR_CONTEXT.md` — rules for the coding agent
6. `docs/` — detailed technical specifications

## Recommended stack
- Mobile: Flutter / Dart
- Backend: Python / FastAPI
- Backend DB: PostgreSQL
- Mobile DB: SQLite via Drift
- Auth: Google + Apple, optional magic link
- AI: provider behind an interface; require structured JSON output
- Speech-to-text: provider behind an interface

## First Cursor prompt
Paste this after opening the repository in Cursor:

> Read README.md, DESCRIPTION.md, REQUIREMENTS.md, ADR.md, PLAN.md, CURSOR_CONTEXT.md and every file under docs/. Do not generate the whole app yet. Implement only Milestone 0 from PLAN.md. Create a Flutter mobile app and FastAPI backend in a monorepo, define clean project structure, add a `/health` endpoint, connect the mobile app to it in development, add lint/test configuration, `.env.example` files, and a root developer README with exact run commands. Follow ADR.md strictly. Do not add any third-party integrations yet. Run tests and fix errors before stopping.

Then continue milestone by milestone.

## Important product limitation
The product must distinguish **direct API execution** from **external app handoff**. In particular, personal WhatsApp should not be treated as freely automatable unless an official supported API explicitly allows the exact account/action scenario.
