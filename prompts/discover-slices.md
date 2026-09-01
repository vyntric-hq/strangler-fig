# Discover Vertical Slices

Paste everything below this line into Claude Code at the root of the application you want to refactor. It reads the codebase and produces a slice map. It does not edit any code.

---

Read this application and map it into vertical slices for an incremental refactoring project. A vertical slice is one business capability end to end, like permissions or reporting or billing, not a layer like "all the controllers" or "the database code".

Rules for this task:

- Do not edit, fix, or refactor anything. This is a read-only survey. The only file you may create is the output file described below.
- Name slices after business capabilities in the domain's own vocabulary, not after technical layers or directories.
- If you are unsure whether something is one slice or two, prefer smaller slices with less shared surface area.

Explore the codebase, then write your findings to `docs/refactor/slices.md` with this structure:

For each slice:

- **Name.** The business capability.
- **What it does.** One or two plain sentences.
- **Entry points.** The routes, commands, jobs, scheduled tasks, or event handlers where this capability starts.
- **File footprint.** The main files and directories involved. Rough is fine, this is a map, not an inventory.
- **Depends on.** Shared foundations this slice needs, such as auth, a shared model, a utility layer. Name the slice or module, not every file.
- **Risk notes.** Anything that makes this slice harder than it looks: tangled shared state, code that several slices reach into, behavior that looks unintentional.

Then finish the document with:

- **Shared foundations.** The cross-cutting pieces that several slices depend on. These get refactored first.
- **Suggested order.** A numbered sequence for the refactoring work. Foundations before the capabilities that depend on them, then slices ordered to minimize overlapping surface area. Flag one small, well-understood slice as the recommended pilot.

When you are done, summarize the slice list in your reply so I can review it. I will correct the map before any refactoring starts.
