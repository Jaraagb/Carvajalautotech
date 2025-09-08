// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'core/theme/app_theme.dart';
// import 'core/navigation/app_router.dart';
// import 'core/constants/app_constants.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Cargar variables de entorno
//   await dotenv.load(fileName: ".env");

//   // Inicializar Supabase
//   await Supabase.initialize(
//     url: dotenv.env['SUPABASE_URL']!,
//     anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
//   );

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: AppConstants.appName,
//       theme: AppTheme.darkTheme,
//       onGenerateRoute: AppRouter.generateRoute,
//       initialRoute: AppConstants.splashRoute,
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Log: Iniciando carga de variables de entorno
    debugPrint('🔄 Cargando variables de entorno...');
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Variables de entorno cargadas exitosamente');

    // Log: Verificar que las variables existen
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    debugPrint(
        '🔍 SUPABASE_URL: ${supabaseUrl != null ? '✅ Cargada' : '❌ No encontrada'}');
    debugPrint(
        '🔍 SUPABASE_ANON_KEY: ${supabaseKey != null ? '✅ Cargada' : '❌ No encontrada'}');

    if (supabaseUrl == null || supabaseKey == null) {
      debugPrint('❌ Error: Variables de entorno de Supabase no encontradas');
      return;
    }

    // Log: Iniciando conexión con Supabase
    debugPrint('🔄 Inicializando conexión con Supabase...');
    debugPrint('📍 URL: $supabaseUrl');
    debugPrint('🔑 Key: ${supabaseKey.substring(0, 20)}...');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: kDebugMode, // Habilita logs de debug de Supabase
    );

    debugPrint('✅ Supabase inicializado correctamente');

    // Log: Verificar conexión
    await _testSupabaseConnection();
  } catch (e, stackTrace) {
    debugPrint('❌ Error durante la inicialización: $e');
    debugPrint('📋 Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

// Función para probar la conexión
Future<void> _testSupabaseConnection() async {
  try {
    debugPrint('🔄 Probando conexión con Supabase...');

    final client = Supabase.instance.client;

    // Test básico - obtener información del usuario actual (será null si no está autenticado)
    final user = client.auth.currentUser;
    debugPrint('👤 Usuario actual: ${user?.email ?? 'No autenticado'}');

    // Test de conectividad - hacer una consulta simple
    // Nota: Esto fallará si no tienes una tabla llamada 'test', pero nos dará info sobre la conexión
    try {
      final response = await client
          .from('usuarios') // Cambia por una tabla que exista en tu BD
          .select('count(*)')
          .limit(1);

      debugPrint('✅ Conexión con base de datos exitosa');
      debugPrint('📊 Respuesta: $response');
    } catch (dbError) {
      debugPrint('⚠️  Conexión establecida pero error en consulta: $dbError');
      debugPrint('💡 Esto es normal si la tabla no existe aún');
    }

    debugPrint('🎉 Test de conexión completado');
  } catch (e) {
    debugPrint('❌ Error al probar conexión: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️  Construyendo MyApp...');
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppConstants.splashRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
