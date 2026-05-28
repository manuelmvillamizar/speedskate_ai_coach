import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';

enum AthleteType { velocista, fondista, mixto }

enum AthleteLevel { novato, competitivo, elite }

enum TrainingPlace { pista, ruta }

class TrainingEngineScreen extends StatefulWidget {
  const TrainingEngineScreen({super.key});

  @override
  State<TrainingEngineScreen> createState() => _TrainingEngineScreenState();
}

class _TrainingEngineScreenState extends State<TrainingEngineScreen> {
  AthleteType type = AthleteType.velocista;
  AthleteLevel level = AthleteLevel.novato;
  TrainingPlace place = TrainingPlace.pista;

  List<String> training = [];

  void generateTraining(AppLanguage lang) {
    List<String> session = [];

    if (type == AthleteType.velocista) {
      if (place == TrainingPlace.pista) {
        session = [
          AppText.t(
            lang,
            'Calentamiento 20 min',
            'Warm-up 20 min',
            'Aufwärmen 20 Min.',
          ),
          AppText.t(
            lang,
            'Técnica de salida 6 repeticiones',
            'Start technique 6 reps',
            'Starttechnik 6 Wiederholungen',
          ),
          AppText.t(
            lang,
            'Trabajo de curva en pista 200m',
            'Curve work on 200m track',
            'Kurventechnik auf der 200-m-Bahn',
          ),
          AppText.t(
            lang,
            '8 x 100m máxima intensidad',
            '8 x 100m maximum intensity',
            '8 x 100 m maximale Intensität',
          ),
          AppText.t(
            lang,
            '4 x 200m recuperación completa',
            '4 x 200m full recovery',
            '4 x 200 m vollständige Erholung',
          ),
          AppText.t(
            lang,
            'Vuelta a la calma 15 min',
            'Cool down 15 min',
            'Auslaufen 15 Min.',
          ),
        ];
      } else {
        session = [
          AppText.t(
            lang,
            'Calentamiento 15 min',
            'Warm-up 15 min',
            'Aufwärmen 15 Min.',
          ),
          AppText.t(
            lang,
            '10 x 80m aceleraciones',
            '10 x 80m accelerations',
            '10 x 80 m Beschleunigungen',
          ),
          AppText.t(
            lang,
            'Trabajo técnico en recta',
            'Technical work on straight road',
            'Technikarbeit auf gerader Strecke',
          ),
          AppText.t(
            lang,
            '6 x 150m velocidad controlada',
            '6 x 150m controlled speed',
            '6 x 150 m kontrollierte Geschwindigkeit',
          ),
          AppText.t(
            lang,
            'Vuelta a la calma 15 min',
            'Cool down 15 min',
            'Auslaufen 15 Min.',
          ),
        ];
      }
    }

    if (type == AthleteType.fondista) {
      if (place == TrainingPlace.pista) {
        session = [
          AppText.t(
            lang,
            'Calentamiento 20 min',
            'Warm-up 20 min',
            'Aufwärmen 20 Min.',
          ),
          AppText.t(
            lang,
            '40 min zona 2 controlada',
            '40 min controlled zone 2',
            '40 Min. kontrollierte Zone 2',
          ),
          AppText.t(
            lang,
            '6 cambios de ritmo por vueltas',
            '6 pace changes by laps',
            '6 Tempowechsel nach Runden',
          ),
          AppText.t(
            lang,
            'Trabajo táctico en grupo',
            'Group tactical work',
            'Taktikarbeit in der Gruppe',
          ),
          AppText.t(
            lang,
            'Final progresivo',
            'Progressive finish',
            'Progressiver Abschluss',
          ),
          AppText.t(
            lang,
            'Vuelta a la calma 20 min',
            'Cool down 20 min',
            'Auslaufen 20 Min.',
          ),
        ];
      } else {
        session = [
          AppText.t(
            lang,
            'Calentamiento 20 min',
            'Warm-up 20 min',
            'Aufwärmen 20 Min.',
          ),
          AppText.t(
            lang,
            '60 min fondo continuo',
            '60 min steady endurance',
            '60 Min. Grundlagenausdauer',
          ),
          AppText.t(
            lang,
            '10 cambios de ritmo de 1 min',
            '10 pace changes of 1 min',
            '10 Tempowechsel à 1 Min.',
          ),
          AppText.t(
            lang,
            'Drafting en grupo',
            'Group drafting',
            'Windschattenfahren in der Gruppe',
          ),
          AppText.t(
            lang,
            'Simulación de carrera',
            'Race simulation',
            'Rennsimulation',
          ),
          AppText.t(
            lang,
            'Vuelta a la calma 20 min',
            'Cool down 20 min',
            'Auslaufen 20 Min.',
          ),
        ];
      }
    }

    if (type == AthleteType.mixto) {
      if (place == TrainingPlace.pista) {
        session = [
          AppText.t(
            lang,
            'Calentamiento 20 min',
            'Warm-up 20 min',
            'Aufwärmen 20 Min.',
          ),
          AppText.t(
            lang,
            'Bloque velocidad: 4 x 100m',
            'Speed block: 4 x 100m',
            'Geschwindigkeitsblock: 4 x 100 m',
          ),
          AppText.t(
            lang,
            'Bloque técnico: curvas y trazada',
            'Technical block: curves and racing line',
            'Technikblock: Kurven und Fahrlinie',
          ),
          AppText.t(
            lang,
            'Bloque resistencia: 25 min zona 2',
            'Endurance block: 25 min zone 2',
            'Ausdauerblock: 25 Min. Zone 2',
          ),
          AppText.t(
            lang,
            '4 cambios de ritmo',
            '4 pace changes',
            '4 Tempowechsel',
          ),
          AppText.t(
            lang,
            'Simulación de carrera por puntos',
            'Points race simulation',
            'Punkterennen-Simulation',
          ),
          AppText.t(
            lang,
            'Vuelta a la calma 20 min',
            'Cool down 20 min',
            'Auslaufen 20 Min.',
          ),
        ];
      } else {
        session = [
          AppText.t(
            lang,
            'Calentamiento 20 min',
            'Warm-up 20 min',
            'Aufwärmen 20 Min.',
          ),
          AppText.t(
            lang,
            'Bloque velocidad: 6 x 80m',
            'Speed block: 6 x 80m',
            'Geschwindigkeitsblock: 6 x 80 m',
          ),
          AppText.t(
            lang,
            'Bloque fondo: 45 min zona 2',
            'Endurance block: 45 min zone 2',
            'Ausdauerblock: 45 Min. Zone 2',
          ),
          AppText.t(
            lang,
            'Drafting en grupo',
            'Group drafting',
            'Windschattenfahren in der Gruppe',
          ),
          AppText.t(lang, 'Cambios de ritmo', 'Pace changes', 'Tempowechsel'),
          AppText.t(
            lang,
            'Simulación de final de carrera',
            'Final sprint simulation',
            'Simulation des Rennfinales',
          ),
          AppText.t(
            lang,
            'Vuelta a la calma 20 min',
            'Cool down 20 min',
            'Auslaufen 20 Min.',
          ),
        ];
      }
    }

    if (level == AthleteLevel.novato) {
      session = session.take((session.length * 0.65).round()).toList();
      session.add(
        AppText.t(
          lang,
          'Enfoque novato: técnica limpia y control de carga',
          'Beginner focus: clean technique and load control',
          'Anfängerfokus: saubere Technik und Belastungskontrolle',
        ),
      );
    }

    if (level == AthleteLevel.competitivo) {
      session.add(
        AppText.t(
          lang,
          'Enfoque competitivo: mantener calidad y volumen medio-alto',
          'Competitive focus: maintain quality and medium-high volume',
          'Wettkampffokus: Qualität und mittelhohes Volumen halten',
        ),
      );
    }

    if (level == AthleteLevel.elite) {
      session.add(
        AppText.t(
          lang,
          'Bloque adicional: core específico',
          'Additional block: specific core',
          'Zusatzblock: spezifischer Core',
        ),
      );
      session.add(
        AppText.t(
          lang,
          'Movilidad y recuperación guiada',
          'Guided mobility and recovery',
          'Geführte Mobilität und Regeneration',
        ),
      );
      session.add(
        AppText.t(
          lang,
          'Enfoque elite: máxima calidad, control de fatiga y precisión técnica',
          'Elite focus: maximum quality, fatigue control and technical precision',
          'Elite-Fokus: maximale Qualität, Ermüdungskontrolle und technische Präzision',
        ),
      );
    }

    setState(() {
      training = session;
    });
  }

  String labelType(AppLanguage lang, AthleteType t) {
    switch (t) {
      case AthleteType.velocista:
        return AppText.t(lang, 'Velocista', 'Sprinter', 'Sprinter');
      case AthleteType.fondista:
        return AppText.t(
          lang,
          'Fondista',
          'Endurance skater',
          'Ausdauerskater',
        );
      case AthleteType.mixto:
        return AppText.t(
          lang,
          'Mixto / generalista europeo',
          'Mixed / European all-rounder',
          'Gemischt / europäischer Allrounder',
        );
    }
  }

  String labelLevel(AppLanguage lang, AthleteLevel l) {
    switch (l) {
      case AthleteLevel.novato:
        return AppText.t(lang, 'Novato', 'Beginner', 'Anfänger');
      case AthleteLevel.competitivo:
        return AppText.t(lang, 'Competitivo', 'Competitive', 'Wettkampfniveau');
      case AthleteLevel.elite:
        return AppText.t(lang, 'Elite', 'Elite', 'Elite');
    }
  }

  String labelPlace(AppLanguage lang, TrainingPlace p) {
    switch (p) {
      case TrainingPlace.pista:
        return AppText.t(lang, 'Pista 200m', '200m track', '200-m-Bahn');
      case TrainingPlace.ruta:
        return AppText.t(
          lang,
          'Ruta asfalto',
          'Asphalt road',
          'Asphaltstrecke',
        );
    }
  }

  String objectiveText(AppLanguage lang) {
    if (type == AthleteType.velocista) {
      return AppText.t(
        lang,
        'Objetivo: fuerza máxima, potencia, salidas, curva, aceleración y velocidad lanzada.',
        'Goal: maximum strength, power, starts, curves, acceleration and flying speed.',
        'Ziel: Maximalkraft, Schnellkraft, Starts, Kurven, Beschleunigung und fliegende Geschwindigkeit.',
      );
    }

    if (type == AthleteType.fondista) {
      return AppText.t(
        lang,
        'Objetivo: fuerza específica, resistencia, drafting, cambios de ritmo, táctica y remate.',
        'Goal: specific strength, endurance, drafting, pace changes, tactics and final sprint.',
        'Ziel: spezifische Kraft, Ausdauer, Windschattenfahren, Tempowechsel, Taktik und Endspurt.',
      );
    }

    return AppText.t(
      lang,
      'Objetivo: regularidad europea, competir varias pruebas, combinar velocidad, fondo y táctica.',
      'Goal: European consistency, racing multiple events, combining speed, endurance and tactics.',
      'Ziel: europäische Konstanz, mehrere Rennen bestreiten, Geschwindigkeit, Ausdauer und Taktik kombinieren.',
    );
  }

  String competitionText(AppLanguage lang) {
    if (type == AthleteType.velocista) {
      return AppText.t(
        lang,
        'Pruebas: 100m, 200m, 200m lanzados, 500m, 1000m, 100m ruta y one lap.',
        'Events: 100m, 200m, flying 200m, 500m, 1000m, road 100m and one lap.',
        'Disziplinen: 100 m, 200 m, fliegende 200 m, 500 m, 1000 m, Stra�Yen-100 m und One Lap.',
      );
    }

    if (type == AthleteType.fondista) {
      return AppText.t(
        lang,
        'Pruebas: 500m, 1000m, 200m lanzados, 5000m puntos, 10000m eliminación, 5000m ruta y maratón.',
        'Events: 500m, 1000m, flying 200m, 5000m points, 10000m elimination, road 5000m and marathon.',
        'Disziplinen: 500 m, 1000 m, fliegende 200 m, 5000 m Punkte, 10000 m Ausscheidung, Stra�Yen-5000 m und Marathon.',
      );
    }

    return AppText.t(
      lang,
      'Pruebas: combina velocidad y fondo para sumar puntos en clasificación general.',
      'Events: combines sprint and endurance to score in the overall ranking.',
      'Disziplinen: kombiniert Sprint und Ausdauer, um in der Gesamtwertung Punkte zu sammeln.',
    );
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
              'Motor de entrenamiento',
              'Training engine',
              'Trainingsmotor',
            ),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Selecciona el perfil deportivo y la superficie para generar una sesión base.',
              'Select the athlete profile and surface to generate a base session.',
              'Wähle das Athletenprofil und die Oberfläche, um eine Basiseinheit zu erstellen.',
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.t(
                      lang,
                      'Perfil del atleta',
                      'Athlete profile',
                      'Athletenprofil',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AthleteType>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Tipo de patinador',
                        'Skater type',
                        'Skatertyp',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: AthleteType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(labelType(lang, e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        type = value!;
                        training = [];
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AthleteLevel>(
                    value: level,
                    decoration: InputDecoration(
                      labelText: AppText.t(lang, 'Nivel', 'Level', 'Niveau'),
                      border: const OutlineInputBorder(),
                    ),
                    items: AthleteLevel.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(labelLevel(lang, e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        level = value!;
                        training = [];
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TrainingPlace>(
                    value: place,
                    decoration: InputDecoration(
                      labelText: AppText.t(
                        lang,
                        'Lugar de entrenamiento',
                        'Training place',
                        'Trainingsort',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: TrainingPlace.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(labelPlace(lang, e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        place = value!;
                        training = [];
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.info_outline),
              title: Text(
                AppText.t(
                  lang,
                  'Lectura deportiva del perfil',
                  'Sport interpretation of the profile',
                  'Sportliche Interpretation des Profils',
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(objectiveText(lang)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(competitionText(lang)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppText.t(
                      lang,
                      'Base semanal recomendada: patines 4-6 veces, gimnasio 3-4 veces y bicicleta como complemento.',
                      'Recommended weekly base: skating 4-6 times, gym 3-4 times and cycling as a complement.',
                      'Empfohlene Wochenbasis: 4-6 Mal Skaten, 3-4 Mal Krafttraining und Radfahren als Ergänzung.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => generateTraining(lang),
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              AppText.t(
                lang,
                'Generar entrenamiento',
                'Generate training',
                'Training erstellen',
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (training.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.t(
                        lang,
                        'Sesión generada',
                        'Generated session',
                        'Erstellte Einheit',
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...training.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
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


