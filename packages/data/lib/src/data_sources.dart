/// Supabase-backed data source layer (PF-DOC-11 §3.3).
///
/// These are feature-agnostic: they know nothing about feature packages or
/// their contracts (PF-DOC-10 §3.2 `data` → `core`/`util` only). Feature
/// repositories adapt these sources to their own contracts in the composition
/// root or a default feature-local implementation.
///
/// ## Boundaries — must NOT
/// - Import any feature package or expose feature contracts.
/// - Make business decisions; mapping to domain models happens one layer up.
library;

export 'data_sources/auth_data_source.dart';
export 'data_sources/catalog_data_source.dart';
export 'data_sources/dto/auth_dto.dart';
export 'data_sources/dto/catalog_dto.dart';
export 'data_sources/dto/profile_dto.dart';
export 'data_sources/profile_data_source.dart';
