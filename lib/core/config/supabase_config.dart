import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'TU_SUPABASE_URL_AQUI';
  static const String anonKey = 'TU_SUPABASE_ANON_KEY_AQUI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
