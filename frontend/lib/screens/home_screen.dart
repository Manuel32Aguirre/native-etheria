import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/app_settings_provider.dart';
import '../providers/sentence_provider.dart';
import 'practice_screen.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import '../utils/review_date_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SentenceProvider>().refreshBlock();
      context.read<SentenceProvider>().refreshHistory();
      context.read<AppSettingsProvider>().loadFromServer();
    });
  }

  Future<void> _extractImages(List<XFile> files) async {
    if (files.isEmpty) return;
    final bytes = await Future.wait(
      files.take(5).map((file) => File(file.path).readAsBytes()),
    );
    if (!mounted) return;
    final sentenceProvider = context.read<SentenceProvider>();
    final createdCount = await sentenceProvider.extractFromImageBytesBatch(
      bytes,
    );
    if (!mounted) return;
    if (createdCount == null) {
      final error = sentenceProvider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Error al procesar la imagen')),
      );
      return;
    }
    final message = createdCount == 0
        ? 'No se agregaron frases nuevas. Las frases repetidas se omitieron.'
        : '$createdCount frase${createdCount == 1 ? '' : 's'} nueva${createdCount == 1 ? '' : 's'} agregada${createdCount == 1 ? '' : 's'}.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) await _extractImages([picked]);
  }

  Future<void> _pickImagesFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, limit: 5);
    await _extractImages(picked);
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
      appBar: AppBar(
        title: Text(
          _selectedTab == 0 ? 'Native – Memorización Activa' : 'Programa',
        ),
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
        onPressed: _selectedTab == 0
            ? () => showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Tomar foto'),
                        onTap: () {
                          Navigator.pop(context);
                          _takePhoto();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Elegir hasta 5 imágenes'),
                        subtitle: const Text(
                          'Puedes seleccionar varias capturas a la vez',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImagesFromGallery();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null,
        child: const Icon(Icons.add_a_photo),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Práctica',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Programa',
          ),
        ],
      ),
      body: _selectedTab == 1
          ? const ScheduleScreen()
          : RefreshIndicator(
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
                                  'Intervalo #${s.intervalIndex} · Próximo repaso: ${formatReviewDate(s.nextReviewAt)}',
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
}
