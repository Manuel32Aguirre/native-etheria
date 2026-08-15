import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/sentence_provider.dart';
import 'practice_screen.dart';
import 'settings_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SentenceProvider>().refreshBlock();
      context.read<SentenceProvider>().refreshHistory();
    });
  }

  Future<void> _pickImageAndExtract(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    if (!mounted) return;
    final sentenceProvider = context.read<SentenceProvider>();
    final ok = await sentenceProvider.extractFromImageBytes(bytes);
    if (!mounted) return;
    if (!ok) {
      final error = sentenceProvider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Error al procesar la imagen')),
      );
    }
  }

  void _startPractice(List<Sentence> block) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PracticeScreen(block: block)))
        .then((_) {
          if (!mounted) return;
          context.read<SentenceProvider>().refreshBlock();
        });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SentenceProvider>();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.menu_book, size: 42),
                    SizedBox(height: 12),
                    Text('Mi progreso', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
              ...provider.history.map(
                (sentence) => ListTile(
                  leading: Icon(
                    sentence.isMastered ? Icons.check_circle : Icons.schedule,
                    color: sentence.isMastered ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    sentence.originalText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    sentence.isMastered
                        ? 'Dominada'
                        : 'Intervalo ${sentence.intervalIndex} · ${_intervalLabel(sentence.intervalIndex)}\n'
                              'Próximo repaso: ${_formatReviewDate(sentence.nextReviewAt)}',
                  ),
                ),
              ),
              if (provider.history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Todavía no hay frases en tu historial.'),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () => context.read<AuthProvider>().logout(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Native – Memorización Activa'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageAndExtract(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Elegir de la galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageAndExtract(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
        child: const Icon(Icons.add_a_photo),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshBlock,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.isLoading) const LinearProgressIndicator(),
            if (provider.errorMessage != null)
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            Text(
              'Bloque Actual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (provider.currentBlock.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No hay oraciones listas para practicar en este momento.',
                ),
              )
            else
              Card(
                child: Column(
                  children: provider.currentBlock
                      .map(
                        (s) => ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(s.originalText),
                          subtitle: Text(
                            'Intervalo #${s.intervalIndex} · Próximo repaso: ${_formatReviewDate(s.nextReviewAt)}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: provider.currentBlock.isEmpty
                  ? null
                  : () => _startPractice(provider.currentBlock),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar sesión de práctica'),
            ),
            const SizedBox(height: 24),
            Text(
              'Cola de Espera',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.hourglass_bottom),
                title: Text(
                  '${provider.pendingNowCount} oraciones en espera (PENDING_NOW)',
                ),
                subtitle: const Text(
                  'Se procesarán en el próximo bloque disponible.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _intervalLabel(int index) {
    const labels = [
      '3 horas',
      '12 horas',
      '1 día',
      '3 días',
      '1 semana',
      '2 semanas',
      '1 mes',
    ];
    return index < labels.length ? labels[index] : 'Completado';
  }

  String _formatReviewDate(DateTime? value) {
    if (value == null) return 'sin programar';
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}'
        ':'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
