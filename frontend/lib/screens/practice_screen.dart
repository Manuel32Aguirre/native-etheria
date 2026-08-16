import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../providers/practice_provider.dart';

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
        appBar: AppBar(title: const Text('Sesión completada')),
        body: const Center(
          child: Text(
            '¡Completaste el bloque actual! 🎉',
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    final sentence = provider.currentSentence;
    final feedbackColor = switch (provider.feedback) {
      FeedbackState.success => Colors.green,
      FeedbackState.error => Colors.red,
      FeedbackState.none => Theme.of(context).colorScheme.surface,
    };

    return PopScope(
      onPopInvokedWithResult: (_, _) => provider.stopSession(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Práctica')),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: feedbackColor.withValues(alpha: 0.15),
          padding: const EdgeInsets.all(24),
          child: sentence == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value:
                          provider.correctRepetitions /
                          provider.requiredRepetitions,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.correctRepetitions}/${provider.requiredRepetitions}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _RepetitionSegments(
                      completed: provider.correctRepetitions,
                      total: provider.requiredRepetitions,
                      isActive: provider.isRecording,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pregunta:',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.question,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: provider.isRecording
                          ? null
                          : provider.replayQuestionAudio,
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'Escuchar de nuevo',
                    ),
                    const SizedBox(height: 16),
                    if (provider.isAnswerVisible) ...[
                      Text(
                        'Memoriza y responde:',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sentence.originalText,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ] else if (provider.phase == PracticePhase.validating)
                      const Center(child: CircularProgressIndicator())
                    else
                      Text(
                        provider.isRecording
                            ? 'Responde en inglés'
                            : 'Preparando audio...',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    const Spacer(),
                    if (provider.lastTranscript != null)
                      Text(
                        'Escuché: "${provider.lastTranscript}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: feedbackColor),
                      ),
                    const SizedBox(height: 16),
                    if (provider.isRecording)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: ((provider.amplitude + 60) / 60).clamp(0, 1),
                            minHeight: 6,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: provider.stopRecordingManually,
                            child: const CircleAvatar(
                              radius: 34,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Toca para detener o espera al silencio'),
                        ],
                      )
                    else
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              provider.phase == PracticePhase.speaking
                              ? Colors.blueAccent
                              : Colors.grey,
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      provider.isRecording
                          ? 'Habla con naturalidad; se enviará al detectar silencio'
                          : 'El micrófono se activa automáticamente',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
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
              ? Colors.green
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
