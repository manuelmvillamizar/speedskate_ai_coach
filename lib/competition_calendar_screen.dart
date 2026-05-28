import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athlete_program_service.dart';

class CompetitionCalendarScreen extends StatefulWidget {
  const CompetitionCalendarScreen({super.key});

  @override
  State<CompetitionCalendarScreen> createState() =>
      _CompetitionCalendarScreenState();
}

class _CompetitionCalendarScreenState extends State<CompetitionCalendarScreen> {
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return formatDate(start);
    }

    return '${formatDate(start)} - ${formatDate(end)}';
  }

  String priorityLabel(AppLanguage lang, CompetitionPriority priority) {
    switch (priority) {
      case CompetitionPriority.main:
        return AppText.t(lang, 'Principal', 'Main', 'Hauptwettkampf');
      case CompetitionPriority.important:
        return AppText.t(lang, 'Importante', 'Important', 'Wichtig');
      case CompetitionPriority.preparation:
        return AppText.t(lang, 'Preparación', 'Preparation', 'Vorbereitung');
    }
  }

  String priorityShort(CompetitionPriority priority) {
    switch (priority) {
      case CompetitionPriority.main:
        return 'A';
      case CompetitionPriority.important:
        return 'B';
      case CompetitionPriority.preparation:
        return 'C';
    }
  }

  Color priorityColor(CompetitionPriority priority) {
    switch (priority) {
      case CompetitionPriority.main:
        return Colors.red;
      case CompetitionPriority.important:
        return Colors.orange;
      case CompetitionPriority.preparation:
        return Colors.blue;
    }
  }

  int daysToMainCompetition(AthleteProgramProfile athlete) {
    final today = DateTime.now();

    final mainCompetitions = athlete.competitions
        .where(
          (c) =>
              c.priority == CompetitionPriority.main &&
              !c.endDate.isBefore(DateTime(today.year, today.month, today.day)),
        )
        .toList();

    if (mainCompetitions.isEmpty) return -1;

    mainCompetitions.sort((a, b) => a.date.compareTo(b.date));

    return mainCompetitions.first.date.difference(today).inDays;
  }

  String peakMessage(AppLanguage lang, AthleteProgramProfile athlete) {
    final days = daysToMainCompetition(athlete);

    if (days < 0) {
      return AppText.t(
        lang,
        'No hay competencia principal próxima registrada para este deportista.',
        'No upcoming main competition registered for this athlete.',
        'Kein kommender Hauptwettkampf für diesen Athleten eingetragen.',
      );
    }

    if (days <= 7) {
      return AppText.t(
        lang,
        'Competencia principal muy cerca: fase de pico y taper.',
        'Main competition very close: peak and taper phase.',
        'Hauptwettkampf sehr nah: Peak- und Taperphase.',
      );
    }

    if (days <= 21) {
      return AppText.t(
        lang,
        'Competencia principal próxima: reducir volumen y mantener velocidad.',
        'Main competition coming soon: reduce volume and maintain speed.',
        'Hauptwettkampf steht bevor: Volumen reduzieren und Geschwindigkeit halten.',
      );
    }

    if (days <= 60) {
      return AppText.t(
        lang,
        'Fase precompetitiva: trabajo específico y control de fatiga.',
        'Pre-competition phase: specific work and fatigue control.',
        'Vorwettkampfphase: spezifische Arbeit und Ermüdungskontrolle.',
      );
    }

    return AppText.t(
      lang,
      'Aún hay tiempo para construir base, fuerza, velocidad y progresar carga.',
      'There is still time to build base, strength, speed and progress load.',
      'Es bleibt Zeit, Grundlage, Kraft, Geschwindigkeit und Belastung aufzubauen.',
    );
  }

  Future<void> createCompetition({
    required AppLanguage lang,
    required AthleteProgramProfile athlete,
  }) async {
    final nameController = TextEditingController();
    final placeController = TextEditingController();
    final eventsController = TextEditingController(text: '500m, 1000m');

    DateTime startDate = DateTime.now().add(const Duration(days: 60));
    DateTime endDate = DateTime.now().add(const Duration(days: 60));
    CompetitionPriority selectedPriority = CompetitionPriority.main;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 1200)),
                helpText: AppText.t(
                  lang,
                  'Fecha de inicio',
                  'Start date',
                  'Startdatum',
                ),
                cancelText: AppText.t(lang, 'Cancelar', 'Cancel', 'Abbrechen'),
                confirmText: AppText.t(lang, 'Aceptar', 'OK', 'OK'),
              );

              if (picked == null) return;

              setDialogState(() {
                startDate = picked;

                if (endDate.isBefore(startDate)) {
                  endDate = startDate;
                }
              });
            }

            Future<void> pickEndDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate.isBefore(startDate) ? startDate : endDate,
                firstDate: startDate,
                lastDate: DateTime.now().add(const Duration(days: 1200)),
                helpText: AppText.t(
                  lang,
                  'Fecha de finalización',
                  'End date',
                  'Enddatum',
                ),
                cancelText: AppText.t(lang, 'Cancelar', 'Cancel', 'Abbrechen'),
                confirmText: AppText.t(lang, 'Aceptar', 'OK', 'OK'),
              );

              if (picked == null) return;

              setDialogState(() {
                endDate = picked;
              });
            }

            Future<void> saveCompetition() async {
              if (saving) return;

              final name = nameController.text.trim();
              final place = placeController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppText.t(
                        lang,
                        'Escribe el nombre de la competencia.',
                        'Enter the competition name.',
                        'Gib den Namen des Wettkampfs ein.',
                      ),
                    ),
                  ),
                );
                return;
              }

              if (place.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppText.t(
                        lang,
                        'Escribe el lugar de la competencia.',
                        'Enter the competition location.',
                        'Gib den Ort des Wettkampfs ein.',
                      ),
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              final events = eventsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              await context.read<AthleteProgramService>().addCompetition(
                athleteId: athlete.id,
                competition: AthleteCompetition(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  date: startDate,
                  endDate: endDate,
                  location: place,
                  priority: selectedPriority,
                  events: events,
                ),
              );

              if (!context.mounted) return;

              Navigator.pop(dialogContext);
            }

            return AlertDialog(
              title: Text(
                AppText.t(
                  lang,
                  'Crear competencia',
                  'Create competition',
                  'Wettkampf erstellen',
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        enabled: !saving,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: AppText.t(lang, 'Nombre', 'Name', 'Name'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: placeController,
                        enabled: !saving,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: AppText.t(lang, 'Lugar', 'Place', 'Ort'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: eventsController,
                        enabled: !saving,
                        decoration: InputDecoration(
                          labelText: AppText.t(
                            lang,
                            'Pruebas',
                            'Events',
                            'Disziplinen',
                          ),
                          hintText: '500m, 1000m, eliminación',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DateFieldButton(
                              label: AppText.t(lang, 'Desde', 'From', 'Von'),
                              value: formatDate(startDate),
                              onTap: saving ? null : pickStartDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateFieldButton(
                              label: AppText.t(lang, 'Hasta', 'To', 'Bis'),
                              value: formatDate(endDate),
                              onTap: saving ? null : pickEndDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CompetitionPriority>(
                        value: selectedPriority,
                        decoration: InputDecoration(
                          labelText: AppText.t(
                            lang,
                            'Prioridad',
                            'Priority',
                            'Priorität',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: CompetitionPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priorityLabel(lang, priority)),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  selectedPriority = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    AppText.t(lang, 'Cancelar', 'Cancel', 'Abbrechen'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : saveCompetition,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    saving
                        ? AppText.t(lang, 'Guardando', 'Saving', 'Speichern')
                        : AppText.t(lang, 'Guardar', 'Save', 'Speichern'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    placeController.dispose();
    eventsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final service = context.watch<AthleteProgramService>();
    final athlete = service.activeAthlete;

    if (athlete == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppText.t(
              lang,
              'Primero crea o selecciona un deportista.',
              'First create or select an athlete.',
              'Erstelle oder wähle zuerst einen Athleten aus.',
            ),
          ),
        ),
      );
    }

    final competitions = [...athlete.competitions]
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Calendario competitivo',
              'Competition calendar',
              'Wettkampfkalender',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${athlete.name} · ${AppText.t(lang, 'competencias del deportista activo', 'competitions of the active athlete', 'Wettkämpfe des aktiven Athleten')}',
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF111827),
            child: ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text(
                AppText.t(
                  lang,
                  'Lectura de pico de rendimiento',
                  'Peak performance reading',
                  'Peak-Performance-Einschätzung',
                ),
              ),
              subtitle: Text(peakMessage(lang, athlete)),
            ),
          ),
          const SizedBox(height: 16),
          if (competitions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  AppText.t(
                    lang,
                    'Este deportista aún no tiene competencias registradas.',
                    'This athlete has no registered competitions yet.',
                    'Dieser Athlet hat noch keine Wettkämpfe eingetragen.',
                  ),
                ),
              ),
            )
          else
            ...competitions.map((competition) {
              final color = priorityColor(competition.priority);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      priorityShort(competition.priority),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    competition.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${competition.location} · ${formatDateRange(competition.date, competition.endDate)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      service.deleteCompetition(
                        athleteId: athlete.id,
                        competitionId: competition.id,
                      );
                    },
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createCompetition(lang: lang, athlete: athlete),
        icon: const Icon(Icons.add),
        label: Text(
          AppText.t(
            lang,
            'Crear competencia',
            'Create competition',
            'Wettkampf erstellen',
          ),
        ),
      ),
    );
  }
}

class _DateFieldButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
