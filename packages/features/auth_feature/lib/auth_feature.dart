/// auth_feature — authentication for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Sign-in/sign-up forms, the session stream and auth-gated navigation state.
/// Layers: `data` defines the [AuthRepository] contract implemented in the
/// composition root on top of `pare_data` (Supabase sessions, MO-R02a);
/// `domain` holds the pure use cases; `application` owns the providers;
/// `presentation` is the UI.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/auth_providers.dart';
export 'src/data/auth_repository.dart';
export 'src/data/supabase_auth_repository.dart';
export 'src/domain/auth_session.dart';
export 'src/domain/auth_use_cases.dart';
export 'src/presentation/pages/forgot_password_page.dart';
export 'src/presentation/pages/register_page.dart';
export 'src/presentation/pages/sign_in_page.dart';
export 'src/presentation/widgets/forgot_password_form.dart';
export 'src/presentation/widgets/phone_sign_in_form.dart';
export 'src/presentation/widgets/register_form.dart';
export 'src/presentation/widgets/role_switcher.dart';
export 'src/presentation/widgets/sign_in_form.dart';
