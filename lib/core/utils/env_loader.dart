import 'dart:io';

class EnvLoader {
  static String get supabaseUrl {
    return const String.fromEnvironment('SUPABASE_URL', defaultValue: '')
            .isNotEmpty
        ? const String.fromEnvironment('SUPABASE_URL')
        : Platform.environment['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    return const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '')
            .isNotEmpty
        ? const String.fromEnvironment('SUPABASE_ANON_KEY')
        : Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  }
}
