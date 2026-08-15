import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/sentence_provider.dart';
import '../services/notification_service.dart';
import '../utils/review_date_formatter.dart';

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
          'Seguro que quieres eliminar esta frase? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
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
        padding: const EdgeInsets.all(16),
        children: [
          if (!_notificationsEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: const Text('Reminders are disabled'),
                subtitle: const Text(
                  'Allow notifications to receive a reminder when a phrase is ready.',
                ),
                trailing: FilledButton(
                  onPressed: _enableNotifications,
                  child: const Text('Allow'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Upcoming reminders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (scheduled.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No phrases are scheduled right now.'),
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
          const SizedBox(height: 24),
          Text('Completed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (completed.isEmpty)
            const Text('Completed phrases will appear here.')
          else
            ...completed.map(
              (sentence) => _SentenceRow(
                sentence: sentence,
                subtitle: 'Completed',
                onConfirmDelete: () => _confirmDelete(sentence),
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
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(sentence.isMastered ? Icons.check_circle : Icons.alarm),
          title: Text(sentence.originalText),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
