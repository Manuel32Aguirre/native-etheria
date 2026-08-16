import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/app_settings_provider.dart';
import '../providers/sentence_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
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

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Añadir frases',
                subtitle: 'Importa texto desde una foto o hasta 5 imágenes.',
              ),
              const SizedBox(height: 20),
              MatteCard(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _takePhoto();
                },
                child: const _SheetChoice(
                  icon: Icons.camera_alt_outlined,
                  title: 'Tomar una foto',
                  subtitle: 'Captura una página o una frase',
                ),
              ),
              const SizedBox(height: 10),
              MatteCard(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImagesFromGallery();
                },
                child: const _SheetChoice(
                  icon: Icons.photo_library_outlined,
                  title: 'Elegir de la galería',
                  subtitle: 'Selecciona hasta 5 imágenes a la vez',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SentenceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppIconContainer(icon: Icons.graphic_eq_rounded, size: 40),
            SizedBox(width: 12),
            Text('Native Etheria'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _selectedTab == 0
            ? FloatingActionButton.extended(
                key: const ValueKey('add'),
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Añadir frases'),
              )
            : const SizedBox.shrink(key: ValueKey('none')),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _selectedTab == 1
            ? const ScheduleScreen(key: ValueKey('schedule'))
            : _PracticeHome(
                key: const ValueKey('practice'),
                provider: provider,
                onStart: () => _startPractice(provider.currentBlock),
              ),
      ),
    );
  }
}

class _PracticeHome extends StatelessWidget {
  final SentenceProvider provider;
  final VoidCallback onStart;

  const _PracticeHome({
    super.key,
    required this.provider,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final mastered = provider.history.where((item) => item.isMastered).length;
    return RefreshIndicator(
      onRefresh: provider.refreshBlock,
      child: ListView(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Hola,', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '¿Listo para recordar?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${provider.currentBlock.length}',
                        label: 'Para practicar',
                        icon: Icons.bolt_rounded,
                        color: AppColors.clay,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '$mastered',
                        label: 'Dominadas',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '${provider.pendingNowCount}',
                        label: 'En espera',
                        icon: Icons.schedule_rounded,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
                if (provider.isLoading) ...[
                  const SizedBox(height: 18),
                  const LinearProgressIndicator(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ],
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 18),
                  StatusBanner(
                    message: provider.errorMessage!,
                    tone: StatusTone.error,
                  ),
                ],
                const SizedBox(height: 28),
                const SectionHeader(
                  title: 'Tu bloque de hoy',
                  subtitle: 'Un grupo breve para practicar con intención.',
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: provider.currentBlock.isEmpty
                      ? const EmptyState(
                          key: ValueKey('empty'),
                          icon: Icons.auto_awesome_outlined,
                          title: 'Todo al día',
                          message: 'No hay frases listas ahora. Añade nuevas o vuelve más tarde.',
                        )
                      : Column(
                          key: const ValueKey('phrases'),
                          children: provider.currentBlock
                              .map(
                                (sentence) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: MatteCard(
                                    child: Row(
                                      children: [
                                        const AppIconContainer(
                                          icon: Icons.format_quote_rounded,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sentence.originalText,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Nivel ${sentence.intervalIndex} · ${formatReviewDate(sentence.nextReviewAt)}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: provider.currentBlock.isEmpty ? null : onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Comenzar práctica'),
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Cola de espera'),
                const SizedBox(height: 12),
                MatteCard(
                  color: AppColors.surfaceMuted,
                  child: Row(
                    children: [
                      const AppIconContainer(
                        icon: Icons.hourglass_bottom_rounded,
                        color: AppColors.clay,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${provider.pendingNowCount} frases esperando',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Entrarán en el próximo bloque disponible.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MatteCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SheetChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconContainer(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}
