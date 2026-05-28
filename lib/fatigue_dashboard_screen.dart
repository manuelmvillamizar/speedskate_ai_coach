import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athlete_context_service.dart';
import 'fatigue_engine.dart';
import 'global_state.dart';
import 'training_history_service.dart';

class FatigueDashboardScreen extends StatelessWidget {
  const FatigueDashboardScreen({super.key});

  Color statusColor(String status) {
    switch (status) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String statusText(AppLanguage lang, String status) {
    switch (status) {
      case 'green':
        return AppText.t(lang, '�"ptimo', 'Optimal', 'Optimal');
      case 'yellow':
        return AppText.t(lang, 'Moderado', 'Moderate', 'Moderat');
      case 'orange':
        return AppText.t(
          lang,
          'Fatiga elevada',
          'Elevated fatigue',
          'Erhöhte Ermüdung',
        );
      case 'red':
        return AppText.t(
          lang,
          'Estrés fisiológico alto',
          'High physiological stress',
          'Hohe physiologische Belastung',
        );
      default:
        return status;
    }
  }

  String performanceRecommendation(AppLanguage lang, String status) {
    switch (status) {
      case 'green':
        return AppText.t(
          lang,
          'El estado fisiológico permite sostener el plan si la técnica se mantiene estable.',
          'Physiological status allows the planned session if technique remains stable.',
          'Der physiologische Zustand erlaubt die geplante Einheit, wenn die Technik stabil bleibt.',
        );
      case 'yellow':
        return AppText.t(
          lang,
          'Controlar volumen e intensidad. Mantener calidad sin añadir carga extra.',
          'Control volume and intensity. Maintain quality without adding extra load.',
          'Umfang und Intensität steuern. Qualität halten, ohne zusätzliche Belastung.',
        );
      case 'orange':
        return AppText.t(
          lang,
          'Se recomienda evitar intensidad máxima, lactato pesado y fuerza máxima.',
          'Avoid maximal intensity, heavy lactate work, and maximal strength.',
          'Maximale Intensität, schwere Laktatbelastung und Maximalkraft vermeiden.',
        );
      case 'red':
        return AppText.t(
          lang,
          'Protección fisiológica prioritaria: recuperación, movilidad y baja carga.',
          'Physiological protection priority: recovery, mobility, and low load.',
          'Physiologischer Schutz hat Priorität: Regeneration, Mobilität und geringe Belastung.',
        );
      default:
        return '';
    }
  }

  double entryLoad(TrainingHistoryEntry entry) {
    return entry.gymKg + (entry.skateKm * 100) + (entry.minutes * 10);
  }

  double averageLast(
    List<TrainingHistoryEntry> entries,
    int days,
    double Function(TrainingHistoryEntry entry) value,
  ) {
    if (entries.isEmpty) return 0;

    final recent = entries.length > days
        ? entries.sublist(entries.length - days)
        : entries;

    return recent.fold<double>(0, (sum, item) => sum + value(item)) /
        recent.length;
  }

  int highIntensityEstimate({
    required double skateKm,
    required int minutes,
    required double gymKg,
  }) {
    var score = 0;

    if (minutes >= 75) score += 10;
    if (skateKm >= 14) score += 12;
    if (gymKg >= 2500) score += 10;

    return score.clamp(0, 45);
  }

  int neuralLoadEstimate({
    required double gymKg,
    required double skateKm,
    required int minutes,
  }) {
    var score = 0;

    if (gymKg >= 2500) score += 35;
    if (skateKm > 0 && skateKm <= 10 && minutes <= 70) score += 25;
    if (minutes >= 80) score += 10;

    return score.clamp(0, 100);
  }

  int metabolicLoadEstimate({
    required double skateKm,
    required int minutes,
    required double acwr,
  }) {
    var score = 0;

    if (minutes >= 60) score += 25;
    if (skateKm >= 12) score += 25;
    if (acwr >= 1.30) score += 25;

    return score.clamp(0, 100);
  }

  String loadStatus(double value) {
    if (value >= 75) return 'red';
    if (value >= 55) return 'orange';
    if (value >= 35) return 'yellow';
    return 'green';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final history = context.watch<TrainingHistoryService>();
    final globalState = context.watch<GlobalTrainingState>();
    
    // �o. MIGRADO: usar AthleteContextService como source of truth
    final athleteContext = context.watch<AthleteContextService>();
    final wearable = athleteContext.activeWearable;

    // �o. Valores por defecto seguros (si no hay wearable activo)
    final hrv = wearable?.hrv ?? 55;
    final sleepHours = wearable?.sleepHours ?? 7.5;
    final stress = wearable?.stress ?? 40;
    final restingHeartRate = wearable?.restingHeartRate ?? 52;
    final soreness = wearable?.soreness ?? 3;

    final entries = history.entries;

    double acuteLoad = 0;
    double chronicLoad = 0;

    for (int i = 0; i < entries.length; i++) {
      final load = entryLoad(entries[i]);

      if (i >= entries.length - 7) {
        acuteLoad += load;
      }

      if (i >= entries.length - 28) {
        chronicLoad += load;
      }
    }

    final lastGym = entries.isEmpty ? 0.0 : entries.last.gymKg;
    final lastSkate = entries.isEmpty ? 0.0 : entries.last.skateKm;
    final lastMinutes = entries.isEmpty ? 0 : entries.last.minutes;

    final acwr = FatigueEngine.acuteChronicRatio(
      acuteLoad7Days: acuteLoad,
      chronicLoad28Days: chronicLoad,
    );

    final acwrStatus = FatigueEngine.injuryRiskStatus(acwr);

    final readiness = FatigueEngine.readinessScore(
      gymLoad: lastGym,
      skateKm: lastSkate,
      minutes: lastMinutes,
      sleepHours: sleepHours.round(),
      stress: stress.round(),
      hrv: hrv.round(),
      restingHeartRate: restingHeartRate.round(),
      soreness: soreness.round(),
    );

    final readinessStatus = FatigueEngine.readinessStatus(readiness);

    final recommendation = FatigueEngine.recommendationEs(
      status: readinessStatus,
      readiness: readiness,
      acuteChronicRatio: acwr,
    );

    final recommendationTranslated = AppText.t(
      lang,
      recommendation,
      FatigueEngine.recommendationEn(
        status: readinessStatus,
        readiness: readiness,
        acuteChronicRatio: acwr,
      ),
      FatigueEngine.recommendationDe(
        status: readinessStatus,
        readiness: readiness,
        acuteChronicRatio: acwr,
      ),
    );

    final neuralLoad = neuralLoadEstimate(
      gymKg: lastGym,
      skateKm: lastSkate,
      minutes: lastMinutes,
    );

    final metabolicLoad = metabolicLoadEstimate(
      skateKm: lastSkate,
      minutes: lastMinutes,
      acwr: acwr,
    );

    final highIntensityMinutes = highIntensityEstimate(
      skateKm: lastSkate,
      minutes: lastMinutes,
      gymKg: lastGym,
    );

    final freshnessScore = max(
      0,
      min(
        100,
        readiness -
            (acwr > 1.30 ? 12 : 0) -
            (soreness * 4) -
            (sleepHours < 6.5 ? 10 : 0),
      ),
    );

    final performanceStatus = freshnessScore >= 80
        ? 'green'
        : freshnessScore >= 65
        ? 'yellow'
        : freshnessScore >= 45
        ? 'orange'
        : 'red';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppText.t(
            lang,
            'Dashboard fisiológico',
            'Physiology dashboard',
            'Physiologie-Dashboard',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.t(
              lang,
              'Estado de rendimiento',
              'Performance status',
              'Leistungsstatus',
            ),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),

          _ReadinessCard(
            lang: lang,
            readiness: readiness,
            readinessStatus: readinessStatus,
            recommendation: recommendationTranslated,
            color: statusColor(readinessStatus),
            statusText: statusText(lang, readinessStatus),
          ),

          const SizedBox(height: 18),

          _PerformanceProtectionCard(
            lang: lang,
            freshnessScore: freshnessScore.toDouble(),
            status: performanceStatus,
            color: statusColor(performanceStatus),
            recommendation: performanceRecommendation(lang, performanceStatus),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'ACWR',
                  value: acwr.toStringAsFixed(2),
                  color: statusColor(acwrStatus),
                  subtitle: statusText(lang, acwrStatus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: AppText.t(lang, 'Fatiga', 'Fatigue', 'Ermüdung'),
                  value: globalState.physiologyStatus.name.toUpperCase(),
                  color: statusColor(globalState.physiologyStatus.name),
                  subtitle: AppText.t(
                    lang,
                    'Estado actual',
                    'Current state',
                    'Aktueller Zustand',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _LoadSystemsCard(
            lang: lang,
            neuralLoad: neuralLoad,
            metabolicLoad: metabolicLoad,
            highIntensityMinutes: highIntensityMinutes,
            neuralColor: statusColor(loadStatus(neuralLoad.toDouble())),
            metabolicColor: statusColor(loadStatus(metabolicLoad.toDouble())),
          ),

          const SizedBox(height: 18),

          _WearableCard(
            lang: lang,
            hrv: hrv,
            sleepHours: sleepHours,
            restingHeartRate: restingHeartRate,
            stress: stress,
            soreness: soreness,
            source: wearable?.source,
          ),

          const SizedBox(height: 18),

          _LoadTrendCard(
            lang: lang,
            entries: entries,
            entryLoad: entryLoad,
          ),

          const SizedBox(height: 18),

          _RiskCard(
            lang: lang,
            acwr: acwr,
            acwrStatus: acwrStatus,
            color: statusColor(acwrStatus),
          ),

          const SizedBox(height: 18),

          _ProgressionProtectionCard(
            lang: lang,
            shouldBlockProgression: globalState.shouldBlockProgression,
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final AppLanguage lang;
  final int readiness;
  final String readinessStatus;
  final String recommendation;
  final Color color;
  final String statusText;

  const _ReadinessCard({
    required this.lang,
    required this.readiness,
    required this.readinessStatus,
    required this.recommendation,
    required this.color,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              AppText.t(lang, 'Readiness', 'Readiness', 'Readiness'),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: CircularProgressIndicator(
                    value: readiness / 100,
                    strokeWidth: 14,
                    color: color,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$readiness',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(recommendation, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PerformanceProtectionCard extends StatelessWidget {
  final AppLanguage lang;
  final double freshnessScore;
  final String status;
  final Color color;
  final String recommendation;

  const _PerformanceProtectionCard({
    required this.lang,
    required this.freshnessScore,
    required this.status,
    required this.color,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppText.t(
                      lang,
                      'Protección del rendimiento',
                      'Performance protection',
                      'Leistungsschutz',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetricRow(
              label: AppText.t(
                lang,
                'Frescura fisiológica',
                'Physiological freshness',
                'Physiologische Frische',
              ),
              value: freshnessScore.toStringAsFixed(0),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: freshnessScore / 100,
              minHeight: 12,
              borderRadius: BorderRadius.circular(20),
              color: color,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(recommendation),
          ],
        ),
      ),
    );
  }
}

class _LoadSystemsCard extends StatelessWidget {
  final AppLanguage lang;
  final int neuralLoad;
  final int metabolicLoad;
  final int highIntensityMinutes;
  final Color neuralColor;
  final Color metabolicColor;

  const _LoadSystemsCard({
    required this.lang,
    required this.neuralLoad,
    required this.metabolicLoad,
    required this.highIntensityMinutes,
    required this.neuralColor,
    required this.metabolicColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.t(
                lang,
                'Sistemas de carga',
                'Load systems',
                'Belastungssysteme',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 14),
            _SystemProgress(
              label: AppText.t(
                lang,
                'Carga neural',
                'Neural load',
                'Neuronale Belastung',
              ),
              value: neuralLoad,
              color: neuralColor,
            ),
            const SizedBox(height: 14),
            _SystemProgress(
              label: AppText.t(
                lang,
                'Carga metabólica',
                'Metabolic load',
                'Metabolische Belastung',
              ),
              value: metabolicLoad,
              color: metabolicColor,
            ),
            const SizedBox(height: 14),
            _MetricRow(
              label: AppText.t(
                lang,
                'Exposición estimada Z4/Z5',
                'Estimated Z4/Z5 exposure',
                'Geschätzte Z4/Z5-Belastung',
              ),
              value: '$highIntensityMinutes min',
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemProgress extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SystemProgress({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricRow(label: label, value: '$value / 100'),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100,
          minHeight: 10,
          borderRadius: BorderRadius.circular(20),
          color: color,
          backgroundColor: Colors.grey.shade300,
        ),
      ],
    );
  }
}

class _WearableCard extends StatelessWidget {
  final AppLanguage lang;
  final int hrv;
  final double sleepHours;
  final int restingHeartRate;
  final int stress;
  final int soreness;
  final String? source;

  const _WearableCard({
    required this.lang,
    required this.hrv,
    required this.sleepHours,
    required this.restingHeartRate,
    required this.stress,
    required this.soreness,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppText.t(
                    lang,
                    'Datos wearable aplicados',
                    'Applied wearable data',
                    'Angewendete Wearable-Daten',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                if (source != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      source!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricRow(label: 'HRV', value: '$hrv'),
            _MetricRow(
              label: AppText.t(lang, 'Sueño', 'Sleep', 'Schlaf'),
              value: '${sleepHours.toStringAsFixed(1)} h',
            ),
            _MetricRow(
              label: AppText.t(lang, 'FC reposo', 'Resting HR', 'Ruhepuls'),
              value: '$restingHeartRate',
            ),
            _MetricRow(
              label: AppText.t(lang, 'Estrés', 'Stress', 'Stress'),
              value: '$stress',
            ),
            _MetricRow(
              label: AppText.t(
                lang,
                'Dolor muscular',
                'Soreness',
                'Muskelkater',
              ),
              value: '$soreness/10',
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadTrendCard extends StatelessWidget {
  final AppLanguage lang;
  final List<TrainingHistoryEntry> entries;
  final double Function(TrainingHistoryEntry entry) entryLoad;

  const _LoadTrendCard({
    required this.lang,
    required this.entries,
    required this.entryLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.t(
                lang,
                'Carga últimos entrenamientos',
                'Recent training load',
                'Letzte Trainingsbelastung',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        AppText.t(
                          lang,
                          'Aún no hay historial suficiente.',
                          'Not enough history yet.',
                          'Noch nicht genug Verlauf.',
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            barWidth: 4,
                            spots: entries.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entryLoad(entry.value),
                              );
                            }).toList(),
                          ),
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

class _RiskCard extends StatelessWidget {
  final AppLanguage lang;
  final double acwr;
  final String acwrStatus;
  final Color color;

  const _RiskCard({
    required this.lang,
    required this.acwr,
    required this.acwrStatus,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber),
                const SizedBox(width: 10),
                Text(
                  AppText.t(
                    lang,
                    'Riesgo fisiológico',
                    'Physiological risk',
                    'Physiologisches Risiko',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: acwr > 2 ? 1 : acwr / 2,
              minHeight: 14,
              borderRadius: BorderRadius.circular(20),
              color: color,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              AppText.t(
                lang,
                'Ratio carga aguda/crónica: ${acwr.toStringAsFixed(2)}',
                'Acute/chronic workload ratio: ${acwr.toStringAsFixed(2)}',
                'Akut/chronisch Belastungsverhältnis: ${acwr.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionProtectionCard extends StatelessWidget {
  final AppLanguage lang;
  final bool shouldBlockProgression;

  const _ProgressionProtectionCard({
    required this.lang,
    required this.shouldBlockProgression,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          shouldBlockProgression ? Icons.lock : Icons.lock_open,
          color: shouldBlockProgression ? Colors.red : Colors.green,
        ),
        title: Text(
          AppText.t(
            lang,
            'Protección de progresión',
            'Progression protection',
            'Progressionsschutz',
          ),
        ),
        subtitle: Text(
          shouldBlockProgression
              ? AppText.t(
                  lang,
                  'Control de carga recomienda no aumentar la carga.',
                  'Load management recommends not increasing load.',
                  'Belastungssteuerung empfiehlt, die Belastung nicht zu erhöhen.',
                )
              : AppText.t(
                  lang,
                  'La progresión está habilitada.',
                  'Progression is enabled.',
                  'Progression ist erlaubt.',
                ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

