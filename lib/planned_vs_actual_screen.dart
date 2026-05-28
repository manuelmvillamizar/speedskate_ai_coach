import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';

enum SessionStatus { planned, completed, skipped, replaced }

enum SkipReason { lluvia, fatiga, dolor, enfermedad, faltaTiempo }

class PlannedVsActualScreen extends StatefulWidget {
  const PlannedVsActualScreen({super.key});

  @override
  State<PlannedVsActualScreen> createState() => _PlannedVsActualScreenState();
}

class _PlannedVsActualScreenState extends State<PlannedVsActualScreen> {
  SessionStatus status = SessionStatus.planned;
  SkipReason? reason;

  String recommendation = '';

  void generateRecommendation(AppLanguage lang) {
    if (status == SessionStatus.completed) {
      recommendation = AppText.t(
        lang,
        'Sesión completada correctamente. Se puede progresar carga.',
        'Session completed correctly. Load can progress.',
        'Einheit korrekt abgeschlossen. Die Belastung kann gesteigert werden.',
      );
    }

    if (status == SessionStatus.skipped) {
      if (reason == SkipReason.lluvia) {
        recommendation = AppText.t(
          lang,
          'Entrenamiento no realizado por lluvia. Recomiendo reemplazar por bicicleta o gimnasio.',
          'Training skipped due to rain. I recommend replacing it with cycling or gym.',
          'Training wegen Regen nicht durchgeführt. Ich empfehle Ersatz durch Radfahren oder Krafttraining.',
        );
      } else if (reason == SkipReason.fatiga) {
        recommendation = AppText.t(
          lang,
          'Fatiga alta. No recuperar carga completa. Realizar sesión suave.',
          'High fatigue. Do not recover the full load. Perform an easy session.',
          'Hohe Ermüdung. Belastung nicht vollständig nachholen. Eine leichte Einheit durchführen.',
        );
      } else if (reason == SkipReason.dolor) {
        recommendation = AppText.t(
          lang,
          'Dolor reportado. Evitar carga alta. Evaluar riesgo de lesión.',
          'Pain reported. Avoid high load. Evaluate injury risk.',
          'Schmerzen gemeldet. Hohe Belastung vermeiden. Verletzungsrisiko prüfen.',
        );
      } else {
        recommendation = AppText.t(
          lang,
          'Sesión no realizada. Ajustar planificación.',
          'Session not completed. Adjust the plan.',
          'Einheit nicht durchgeführt. Planung anpassen.',
        );
      }
    }

    if (status == SessionStatus.replaced) {
      recommendation = AppText.t(
        lang,
        'Sesión reemplazada correctamente. Mantener estímulo equivalente.',
        'Session replaced correctly. Maintain an equivalent stimulus.',
        'Einheit korrekt ersetzt. Einen gleichwertigen Trainingsreiz beibehalten.',
      );
    }

    if (status == SessionStatus.planned) {
      recommendation = AppText.t(
        lang,
        'La sesión sigue planificada. Registra si fue realizada, no realizada o reemplazada.',
        'The session is still planned. Register whether it was completed, skipped or replaced.',
        'Die Einheit ist noch geplant. Trage ein, ob sie durchgeführt, ausgelassen oder ersetzt wurde.',
      );
    }

    setState(() {});
  }

  String labelStatus(AppLanguage lang, SessionStatus s) {
    switch (s) {
      case SessionStatus.planned:
        return AppText.t(lang, 'Planificada', 'Planned', 'Geplant');
      case SessionStatus.completed:
        return AppText.t(lang, 'Realizada', 'Completed', 'Durchgeführt');
      case SessionStatus.skipped:
        return AppText.t(lang, 'No realizada', 'Skipped', 'Nicht durchgeführt');
      case SessionStatus.replaced:
        return AppText.t(lang, 'Reemplazada', 'Replaced', 'Ersetzt');
    }
  }

  String labelReason(AppLanguage lang, SkipReason r) {
    switch (r) {
      case SkipReason.lluvia:
        return AppText.t(lang, 'Lluvia', 'Rain', 'Regen');
      case SkipReason.fatiga:
        return AppText.t(lang, 'Fatiga', 'Fatigue', 'Ermüdung');
      case SkipReason.dolor:
        return AppText.t(lang, 'Dolor', 'Pain', 'Schmerz');
      case SkipReason.enfermedad:
        return AppText.t(lang, 'Enfermedad', 'Illness', 'Krankheit');
      case SkipReason.faltaTiempo:
        return AppText.t(lang, 'Falta de tiempo', 'Lack of time', 'Zeitmangel');
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
              'Planeado vs realizado',
              'Planned vs actual',
              'Geplant vs durchgeführt',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Registra si la sesión fue realizada, no realizada o reemplazada.',
              'Register whether the session was completed, skipped or replaced.',
              'Trage ein, ob die Einheit durchgeführt, ausgelassen oder ersetzt wurde.',
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<SessionStatus>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Estado de la sesión',
                        'Session status',
                        'Status der Einheit',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: SessionStatus.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(labelStatus(lang, e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        status = value!;
                        recommendation = '';
                        if (status != SessionStatus.skipped) {
                          reason = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (status == SessionStatus.skipped)
                    DropdownButtonFormField<SkipReason>(
                      value: reason,
                      decoration: InputDecoration(
                        labelText: AppText.t(lang, 'Motivo', 'Reason', 'Grund'),
                        border: const OutlineInputBorder(),
                      ),
                      items: SkipReason.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(labelReason(lang, e)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          reason = value!;
                          recommendation = '';
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => generateRecommendation(lang),
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              AppText.t(
                lang,
                'Generar recomendación',
                'Generate recommendation',
                'Empfehlung erstellen',
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (recommendation.isNotEmpty)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  recommendation,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


