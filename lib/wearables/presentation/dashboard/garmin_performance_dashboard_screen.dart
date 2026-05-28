import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../athlete_context_service.dart';
import '../../../athlete_physiology_profile.dart';
import '../../../athlete_program_service.dart';
import '../../../physiology_profile_storage_service.dart';
import '../../../wearable_integration_service.dart';

class GarminPerformanceDashboardScreen extends StatelessWidget {
  const GarminPerformanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final athlete = context.watch<AthleteProgramService>().activeAthlete;
    final athleteContext = context.watch<AthleteContextService>();
    final wearableService = context.watch<WearableIntegrationService>();

    if (athlete == null) {
      return const Scaffold(body: Center(child: Text('No hay atleta activo.')));
    }

    return FutureBuilder<AthletePhysiologyProfile?>(
      future: PhysiologyProfileStorageService.loadProfile(athlete.id),
      builder: (context, snapshot) {
        final profile =
            snapshot.data ?? AthletePhysiologyProfile(athleteId: athlete.id);

        final wearable = athleteContext.activeWearable ?? wearableService.today;

        final history = wearableService.history;

        final readiness = athleteContext.activeReadinessScore;
        final fatigue = athleteContext.activeFatigueStatus;

        final acuteLoad = _averageLast(history, 7, (w) => w.trainingLoad);
        final chronicLoad = _averageLast(history, 28, (w) => w.trainingLoad);
        final acwr = chronicLoad <= 0 ? 1.0 : acuteLoad / chronicLoad;

        return Scaffold(
          appBar: AppBar(title: const Text('Estado corporal del atleta')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                athleteName: athlete.name,
                readiness: readiness,
                fatigue: fatigue,
                acwr: acwr,
              ),
              const SizedBox(height: 16),

              _SectionTitle('Estado corporal de hoy'),

              _MetricGrid(
                cards: [
                  _MetricData(
                    title: 'Disponibilidad',
                    value: '$readiness / 100',
                    explanation:
                        'Indica qué tan preparado está el cuerpo para entrenar hoy combinando sueño, HRV, estrés, fatiga y carga.',
                    recommendation: readiness < 60
                        ? 'Reducir volumen, bloquear lactato y priorizar recuperación.'
                        : readiness < 80
                        ? 'Mantener calidad, pero no aumentar volumen.'
                        : 'Puede tolerar entrenamiento planificado.',
                    color: _readinessColor(readiness),
                  ),
                  _MetricData(
                    title: 'Recuperación',
                    value: '${wearable?.hrv ?? 0}',
                    explanation:
                        'La variabilidad cardiaca refleja recuperación del sistema nervioso. Si baja frente a la base, puede indicar fatiga.',
                    recommendation: wearable == null
                        ? 'Sin dato Garmin disponible.'
                        : wearable.hrv < profile.baselineHrv * 0.90
                        ? 'Evitar alta intensidad y pliometría agresiva.'
                        : 'Señal autonómica estable.',
                    color: Colors.blue,
                  ),
                  _MetricData(
                    title: 'HRV base',
                    value: profile.baselineHrv.toStringAsFixed(1),
                    explanation:
                        'Referencia individual del atleta. No se compara contra otros atletas, sino contra su propio promedio.',
                    recommendation:
                        'Usar esta base para interpretar si el HRV actual está bajo, normal o alto.',
                    color: Colors.indigo,
                  ),
                  _MetricData(
                    title: 'Pulso en reposo',
                    value: '${wearable?.restingHeartRate ?? 0}',
                    explanation:
                        'Pulso en reposo. Si sube respecto a la base puede indicar mala recuperación, estrés o carga acumulada.',
                    recommendation: wearable == null
                        ? 'Sin dato Garmin disponible.'
                        : wearable.restingHeartRate >
                              profile.baselineRestingHeartRate + 6
                        ? 'Reducir carga y vigilar respuesta al calentamiento.'
                        : 'FC reposo dentro de rango aceptable.',
                    color: Colors.red,
                  ),
                  _MetricData(
                    title: 'FC base',
                    value: '${profile.baselineRestingHeartRate}',
                    explanation:
                        'Referencia normal de frecuencia cardiaca en reposo del atleta.',
                    recommendation:
                        'Si la FC actual supera esta base por 7-10 ppm, proteger la sesión.',
                    color: Colors.deepOrange,
                  ),
                  _MetricData(
                    title: 'Sueño',
                    value:
                        '${wearable?.sleepHours.toStringAsFixed(1) ?? '-'} h',
                    explanation:
                        'El sueño afecta recuperación, aprendizaje motor, producción hormonal y tolerancia a intensidad.',
                    recommendation:
                        wearable != null && wearable.sleepHours < 6.5
                        ? 'No programar lactato pesado ni fuerza máxima.'
                        : 'Sueño suficiente para tolerar estímulo controlado.',
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _SectionTitle('Exigencia reciente'),

              _AcwrCard(
                acuteLoad: acuteLoad,
                chronicLoad: chronicLoad,
                acwr: acwr,
              ),

              const SizedBox(height: 16),

              _ChartCard(
                title: 'Tendencia de recuperación',
                subtitle: '�sltimos registros Garmin',
                child: _LineMetricChart(
                  history: history,
                  value: (w) => w.hrv.toDouble(),
                  baseline: profile.baselineHrv,
                ),
              ),

              const SizedBox(height: 16),

              _ChartCard(
                title: 'Exigencia diaria',
                subtitle: 'Carga de entrenamiento reportada por wearable',
                child: _BarLoadChart(history: history),
              ),

              const SizedBox(height: 16),

              _ChartCard(
                title: 'Distribución de intensidad',
                subtitle: 'Control de intensidad para patinaje de velocidad',
                child: _ZonePieChart(wearable: wearable),
              ),

              const SizedBox(height: 20),

              _SectionTitle('Perfil de respuesta del atleta'),

              _MetricGrid(
                cards: [
                  _MetricData(
                    title: 'Recuperación',
                    value: profile.recoveryRate.toStringAsFixed(2),
                    explanation:
                        'Capacidad individual para asimilar carga y volver fresco al siguiente estímulo.',
                    recommendation: profile.recoveryRate < 0.90
                        ? 'Usar más recuperación activa, movilidad y bicicleta suave.'
                        : 'Recuperación adecuada.',
                    color: Colors.green,
                  ),
                  _MetricData(
                    title: 'Acumulación fatiga',
                    value: profile.fatigueAccumulationRate.toStringAsFixed(2),
                    explanation:
                        'Qué tan rápido se fatiga este atleta ante carga de gimnasio, patines, lactato o intensidad.',
                    recommendation: profile.fatigueAccumulationRate > 1.20
                        ? 'Dosificar pliometría, lactato y dobles sesiones.'
                        : 'Tolerancia de carga estable.',
                    color: Colors.orange,
                  ),
                  _MetricData(
                    title: 'Respuesta velocidad',
                    value: profile.speedResponse.toStringAsFixed(2),
                    explanation:
                        'Qué tan bien responde el atleta a estímulos de velocidad corta, aceleración y máxima velocidad.',
                    recommendation:
                        'Preservar velocidad corta cuando sea posible, incluso en días de carga reducida.',
                    color: Colors.blue,
                  ),
                  _MetricData(
                    title: 'Respuesta fuerza',
                    value: profile.strengthResponse.toStringAsFixed(2),
                    explanation:
                        'Respuesta individual al gimnasio, fuerza máxima, potencia y trabajo neuromuscular.',
                    recommendation: profile.strengthResponse < 0.90
                        ? 'Evitar fuerza pesada si hay fatiga amarilla/naranja.'
                        : 'Fuerza tolerada si readiness acompaña.',
                    color: Colors.teal,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _CoachDecisionCard(
                readiness: readiness,
                fatigue: fatigue,
                acwr: acwr,
                wearable: wearable,
                profile: profile,
              ),
            ],
          ),
        );
      },
    );
  }

  static double _averageLast(
    List<WearableDailyData> history,
    int days,
    double Function(WearableDailyData) value,
  ) {
    if (history.isEmpty) return 0;
    final recent = history.length > days
        ? history.sublist(history.length - days)
        : history;
    return recent.fold<double>(0, (sum, item) => sum + value(item)) /
        recent.length;
  }

  static Color _readinessColor(int readiness) {
    if (readiness < 40) return Colors.red;
    if (readiness < 60) return Colors.deepOrange;
    if (readiness < 80) return Colors.orange;
    return Colors.green;
  }
}

class _HeaderCard extends StatelessWidget {
  final String athleteName;
  final int readiness;
  final String fatigue;
  final double acwr;

  const _HeaderCard({
    required this.athleteName,
    required this.readiness,
    required this.fatigue,
    required this.acwr,
  });

  @override
  Widget build(BuildContext context) {
    final color = GarminPerformanceDashboardScreen._readinessColor(readiness);

    return Card(
      color: color.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(0.18),
              child: Icon(Icons.monitor_heart, color: color, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athleteName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Readiness $readiness · Fatiga ${fatigue.toUpperCase()}',
                  ),
                  Text('ACWR ${acwr.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String explanation;
  final String recommendation;
  final Color color;

  const _MetricData({
    required this.title,
    required this.value,
    required this.explanation,
    required this.recommendation,
    required this.color,
  });
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> cards;

  const _MetricGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cards
          .map((data) => _MetricExplanationCard(data: data))
          .toList(),
    );
  }
}

class _MetricExplanationCard extends StatelessWidget {
  final _MetricData data;

  const _MetricExplanationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: data.color.withOpacity(0.15),
          child: Icon(Icons.insights, color: data.color),
        ),
        title: Text(
          data.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data.value),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(data.explanation),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'IA Coach: ${data.recommendation}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcwrCard extends StatelessWidget {
  final double acuteLoad;
  final double chronicLoad;
  final double acwr;

  const _AcwrCard({
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acwr,
  });

  Color get color {
    if (acwr > 1.5) return Colors.red;
    if (acwr > 1.3) return Colors.deepOrange;
    if (acwr < 0.8) return Colors.blueGrey;
    return Colors.green;
  }

  String get status {
    if (acwr > 1.5) return 'Riesgo alto';
    if (acwr > 1.3) return 'Precaución';
    if (acwr < 0.8) return 'Bajo estímulo';
    return 'Zona óptima';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACWR ${acwr.toStringAsFixed(2)} · $status',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ACWR compara la carga aguda reciente contra la carga crónica. Sirve para detectar si el atleta está entrenando por encima de su tolerancia construida.',
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: min(acwr / 2.0, 1.0),
              minHeight: 10,
              borderRadius: BorderRadius.circular(12),
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniStat('Carga aguda', acuteLoad.toStringAsFixed(1)),
                _MiniStat('Carga crónica', chronicLoad.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF05070A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.60)),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

class _LineMetricChart extends StatelessWidget {
  final List<WearableDailyData> history;
  final double Function(WearableDailyData) value;
  final double baseline;

  const _LineMetricChart({
    required this.history,
    required this.value,
    required this.baseline,
  });

  @override
  Widget build(BuildContext context) {
    final recent = history.length > 14
        ? history.sublist(history.length - 14)
        : history;

    if (recent.isEmpty) {
      return const Center(child: Text('Sin historial suficiente.'));
    }

    final spots = <FlSpot>[
      for (int i = 0; i < recent.length; i++)
        FlSpot(i.toDouble(), value(recent[i])),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF05070A),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: LineChart(
        LineChartData(
          minY: baseline - 15,
          maxY: baseline + 15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 42,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.12),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.round().toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final labels = ['00', '04', '08', '12', '16', '20'];
                  final index = value ~/ 3;

                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }

                  return Text(
                    '${labels[index]} h',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: baseline,
                color: Colors.white.withOpacity(0.25),
                strokeWidth: 1.4,
                dashArray: [7, 5],
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF111827),
              getTooltipItems: (items) {
                return items.map((item) {
                  return LineTooltipItem(
                    '${item.y.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              barWidth: 5,
              dotData: const FlDotData(show: true),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF22C55E),
                  Color(0xFF3B82F6),
                  Color(0xFFB96DD8),
                ],
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarLoadChart extends StatelessWidget {
  final List<WearableDailyData> history;

  const _BarLoadChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final recent = history.length > 14
        ? history.sublist(history.length - 14)
        : history;

    if (recent.isEmpty) {
      return const Center(child: Text('Sin historial suficiente.'));
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          for (int i = 0; i < recent.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: recent[i].trainingLoad,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ZonePieChart extends StatelessWidget {
  final WearableDailyData? wearable;

  const _ZonePieChart({required this.wearable});

  @override
  Widget build(BuildContext context) {
    final w = wearable;

    if (w == null || w.totalZoneMinutes <= 0) {
      return const Center(child: Text('Sin zonas Garmin disponibles.'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 42,
        sections: [
          _section('Z1', w.zone1Minutes.toDouble(), Colors.green),
          _section('Z2', w.zone2Minutes.toDouble(), Colors.lightGreen),
          _section('Z3', w.zone3Minutes.toDouble(), Colors.orange),
          _section('Z4', w.zone4Minutes.toDouble(), Colors.deepOrange),
          _section('Z5', w.zone5Minutes.toDouble(), Colors.red),
        ],
      ),
    );
  }

  PieChartSectionData _section(String title, double value, Color color) {
    return PieChartSectionData(
      title: '$title\n${value.round()}',
      value: value <= 0 ? 0.01 : value,
      color: color,
      radius: 58,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _CoachDecisionCard extends StatelessWidget {
  final int readiness;
  final String fatigue;
  final double acwr;
  final WearableDailyData? wearable;
  final AthletePhysiologyProfile profile;

  const _CoachDecisionCard({
    required this.readiness,
    required this.fatigue,
    required this.acwr,
    required this.wearable,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final decisions = <String>[];

    if (readiness < 60) {
      decisions.add('Reducir volumen total.');
      decisions.add('Bloquear lactato pesado.');
    }

    if (readiness < 75 || fatigue != 'green') {
      decisions.add('Quitar pliometría agresiva.');
    }

    if (acwr > 1.30) {
      decisions.add('No aumentar carga aguda.');
    }

    if (wearable != null && wearable!.sleepHours < 6.5) {
      decisions.add('Priorizar recovery bike y movilidad.');
    }

    if (profile.speedResponse >= 1.0 && readiness >= 55) {
      decisions.add('Preservar velocidad corta técnica si no hay dolor.');
    }

    if (decisions.isEmpty) {
      decisions.add('Mantener plan original con control de calidad.');
    }

    return Card(
      color: Colors.black.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recomendaciones para hoy',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...decisions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
