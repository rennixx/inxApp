import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/performance/memory_manager.dart';
import 'core/performance/battery_optimizer.dart';
import 'core/performance/performance_monitor.dart';
import 'core/performance/power_profile_manager.dart';
import 'core/performance/dynamic_memory_manager.dart';
import 'core/performance/background_processing_manager.dart';
import 'core/config/api_config.dart';
import 'core/utils/logger.dart';
import 'data/services/translation_pipeline_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance managers
  await _initializeServices();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Initialize all services
Future<void> _initializeServices() async {
  // Initialize memory management
  MemoryManager().initialize();

  // Initialize battery optimizer
  BatteryOptimizer().startIdleDetection();

  // Initialize performance monitoring
  PerformanceMonitor().startMonitoring();

  // Initialize power profile manager (auto-switches based on battery)
  PowerProfileManager();

  // Initialize dynamic memory manager
  DynamicMemoryManager();

  // Initialize background processing manager
  BackgroundProcessingManager().initialize();

  // Initialize translation pipeline if API key is stored
  final apiKey = await ApiConfig.getGeminiApiKey();
  if (apiKey != null && apiKey.isNotEmpty) {
    try {
      await TranslationPipelineService.initialize(geminiApiKey: apiKey);
      AppLogger.info('Translation pipeline initialized with stored API key', tag: 'Main');
    } catch (e) {
      AppLogger.error('Failed to initialize translation pipeline', error: e, tag: 'Main');
    }
  } else {
    AppLogger.info('No API key found - translation features disabled', tag: 'Main');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
