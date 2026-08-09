/// pare_data — data and infrastructure layer for PareFood.
///
/// ## Responsibility (PF-DOC-10 §3.2 / PF-DOC-11 §3.5)
/// Runtime environment config, Supabase client bootstrap, Dio networking with
/// PareFood defaults, and the mapper from raw SDK errors to the typed
/// `pare_core` exception hierarchy.
///
/// ## Boundaries — must NOT
/// - Contain widgets or any business decision.
/// - Know about feature packages or apps.
///
/// ## Consumers
/// Feature repositories and the app composition roots.
library;

export 'src/config/app_config.dart';
export 'src/data_sources.dart';
export 'src/networking/dio_factory.dart';
export 'src/networking/exception_mapper.dart';
export 'src/supabase/supabase_bootstrap.dart';
