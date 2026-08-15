import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          Text('Práctica', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Repeticiones correctas'),
            subtitle: Text('${settings.requiredRepetitions} por oración'),
            trailing: DropdownButton<int>(
              value: settings.requiredRepetitions,
              items: [5, 10, 15, 20, 30, 50]
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text('$value')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) settings.setRequiredRepetitions(value);
              },
            ),
          ),
          ListTile(
            title: const Text('Voz de síntesis'),
            subtitle: const Text('Se guarda para las próximas sesiones'),
            trailing: DropdownButton<String>(
              value: voices.containsKey(settings.voice)
                  ? settings.voice
                  : 'alloy',
              items: voices.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) settings.setVoice(value);
              },
            ),
          ),
          const Divider(height: 32),
          FilledButton.tonalIcon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
