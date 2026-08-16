import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/practice_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class PracticeScreen extends StatefulWidget {
  final List<Sentence> block;

  const PracticeScreen({super.key, required this.block});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PracticeProvider>().startSession(widget.block);
    });
  }

  @override
  void dispose() {
    context.read<PracticeProvider>().stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PracticeProvider>();

    if (provider.sessionComplete) {
      return Scaffold(
        body: SafeArea(
          child: ResponsiveContent(
            maxWidth: 520,
            child: Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: .8, end: 1),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: MatteCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIconContainer(
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.success,
                        size: 80,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Sesión completada',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Terminaste el bloque. Cada repetición fortalece tu memoria.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Volver al inicio'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final sentence = provider.currentSentence;
    final feedbackColor = switch (provider.feedback) {
      FeedbackState.success => AppColors.success,
      FeedbackState.error => AppColors.error,
      FeedbackState.none => AppColors.teal,
    };

    return PopScope(
      onPopInvokedWithResult: (_, _) => provider.stopSession(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Práctica guiada'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${provider.correctRepetitions}/${provider.requiredRepetitions}',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: AppColors.teal),
                ),
              ),
            ),
          ],
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          color: feedbackColor.withValues(
            alpha: provider.feedback == FeedbackState.none ? 0 : .08,
          ),
          child: sentence == null
              ? const Center(child: CircularProgressIndicator())
              : ResponsiveContent(
                  maxWidth: 680,
                  child: ListView(
                    children: [
                      LinearProgressIndicator(
                        value:
                            provider.correctRepetitions /
                            provider.requiredRepetitions,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 12),
                      _RepetitionSegments(
                        completed: provider.correctRepetitions,
                        total: provider.requiredRepetitions,
                        isActive: provider.isRecording,
                      ),
                      const SizedBox(height: 24),
                      MatteCard(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AppIconContainer(
                                  icon: Icons.hearing_rounded,
                                  color: AppColors.clay,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Escucha la pregunta',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: provider.isRecording
                                      ? null
                                      : provider.replayQuestionAudio,
                                  icon: const Icon(Icons.volume_up_rounded),
                                  tooltip: 'Escuchar de nuevo',
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              provider.question,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: provider.isAnswerVisible
                                  ? Container(
                                      key: const ValueKey('answer'),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Memoriza y responde en inglés',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: AppColors.teal,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            sentence.originalText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      key: ValueKey(provider.phase),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.ink.withValues(
                                          alpha: .04,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        provider.phase ==
                                                PracticePhase.validating
                                            ? 'Comprobando tu respuesta…'
                                            : provider.isRecording
                                            ? 'La respuesta está oculta mientras te escucho.'
                                            : 'Preparando la siguiente escucha…',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _MicrophoneControl(provider: provider),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: provider.errorMessage != null
                            ? StatusBanner(
                                key: ValueKey(provider.errorMessage),
                                message: provider.errorMessage!,
                                tone: StatusTone.error,
                              )
                            : provider.lastTranscript != null
                            ? StatusBanner(
                                key: ValueKey(provider.lastTranscript),
                                message:
                                    'Escuché: “${provider.lastTranscript}”',
                                tone: provider.feedback == FeedbackState.success
                                    ? StatusTone.success
                                    : StatusTone.error,
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MicrophoneControl extends StatelessWidget {
  final PracticeProvider provider;

  const _MicrophoneControl({required this.provider});

  @override
  Widget build(BuildContext context) {
    final level = ((provider.amplitude + 60) / 60).clamp(0.0, 1.0);
    final isListening = provider.phase == PracticePhase.listening;
    final (label, detail, icon) = switch (provider.phase) {
      PracticePhase.speaking => (
        'Escuchando la pregunta',
        'La respuesta aparecerá antes de activar el micrófono.',
        Icons.volume_up_rounded,
      ),
      PracticePhase.listening => (
        'Te escucho',
        'Habla con naturalidad. Se enviará al detectar silencio.',
        Icons.stop_rounded,
      ),
      PracticePhase.validating => (
        'Validando',
        'Comparando pronunciación y contenido…',
        Icons.more_horiz_rounded,
      ),
      PracticePhase.loading => (
        'Preparando',
        'El micrófono se activa automáticamente.',
        Icons.mic_none_rounded,
      ),
    };

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 140),
          tween: Tween(begin: 0, end: isListening ? level : 0),
          builder: (context, value, child) => Container(
            width: 108 + (value * 26),
            height: 108 + (value * 26),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: .08 + value * .12),
            ),
            child: child,
          ),
          child: GestureDetector(
            onTap: isListening ? provider.stopRecordingManually : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? AppColors.clay : AppColors.teal,
              ),
              child: provider.phase == PracticePhase.validating
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _RepetitionSegments extends StatelessWidget {
  final int completed;
  final int total;
  final bool isActive;

  const _RepetitionSegments({
    required this.completed,
    required this.total,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$completed de $total repeticiones completadas',
      child: Row(
        children: List.generate(total, (index) {
          final isCompleted = index < completed;
          final isCurrent = index == completed && isActive;
          final color = isCompleted
              ? AppColors.success
              : isCurrent
              ? colorScheme.primary
              : colorScheme.outlineVariant;
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: index == total - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
