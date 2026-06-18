import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athlete_program_service.dart';
import 'athlete_context_service.dart';
import 'athlete_detail_screen.dart';
import 'athlete_wearable_screen.dart';

class AthletesScreen extends StatelessWidget {
  const AthletesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AthletesContent();
  }
}

class _AthletesContent extends StatelessWidget {
  const _AthletesContent();

  void openCreateAthlete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AthleteFormDialog(),
    );
  }

  void openEditAthlete(BuildContext context, AthleteProgramProfile athlete) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AthleteFormDialog(athleteToEdit: athlete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final service = context.watch<AthleteProgramService>();

    return Scaffold(
      body: service.athletes.isEmpty
          ? Center(
              child: Text(
                AppText.t(
                  lang,
                  'No hay atletas creados',
                  'No athletes created',
                  'Keine Athleten erstellt',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  AppText.t(lang, 'Atletas', 'Athletes', 'Athleten'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppText.t(
                    lang,
                    'Cada atleta tiene su propio perfil, competencias, wearable y programación automática.',
                    'Each athlete has their own profile, competitions, wearable and automatic planning.',
                    'Jeder Athlet hat eigenes Profil, Wettkämpfe, Wearable und automatische Planung.',
                  ),
                ),
                const SizedBox(height: 16),
                ...service.athletes.map((athlete) {
                  final selected = service.activeAthleteId == athlete.id;

                  return Card(
                    color: selected ? const Color(0xFF1E293B) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: selected
                            ? Colors.blue
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.speed,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                      title: Text(
                        athlete.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${athlete.category} · ${athlete.age} años · ${_typeText(lang, athlete.type)} · ${_levelText(lang, athlete.level)}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Editar atleta',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => openEditAthlete(context, athlete),
                          ),
                          IconButton(
                            tooltip: 'Eliminar atleta',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await service.deleteAthlete(athlete.id);
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        await service.selectAthlete(athlete.id);

                        if (!context.mounted) return;

                        context.read<AthleteContextService>().setActiveAthlete(
                          athlete,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AthleteDetailHubScreen(athlete: athlete),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCreateAthlete(context),
        icon: const Icon(Icons.add),
        label: Text(
          AppText.t(lang, 'Crear atleta', 'Create athlete', 'Athlet erstellen'),
        ),
      ),
    );
  }

  static String _typeText(AppLanguage lang, AthleteProgramType type) {
    switch (type) {
      case AthleteProgramType.sprinter:
        return AppText.t(lang, 'Velocista', 'Sprinter', 'Sprinter');
      case AthleteProgramType.endurance:
        return AppText.t(
          lang,
          'Fondista',
          'Endurance skater',
          'Ausdauerskater',
        );
      case AthleteProgramType.mixed:
        return AppText.t(lang, 'Mixto', 'Mixed', 'Gemischt');
    }
  }

  static String _levelText(AppLanguage lang, AthleteProgramLevel level) {
    switch (level) {
      case AthleteProgramLevel.novice:
        return AppText.t(lang, 'Novato', 'Beginner', 'Anfänger');
      case AthleteProgramLevel.competitive:
        return AppText.t(lang, 'Competitivo', 'Competitive', 'Wettkampf');
      case AthleteProgramLevel.elite:
        return AppText.t(lang, 'Elite', 'Elite', 'Elite');
    }
  }
}

class _AthleteFormDialog extends StatefulWidget {
  final AthleteProgramProfile? athleteToEdit;

  const _AthleteFormDialog({this.athleteToEdit});

  bool get isEditing => athleteToEdit != null;

  @override
  State<_AthleteFormDialog> createState() => _AthleteFormDialogState();
}

class _AthleteFormDialogState extends State<_AthleteFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController weightController;
  late final TextEditingController heightController;
  late final TextEditingController emailController;
  late final TextEditingController whatsappController;

  DateTime? birthDate;

  late AthleteProgramType type;
  late AthleteProgramLevel level;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final athlete = widget.athleteToEdit;

    nameController = TextEditingController(text: athlete?.name ?? '');
    weightController = TextEditingController(
      text: athlete == null ? '65' : athlete.weightKg.toStringAsFixed(1),
    );
    heightController = TextEditingController(
      text: athlete == null
          ? ''
          : athlete.heightCm > 0
          ? athlete.heightCm.toStringAsFixed(1)
          : '',
    );

    emailController = TextEditingController(text: athlete?.email ?? '');
    whatsappController = TextEditingController(text: athlete?.whatsapp ?? '');

    birthDate = athlete?.birthDate;
    type = athlete?.type ?? AthleteProgramType.sprinter;
    level = athlete?.level ?? AthleteProgramLevel.competitive;
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    heightController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  String _typeText(AppLanguage lang, AthleteProgramType value) {
    switch (value) {
      case AthleteProgramType.sprinter:
        return AppText.t(lang, 'Velocista', 'Sprinter', 'Sprinter');
      case AthleteProgramType.endurance:
        return AppText.t(
          lang,
          'Fondista',
          'Endurance skater',
          'Ausdauerskater',
        );
      case AthleteProgramType.mixed:
        return AppText.t(lang, 'Mixto', 'Mixed', 'Gemischt');
    }
  }

  String _levelText(AppLanguage lang, AthleteProgramLevel value) {
    switch (value) {
      case AthleteProgramLevel.novice:
        return AppText.t(lang, 'Novato', 'Beginner', 'Anfänger');
      case AthleteProgramLevel.competitive:
        return AppText.t(lang, 'Competitivo', 'Competitive', 'Wettkampf');
      case AthleteProgramLevel.elite:
        return AppText.t(lang, 'Elite', 'Elite', 'Elite');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  int? get calculatedAge {
    final date = birthDate;
    if (date == null) return null;
    return AthleteProgramService.calculateAge(date);
  }

  String? get calculatedCategory {
    final date = birthDate;
    if (date == null) return null;
    return AthleteProgramService.calculateSkatingCategory(date);
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 16, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked == null) return;

    setState(() {
      birthDate = picked;
    });
  }

  double _parseWeight(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double _parseHeight(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> saveAthlete() async {
    if (saving) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = nameController.text.trim();
    final selectedBirthDate = birthDate;
    final weight = _parseWeight(weightController.text);
    final height = _parseHeight(heightController.text);
    final email = emailController.text.trim();
    final whatsapp = whatsappController.text.trim();

    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del atleta.')),
      );
      return;
    }

    if (selectedBirthDate == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento.')),
      );
      return;
    }

    if (weight <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe un peso válido en kg.')),
      );
      return;
    }
    if (height <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe una estatura válida en cm.')),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final service = context.read<AthleteProgramService>();

      if (widget.isEditing) {
        final athlete = widget.athleteToEdit!;

        await service
            .updateAthlete(
              athleteId: athlete.id,
              name: name,
              category: AthleteProgramService.calculateSkatingCategory(
                selectedBirthDate,
              ),
              type: type,
              level: level,
              age: AthleteProgramService.calculateAge(selectedBirthDate),
              weightKg: weight,
              heightCm: height,
              email: email,
              whatsapp: whatsapp,
              birthDate: selectedBirthDate,
            )
            .timeout(const Duration(seconds: 8));

        final updatedAthlete = service.athletes.firstWhere(
          (item) => item.id == athlete.id,
          orElse: () => athlete,
        );

        if (!mounted) return;

        if (service.activeAthleteId == updatedAthlete.id) {
          context.read<AthleteContextService>().setActiveAthlete(
            updatedAthlete,
          );
        }

        navigator.pop();

        if (!mounted) return;

        await service.selectAthlete(athlete.id);

        if (!mounted) return;

        context.read<AthleteContextService>().setActiveAthlete(athlete);

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AthleteWearableScreen()),
        );

        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Atleta ${athlete.name} creado. Ahora puedes conectar su dispositivo.',
            ),
          ),
        );

        return;
      }

      final athleteId = name.trim().toLowerCase().replaceAll(' ', '_');

      final athlete = AthleteProgramProfile(
        id: athleteId,
        name: name,
        category: AthleteProgramService.calculateSkatingCategory(
          selectedBirthDate,
        ),
        type: type,
        level: level,
        age: AthleteProgramService.calculateAge(selectedBirthDate),
        weightKg: weight,
        heightCm: height,
        email: email,
        whatsapp: whatsapp,
        birthDate: selectedBirthDate,
      );

      await service.addAthlete(athlete).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      context.read<AthleteContextService>().setActiveAthlete(athlete);

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(content: Text('Atleta ${athlete.name} creado.')),
      );
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('La app tardó demasiado guardando. Intenta de nuevo.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo guardar el atleta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    final age = calculatedAge;
    final category = calculatedCategory;

    return AlertDialog(
      title: Text(widget.isEditing ? 'Editar atleta' : 'Crear atleta'),
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
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: saving ? null : pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(
                    birthDate == null
                        ? 'Seleccionar fecha'
                        : _formatDate(birthDate!),
                    style: TextStyle(
                      fontSize: 16,
                      color: birthDate == null
                          ? Theme.of(context).hintColor
                          : null,
                    ),
                  ),
                ),
              ),
              if (birthDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.18)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.person, size: 18),
                        label: Text('$age años'),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.emoji_events, size: 18),
                        label: Text(category ?? ''),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: weightController,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppText.t(
                    lang,
                    'Peso kg',
                    'Weight kg',
                    'Gewicht kg',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightController,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Estatura cm'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: !saving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo del atleta',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: whatsappController,
                enabled: !saving,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp del atleta',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AthleteProgramType>(
                value: type,
                decoration: InputDecoration(
                  labelText: AppText.t(
                    lang,
                    'Tipo de atleta',
                    'Athlete type',
                    'Athletentyp',
                  ),
                ),
                items: AthleteProgramType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_typeText(lang, value)),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          type = value;
                        });
                      },
              ),
              DropdownButtonFormField<AthleteProgramLevel>(
                value: level,
                decoration: InputDecoration(
                  labelText: AppText.t(lang, 'Nivel', 'Level', 'Niveau'),
                ),
                items: AthleteProgramLevel.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_levelText(lang, value)),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          level = value;
                        });
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(AppText.t(lang, 'Cancelar', 'Cancel', 'Abbrechen')),
        ),
        FilledButton.icon(
          onPressed: saving ? null : saveAthlete,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(widget.isEditing ? Icons.check : Icons.save),
          label: Text(
            saving
                ? AppText.t(lang, 'Guardando', 'Saving', 'Speichern')
                : widget.isEditing
                ? 'Actualizar'
                : AppText.t(lang, 'Guardar', 'Save', 'Speichern'),
          ),
        ),
      ],
    );
  }
}

/// Compatibilidad por si alguna parte antigua abre AthleteDetailScreen.
/// El flujo oficial usa AthleteDetailHubScreen.
class AthleteDetailScreen extends StatelessWidget {
  final String athleteId;

  const AthleteDetailScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AthleteProgramService>();

    AthleteProgramProfile? athlete;

    for (final item in service.athletes) {
      if (item.id == athleteId) {
        athlete = item;
        break;
      }
    }

    if (athlete == null) {
      return const Scaffold(body: Center(child: Text('Atleta no encontrado.')));
    }

    return AthleteDetailHubScreen(athlete: athlete);
  }
}
