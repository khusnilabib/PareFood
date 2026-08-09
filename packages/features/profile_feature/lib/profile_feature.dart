/// profile_feature — user profile for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Profile view/edit, edit validation and the profile screen.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/profile_providers.dart';
export 'src/data/profile_repository.dart';
export 'src/data/supabase_profile_repository.dart';
export 'src/domain/profile_use_cases.dart';
export 'src/domain/user_profile.dart';
export 'src/presentation/pages/edit_profile_page.dart';
export 'src/presentation/pages/profile_page.dart';
export 'src/presentation/widgets/edit_profile_form.dart';
export 'src/presentation/widgets/profile_header.dart';
