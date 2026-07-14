---
name: poc
description: Build a polished, lightweight proof of concept as a thin vertical slice. Use when the user asks for a PoC, proof of concept, prototype, demo app, or a lightweight MVP focused on validating one core experience.
---

# Build a PoC

Build a polished thin vertical slice while keeping the backend and infrastructure to the minimum required for the core functionality.

Assume simplicity unless stated otherwise. All defaults in this skill are starting points. Explicit user instructions and established project conventions take precedence.

## 1. Concept

Before implementation, establish:

- The primary audience and whether distinct user roles are genuinely needed
- The job they need to complete or showcase
- The shortest complete user flow and any essential alternate path
- What is deliberately excluded or represented only as a mock

Infer these from the conversation whenever possible. Ask only about decisions that would materially change the result.

Present a compact plan and wait for acceptance unless the plan has already been agreed upon.

Do not expand the PoC into a production platform.

## 2. Tech Stack

These are the default choices, applied **only when the respective functionality is needed**. If there is reasonable doubt about a choice, suggest an alternative and briefly explain why.

- Language: Python 3.13 managed with `uv`
- CLI: Typer, Rich
- Backend: FastAPI, Pydantic, SQLModel, Jinja2, httpx
- Auth: HTTP Basic
- Frontend: HTML, CSS, vanilla JS, and HTMX when needed
- Database: SQLite locally, PostgreSQL when deployed
- AI: PydanticAI for structured LLM calls, Codex SDK for multi-step agent workflows
- Deployment: Railway using Railpack

Keep the application stateless when practical.

## 3. Implementation

After the plan is accepted, set up the project in the current directory if it is already the intended project folder; otherwise create a new one. Initialize a local git repository without a remote and commit at sensible milestones.

Consider using subagents for independent work that can proceed in parallel, such as frontend and backend implementation.

Keep the implementation focused on the accepted demonstration path.

### Frontend

PoCs are reduced to their minimum functionality, but their UI and UX should still feel excellent. The interface should persuade the user without becoming powerful, busy, or complex. It can be beautiful, original, and simple at the same time.

Use the `frontend-design` skill before implementing or substantially changing the interface.

The frontend should:

- Present one clear primary action at a time
- Use concise explanatory copy
- Work comfortably on mobile and desktop
- Include appropriate loading, success, empty, and error states
- Prefer clear state transitions over displaying several competing sections at once

### Backend and CLI

Keep the backend narrow and organized in a small number of files.

Use environment variables for secrets and a local `.env` file when useful. Never commit secrets.

Keep the code straightforward and handle only important, realistic error behavior. External service failures should be explained in language the user can understand.

Do not introduce speculative abstractions or production architecture that the current PoC does not need.

Do not add unit or integration tests by default.

## 4. Verification

Before presenting the result, run the application. For web UIs, use the `agent-browser` skill to smoke-test:

- The primary success flow
- Loading and result states
- One relevant failure state when practical
- Desktop layout
- Mobile layout
- Upload, camera capture, or other device-oriented interactions when present

For CLI or API-only PoCs, exercise the main commands or endpoints directly instead.

Fix obvious visual or functional problems discovered during the smoke test.

Do not introduce a large testing or linting setup solely for the PoC.

## 5. Deployment

Unless the user requests a local-only result, include Railway deployment in the proposed plan.

Once the user has agreed to the deployment, use the `railway` skill to create a dedicated Railway project using Railpack and expose it through a Railway-provided public domain.

If multiple Railway workspaces exist, select the one that fits the topic. In doubt, choose the private one.

Add PostgreSQL or a storage volume only when required by the implemented flow.

## 6. Finish

A PoC is complete when:

- The primary demonstration path works
- The interface has been visually smoke-tested
- The mobile experience is usable
- Required environment variables are documented
- Important limitations are stated clearly
- Unnecessary infrastructure has not been added
