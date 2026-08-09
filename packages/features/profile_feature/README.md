# profile_feature

User profile for PareFood (PF-DOC-11 §3.1): profile view, edit validation and
the profile screen with four-state handling.

## Layers

- `data/` — `ProfileRepository` contract. Implementations live in the app
  composition root and delegate to `pare_data` (Dio/Supabase, MO-R02a).
- `domain/` — `UserProfile`, `UpdateProfile` use case (validation via
  `pare_util`).
- `application/` — `profileRepositoryProvider`, `profileProvider`,
  `updateProfileProvider`.
- `presentation/` — `ProfilePage` + `ProfileHeader`.

## Boundaries

- Never imports Supabase/Dio SDKs directly (MO-R02a).
- Never depends on another feature package (MO-R02d).
- Presentation never imports `data`; it consumes providers only (PF-DOC-11 §3.1).
