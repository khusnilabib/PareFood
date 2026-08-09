# auth_feature

Authentication for PareFood (PF-DOC-11 §3.1): sign-in/sign-up, session stream
and auth-gated navigation state.

## Layers

- `data/` — `AuthRepository` contract. Concrete implementations live in the app
  composition root and delegate to `pare_data` (Supabase sessions, MO-R02a).
- `domain/` — `AuthSession` + `SignInWithEmail` use case (pure Dart).
- `application/` — `authRepositoryProvider`, `authSessionProvider`,
  `signInUseCaseProvider` (Riverpod).
- `presentation/` — `SignInPage` + `SignInForm`.

## Boundaries

- Never imports Supabase/Dio SDKs directly (MO-R02a).
- Never depends on another feature package (MO-R02d).
- Presentation never imports `data`; it consumes providers only (PF-DOC-11 §3.1).
