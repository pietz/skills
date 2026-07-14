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

Consider these the default choices when the respective functionality is needed. If there is reasonable doubt about a choice, suggest an alternative and briefly explain why.

- Language: Python 3.13 managed with `uv`
- CLI when needed: Typer and Rich
- Backend: FastAPI and Pydantic
- Server-rendered HTML when needed: Jinja2 templates served by FastAPI
- HTTP client when needed: httpx
- Authentication when needed: HTTP Basic
- Database access when needed: SQLModel
- Database: SQLite for local use and PostgreSQL for deployed web applications
- Frontend: HTML, CSS, vanilla JavaScript, and HTMX when it simplifies interaction
- AI functionality:
  - Pydantic AI for simple or structured LLM functionality
  - OpenAI Codex SDK for powerful multi-step agent workflows
- Deployment: Railway using Railpack
- Blob storage when needed: Railway storage volume

Keep the application stateless when practical.

Do not add authentication, persistence, background workers, queues, caches, or additional services unless the primary flow requires them.

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

## 4. Visual Verification

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

Choose the Railway workspace from the project context:

- Use the work workspace for clearly professional, company, or client-related projects.
- Use the private workspace for personal projects.
- When uncertain, use the private workspace.
- An explicitly named workspace always takes precedence.

Add PostgreSQL or a storage volume only when required by the implemented flow.

Do not add a Procfile unless the application genuinely requires one.

## 6. Finish

A PoC is complete when:

- The primary demonstration path works
- The interface has been visually smoke-tested
- The mobile experience is usable
- Required environment variables are documented
- Important limitations are stated clearly
- Unnecessary infrastructure has not been added
