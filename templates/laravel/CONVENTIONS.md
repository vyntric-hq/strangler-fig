# Conventions

This document describes the target architecture for this application. It is prescriptive. It describes where the code is going, not where it is today. Every agent working on a refactoring slice loads this document and follows it. If something you need to decide is not answered here, stop and ask a human, then add the answer to this document.

## Stack Defaults

- Laravel 11 or later, PHP 8.2 or later
- Eloquent as the ORM
- Pest as the test framework
- Laravel Pint for formatting, PHPStan (Larastan) for static analysis

## Layering

Requests flow through four layers. Each layer may call the layer directly below it and nothing else.

1. **Transport.** Controllers, console commands, jobs, event listeners, scheduled tasks. Transport validates input, calls one action, and shapes the response. Nothing else.
2. **Actions.** One class per use case in `app/Actions`, named as a verb phrase, with a single `handle` method. Actions own the transaction boundary and orchestrate domain objects. An action may call other actions, domain services, and repositories.
3. **Domain.** Models, domain services, value objects, enums. Domain code never reads the request, the session, or config directly. Values it needs get passed in.
4. **Infrastructure.** External API clients, mail, storage, queues. Wrapped behind small interfaces in `app/Contracts` when more than one implementation exists or the boundary needs faking in tests.

## Controllers

- A controller method validates via a FormRequest, calls one action, and returns a response. Target is five lines or fewer of real logic.
- No queries in controllers. No business rules in controllers. No `DB::` calls in controllers.
- Authorization runs in the FormRequest or a policy, never inline in the controller body.

## Data Access

- Eloquent models hold relationships, casts, scopes, and accessors. They do not hold business workflows.
- Queries beyond trivial finds live in query scopes or dedicated query classes in `app/Queries`. No query builder chains in controllers or Blade views.
- Every list query is bounded with pagination or an explicit limit.
- N+1 access is a defect. Eager load explicitly.
- Transactions open in the action, wrap the whole unit of work, and never span an external API call.

## DTOs

- Data crossing the transport boundary in or out travels in readonly PHP classes in `app/Data`, constructed in one place: from the FormRequest on the way in, from a model or action result on the way out.
- No associative arrays as return types between layers. If two layers exchange a shape, that shape has a class.

## Files and Naming

- One class per file, matching PSR-4 paths.
- Actions: `app/Actions/{Domain}/{VerbPhrase}.php`, for example `app/Actions/Billing/IssueInvoice.php`.
- DTOs: `app/Data/{Domain}/{Noun}Data.php`.
- Name things after the business domain using the vocabulary the product uses, not generic technical words. `IssueInvoice`, not `ProcessBillingRecord`.

## Errors and Validation

- Input validation happens at the edge in FormRequests. Inside the boundary, code works with validated, typed values.
- Domain rules that can fail throw domain exceptions from `app/Exceptions`, rendered to responses in one place.
- Never swallow exceptions. Either handle with a defined fallback or let them propagate with context.
- Every external call has a timeout and a defined failure path.

## Testing

- Pest, with tests in `tests/Feature` and `tests/Unit`.
- Characterization tests are Feature tests that exercise the application through HTTP, console, or job dispatch, the same entry points production uses. They live in `tests/Feature/Characterization/{Slice}/`.
- Unit tests for the refactored structure test actions and domain classes through their public interfaces.
- Mock only at system boundaries: external APIs, clocks, randomness. Never mock your own actions or models. Use fakes Laravel provides (`Http::fake`, `Mail::fake`, `Queue::fake`) at the boundary.
- Cover the empty state, the failure path, and the retry path, not just the happy path.

## Refactoring Rules

- New implementations are built alongside the old ones, then callers switch, then the old code is deleted. Both never stay live past the end of the slice.
- Existing bugs are preserved during a refactor and logged in the specification as follow-up work. Behavior changes never ride along with structural changes.
- Characterization tests pass unchanged before and after the refactor. If one fails, the refactor changed behavior. Stop and find out why.
