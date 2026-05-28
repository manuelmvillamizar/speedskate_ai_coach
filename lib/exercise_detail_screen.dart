import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'exercise_model.dart';

class ExerciseDetailScreenPro extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreenPro({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreenPro> createState() =>
      _ExerciseDetailScreenProState();
}

class _ExerciseDetailScreenProState extends State<ExerciseDetailScreenPro> {
  VideoPlayerController? videoController;
  bool videoReady = false;

  @override
  void initState() {
    super.initState();

    if (widget.exercise.videoPath != null &&
        widget.exercise.videoPath!.isNotEmpty) {
      videoController = VideoPlayerController.asset(widget.exercise.videoPath!)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            videoReady = true;
          });
        });
    }
  }

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }

  String categoryLabel(AppLanguage lang, ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return AppText.t(lang, 'Fuerza', 'Strength', 'Kraft');
      case ExerciseCategory.machine:
        return AppText.t(lang, 'Máquina', 'Machine', 'Maschine');
      case ExerciseCategory.olympic:
        return AppText.t(lang, 'Olímpico', 'Olympic', 'Olympisch');
      case ExerciseCategory.plyometric:
        return AppText.t(lang, 'Pliometría', 'Plyometric', 'Plyometrie');
      case ExerciseCategory.core:
        return AppText.t(lang, 'Core', 'Core', 'Core');
      case ExerciseCategory.mobility:
        return AppText.t(lang, 'Movilidad', 'Mobility', 'Mobilität');
    }
  }

  List<String> techniqueSteps(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.es:
        return widget.exercise.techniqueStepsEs;
      case AppLanguage.en:
        return widget.exercise.techniqueStepsEn;
      case AppLanguage.de:
        return widget.exercise.techniqueStepsDe;
    }
  }

  List<String> commonMistakes(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.es:
        return widget.exercise.commonMistakesEs;
      case AppLanguage.en:
        return widget.exercise.commonMistakesEn;
      case AppLanguage.de:
        return widget.exercise.commonMistakesDe;
    }
  }

  String skatingTransfer(AppLanguage lang) {
    return AppText.t(
      lang,
      widget.exercise.skatingTransferEs,
      widget.exercise.skatingTransferEn,
      widget.exercise.skatingTransferDe,
    );
  }

  String description(AppLanguage lang) {
    return AppText.t(
      lang,
      widget.exercise.descriptionEs,
      widget.exercise.descriptionEn,
      widget.exercise.descriptionDe,
    );
  }

  int technicalScore() {
    int score = 70;

    if (widget.exercise.category == ExerciseCategory.olympic) score += 10;
    if (widget.exercise.category == ExerciseCategory.plyometric) score += 8;
    if (widget.exercise.category == ExerciseCategory.core) score += 6;
    if (widget.exercise.skatingTransferEs.isNotEmpty) score += 8;
    if (widget.exercise.techniqueStepsEs.length >= 3) score += 4;

    if (score > 100) return 100;
    return score;
  }

  Color scoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final score = technicalScore();

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              widget.exercise.imagePath,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 240,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 80),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(categoryLabel(lang, widget.exercise.category))),
              Chip(label: Text(widget.exercise.level)),
              Chip(label: Text(widget.exercise.equipment)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: scoreColor(score).withOpacity(0.12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scoreColor(score),
                child: Text(
                  '$score',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                AppText.t(
                  lang,
                  'Score técnico IA',
                  'AI technical score',
                  'KI-Technikscore',
                ),
              ),
              subtitle: Text(
                AppText.t(
                  lang,
                  'Valoración de transferencia, complejidad y utilidad para patinaje.',
                  'Assessment of transfer, complexity and usefulness for skating.',
                  'Bewertung von Transfer, Komplexität und Nutzen für Skating.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: AppText.t(
              lang,
              'Descripción',
              'Description',
              'Beschreibung',
            ),
            child: Text(description(lang)),
          ),
          _InfoCard(
            title: AppText.t(lang, 'Músculos', 'Muscles', 'Muskeln'),
            child: Text(widget.exercise.muscles),
          ),
          if (widget.exercise.gifPath != null &&
              widget.exercise.gifPath!.isNotEmpty)
            _InfoCard(
              title: AppText.t(
                lang,
                'GIF técnico',
                'Technical GIF',
                'Technik-GIF',
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  widget.exercise.gifPath!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.gif_box, size: 70),
                  ),
                ),
              ),
            ),
          if (videoController != null)
            _InfoCard(
              title: AppText.t(
                lang,
                'Video técnico',
                'Technical video',
                'Technikvideo',
              ),
              child: videoReady
                  ? Column(
                      children: [
                        AspectRatio(
                          aspectRatio: videoController!.value.aspectRatio,
                          child: VideoPlayer(videoController!),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              if (videoController!.value.isPlaying) {
                                videoController!.pause();
                              } else {
                                videoController!.play();
                              }
                            });
                          },
                          icon: Icon(
                            videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            videoController!.value.isPlaying
                                ? AppText.t(
                                    lang,
                                    'Pausar',
                                    'Pause',
                                    'Pausieren',
                                  )
                                : AppText.t(
                                    lang,
                                    'Reproducir',
                                    'Play',
                                    'Abspielen',
                                  ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          _ListCard(
            title: AppText.t(
              lang,
              'Pasos técnicos',
              'Technical steps',
              'Technische Schritte',
            ),
            items: techniqueSteps(lang),
            emptyText: AppText.t(
              lang,
              'Aún no hay pasos técnicos cargados.',
              'No technical steps loaded yet.',
              'Noch keine technischen Schritte geladen.',
            ),
            icon: Icons.check_circle_outline,
          ),
          _ListCard(
            title: AppText.t(
              lang,
              'Errores comunes',
              'Common mistakes',
              'Häufige Fehler',
            ),
            items: commonMistakes(lang),
            emptyText: AppText.t(
              lang,
              'Aún no hay errores comunes cargados.',
              'No common mistakes loaded yet.',
              'Noch keine häufigen Fehler geladen.',
            ),
            icon: Icons.warning_amber,
          ),
          _InfoCard(
            title: AppText.t(
              lang,
              'Transferencia al patinaje',
              'Skating transfer',
              'Transfer zum Skating',
            ),
            child: Text(
              skatingTransfer(lang).isEmpty
                  ? AppText.t(
                      lang,
                      'Transferencia pendiente de completar.',
                      'Transfer pending completion.',
                      'Transfer muss noch ergänzt werden.',
                    )
                  : skatingTransfer(lang),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final String emptyText;
  final IconData icon;

  const _ListCard({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: title,
      child: items.isEmpty
          ? Text(emptyText)
          : Column(
              children: items
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${entry.key + 1}. ${entry.value}'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}


