# Strangler Fig

A toolkit for refactoring legacy production applications with AI agents, one vertical slice at a time, without changing what the application does. That includes the newest kind of legacy: vibe coded apps that shipped, found real users, and now need real structure.

This repository gives you framework-specific starting points. Each template folder contains a conventions document that describes the target architecture and four agent definitions for Claude Code that do the mechanical work inside a structure that keeps them honest. You copy a template into your application, tailor the conventions to your project, and run the workflow.

## The Problem

Applications that grow without enforced conventions get expensive to change. The symptoms are familiar. Business logic scattered across controllers. DTOs constructed wherever it was convenient. One file holding a dozen unrelated classes. No reliable boundary between layers. The code works, mostly, but nobody can predict what a change will break.

Vibe coded applications get here faster than anything before them. An app prompted into existence over a few weekends can absolutely reach production and win paying customers. But nobody enforced conventions along the way because nobody was reading the code, so it arrives at the same place a decade of undisciplined hand-written changes used to: logic everywhere, boundaries nowhere, behavior nobody can fully explain. The age of the codebase stopped being the thing that makes it legacy. The absence of structure is.

A full rewrite is the tempting answer and usually the wrong one. It stops feature delivery, carries enormous risk, and throws away behavior that nobody documented but customers depend on.

This pattern takes the other route. Keep the application running, refactor one capability at a time, and use AI agents to do the mechanical work inside a structure that keeps them honest. If AI speed created the mess, AI speed with guardrails is how you clean it up without stopping the business.

## Core Principles

**Preserve behavior, change structure.** The goal is not to fix bugs. Existing bugs get preserved on purpose and fixed later as separate, visible work. Mixing behavior changes into a refactor destroys your ability to tell what went wrong.

**Work in vertical slices.** Refactor one business capability end to end, like permissions or reporting or billing. Refactoring layer by layer leaves the system half-migrated for months. Slices ship.

**Humans own the specification.** Agents are fast at writing code and mediocre at deciding what the code should mean. The one artifact a person has to review carefully is the description of what the current code does.

**Fresh context per role.** Drift happens when a single long session accumulates its own assumptions and then validates against them. Separate agents with separate context windows are the fix.

## Strangler Fig at Module Scope

The strangler fig pattern comes from large system migration. You build the replacement alongside the original, redirect callers to it piece by piece, then remove the original once nothing references it.

The same mechanic works inside a single codebase. Your call sites are the routing.

1. Build the new, properly structured implementation of a capability alongside the existing one.
2. Point the callers at the new implementation.
3. Delete the old implementation.

At this scale the whole cycle can land in a single pull request, or a short series of them. You are never running a half-built parallel system in production.

## Characterization Tests

A characterization test records what the code currently does, bugs and oddities included, and locks that in as the expected result. It is different from a unit or acceptance test, which encodes what the code should do.

These tests are the safety net. You write them before any restructuring starts, against the existing implementation, and they have to pass unchanged after the refactor. If one fails, either the refactor changed behavior or the test captured something that was never actually true.

They are often integration-level rather than unit-level, because badly layered code rarely gives you clean seams. That is fine. Coverage of real behavior matters more than test purity here.

Treat them as scaffolding. Once a slice is refactored and covered by proper unit tests against the new structure, retire its characterization tests.

## The Four Agent Roles

Each role runs in its own context, with its own instructions and its own tool permissions.

**1. Surveyor.** Reads one slice of the existing application and produces a plain-language specification of what it does, including edge cases, implicit behavior, and anything that looks unintentional. Writes no code.

**2. Test Author.** Writes characterization tests from the specification. Writes to the test directory only. That constraint matters. An agent that can see and edit the implementation tends to write tests describing the implementation instead of the behavior.

**3. Refactorer.** Receives the specification, the tests, and the conventions document. Builds the new implementation and makes the tests pass. Does not modify the tests.

**4. Reviewer.** Starts with no history of the previous three. Checks the diff against the specification and the conventions document, and reports deviations. Does not fix them. A human decides.

### The Human Gate

A person reviews and approves the surveyor's specification before anything downstream begins. Everything after that point inherits its accuracy. This is the highest-leverage review in the process and it should not be delegated.

## Quick Start

You need [Claude Code](https://claude.com/claude-code) and a git repository you want to refactor.

**1. Clone this repo somewhere outside your application.**

```bash
git clone https://github.com/vyntric-hq/strangler-fig.git
```

**2. Install a template into your application.**

```bash
./strangler-fig/scripts/install.sh laravel /path/to/your-app
# or
./strangler-fig/scripts/install.sh typescript /path/to/your-app
```

The installer copies the four agent definitions into `.claude/agents/`, the conventions document to `CONVENTIONS.md` at your repository root, and the slice discovery prompt to `docs/refactor/`.

**3. Tailor the conventions document.**

This step is not optional. `CONVENTIONS.md` ships with sensible defaults for the framework, but it describes a target architecture and yours will differ in places. Read the whole thing. Change what does not fit. If the answer to "may a controller do this?" is not in the document, agents will invent an answer, and different agents will invent different ones.

**4. Map your application into slices.**

Open Claude Code in your application and paste the contents of `docs/refactor/discover-slices.md`. It reads your codebase without editing anything and produces `docs/refactor/slices.md`, a list of business capabilities with entry points, file footprints, dependencies, and a suggested order of attack. Review the list and correct it. You know the business better than the code does.

**5. Run the per-slice workflow.**

Pick one small, well-understood slice as a pilot. The first pass exists to expose gaps in the conventions document, which will be incomplete on the first attempt no matter how carefully it was written. Revise it based on what the pilot surfaces, then scale to the rest of the team.

## Per-Slice Workflow

Each role is a Claude Code agent installed in `.claude/agents/`, and you invoke one by asking Claude to use it. The prompts below are ready to paste. They use a slice named `billing` as the example; swap in your slice.

**1. Pick a slice.** Choose one business capability from `docs/refactor/slices.md` and assign it to one developer. Start a branch for it.

**2. Survey it.** Paste:

```text
Use the surveyor agent to survey the billing slice. Its entry points are
listed under "Billing" in docs/refactor/slices.md. Save the specification
it reports to docs/refactor/billing-spec.md so I can review it.
```

The surveyor itself is read-only. It reports the specification back and the main session saves the file for your review.

**3. Approve the specification.** This is the human gate. Do not skip it and do not delegate it. Read the spec against your knowledge of the product, correct anything wrong by editing the file directly, and decide which flagged oddities are bugs to preserve. Everything downstream inherits this document's accuracy.

**4. Write the characterization tests.** Paste:

```text
The specification at docs/refactor/billing-spec.md is approved. Use the
test-author agent to write characterization tests from it, run them against
the current implementation, and show me the results.
```

Every test must pass against the existing code before you continue. If the test author reports spec claims it could not reproduce, resolve those with the spec first.

**5. Refactor.** Paste:

```text
Use the refactorer agent to rebuild the billing slice. The approved spec is
docs/refactor/billing-spec.md, the characterization tests live in this
slice's characterization directory, and CONVENTIONS.md describes the target
architecture. Build the new implementation alongside the old one, switch the
callers, delete the old code, and leave the characterization tests passing
unchanged.
```

**6. Confirm the gates.** Characterization tests pass unchanged, the full suite passes, CI is green. If a characterization test fails, the refactor changed behavior. Stop and find out why.

**7. Review.** Start a fresh Claude Code session first, so the reviewer inherits no context from the work it is auditing. Then paste:

```text
Use the reviewer agent to audit the billing refactor. The spec is
docs/refactor/billing-spec.md and the diff is main...HEAD. Report deviations
from the spec and from CONVENTIONS.md. Change nothing.
```

You resolve the findings, not the reviewer. Send fixes back through the refactorer if they are structural.

**8. Ship it.** Pull request, human code review, merge.

Assign slices to individual developers so two people are not restructuring overlapping code at the same time. Pick slice boundaries that minimize shared surface area, and sequence the work so shared foundations get refactored before the capabilities that depend on them.

## Templates

| Template | Framework | Test framework | Data access | Notes |
|---|---|---|---|---|
| `laravel` | Laravel 11+ | Pest | Eloquent | Feature tests through HTTP as the characterization layer |
| `typescript` | Next.js App Router | Vitest | Repository modules over your SQL client | Route handlers with zod at the boundary, no server actions |

Each template folder has its own README describing the defaults it assumes and how to swap them, for example Pest to PHPUnit, or Eloquent to Doctrine. The agent definitions and conventions are written against those defaults, so if you swap a default, update both.

Want a template for another stack? The four roles and the workflow are framework-agnostic. Copy an existing template folder, rewrite `CONVENTIONS.md` for your stack, and adjust the framework-specific instructions in each agent file. Pull requests welcome.

## Enforcing Role Separation

Enforce role separation through permissions rather than instructions. The test author being unable to write to source directories is a mechanical guarantee. Asking it not to is not.

The agent definitions ship with that enforcement built in. The surveyor and reviewer carry read-only tool lists in their frontmatter, so they cannot edit files at all. The test author's write boundary is a path rule, which tool lists cannot express, so its definition declares a PreToolUse hook that rejects any write outside the test directory. The hook travels with the agent file, so installing the template installs the enforcement. Details, including the trust requirement and how to change the path, are in each template's README.

Back the mechanically checkable conventions with tooling too. Linters, static analysis, architecture fitness tests, dependency rules, all running in CI. Anything a linter can enforce should not depend on an agent remembering it. The reviewer agent covers what tooling cannot check, which is whether the code actually matches the intent of the conventions.

## What to Expect

**Timeline.** Slices ship continuously instead of arriving as one large delivery. Progress is visible from the first week, and the work can pause at any slice boundary without leaving the system inconsistent.

**Risk profile.** Substantially lower than a rewrite. Each change is scoped to one capability, covered by tests that assert existing behavior, and independently revertible.

**Feature delivery.** Continues in parallel. Refactored slices are usually easier to build on right away, so velocity tends to improve before the migration finishes.

**Where it fails.** Three failure modes account for most problems. Skipping the human review of the specification. Letting behavior changes slip in alongside structural changes. A conventions document vague enough that agents interpret it differently. All three are avoidable and all three are worth watching for explicitly.

## License

MIT. See [LICENSE](LICENSE).
