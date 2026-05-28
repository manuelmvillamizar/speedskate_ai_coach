import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'auto_adjust_screen.dart';
import 'global_state.dart';
import 'periodization_engine.dart';
import 'training_library/training_library_models.dart';
import 'training_system/microcycle/weekly_microcycle_builder.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen> {
  PeriodizationAthleteType type = PeriodizationAthleteType.sprinter;
  PeriodizationLevel level = PeriodizationLevel.competitive;
  PeriodizationFocus focus = PeriodizationFocus.specific;

  AutoPhysiologyStatus manualFatigue = AutoPhysiologyStatus.green;
  bool useGlobalFatigue = true;

  WeeklyMicrocyclePlan? intelligentPlan;

  void generateWeek(GlobalTrainingState globalState) {
    final fatigue = useGlobalFatigue
        ? globalState.physiologyStatus
        : manualFatigue;

    final readiness = _readinessFromFatigue(fatigue);
    final acwr = _acwrFromFatigue(fatigue);
    final taperPhase = focus == PeriodizationFocus.competition;

    setState(() {
      intelligentPlan = WeeklyMicrocycleBuilder.build(
        modality: _modalityFromType(type),
        readiness: readiness,
        acwr: acwr,
        taperPhase: taperPhase,
        trainingDays: _trainingDaysFromLevel(level),
      );
    });
  }

  TrainingLibraryModality _modalityFromType(PeriodizationAthleteType value) {
    switch (value) {
      case PeriodizationAthleteType.sprinter:
        return TrainingLibraryModality.sprinter;
      case PeriodizationAthleteType.endurance:
        return TrainingLibraryModality.endurance;
      case PeriodizationAthleteType.mixed:
        return TrainingLibraryModality.mixed;
    }
  }

  double _readinessFromFatigue(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 0.85;
      case AutoPhysiologyStatus.yellow:
        return 0.68;
      case AutoPhysiologyStatus.orange:
        return 0.48;
      case AutoPhysiologyStatus.red:
        return 0.30;
    }
  }

  double _acwrFromFatigue(AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return 1.00;
      case AutoPhysiologyStatus.yellow:
        return 1.25;
      case AutoPhysiologyStatus.orange:
        return 1.45;
      case AutoPhysiologyStatus.red:
        return 1.65;
    }
  }

  int _trainingDaysFromLevel(PeriodizationLevel value) {
    switch (value) {
      case PeriodizationLevel.beginner:
        return 4;
      case PeriodizationLevel.competitive:
        return 6;
      case PeriodizationLevel.elite:
        return 6;
    }
  }

  String typeLabel(AppLanguage lang, PeriodizationAthleteType value) {
    switch (value) {
      case PeriodizationAthleteType.sprinter:
        return AppText.t(lang, 'Velocista', 'Sprinter', 'Sprinter');
      case PeriodizationAthleteType.endurance:
        return AppText.t(
          lang,
          'Fondista',
          'Endurance skater',
          'Ausdauerskater',
        );
      case PeriodizationAthleteType.mixed:
        return AppText.t(
          lang,
          'Mixto / europeo',
          'Mixed / European',
          'Gemischt / europäisch',
        );
    }
  }

  String levelLabel(AppLanguage lang, PeriodizationLevel value) {
    switch (value) {
      case PeriodizationLevel.beginner:
        return AppText.t(lang, 'Novato', 'Beginner', 'Anfänger');
      case PeriodizationLevel.competitive:
        return AppText.t(lang, 'Competitivo', 'Competitive', 'Wettkampf');
      case PeriodizationLevel.elite:
        return AppText.t(lang, 'Elite', 'Elite', 'Elite');
    }
  }

  String focusLabel(AppLanguage lang, PeriodizationFocus value) {
    switch (value) {
      case PeriodizationFocus.base:
        return AppText.t(lang, 'Base', 'Base', 'Basis');
      case PeriodizationFocus.specific:
        return AppText.t(lang, 'Específica', 'Specific', 'Spezifisch');
      case PeriodizationFocus.competition:
        return AppText.t(
          lang,
          'Competencia / taper',
          'Competition / taper',
          'Wettkampf / Taper',
        );
      case PeriodizationFocus.recovery:
        return AppText.t(lang, 'Recuperación', 'Recovery', 'Regeneration');
    }
  }

  String fatigueLabel(AppLanguage lang, AutoPhysiologyStatus status) {
    switch (status) {
      case AutoPhysiologyStatus.green:
        return AppText.t(lang, 'Verde', 'Green', 'Grün');
      case AutoPhysiologyStatus.yellow:
        return AppText.t(lang, 'Amarillo', 'Yellow', 'Gelb');
      case AutoPhysiologyStatus.orange:
        return AppText.t(lang, 'Naranja', 'Orange', 'Orange');
      case AutoPhysiologyStatus.red:
        return AppText.t(lang, 'Rojo', 'Red', 'Rot');
    }
  }

  Color fatigueColor(AutoPhysiologyStatus status) {
    switch (status) {
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

  Color sessionColor(TrainingSessionTemplate session) {
    if (session.recoverySession) return Colors.green;
    if (session.category == TrainingLibraryCategory.lactate)
      return Colors.deepOrange;
    if (session.category == TrainingLibraryCategory.speed ||
        session.category == TrainingLibraryCategory.acceleration ||
        session.category == TrainingLibraryCategory.maxVelocity) {
      return Colors.blue;
    }
    if (session.category == TrainingLibraryCategory.strength ||
        session.category == TrainingLibraryCategory.power ||
        session.category == TrainingLibraryCategory.plyometric) {
      return Colors.purple;
    }
    if (session.category == TrainingLibraryCategory.endurance ||
        session.category == TrainingLibraryCategory.tempo) {
      return Colors.teal;
    }
    if (session.category == TrainingLibraryCategory.tactical)
      return Colors.orange;
    return Colors.blueGrey;
  }

  IconData sessionIcon(TrainingSessionTemplate session) {
    if (session.recoverySession) return Icons.spa;
    if (session.gymSession) return Icons.fitness_center;
    if (session.cyclingSession) return Icons.directions_bike;
    if (session.category == TrainingLibraryCategory.tactical)
      return Icons.emoji_events;
    if (session.category == TrainingLibraryCategory.speed ||
        session.category == TrainingLibraryCategory.acceleration ||
        session.category == TrainingLibraryCategory.maxVelocity) {
      return Icons.speed;
    }
    if (session.category == TrainingLibraryCategory.endurance ||
        session.category == TrainingLibraryCategory.tempo) {
      return Icons.timeline;
    }
    return Icons.track_changes;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final globalState = context.watch<GlobalTrainingState>();
    final appliedFatigue = useGlobalFatigue
        ? globalState.physiologyStatus
        : manualFatigue;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Plan semanal inteligente',
              'Intelligent weekly plan',
              'Intelligenter Wochenplan',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Genera una semana con sesiones reales, protección de fatiga, ACWR, taper y compatibilidad por modalidad.',
              'Generate a week with real sessions, fatigue protection, ACWR, taper and modality compatibility.',
              'Erstelle eine Woche mit echten Einheiten, Ermüdungsschutz, ACWR, Taper und Modalitätskompatibilität.',
            ),
          ),
          const SizedBox(height: 16),

          Card(
            color: fatigueColor(appliedFatigue).withOpacity(0.12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: fatigueColor(appliedFatigue),
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
              title: Text(
                AppText.t(
                  lang,
                  'Fatiga aplicada',
                  'Applied fatigue',
                  'Angewendete Ermüdung',
                ),
              ),
              subtitle: Text(fatigueLabel(lang, appliedFatigue)),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<PeriodizationAthleteType>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Tipo de atleta',
                        'Athlete type',
                        'Athletentyp',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: PeriodizationAthleteType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(typeLabel(lang, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        type = value!;
                        intelligentPlan = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PeriodizationLevel>(
                    value: level,
                    decoration: InputDecoration(
                      labelText: AppText.t(lang, 'Nivel', 'Level', 'Niveau'),
                      border: const OutlineInputBorder(),
                    ),
                    items: PeriodizationLevel.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(levelLabel(lang, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        level = value!;
                        intelligentPlan = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PeriodizationFocus>(
                    value: focus,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Objetivo del microciclo',
                        'Microcycle goal',
                        'Mikrozyklus-Ziel',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: PeriodizationFocus.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(focusLabel(lang, value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        focus = value!;
                        intelligentPlan = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: useGlobalFatigue,
                    title: Text(
                      AppText.t(
                        lang,
                        'Usar fatiga global',
                        'Use global fatigue',
                        'Globale Ermüdung nutzen',
                      ),
                    ),
                    subtitle: Text(
                      AppText.t(
                        lang,
                        'Toma el estado desde GlobalTrainingState.',
                        'Reads status from GlobalTrainingState.',
                        'Liest den Status aus GlobalTrainingState.',
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        useGlobalFatigue = value;
                        intelligentPlan = null;
                      });
                    },
                  ),
                  if (!useGlobalFatigue)
                    DropdownButtonFormField<AutoPhysiologyStatus>(
                      value: manualFatigue,
                      decoration: InputDecoration(
                        labelText: AppText.t(
                          lang,
                          'Fatiga manual',
                          'Manual fatigue',
                          'Manuelle Ermüdung',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: AutoPhysiologyStatus.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(fatigueLabel(lang, value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          manualFatigue = value!;
                          intelligentPlan = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () => generateWeek(globalState),
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              AppText.t(
                lang,
                'Generar semana inteligente',
                'Generate intelligent week',
                'Intelligente Woche erstellen',
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (intelligentPlan != null) ...[
            if (intelligentPlan!.globalNotes.isNotEmpty)
              Card(
                color: const Color(0xFF111827),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notas IA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...intelligentPlan!.globalNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('�?� $note'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            ...intelligentPlan!.days.map(
              (day) => Card(
                child: ExpansionTile(
                  title: Text(
                    day.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${day.sessions.length} sesión(es)'),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    ...day.sessions.map((session) {
                      final color = sessionColor(session);

                      return Card(
                        color: color.withOpacity(0.08),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.18),
                            child: Icon(sessionIcon(session), color: color),
                          ),
                          title: Text(
                            '${session.number}. ${session.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${session.category.name} · ${session.intensity.name}\n${session.objective}',
                          ),
                        ),
                      );
                    }),
                    if (day.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Razones IA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...day.notes.map(
                        (note) => Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('�?� $note'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
