import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';

enum WorkType { skates, bike, gym, jumps }

class WorkItem {
  final WorkType type;
  String nameEs;
  String nameEn;
  String nameDe;
  double km;
  int sets;
  int reps;
  double weightKg;

  WorkItem({
    required this.type,
    required this.nameEs,
    required this.nameEn,
    required this.nameDe,
    this.km = 0,
    this.sets = 0,
    this.reps = 0,
    this.weightKg = 0,
  });

  String name(AppLanguage lang) {
    return AppText.t(lang, nameEs, nameEn, nameDe);
  }

  double get gymVolumeKg {
    if (type != WorkType.gym) return 0;
    return sets * reps * weightKg;
  }

  double jumpVolumeKg(double athleteWeightKg) {
    if (type != WorkType.jumps) return 0;
    return sets * reps * athleteWeightKg;
  }
}

class VolumeLoadScreen extends StatefulWidget {
  const VolumeLoadScreen({super.key});

  @override
  State<VolumeLoadScreen> createState() => _VolumeLoadScreenState();
}

class _VolumeLoadScreenState extends State<VolumeLoadScreen> {
  double athleteWeightKg = 70;

  final List<WorkItem> items = [
    WorkItem(
      type: WorkType.skates,
      nameEs: 'Patines mañana',
      nameEn: 'Morning skating',
      nameDe: 'Skaten morgens',
      km: 20,
    ),
    WorkItem(
      type: WorkType.skates,
      nameEs: 'Patines tarde',
      nameEn: 'Afternoon skating',
      nameDe: 'Skaten nachmittags',
      km: 10,
    ),
    WorkItem(
      type: WorkType.bike,
      nameEs: 'Bicicleta zona 2',
      nameEn: 'Zone 2 cycling',
      nameDe: 'Radfahren Zone 2',
      km: 35,
    ),
    WorkItem(
      type: WorkType.gym,
      nameEs: 'Sentadilla',
      nameEn: 'Squat',
      nameDe: 'Kniebeuge',
      sets: 4,
      reps: 6,
      weightKg: 50,
    ),
    WorkItem(
      type: WorkType.gym,
      nameEs: 'Hip Thrust',
      nameEn: 'Hip Thrust',
      nameDe: 'Hip Thrust',
      sets: 4,
      reps: 8,
      weightKg: 60,
    ),
    WorkItem(
      type: WorkType.jumps,
      nameEs: 'Saltos de patinador',
      nameEn: 'Skater jumps',
      nameDe: 'Skater-Sprünge',
      sets: 4,
      reps: 10,
    ),
  ];

  double get totalSkateKm {
    return items
        .where((item) => item.type == WorkType.skates)
        .fold(0, (sum, item) => sum + item.km);
  }

  double get totalBikeKm {
    return items
        .where((item) => item.type == WorkType.bike)
        .fold(0, (sum, item) => sum + item.km);
  }

  double get totalGymKg {
    return items.fold(0, (sum, item) => sum + item.gymVolumeKg);
  }

  double get totalJumpKg {
    return items.fold(
      0,
      (sum, item) => sum + item.jumpVolumeKg(athleteWeightKg),
    );
  }

  String loadStatus(AppLanguage lang) {
    final total = totalGymKg + totalJumpKg;

    if (total > 10000 || totalSkateKm > 45 || totalBikeKm > 60) {
      return AppText.t(lang, 'Carga alta', 'High load', 'Hohe Belastung');
    }

    if (total < 3000 && totalSkateKm < 15 && totalBikeKm < 20) {
      return AppText.t(lang, 'Carga baja', 'Low load', 'Niedrige Belastung');
    }

    return AppText.t(
      lang,
      'Carga equilibrada',
      'Balanced load',
      'Ausgewogene Belastung',
    );
  }

  Color loadColor(AppLanguage lang) {
    final status = loadStatus(lang);

    if (status ==
        AppText.t(lang, 'Carga alta', 'High load', 'Hohe Belastung')) {
      return Colors.red;
    }

    if (status ==
        AppText.t(lang, 'Carga baja', 'Low load', 'Niedrige Belastung')) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String defaultNameEs(WorkType type) {
    switch (type) {
      case WorkType.skates:
        return 'Nueva sesión de patines';
      case WorkType.bike:
        return 'Nueva sesión de bicicleta';
      case WorkType.gym:
        return 'Nuevo ejercicio gimnasio';
      case WorkType.jumps:
        return 'Nuevo ejercicio de saltos';
    }
  }

  String defaultNameEn(WorkType type) {
    switch (type) {
      case WorkType.skates:
        return 'New skating session';
      case WorkType.bike:
        return 'New cycling session';
      case WorkType.gym:
        return 'New gym exercise';
      case WorkType.jumps:
        return 'New jump exercise';
    }
  }

  String defaultNameDe(WorkType type) {
    switch (type) {
      case WorkType.skates:
        return 'Neue Skate-Einheit';
      case WorkType.bike:
        return 'Neue Radeinheit';
      case WorkType.gym:
        return 'Neue Kraftübung';
      case WorkType.jumps:
        return 'Neue Sprungübung';
    }
  }

  void addItem(WorkType type) {
    setState(() {
      items.add(
        WorkItem(
          type: type,
          nameEs: defaultNameEs(type),
          nameEn: defaultNameEn(type),
          nameDe: defaultNameDe(type),
          km: type == WorkType.skates || type == WorkType.bike ? 10 : 0,
          sets: type == WorkType.gym || type == WorkType.jumps ? 3 : 0,
          reps: type == WorkType.gym || type == WorkType.jumps ? 10 : 0,
          weightKg: type == WorkType.gym ? 40 : 0,
        ),
      );
    });
  }

  String typeLabel(AppLanguage lang, WorkType type) {
    switch (type) {
      case WorkType.skates:
        return AppText.t(lang, 'Patines', 'Skating', 'Skaten');
      case WorkType.bike:
        return AppText.t(lang, 'Bicicleta', 'Cycling', 'Radfahren');
      case WorkType.gym:
        return AppText.t(lang, 'Gimnasio', 'Gym', 'Krafttraining');
      case WorkType.jumps:
        return AppText.t(lang, 'Saltos', 'Jumps', 'Sprünge');
    }
  }

  IconData typeIcon(WorkType type) {
    switch (type) {
      case WorkType.skates:
        return Icons.speed;
      case WorkType.bike:
        return Icons.directions_bike;
      case WorkType.gym:
        return Icons.fitness_center;
      case WorkType.jumps:
        return Icons.accessibility_new;
    }
  }

  Future<void> editItem(int index, AppLanguage lang) async {
    final item = items[index];

    final nameController = TextEditingController(text: item.name(lang));
    final kmController = TextEditingController(text: item.km.toString());
    final setsController = TextEditingController(text: item.sets.toString());
    final repsController = TextEditingController(text: item.reps.toString());
    final weightController = TextEditingController(
      text: item.weightKg.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppText.t(
              lang,
              'Editar ${typeLabel(lang, item.type)}',
              'Edit ${typeLabel(lang, item.type)}',
              '${typeLabel(lang, item.type)} bearbeiten',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppText.t(lang, 'Nombre', 'Name', 'Name'),
                  ),
                ),
                if (item.type == WorkType.skates || item.type == WorkType.bike)
                  TextField(
                    controller: kmController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Kilómetros',
                        'Kilometers',
                        'Kilometer',
                      ),
                    ),
                  ),
                if (item.type == WorkType.gym ||
                    item.type == WorkType.jumps) ...[
                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppText.t(lang, 'Series', 'Sets', 'Sätze'),
                    ),
                  ),
                  TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Repeticiones / saltos',
                        'Reps / jumps',
                        'Wiederholungen / Sprünge',
                      ),
                    ),
                  ),
                ],
                if (item.type == WorkType.gym)
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Peso externo kg',
                        'External weight kg',
                        'Externes Gewicht kg',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppText.t(lang, 'Cancelar', 'Cancel', 'Abbrechen')),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  item.nameEs = nameController.text;
                  item.nameEn = nameController.text;
                  item.nameDe = nameController.text;
                  item.km = double.tryParse(kmController.text) ?? 0;
                  item.sets = int.tryParse(setsController.text) ?? 0;
                  item.reps = int.tryParse(repsController.text) ?? 0;
                  item.weightKg = double.tryParse(weightController.text) ?? 0;
                });

                Navigator.pop(context);
              },
              child: Text(AppText.t(lang, 'Guardar', 'Save', 'Speichern')),
            ),
          ],
        );
      },
    );
  }

  Future<void> editAthleteWeight(AppLanguage lang) async {
    final controller = TextEditingController(text: athleteWeightKg.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppText.t(
              lang,
              'Peso del atleta',
              'Athlete weight',
              'Athletengewicht',
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppText.t(lang, 'Peso kg', 'Weight kg', 'Gewicht kg'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppText.t(lang, 'Cancelar', 'Cancel', 'Abbrechen')),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  athleteWeightKg = double.tryParse(controller.text) ?? 70;
                });

                Navigator.pop(context);
              },
              child: Text(AppText.t(lang, 'Guardar', 'Save', 'Speichern')),
            ),
          ],
        );
      },
    );
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
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
              'Volumen y carga',
              'Volume & load',
              'Volumen & Belastung',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'La app calcula automáticamente kilómetros, kilos levantados y kilos equivalentes en saltos.',
              'The app automatically calculates kilometers, lifted kilograms and equivalent kilograms in jumps.',
              'Die App berechnet automatisch Kilometer, gehobene Kilogramm und äquivalente Kilogramm bei Sprüngen.',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: Text(
                AppText.t(
                  lang,
                  'Peso del atleta',
                  'Athlete weight',
                  'Athletengewicht',
                ),
              ),
              subtitle: Text('$athleteWeightKg kg'),
              trailing: const Icon(Icons.edit),
              onTap: () => editAthleteWeight(lang),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => addItem(WorkType.skates),
                icon: const Icon(Icons.speed),
                label: Text(
                  AppText.t(
                    lang,
                    'Agregar patines',
                    'Add skating',
                    'Skaten hinzufügen',
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => addItem(WorkType.bike),
                icon: const Icon(Icons.directions_bike),
                label: Text(
                  AppText.t(lang, 'Agregar bici', 'Add bike', 'Rad hinzufügen'),
                ),
              ),
              FilledButton.icon(
                onPressed: () => addItem(WorkType.gym),
                icon: const Icon(Icons.fitness_center),
                label: Text(
                  AppText.t(
                    lang,
                    'Agregar gym',
                    'Add gym',
                    'Krafttraining hinzufügen',
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => addItem(WorkType.jumps),
                icon: const Icon(Icons.accessibility_new),
                label: Text(
                  AppText.t(
                    lang,
                    'Agregar saltos',
                    'Add jumps',
                    'Sprünge hinzufügen',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.calculate),
              title: Text(
                AppText.t(
                  lang,
                  'Resumen calculado',
                  'Calculated summary',
                  'Berechnete �obersicht',
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(
                  label: AppText.t(lang, 'Patines', 'Skating', 'Skaten'),
                  value: '${totalSkateKm.toStringAsFixed(1)} km',
                ),
                _SummaryRow(
                  label: AppText.t(lang, 'Bicicleta', 'Cycling', 'Radfahren'),
                  value: '${totalBikeKm.toStringAsFixed(1)} km',
                ),
                _SummaryRow(
                  label: AppText.t(lang, 'Gimnasio', 'Gym', 'Krafttraining'),
                  value: '${totalGymKg.toStringAsFixed(0)} kg',
                ),
                _SummaryRow(
                  label: AppText.t(lang, 'Saltos', 'Jumps', 'Sprünge'),
                  value: AppText.t(
                    lang,
                    '${totalJumpKg.toStringAsFixed(0)} kg equivalentes',
                    '${totalJumpKg.toStringAsFixed(0)} equivalent kg',
                    '${totalJumpKg.toStringAsFixed(0)} kg äquivalent',
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(loadStatus(lang)),
                    labelStyle: const TextStyle(color: Colors.white),
                    backgroundColor: loadColor(lang),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppText.t(
              lang,
              'Detalle editable del día',
              'Editable daily detail',
              'Bearbeitbare Tagesdetails',
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            String subtitle = '';

            if (item.type == WorkType.skates || item.type == WorkType.bike) {
              subtitle = '${item.km.toStringAsFixed(1)} km';
            }

            if (item.type == WorkType.gym) {
              subtitle =
                  '${item.sets} x ${item.reps} x ${item.weightKg.toStringAsFixed(1)} kg = ${item.gymVolumeKg.toStringAsFixed(0)} kg';
            }

            if (item.type == WorkType.jumps) {
              subtitle =
                  '${item.sets} x ${item.reps} ${AppText.t(lang, 'saltos', 'jumps', 'Sprünge')} x $athleteWeightKg kg = ${item.jumpVolumeKg(athleteWeightKg).toStringAsFixed(0)} kg';
            }

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(typeIcon(item.type))),
                title: Text(item.name(lang)),
                subtitle: Text('${typeLabel(lang, item.type)} · $subtitle'),
                onTap: () => editItem(index, lang),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => removeItem(index),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


