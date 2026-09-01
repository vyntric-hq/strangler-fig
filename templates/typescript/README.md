# TypeScript Template

Agent definitions and conventions for refactoring a TypeScript web application one vertical slice at a time. See the [root README](../../README.md) for the pattern and the per-slice workflow.

## Defaults This Template Assumes

| Concern | Default |
|---|---|
| Framework | Next.js with the App Router, React, strict TypeScript |
| API style | Route handlers with explicit status codes, no server actions |
| Validation | zod schemas at the boundary |
| Test framework | Vitest, tests in `src/__tests__/` |
| Data access | Raw SQL behind store modules, one store per domain |
| Domain logic | Modules under `src/lib/<domain>/` |
| Verification gate | `tsc --noEmit`, full Vitest suite, production build |

These defaults come from running production Next.js applications, but nothing in the workflow depends on Next.js specifically. The layering rules translate directly to any TypeScript server framework.

## Swapping Defaults

The defaults live in two places: `CONVENTIONS.md` and the agent definition files. If you swap one, update both, because the agents follow whichever document they are given.

**An ORM instead of raw SQL.** Rewrite the Data Access section of `CONVENTIONS.md` around your ORM (Drizzle, Prisma, Kysely). The rule that survives any swap: all data access behind store modules with typed inputs and outputs, nothing above that layer constructing queries.

**Express, Fastify, or Hono instead of Next.js.** Update the Transport layer description and the entry-point language in the surveyor and test-author definitions. Characterization tests invoke your framework's handlers or use its injection helper instead of constructing `Request` objects.

**Jest instead of Vitest.** Change the Testing section of `CONVENTIONS.md` and the run commands in `agents/test-author.md` and `agents/refactorer.md`. The characterization strategy stays the same.

**A different test directory.** If your tests live in `tests/` or are colocated, update the Testing section, the test-author's instructions, and the path pattern in the hook in `agents/test-author.md` frontmatter.

## How the Test Author's Write Boundary Is Enforced

The surveyor and reviewer are read-only through the `tools` list in their frontmatter. The test author needs write access, but only to the test directory, and a tool list cannot express a path rule. So `agents/test-author.md` declares a `PreToolUse` hook in its frontmatter that rejects any Write or Edit outside `src/__tests__/`. The hook is scoped to that agent and travels with the file, so installing the template installs the enforcement.

Two things to know:

- The hook uses `jq`, which needs to be on your PATH.
- Claude Code only runs frontmatter hooks from a trusted project folder. If the hook does not fire, check that the repository is trusted in Claude Code.
