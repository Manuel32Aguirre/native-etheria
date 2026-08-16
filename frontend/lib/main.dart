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
import 'theme/app_theme.dart';

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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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
      return Scaffold(
        body: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: SizedBox(
                    width: 74,
                    height: 74,
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                SizedBox(height: 22),
                Text(
                  'Native Etheria',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text('Restaurando tu espacio de práctica…'),
                SizedBox(height: 24),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
