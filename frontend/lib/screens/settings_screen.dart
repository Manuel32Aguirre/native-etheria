import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const voices = <String, String>{
    'alloy': 'Alloy',
    'echo': 'Echo',
    'fable': 'Fable',
    'onyx': 'Onyx',
    'nova': 'Nova',
    'shimmer': 'Shimmer',
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          ResponsiveContent(
            maxWidth: 680,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MatteCard(
                  color: AppColors.surfaceMuted,
                  child: Row(
                    children: [
                      const AppIconContainer(
                        icon: Icons.person_outline_rounded,
                        size: 56,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu espacio de aprendizaje',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text('Native Etheria · Memorización activa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  title: 'Práctica',
                  subtitle:
                      'Ajusta el ritmo de las sesiones a tu forma de aprender.',
                ),
                const SizedBox(height: 12),
                MatteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppIconContainer(
                            icon: Icons.repeat_rounded,
                            color: AppColors.clay,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Repeticiones correctas',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  '${settings.requiredRepetitions} por frase',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [5, 10, 15, 20, 30, 50]
                            .map(
                              (value) => ChoiceChip(
                                label: Text('$value'),
                                selected: settings.requiredRepetitions == value,
                                onSelected: (_) =>
                                    settings.setRequiredRepetitions(value),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Más repeticiones refuerzan la memoria, pero alargan cada bloque.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MatteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppIconContainer(
                            icon: Icons.record_voice_over_outlined,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voz de síntesis',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const Text('La escucharás en las preguntas'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownMenu<String>(
                        initialSelection: voices.containsKey(settings.voice)
                            ? settings.voice
                            : 'alloy',
                        expandedInsets: EdgeInsets.zero,
                        label: const Text('Selecciona una voz'),
                        leadingIcon: const Icon(
                          Icons.spatial_audio_off_rounded,
                        ),
                        dropdownMenuEntries: voices.entries
                            .map(
                              (entry) => DropdownMenuEntry(
                                value: entry.key,
                                label: entry.value,
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          if (value != null) settings.setVoice(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'El cambio se aplica en la próxima reproducción y se sincroniza con tu cuenta.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  title: 'Cuenta',
                  subtitle: 'Gestiona tu sesión en este dispositivo.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Native Etheria · Aprende una frase a la vez',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
