import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/practice_provider.dart';
import 'providers/sentence_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/audio_player_service.dart';
import 'services/audio_recorder_service.dart';
import 'services/auth_service.dart';
import 'services/practice_service.dart';
import 'services/sentence_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

void main() {
  runApp(const NativeApp());
}

class NativeApp extends StatelessWidget {
  const NativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final notificationService = NotificationService()..initialize();

    return MultiProvider(
      providers: [
        Provider(create: (_) => apiClient),
        Provider(create: (_) => AuthService(apiClient)),
        Provider(create: (_) => SentenceService(apiClient)),
        Provider(create: (_) => SettingsService(apiClient)),
        Provider(create: (_) => PracticeService(apiClient)),
        Provider(create: (_) => AudioRecorderService()),
        Provider(create: (_) => AudioPlayerService()),
        Provider.value(value: notificationService),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              AppSettingsProvider(ctx.read<SettingsService>())..load(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SentenceProvider(ctx.read<SentenceService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PracticeProvider(
            practiceService: ctx.read<PracticeService>(),
            sentenceService: ctx.read<SentenceService>(),
            recorderService: ctx.read<AudioRecorderService>(),
            playerService: ctx.read<AudioPlayerService>(),
            settingsProvider: ctx.read<AppSettingsProvider>(),
            notificationService: ctx.read<NotificationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Native – Memorización Activa',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0E7490),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F7F8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4F7F8),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              side: BorderSide(color: Color(0xFFDCE7EA)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
