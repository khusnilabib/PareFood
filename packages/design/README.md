# pare_design

PareFood design system (PF-DOC-16): Material 3 tokens, `AppTheme` light/dark and
the shared `Pf*` widget library.

## Owns

- Tokens — colour (`PfColors`), spacing (`PfSpacing`), shape (`PfRadius`),
  motion (`PfMotion`), typography (`PfTypography`).
- `AppTheme.light()` / `AppTheme.dark()` built purely from tokens (DS-R02).
- Widgets — `PfButton`, `PfStatusBadge`, `PfSkeleton`, `PfEmptyState`,
  `PfErrorState` (the four-state set for FL-R07).

## Rules

- No hard-coded colours in widgets (DS-R01); status colour + icon + text always
  rendered together (DS-R03).
- User-facing strings come from callers (ARB, DS-R05).

## Boundaries

- No business logic, no networking.
- Depends on `pare_core` (exceptions) and `pare_util`.

## Tests

`flutter test` — token contrast (WCAG, NFR-030) and widget smoke tests.
