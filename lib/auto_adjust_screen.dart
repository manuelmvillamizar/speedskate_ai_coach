import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';

enum AutoPhysiologyStatus { green, yellow, orange, red }

enum PlannedTrainingType { speed, endurance, gymStrength, mixed }

class AutoAdjustedSession {
  final String titleEs;
  final String titleEn;
  final String titleDe;
  final List<String> blocksEs;
  final List<String> blocksEn;
  final List<String> blocksDe;
  final int loadReductionPercent;
  final String reasonEs;
  final String reasonEn;
  final String reasonDe;

  AutoAdjustedSession({
    required this.titleEs,
    required this.titleEn,
    required this.titleDe,
    required this.blocksEs,
    required this.blocksEn,
    required this.blocksDe,
    required this.loadReductionPercent,
    required this.reasonEs,
    required this.reasonEn,
    required this.reasonDe,
  });

  String title(AppLanguage lang) => AppText.t(lang, titleEs, titleEn, titleDe);

  String reason(AppLanguage lang) =>
      AppText.t(lang, reasonEs, reasonEn, reasonDe);

  List<String> blocks(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.es:
        return blocksEs;
      case AppLanguage.en:
        return blocksEn;
      case AppLanguage.de:
        return blocksDe;
    }
  }
}

class AutoAdjustScreen extends StatefulWidget {
  const AutoAdjustScreen({super.key});

  @override
  State<AutoAdjustScreen> createState() => _AutoAdjustScreenState();
}

class _AutoAdjustScreenState extends State<AutoAdjustScreen> {
  AutoPhysiologyStatus physiologyStatus = AutoPhysiologyStatus.green;
  PlannedTrainingType plannedType = PlannedTrainingType.speed;
  int plannedLoad = 85;
  int plannedMinutes = 90;
  double plannedKm = 18;

  AutoAdjustedSession? adjusted;

  void generateAdjustment() {
    setState(() {
      adjusted = AutoAdjustEngine.adjust(
        lang: context.read<AppLanguageNotifier>().current,
        physiologyStatus: physiologyStatus,
        plannedType: plannedType,
        plannedLoad: plannedLoad,
        plannedMinutes: plannedMinutes,
        plannedKm: plannedKm,
      );
    });
  }

  String physiologyLabel(AppLanguage lang, AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return AppText.t(
          lang,
          'Verde: adaptación positiva',
          'Green: positive adaptation',
          'Grün: positive Anpassung',
        );
      case AutoPhysiologyStatus.yellow:
        return AppText.t(
          lang,
          'Amarillo: vigilar',
          'Yellow: monitor',
          'Gelb: beobachten',
        );
      case AutoPhysiologyStatus.orange:
        return AppText.t(
          lang,
          'Naranja: fatiga acumulada',
          'Orange: accumulated fatigue',
          'Orange: kumulierte Ermüdung',
        );
      case AutoPhysiologyStatus.red:
        return AppText.t(
          lang,
          'Rojo: riesgo de sobrecarga',
          'Red: overload risk',
          'Rot: �oberlastungsrisiko',
        );
    }
  }

  String trainingTypeLabel(AppLanguage lang, PlannedTrainingType type) {
    switch (type) {
      case PlannedTrainingType.speed:
        return AppText.t(lang, 'Velocidad', 'Speed', 'Geschwindigkeit');
      case PlannedTrainingType.endurance:
        return AppText.t(lang, 'Resistencia', 'Endurance', 'Ausdauer');
      case PlannedTrainingType.gymStrength:
        return AppText.t(
          lang,
          'Gimnasio fuerza',
          'Gym strength',
          'Krafttraining',
        );
      case PlannedTrainingType.mixed:
        return AppText.t(lang, 'Mixto', 'Mixed', 'Gemischt');
    }
  }

  Color statusColor() {
    switch (physiologyStatus) {
      case AutoPhysiologyStatus.green:
        return Colors.green;
      case AutoPhysiologyStatus.yellow:
        return Colors.amber;
      case AutoPhysiologyStatus.orange:
        return Colors.deepOrange;
      case AutoPhysiologyStatus.red:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Auto ajuste inteligente',
              'Smart auto adjustment',
              'Intelligente automatische Anpassung',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'La app ajusta el entrenamiento según la respuesta fisiológica del atleta.',
              'The app adjusts training based on the athlete physiological response.',
              'Die App passt das Training anhand der physiologischen Reaktion des Athleten an.',
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<AutoPhysiologyStatus>(
                    value: physiologyStatus,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Estado fisiológico',
                        'Physiological status',
                        'Physiologischer Status',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: AutoPhysiologyStatus.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(physiologyLabel(lang, e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        physiologyStatus = value!;
                        adjusted = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PlannedTrainingType>(
                    value: plannedType,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Entrenamiento planificado',
                        'Planned training',
                        'Geplantes Training',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: PlannedTrainingType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(trainingTypeLabel(lang, e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        plannedType = value!;
                        adjusted = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  _NumberSlider(
                    label: AppText.t(
                      lang,
                      'Carga planificada',
                      'Planned load',
                      'Geplante Belastung',
                    ),
                    value: plannedLoad,
                    min: 10,
                    max: 100,
                    onChanged: (value) {
                      setState(() {
                        plannedLoad = value;
                        adjusted = null;
                      });
                    },
                  ),
                  _NumberSlider(
                    label: AppText.t(
                      lang,
                      'Minutos planificados',
                      'Planned minutes',
                      'Geplante Minuten',
                    ),
                    value: plannedMinutes,
                    min: 20,
                    max: 180,
                    onChanged: (value) {
                      setState(() {
                        plannedMinutes = value;
                        adjusted = null;
                      });
                    },
                  ),
                  Text(
                    '${AppText.t(lang, 'Kilómetros planificados', 'Planned kilometers', 'Geplante Kilometer')}: ${plannedKm.toStringAsFixed(1)} km',
                  ),
                  Slider(
                    value: plannedKm,
                    min: 0,
                    max: 80,
                    divisions: 80,
                    label: plannedKm.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        plannedKm = value;
                        adjusted = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: generateAdjustment,
            icon: const Icon(Icons.auto_fix_high),
            label: Text(
              AppText.t(
                lang,
                'Generar ajuste',
                'Generate adjustment',
                'Anpassung erstellen',
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (adjusted != null)
            Card(
              color: statusColor().withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adjusted!.title(lang),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        AppText.t(
                          lang,
                          'Reducción: ${adjusted!.loadReductionPercent}%',
                          'Reduction: ${adjusted!.loadReductionPercent}%',
                          'Reduktion: ${adjusted!.loadReductionPercent}%',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      adjusted!.reason(lang),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...adjusted!
                        .blocks(lang)
                        .map(
                          (block) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(block)),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value',
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}

class AutoAdjustEngine {
  static AutoAdjustedSession adjust({
    required AppLanguage lang,
    required AutoPhysiologyStatus physiologyStatus,
    required PlannedTrainingType plannedType,
    required int plannedLoad,
    required int plannedMinutes,
    required double plannedKm,
  }) {
    if (physiologyStatus == AutoPhysiologyStatus.green) {
      return _green(plannedType);
    }

    if (physiologyStatus == AutoPhysiologyStatus.yellow) {
      return _yellow(plannedType);
    }

    if (physiologyStatus == AutoPhysiologyStatus.orange) {
      return _orange(plannedType);
    }

    return _red();
  }

  static AutoAdjustedSession _green(PlannedTrainingType type) {
    return AutoAdjustedSession(
      titleEs: 'Mantener o progresar ligeramente',
      titleEn: 'Maintain or slightly progress',
      titleDe: 'Beibehalten oder leicht steigern',
      loadReductionPercent: 0,
      reasonEs:
          'El estado fisiológico es favorable. El atleta asimiló bien la carga.',
      reasonEn:
          'Physiological status is favorable. The athlete adapted well to the load.',
      reasonDe:
          'Der physiologische Status ist günstig. Der Athlet hat die Belastung gut verarbeitet.',
      blocksEs: [
        'Mantener sesión planificada',
        'Permitir progresión ligera si la técnica es buena',
        'Controlar RPE al final',
      ],
      blocksEn: [
        'Keep the planned session',
        'Allow slight progression if technique is good',
        'Monitor RPE at the end',
      ],
      blocksDe: [
        'Geplante Einheit beibehalten',
        'Leichte Steigerung erlauben, wenn die Technik gut ist',
        'RPE am Ende kontrollieren',
      ],
    );
  }

  static AutoAdjustedSession _yellow(PlannedTrainingType type) {
    return AutoAdjustedSession(
      titleEs: 'Mantener estímulo, sin aumentar carga',
      titleEn: 'Keep stimulus, do not increase load',
      titleDe: 'Reiz beibehalten, Belastung nicht erhöhen',
      loadReductionPercent: 15,
      reasonEs:
          'Hay señales moderadas de carga interna. Conviene controlar volumen e intensidad.',
      reasonEn:
          'There are moderate internal load signals. Volume and intensity should be controlled.',
      reasonDe:
          'Es gibt moderate Zeichen innerer Belastung. Volumen und Intensität sollten kontrolliert werden.',
      blocksEs: [
        'Reducir volumen aproximado 15%',
        'Mantener técnica y calidad',
        'Evitar trabajo extra',
      ],
      blocksEn: [
        'Reduce volume by about 15%',
        'Maintain technique and quality',
        'Avoid extra work',
      ],
      blocksDe: [
        'Volumen um etwa 15% reduzieren',
        'Technik und Qualität beibehalten',
        'Zusatzarbeit vermeiden',
      ],
    );
  }

  static AutoAdjustedSession _orange(PlannedTrainingType type) {
    if (type == PlannedTrainingType.gymStrength) {
      return AutoAdjustedSession(
        titleEs: 'Cambiar fuerza pesada por técnica y movilidad',
        titleEn: 'Replace heavy strength with technique and mobility',
        titleDe: 'Schwere Kraft durch Technik und Mobilität ersetzen',
        loadReductionPercent: 40,
        reasonEs:
            'Fatiga acumulada. No conviene mantener cargas altas de gimnasio.',
        reasonEn: 'Accumulated fatigue. Heavy gym loads are not recommended.',
        reasonDe:
            'Kumulierte Ermüdung. Schwere Kraftbelastungen sind nicht empfohlen.',
        blocksEs: [
          'Movilidad 20-30 min',
          'Core suave',
          'Técnica en seco',
          'Sin cargas máximas',
        ],
        blocksEn: [
          'Mobility 20-30 min',
          'Easy core',
          'Dry-land technique',
          'No maximal loads',
        ],
        blocksDe: [
          'Mobilität 20-30 Min.',
          'Leichter Core',
          'Trockentraining Technik',
          'Keine Maximallasten',
        ],
      );
    }

    return AutoAdjustedSession(
      titleEs: 'Reducir volumen y mantener técnica',
      titleEn: 'Reduce volume and keep technique',
      titleDe: 'Volumen reduzieren und Technik beibehalten',
      loadReductionPercent: 35,
      reasonEs:
          'El cuerpo muestra fatiga acumulada. Conviene bajar carga sin perder estímulo técnico.',
      reasonEn:
          'The body shows accumulated fatigue. Reduce load while keeping technical stimulus.',
      reasonDe:
          'Der Körper zeigt kumulierte Ermüdung. Belastung reduzieren, aber technischen Reiz erhalten.',
      blocksEs: [
        'Reducir volumen 30-40%',
        'Eliminar intensidad máxima',
        'Mantener técnica suave',
        'Agregar recuperación',
      ],
      blocksEn: [
        'Reduce volume 30-40%',
        'Remove maximal intensity',
        'Keep easy technique',
        'Add recovery',
      ],
      blocksDe: [
        'Volumen um 30-40% reduzieren',
        'Maximale Intensität streichen',
        'Leichte Technik beibehalten',
        'Regeneration hinzufügen',
      ],
    );
  }

  static AutoAdjustedSession _red() {
    return AutoAdjustedSession(
      titleEs: 'Reemplazar por recuperación',
      titleEn: 'Replace with recovery',
      titleDe: 'Durch Regeneration ersetzen',
      loadReductionPercent: 70,
      reasonEs:
          'Riesgo alto de sobrecarga. No conviene recuperar carga perdida ni hacer intensidad.',
      reasonEn:
          'High overload risk. Do not recover missed load and do not perform intensity.',
      reasonDe:
          'Hohes �oberlastungsrisiko. Keine verpasste Belastung nachholen und keine Intensität durchführen.',
      blocksEs: [
        'Movilidad 20 min',
        'Bicicleta muy suave 20-30 min opcional',
        'Respiración y recuperación',
        'Revisar sueño, dolor y fatiga',
      ],
      blocksEn: [
        'Mobility 20 min',
        'Very easy bike 20-30 min optional',
        'Breathing and recovery',
        'Review sleep, pain and fatigue',
      ],
      blocksDe: [
        'Mobilität 20 Min.',
        'Sehr lockeres Radfahren 20-30 Min. optional',
        'Atmung und Regeneration',
        'Schlaf, Schmerz und Ermüdung prüfen',
      ],
    );
  }
}


