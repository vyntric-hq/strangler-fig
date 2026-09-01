# Conventions

This document describes the target architecture for this application. It is prescriptive. It describes where the code is going, not where it is today. Every agent working on a refactoring slice loads this document and follows it. If something you need to decide is not answered here, stop and ask a human, then add the answer to this document.

## Stack Defaults

- Next.js with the App Router, React, TypeScript in strict mode
- Path alias `@/*` mapped to `./src/*`
- zod for input validation at boundaries
- Vitest as the test framework
- Raw SQL through the project's database client, behind store modules (adjust this section if the project uses an ORM)

## Layering

Requests flow through four layers. Each layer may call the layer directly below it and nothing else.

1. **Transport.** Route handlers in `src/app/api/**/route.ts`, server components, middleware. Transport validates input, calls one domain function, and shapes the response. Nothing else.
2. **Domain.** Business logic in `src/lib/<domain>/` modules, one directory per business capability. Domain functions take typed values and return typed results. They never touch `Request`, `Response`, cookies, or headers.
3. **Data access.** Store modules in `src/lib/<domain>/store.ts` (or `src/lib/<domain>/queries.ts`). All SQL lives here. Nothing above this layer constructs a query.
4. **Infrastructure.** External API clients, mail, storage, queues, in `src/lib/<service>/`. Wrapped behind small typed functions. When more than one implementation exists, or a test needs a fake, define an interface at that seam.

Client components never import server-only modules. Server-only modules declare it with the `server-only` package.

## Route Handlers

- API endpoints are route handlers: `export async function GET/POST(req: Request)` returning `Response.json` (or `NextResponse.json`) with an explicit status code. No server actions.
- Every handler that accepts a body defines a module-level zod schema above the handler and parses with it. Failed parses return 400 with a stable error shape.
- A handler validates, checks authorization, calls one domain function, and maps the result to a response. Target is a screenful. No business rules, no SQL, no multi-step orchestration in handlers.
- Authorization is enforced in the handler or the domain layer on every request. Never only in the UI.

## Types and DTOs

- Data crossing a boundary has a named type, exported from the domain module that owns it. Types are derived from zod schemas with `z.infer` where a schema exists.
- No `any`, no untyped object literals passed between layers, no reaching into another domain's internal types. If two domains exchange a shape, the owning domain exports it.

## Data Access

- All SQL lives in store modules. One store per domain. Store functions take typed parameters and return typed rows.
- Every list query is bounded with a limit or pagination.
- N+1 access is a defect. Batch or join instead.
- Transactions wrap the whole unit of work and are opened by the domain function that owns the use case, never by a route handler, and never spanning an external API call.
- Multi-tenant scoping happens inside the store functions, never by caller discipline.

## Files and Naming

- One domain per directory under `src/lib/`. Small focused modules over one large file.
- UI components in `src/components/`, shared primitives in `src/components/ui/`. Components contain no business rules and no data access; they receive typed props.
- Name things after the business domain using the vocabulary the product uses, not generic technical words. `issueInvoice`, not `processBillingRecord`.

## Errors and Validation

- Validate at the edge with zod. Inside the boundary, code works with parsed, typed values, never raw `unknown` or request objects.
- Expected domain failures return typed results (a discriminated union beats a thrown string). Unexpected failures throw and are mapped to a 500 in one place.
- Never swallow errors. Either handle with a defined fallback or propagate with context.
- Every external call (fetch, database, subprocess) has a timeout and a defined failure path.
- No reading the clock, randomness, or env vars deep in domain code. Read them at the edge or inject them.

## Testing

- Vitest. Tests live in `src/__tests__/`, named `<area>-<behavior>.test.ts`.
- Characterization tests live in `src/__tests__/characterization/<slice>/` and exercise the application through real entry points: invoke the route handler functions with constructed `Request` objects and assert on status, body, and side effects.
- Unit tests for the refactored structure test domain functions and stores through their public interfaces.
- Mock only at system boundaries: external APIs, clocks, randomness. Never mock your own domain modules or stores. Tests that need a database use the project's test database setup.
- Architectural rules that a machine can check get encoded as tests, for example a test that greps route handlers for SQL, so the rule cannot regress silently.
- Cover the empty state, the failure path, and the concurrency or retry path, not just the happy path.

## Verification Gate

A slice is done when `tsc --noEmit` passes, the full Vitest suite passes, and the production build succeeds. Run all three before reporting success.

## Refactoring Rules

- New implementations are built alongside the old ones, then callers switch, then the old code is deleted. Both never stay live past the end of the slice.
- Existing bugs are preserved during a refactor and logged in the specification as follow-up work. Behavior changes never ride along with structural changes.
- Characterization tests pass unchanged before and after the refactor. If one fails, the refactor changed behavior. Stop and find out why.
