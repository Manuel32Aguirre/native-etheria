import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/sentence_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/review_date_formatter.dart';
import '../widgets/app_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final sentences = context.read<SentenceProvider>();
    await sentences.refreshHistory();
    if (!mounted) return;
    final notifications = context.read<NotificationService>();
    _notificationsEnabled = await notifications.areNotificationsEnabled();
    if (_notificationsEnabled) {
      for (final sentence in sentences.history.where(
        (item) => !item.isMastered,
      )) {
        final at = sentence.nextReviewAt;
        if (at != null) {
          await notifications.scheduleReview(
            id: sentence.id,
            at: at,
            sentence: sentence.originalText,
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _enableNotifications() async {
    final granted = await context
        .read<NotificationService>()
        .requestPermission();
    if (!mounted) return;
    setState(() => _notificationsEnabled = granted);
    if (granted) await _refresh();
  }

  Future<bool> _confirmDelete(Sentence sentence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar frase'),
        content: const Text(
          '¿Seguro que quieres eliminar esta frase? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    final sentences = context.read<SentenceProvider>();
    final notifications = context.read<NotificationService>();
    final deleted = await sentences.deleteSentence(sentence.id);
    if (deleted) {
      await notifications.cancelReview(sentence.id);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sentences.errorMessage ?? 'No se pudo eliminar la frase.',
          ),
        ),
      );
    }
    return deleted;
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SentenceProvider>().history;
    final scheduled = history.where((sentence) => !sentence.isMastered).toList()
      ..sort(
        (a, b) => (a.nextReviewAt ?? DateTime.now()).compareTo(
          b.nextReviewAt ?? DateTime.now(),
        ),
      );
    final completed = history.where((sentence) => sentence.isMastered).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tu programa',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text('Repasos distribuidos para recordar a largo plazo.'),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: !_notificationsEnabled
                      ? StatusBanner(
                          key: const ValueKey('disabled'),
                          message: 'Activa las notificaciones para recibir avisos cuando una frase esté lista.',
                          tone: StatusTone.warning,
                          action: TextButton(
                            onPressed: _enableNotifications,
                            child: const Text('Activar'),
                          ),
                        )
                      : const StatusBanner(
                          key: ValueKey('enabled'),
                          message: 'Los recordatorios están activos.',
                          tone: StatusTone.success,
                        ),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Próximos repasos',
                  subtitle:
                      '${scheduled.length} frase${scheduled.length == 1 ? '' : 's'} programada${scheduled.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 12),
                if (scheduled.isEmpty)
                  const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'Sin repasos pendientes',
                    message: 'Cuando completes una práctica, los próximos repasos aparecerán aquí.',
                  )
                else
                  ...scheduled.map(
                    (sentence) => _SentenceRow(
                      sentence: sentence,
                      subtitle:
                          '${formatReviewDate(sentence.nextReviewAt)} · ${formatTimeUntil(sentence.nextReviewAt)}',
                      onConfirmDelete: () => _confirmDelete(sentence),
                    ),
                  ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Dominadas',
                  subtitle: '${completed.length} frases completadas',
                ),
                const SizedBox(height: 12),
                if (completed.isEmpty)
                  const EmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Tu colección está creciendo',
                    message: 'Las frases dominadas aparecerán aquí como registro de tu avance.',
                  )
                else
                  ...completed.map(
                    (sentence) => _SentenceRow(
                      sentence: sentence,
                      subtitle: 'Completada',
                      onConfirmDelete: () => _confirmDelete(sentence),
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

class _SentenceRow extends StatelessWidget {
  final Sentence sentence;
  final String subtitle;
  final Future<bool> Function() onConfirmDelete;

  const _SentenceRow({
    required this.sentence,
    required this.subtitle,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(sentence.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onConfirmDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: MatteCard(
          child: Row(
            children: [
              AppIconContainer(
                icon: sentence.isMastered
                    ? Icons.check_rounded
                    : Icons.schedule_rounded,
                color: sentence.isMastered ? AppColors.success : AppColors.clay,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sentence.originalText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.drag_handle_rounded, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
