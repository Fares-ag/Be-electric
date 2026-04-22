// Supabase configuration for q-auto CMMS project.
// Values come from AppConfig (--dart-define or defaults) so production
// can override without hardcoding secrets in source.

import 'app_config.dart';

class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL (from AppConfig / SUPABASE_URL)
  static String get projectUrl => AppConfig.supabaseUrl;

  /// Supabase publishable/anon key (from AppConfig / SUPABASE_ANON_KEY)
  static String get publishableKey => AppConfig.supabaseAnonKey;

  /// Supabase anon key (same as publishable key for client-side)
  static String get anonKey => AppConfig.supabaseAnonKey;
}



