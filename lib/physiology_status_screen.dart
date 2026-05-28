import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athlete_context_service.dart';
import 'fatigue_engine.dart';
import 'physiology_sports_translator.dart';
import 'wearable_integration_service.dart';

class PhysiologyStatusScreen extends StatelessWidget {
  const PhysiologyStatusScreen({super.key});

  static const Color bg = Color(0xFF0B0B0F);
  static const Color cardBg = Color(0xFF17171C);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final athleteContext = context.watch<AthleteContextService>();
    final wearableService = context.watch<WearableIntegrationService>();

    final wearable = athleteContext.activeWearable ?? wearableService.today;
    final readiness = athleteContext.activeReadinessScore;
    final fatigueStatus = athleteContext.activeFatigueStatus;
    final readinessStatus = FatigueEngine.readinessStatus(readiness);

    final history = athleteContext.wearableHistory.isNotEmpty
        ? athleteContext.wearableHistory
        : wearableService.history;

    final dataQuality = athleteContext.activeDataQuality;

    final zoneHistory = history
        .where((item) => item.totalZoneMinutes > 0)
        .toList();

    final heartRateHistory = history
        .where((item) => item.averageHeartRate > 0 || item.maxHeartRate > 0)
        .toList();

    final zonesWearable = zoneHistory.isNotEmpty ? zoneHistory.last : wearable;

    final displayWearable = heartRateHistory.isNotEmpty
        ? heartRateHistory.last
        : wearable;

    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            AppText.t(
              lang,
              'Estado corporal del atleta',
              'Athlete body status',
              'Körperstatus des Athleten',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t(
              lang,
              'Lectura del dispositivo, recuperación y estado actual del atleta.',
              'Device reading, recovery and current athlete status.',
              'Gerätedaten, Erholung und aktueller Athletenstatus.',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _ReadinessHeader(
            lang: lang,
            readiness: readiness,
            readinessStatus: readinessStatus,
            fatigueStatus: fatigueStatus,
          ),
          const SizedBox(height: 12),
          _QuickStatusRow(lang: lang, wearable: wearable, readiness: readiness),
          const SizedBox(height: 12),
          if (wearable == null && history.isEmpty)
            _EmptyPhysiologyCard(lang: lang)
          else ...[
            if (wearable != null) ...[
              _RecoveryGrid(lang: lang, wearable: displayWearable ?? wearable),
              const SizedBox(height: 12),
              _TrainingLoadCard(
                lang: lang,
                wearable: displayWearable ?? wearable,
              ),
              const SizedBox(height: 12),
            ],

            _ChartCard(
              title: AppText.t(
                lang,
                'Tendencia de recuperación',
                'Recovery trend',
                'Erholungstrend',
              ),
              subtitle: AppText.t(
                lang,
                'Últimos registros disponibles del dispositivo.',
                'Latest available device records.',
                'Letzte verfügbare Gerätedaten.',
              ),
              child: _LineMetricChart(
                history: history,
                value: (item) => item.hrv.toDouble(),
                fallbackValue: wearable?.hrv.toDouble() ?? 0,
              ),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: AppText.t(
                lang,
                'Exigencia diaria',
                'Daily effort',
                'Tägliche Belastung',
              ),
              subtitle: AppText.t(
                lang,
                'Carga reportada por entrenamientos Garmin recientes.',
                'Load reported by recent Garmin sessions.',
                'Belastung aus aktuellen Garmin-Einheiten.',
              ),
              child: _BarLoadChart(history: history),
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: AppText.t(
                lang,
                'Distribución de intensidad',
                'Intensity distribution',
                'Intensitätsverteilung',
              ),
              subtitle: AppText.t(
                lang,
                'Tiempo acumulado en Z1-Z5 del último entrenamiento disponible.',
                'Time accumulated in Z1-Z5 from the latest available session.',
                'Zeit in Z1-Z5 aus der letzten verfügbaren Einheit.',
              ),
              child: _ZonePieChart(wearable: zonesWearable),
            ),
            const SizedBox(height: 12),

            if (zonesWearable != null) ...[
              _ZonesCard(lang: lang, wearable: zonesWearable),
              const SizedBox(height: 12),
            ],

            if ((wearable ?? zonesWearable) != null) ...[
              _PhysiologyRadarCard(
                lang: lang,
                wearable: wearable ?? zonesWearable!,
                readiness: readiness,
                dataQualityOk: true,
              ),
              const SizedBox(height: 12),
              _CoachInterpretationCard(
                lang: lang,
                wearable: wearable ?? zonesWearable!,
                readiness: readiness,
              ),
              const SizedBox(height: 12),
              _DataSourceCard(
                lang: lang,
                wearable: wearable ?? zonesWearable!,
                historyCount: history.length,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _DarkCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PhysiologyStatusScreen.cardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ReadinessHeader extends StatelessWidget {
  final AppLanguage lang;
  final int readiness;
  final String readinessStatus;
  final String fatigueStatus;

  const _ReadinessHeader({
    required this.lang,
    required this.readiness,
    required this.readinessStatus,
    required this.fatigueStatus,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(readinessStatus);

    return _DarkCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color,
            child: Text(
              '$readiness',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.t(
                    lang,
                    'Disponibilidad',
                    'Availability',
                    'Verfügbarkeit',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _readinessText(lang, readiness),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  '${AppText.t(lang, 'Fatiga', 'Fatigue', 'Müdigkeit')}: ${_fatigueText(lang, fatigueStatus)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatusRow extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData? wearable;
  final int readiness;

  const _QuickStatusRow({
    required this.lang,
    required this.wearable,
    required this.readiness,
  });

  @override
  Widget build(BuildContext context) {
    if (wearable == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _QuickPill(
            label: AppText.t(lang, 'Recuperación', 'Recovery', 'Erholung'),
            value: '$readiness%',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickPill(
            label: AppText.t(
              lang,
              'Recuperación nerviosa',
              'Nervous recovery',
              'Nervenerholung',
            ),
            value: wearable!.hrv > 0 ? '${wearable!.hrv}' : '-',
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickPill(
            label: AppText.t(lang, 'Sueño', 'Sleep', 'Schlaf'),
            value: wearable!.sleepHours > 0
                ? '${wearable!.sleepHours.toStringAsFixed(1)}h'
                : '-',
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickPill(
            label: AppText.t(lang, 'Exigencia', 'Effort', 'Belastung'),
            value: wearable!.trainingLoad > 0
                ? wearable!.trainingLoad.toStringAsFixed(0)
                : '-',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _QuickPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _RecoveryGrid extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData wearable;

  const _RecoveryGrid({required this.lang, required this.wearable});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          AppText.t(lang, 'Estado actual', 'Current status', 'Aktueller Stand'),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.05,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              title: AppText.t(lang, 'Recuperación', 'Recovery', 'Erholung'),
              value: wearable.hrv > 0 ? '${wearable.hrv}' : _noData(lang),
              subtitle: AppText.t(
                lang,
                'Sistema nervioso',
                'Nervous system',
                'Nervensystem',
              ),
              icon: Icons.favorite,
              color: wearable.hrv > 0 ? Colors.green : Colors.grey,
            ),
            _MetricCard(
              title: AppText.t(lang, 'Sueño', 'Sleep', 'Schlaf'),
              value: wearable.sleepHours > 0
                  ? '${wearable.sleepHours.toStringAsFixed(1)} h'
                  : _noData(lang),
              subtitle: AppText.t(
                lang,
                'Recuperación nocturna',
                'Night recovery',
                'Nächtliche Erholung',
              ),
              icon: Icons.bedtime,
              color: wearable.sleepHours > 0 ? Colors.indigo : Colors.grey,
            ),
            _MetricCard(
              title: AppText.t(lang, 'Estrés', 'Stress', 'Stress'),
              value: wearable.stress > 0 ? '${wearable.stress}' : _noData(lang),
              subtitle: AppText.t(
                lang,
                'Carga interna',
                'Internal strain',
                'Innere Belastung',
              ),
              icon: Icons.psychology,
              color: wearable.stress > 0 ? Colors.orange : Colors.grey,
            ),
            _MetricCard(
              title: AppText.t(lang, 'Energía', 'Energy', 'Energie'),
              value: wearable.bodyBattery > 0
                  ? '${wearable.bodyBattery}'
                  : _noData(lang),
              subtitle: AppText.t(
                lang,
                'Energía disponible',
                'Available energy',
                'Verfügbare Energie',
              ),
              icon: Icons.battery_charging_full,
              color: wearable.bodyBattery > 0 ? Colors.teal : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}

class _TrainingLoadCard extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData wearable;

  const _TrainingLoadCard({required this.lang, required this.wearable});

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            AppText.t(
              lang,
              'Exigencia del entrenamiento',
              'Training effort',
              'Trainingsbelastung',
            ),
          ),
          const SizedBox(height: 8),
          _LoadRow(
            label: AppText.t(lang, 'Exigencia', 'Effort', 'Belastung'),
            value: wearable.trainingLoad > 0
                ? wearable.trainingLoad.toStringAsFixed(1)
                : _noData(lang),
          ),
          _LoadRow(
            label: AppText.t(lang, 'Duración', 'Duration', 'Dauer'),
            value: wearable.totalTrainingMinutes > 0
                ? '${wearable.totalTrainingMinutes} min'
                : _noData(lang),
          ),
          _LoadRow(
            label: AppText.t(lang, 'Distancia', 'Distance', 'Distanz'),
            value: wearable.totalDistanceKm > 0
                ? '${wearable.totalDistanceKm.toStringAsFixed(1)} km'
                : _noData(lang),
          ),
          _LoadRow(
            label: AppText.t(
              lang,
              'Pulso medio',
              'Average pulse',
              'Durchschnittspuls',
            ),
            value: wearable.averageHeartRate > 0
                ? '${wearable.averageHeartRate}'
                : _noData(lang),
          ),
          _LoadRow(
            label: AppText.t(
              lang,
              'Pulso máximo',
              'Maximum pulse',
              'Maximalpuls',
            ),
            value: wearable.maxHeartRate > 0
                ? '${wearable.maxHeartRate}'
                : _noData(lang),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (wearable.trainingLoad / 800).clamp(0.0, 1.0),
            minHeight: 10,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }
}

class _ZonesCard extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData wearable;

  const _ZonesCard({required this.lang, required this.wearable});

  @override
  Widget build(BuildContext context) {
    final total = wearable.totalZoneMinutes;

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            AppText.t(lang, 'Detalle Z1-Z5', 'Z1-Z5 detail', 'Z1-Z5 Details'),
          ),
          const SizedBox(height: 8),
          if (total <= 0)
            Text(
              AppText.t(
                lang,
                'Sin distribución real de intensidad importada.',
                'No real intensity distribution imported.',
                'Keine echte Intensitätsverteilung importiert.',
              ),
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            _ZoneBar(label: 'Z1', value: wearable.zone1Minutes, total: total),
            _ZoneBar(label: 'Z2', value: wearable.zone2Minutes, total: total),
            _ZoneBar(label: 'Z3', value: wearable.zone3Minutes, total: total),
            _ZoneBar(label: 'Z4', value: wearable.zone4Minutes, total: total),
            _ZoneBar(label: 'Z5', value: wearable.zone5Minutes, total: total),
            const SizedBox(height: 8),
            Text(
              '${AppText.t(lang, 'Alta intensidad', 'High intensity', 'Hohe Intensität')}: ${wearable.highIntensityMinutes} min '
              '(${(wearable.highIntensityRatio * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
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
      surfaceTintColor: Colors.transparent,
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
  final double fallbackValue;

  const _LineMetricChart({
    required this.history,
    required this.value,
    required this.fallbackValue,
  });

  @override
  Widget build(BuildContext context) {
    final usable = history.where((item) => value(item) > 0).toList();

    final recent = usable.length > 14
        ? usable.sublist(usable.length - 14)
        : usable;

    if (recent.isEmpty && fallbackValue <= 0) {
      return const Center(
        child: Text(
          'Sin historial suficiente.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final chartValues = recent.isNotEmpty
        ? recent.map(value).toList()
        : [fallbackValue, fallbackValue];

    final minValue = chartValues.reduce((a, b) => a < b ? a : b);
    final maxValue = chartValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue).abs() < 5 ? 10.0 : 5.0;

    final spots = <FlSpot>[
      for (int i = 0; i < chartValues.length; i++)
        FlSpot(i.toDouble(), chartValues[i]),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF05070A),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: LineChart(
        LineChartData(
          minY: (minValue - padding).clamp(0, double.infinity),
          maxY: maxValue + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) {
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
                  return Text(
                    '${value.toInt() + 1}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF111827),
              getTooltipItems: (items) {
                return items.map((item) {
                  return LineTooltipItem(
                    item.y.toStringAsFixed(0),
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
    final usable = history.where((item) => item.trainingLoad > 0).toList();

    final recent = usable.length > 14
        ? usable.sublist(usable.length - 14)
        : usable;

    if (recent.isEmpty) {
      return const Center(
        child: Text(
          'Sin historial suficiente.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final maxLoad = recent
        .map((item) => item.trainingLoad)
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxLoad + 100,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) {
            return FlLine(
              color: Colors.white.withOpacity(0.10),
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
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.round().toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt() + 1}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFFF97316),
                      Color(0xFFEF4444),
                    ],
                  ),
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
      return const Center(
        child: Text(
          'Sin zonas Garmin disponibles.',
          style: TextStyle(color: Colors.white70),
        ),
      );
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

class _PhysiologyRadarCard extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData wearable;
  final int readiness;
  final bool dataQualityOk;

  const _PhysiologyRadarCard({
    required this.lang,
    required this.wearable,
    required this.readiness,
    required this.dataQualityOk,
  });

  @override
  Widget build(BuildContext context) {
    if (!dataQualityOk) {
      return _DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              AppText.t(
                lang,
                'Mapa físico del atleta',
                'Athlete physical map',
                'Körperprofil des Athleten',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppText.t(
                lang,
                'Todavía no hay suficientes datos reales para construir un mapa confiable.',
                'There is not enough real data yet to build a reliable map.',
                'Es gibt noch nicht genug echte Daten für ein zuverlässiges Profil.',
              ),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final recovery = readiness / 100;
    final stressLoad = ((100 - wearable.stress).clamp(0, 100)) / 100;
    final sleep = (wearable.sleepHours.clamp(0, 10)) / 10;
    final bodyBattery = wearable.bodyBattery.clamp(0, 100) / 100;
    final loadBalance = (1 - (wearable.trainingLoad / 800).clamp(0.0, 1.0))
        .clamp(0.0, 1.0);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            AppText.t(
              lang,
              'Mapa físico del atleta',
              'Athlete physical map',
              'Körperprofil des Athleten',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 5,
                radarBorderData: const BorderSide(color: Colors.white24),
                ticksTextStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
                titleTextStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                dataSets: [
                  RadarDataSet(
                    fillColor: Colors.blue.withOpacity(0.28),
                    borderColor: Colors.blueAccent,
                    entryRadius: 3,
                    borderWidth: 3,
                    dataEntries: [
                      RadarEntry(value: recovery),
                      RadarEntry(value: sleep),
                      RadarEntry(value: stressLoad),
                      RadarEntry(value: bodyBattery),
                      RadarEntry(value: loadBalance),
                    ],
                  ),
                ],
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(
                        text: AppText.t(
                          lang,
                          'Recuperación',
                          'Recovery',
                          'Erholung',
                        ),
                      );
                    case 1:
                      return RadarChartTitle(
                        text: AppText.t(lang, 'Sueño', 'Sleep', 'Schlaf'),
                      );
                    case 2:
                      return RadarChartTitle(
                        text: AppText.t(lang, 'Estrés', 'Stress', 'Stress'),
                      );
                    case 3:
                      return RadarChartTitle(
                        text: AppText.t(lang, 'Energía', 'Energy', 'Energie'),
                      );
                    case 4:
                      return RadarChartTitle(
                        text: AppText.t(
                          lang,
                          'Exigencia',
                          'Effort',
                          'Belastung',
                        ),
                      );
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppText.t(
              lang,
              'La forma del mapa ayuda a detectar desequilibrios entre recuperación, energía y exigencia.',
              'The shape helps detect imbalance between recovery, energy and effort.',
              'Die Form hilft dabei, Ungleichgewichte zwischen Erholung, Energie und Belastung zu erkennen.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CoachInterpretationCard extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData wearable;
  final int readiness;

  const _CoachInterpretationCard({
    required this.lang,
    required this.wearable,
    required this.readiness,
  });

  @override
  Widget build(BuildContext context) {
    final interpretations = <SportsMetricInterpretation>[
      PhysiologySportsTranslator.translateReadiness(readiness),
      if (wearable.sleepHours > 0)
        PhysiologySportsTranslator.translateSleep(wearable.sleepHours),
      if (wearable.trainingLoad > 0)
        PhysiologySportsTranslator.translateTrainingLoad(
          wearable.trainingLoad,
          350,
        ),
    ];

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            AppText.t(
              lang,
              'Interpretación para el entrenador',
              'Coach interpretation',
              'Trainerinterpretation',
            ),
          ),
          const SizedBox(height: 8),
          ...interpretations.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.severityIcon, color: item.severityColor),
              title: Text(
                item.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                item.explanation,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceCard extends StatelessWidget {
  final AppLanguage lang;
  final WearableDailyData wearable;
  final int historyCount;

  const _DataSourceCard({
    required this.lang,
    required this.wearable,
    required this.historyCount,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Text(
        '${AppText.t(lang, 'Dispositivo conectado', 'Connected device', 'Verbundenes Gerät')}: ${wearable.source}\n'
        '${AppText.t(lang, 'Registros históricos', 'History records', 'Historische Einträge')}: $historyCount\n'
        '${AppText.t(lang, 'Datos reales de entrenamiento', 'Real training data', 'Echte Trainingsdaten')}: ${wearable.hasAnyRealTrainingData ? AppText.t(lang, "sí", "yes", "ja") : AppText.t(lang, "no", "no", "nein")}',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.26), const Color(0xFF17171C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;

  const _ZoneBar({
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? value / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 9,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              '$value min',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadRow extends StatelessWidget {
  final String label;
  final String value;

  const _LoadRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EmptyPhysiologyCard extends StatelessWidget {
  final AppLanguage lang;

  const _EmptyPhysiologyCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Text(
        AppText.t(
          lang,
          'Todavía no hay lectura del dispositivo para este atleta. Conecta un dispositivo del atleta para comenzar a recibir información.',
          'There is no device reading for this athlete yet. Connect an athlete device to start receiving information.',
          'Für diesen Athleten gibt es noch keine Gerätedaten. Verbinde ein Gerät, um Informationen zu erhalten.',
        ),
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}

Color _statusColor(String status) {
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

String _fatigueText(AppLanguage lang, String fatigueStatus) {
  final normalized = fatigueStatus.toLowerCase();

  if (normalized.contains('green') || normalized.contains('verde')) {
    return AppText.t(lang, 'controlada', 'controlled', 'kontrolliert');
  }

  if (normalized.contains('yellow') || normalized.contains('amarillo')) {
    return AppText.t(lang, 'moderada', 'moderate', 'moderat');
  }

  if (normalized.contains('orange') || normalized.contains('naranja')) {
    return AppText.t(lang, 'acumulada', 'accumulated', 'angesammelt');
  }

  if (normalized.contains('red') || normalized.contains('rojo')) {
    return AppText.t(lang, 'alta', 'high', 'hoch');
  }

  return fatigueStatus;
}

String _readinessText(AppLanguage lang, int readiness) {
  if (readiness >= 85) {
    return AppText.t(
      lang,
      'Excelente disponibilidad para entrenar.',
      'Excellent availability to train.',
      'Ausgezeichnete Trainingsverfügbarkeit.',
    );
  }

  if (readiness >= 75) {
    return AppText.t(
      lang,
      'Buena respuesta al entrenamiento.',
      'Good training response.',
      'Gute Trainingsreaktion.',
    );
  }

  if (readiness >= 60) {
    return AppText.t(
      lang,
      'Estado aceptable, controlar exigencia.',
      'Acceptable status, control effort.',
      'Akzeptabler Zustand, Belastung kontrollieren.',
    );
  }

  if (readiness >= 40) {
    return AppText.t(
      lang,
      'Fatiga acumulada, conviene proteger.',
      'Accumulated fatigue, protection is recommended.',
      'Angesammelte Müdigkeit, Schutz wird empfohlen.',
    );
  }

  return AppText.t(
    lang,
    'Riesgo alto, priorizar recuperación.',
    'High risk, prioritize recovery.',
    'Hohes Risiko, Erholung priorisieren.',
  );
}

String _noData(AppLanguage lang) {
  return AppText.t(lang, 'Sin dato', 'No data', 'Keine Daten');
}
