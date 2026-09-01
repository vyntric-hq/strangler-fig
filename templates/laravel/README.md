# Laravel Template

Agent definitions and conventions for refactoring a Laravel application one vertical slice at a time. See the [root README](../../README.md) for the pattern and the per-slice workflow.

## Defaults This Template Assumes

| Concern | Default |
|---|---|
| Framework | Laravel 11+, PHP 8.2+ |
| ORM | Eloquent |
| Test framework | Pest |
| Formatting | Laravel Pint |
| Static analysis | PHPStan via Larastan |
| Use case layer | Single-purpose action classes in `app/Actions` |
| DTOs | Readonly PHP classes in `app/Data` |

## Swapping Defaults

The defaults live in two places: `CONVENTIONS.md` and the agent definition files. If you swap one, update both, because the agents follow whichever document they are given.

**PHPUnit instead of Pest.** In `CONVENTIONS.md`, change the Testing section. In `agents/test-author.md`, change the framework instruction and the example test style. The characterization strategy stays the same: Feature tests through real entry points.

**Doctrine instead of Eloquent.** Rewrite the Data Access section of `CONVENTIONS.md` around repositories and the EntityManager, and update the surveyor and refactorer instructions that mention Eloquent relationships and scopes.

**No action classes.** Some teams prefer service classes or command bus handlers. The layering rule is what matters: one class per use case, owning the transaction, called by thin transport. Rename the layer to whatever your team calls it and keep the rule.

## How the Test Author's Write Boundary Is Enforced

The surveyor and reviewer are read-only through the `tools` list in their frontmatter. The test author needs write access, but only to `tests/`, and a tool list cannot express a path rule. So `agents/test-author.md` declares a `PreToolUse` hook in its frontmatter that rejects any Write or Edit outside `tests/`. The hook is scoped to that agent and travels with the file, so installing the template installs the enforcement.

Two things to know:

- The hook uses `jq`, which needs to be on your PATH.
- Claude Code only runs frontmatter hooks from a trusted project folder. If the hook does not fire, check that the repository is trusted in Claude Code.

If your tests live somewhere other than `tests/`, update the path pattern in the hook.
