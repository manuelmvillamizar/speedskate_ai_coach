import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athlete_context_service.dart';
import 'athlete_program_service.dart';
import 'daily_training_assignment_service.dart';
import 'garmin_backend_api_service.dart';
import 'wearable_integration_service.dart';
import 'wearable_provider_service.dart';
import 'wearables/application/garmin_context_sync_service.dart';
import 'wearables/presentation/garmin_credentials_screen.dart';

// Ruta de Python (solo para Windows)
const String _pythonPath = r'C:\Python314\python.exe';

class AthleteWearableScreen extends StatefulWidget {
  const AthleteWearableScreen({super.key});

  @override
  State<AthleteWearableScreen> createState() => _AthleteWearableScreenState();
}

class _AthleteWearableScreenState extends State<AthleteWearableScreen> {
  WearableProviderType? connectedProvider;
  bool loading = false;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedProvider();
  }

  Future<void> _loadSavedProvider() async {
    final athlete = context.read<AthleteProgramService>().activeAthlete;

    if (athlete == null) {
      setState(() {
        connectedProvider = null;
        statusMessage = 'Primero selecciona o crea un atleta.';
      });
      return;
    }

    final provider = await WearableProviderService.loadSavedProvider(
      athleteId: athlete.id,
    );

    final connection = await WearableProviderService.loadConnection(
      athleteId: athlete.id,
    );

    if (!mounted) return;

    setState(() {
      connectedProvider = provider;
      statusMessage = connection?.message ?? 'Ningún dispositivo conectado.';
    });
  }

  Future<void> connectProvider(WearableProviderType provider) async {
    final athlete = context.read<AthleteProgramService>().activeAthlete;

    if (athlete == null) return;

    setState(() {
      loading = true;
    });

    if (provider == WearableProviderType.garmin) {
      final configured = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => GarminCredentialsScreen(athlete: athlete),
        ),
      );

      if (configured != true) {
        setState(() {
          loading = false;
          statusMessage = 'Configura las credenciales Garmin para este atleta.';
        });
        return;
      }

      final result = await _syncGarminForActiveAthlete(athlete);

      if (!mounted) return;

      setState(() {
        connectedProvider = provider;
        statusMessage = result.message;
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));

      return;
    }

    final connection = await WearableProviderService.connect(
      provider,
      athleteId: athlete.id,
    );

    await WearableProviderService.saveProvider(
      athleteId: athlete.id,
      provider: provider,
    );

    await WearableProviderService.saveConnection(connection);

    if (!mounted) return;

    if (connection.isConnected) {
      final wearable = await WearableProviderService.fetchToday(
        provider: provider,
        athleteId: athlete.id,
      );

      if (wearable != null) {
        context.read<AthleteContextService>().setWearableData(wearable);
      }
    }

    setState(() {
      connectedProvider = provider;
      statusMessage = connection.message;
      loading = false;
    });
  }

  Future<void> syncNow() async {
    final athlete = context.read<AthleteProgramService>().activeAthlete;

    if (athlete == null) return;

    final provider = connectedProvider;

    if (provider == null) return;

    setState(() {
      loading = true;
    });

    if (provider == WearableProviderType.garmin) {
      final result = await _syncGarminForActiveAthlete(athlete);

      if (!mounted) return;

      setState(() {
        statusMessage = result.message;
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));

      return;
    }

    final wearable = await WearableProviderService.fetchToday(
      provider: provider,
      athleteId: athlete.id,
    );

    if (!mounted) return;

    if (wearable != null) {
      context.read<AthleteContextService>().setWearableData(wearable);

      setState(() {
        statusMessage = 'Datos actualizados correctamente.';
      });
    } else {
      setState(() {
        statusMessage = 'No fue posible actualizar los datos.';
      });
    }

    setState(() {
      loading = false;
    });
  }

  Future<GarminContextSyncResult> _syncGarminForActiveAthlete(
    AthleteProgramProfile athlete,
  ) async {
    final athleteContext = context.read<AthleteContextService>();

    if (!athleteContext.hasActiveAthlete) {
      athleteContext.setActiveAthlete(athlete);
    }

    if (Platform.isAndroid || Platform.isIOS) {
      if (mounted) {
        setState(() {
          statusMessage = 'Actualizando datos del deportista...';
        });
      }

      try {
        // ✅ PASO 32 - FALLBACK INTELIGENTE PARA QUE LAS TARJETAS NO SE APAGUEN
        final wearableService = context.read<WearableIntegrationService>();

        WearableDailyData? fallbackWearable =
            athleteContext.activeWearable ?? wearableService.today;

        if (fallbackWearable == null ||
            (fallbackWearable.hrv <= 0 &&
                fallbackWearable.stress <= 0 &&
                fallbackWearable.bodyBattery <= 0)) {
          for (final item in wearableService.history.reversed) {
            if (item.hrv > 0 || item.stress > 0 || item.bodyBattery > 0) {
              fallbackWearable = item;
              break;
            }
          }
        }

        final result = await GarminBackendApiService.syncGarmin(
          athleteId: athlete.id,
          currentToday: fallbackWearable,
          onProgress: (message) {
            if (mounted) {
              setState(() {
                statusMessage = message;
              });
            }
          },
        );

        if (!mounted) {
          return const GarminContextSyncResult(
            success: false,
            message: 'Pantalla desmontada durante la actualización.',
          );
        }

        if (result.success && result.wearableData != null) {
          final wearableService = context.read<WearableIntegrationService>();

          for (final day in result.historyData) {
            await wearableService.setToday(
              athleteId: athlete.id,
              provider: 'Garmin',
              data: day,
            );
          }
          final syncResult =
              await GarminContextSyncService.syncToAthleteContext(
                athleteService: context.read<AthleteProgramService>(),
                athleteContext: athleteContext,
                wearableService: context.read<WearableIntegrationService>(),
                assignmentService: context
                    .read<DailyTrainingAssignmentService>(),
                sendToAthlete: true,
                externalWearableData: result.wearableData!,
                externalSource: 'garmin_backend_normalized',
              );

          return GarminContextSyncResult(
            success: true,
            message: '${result.message} ${syncResult.message}',
          );
        }

        return GarminContextSyncResult(success: false, message: result.message);
      } catch (e) {
        return GarminContextSyncResult(
          success: false,
          message: 'Error actualizando datos: $e',
        );
      }
    }

    try {
      if (mounted) {
        setState(() {
          statusMessage = 'Descargando datos del dispositivo...';
        });
      }

      final syncResult = await Process.run(_pythonPath, [
        'backend_tools/garmin_private_sync/garmin_sync.py',
        athlete.id,
      ], workingDirectory: Directory.current.path);

      if (syncResult.exitCode != 0) {
        throw Exception('Error en sync: ${syncResult.stderr}');
      }

      if (mounted) {
        setState(() {
          statusMessage = 'Preparando datos de entrenamiento...';
        });
      }

      final jsonResult = await Process.run(_pythonPath, [
        'backend_tools/garmin_private_sync/fit_to_speedskate_json.py',
        athlete.id,
      ], workingDirectory: Directory.current.path);

      if (jsonResult.exitCode != 0) {
        throw Exception('Error generando JSON: ${jsonResult.stderr}');
      }

      if (mounted) {
        setState(() {
          statusMessage = 'Actualizando información del atleta...';
        });
      }

      final source = File(
        'backend_tools/garmin_private_sync/athletes/${athlete.id}/garmin_latest_training.json',
      );

      final athleteDir = Directory('assets/data/garmin/${athlete.id}');

      if (!await athleteDir.exists()) {
        await athleteDir.create(recursive: true);
      }

      final dest = File(
        'assets/data/garmin/${athlete.id}/garmin_latest_training.json',
      );

      if (await source.exists()) {
        await source.copy(dest.path);
      } else {
        throw Exception(
          'No se encontró garmin_latest_training.json para ${athlete.id}',
        );
      }

      if (!mounted) {
        return const GarminContextSyncResult(
          success: false,
          message: 'Pantalla desmontada durante la actualización.',
        );
      }

      if (mounted) {
        setState(() {
          statusMessage = 'Actualizando plan de entrenamiento...';
        });
      }

      return await GarminContextSyncService.syncToAthleteContext(
        athleteService: context.read<AthleteProgramService>(),
        athleteContext: athleteContext,
        wearableService: context.read<WearableIntegrationService>(),
        assignmentService: context.read<DailyTrainingAssignmentService>(),
        sendToAthlete: true,
      );
    } catch (e) {
      return GarminContextSyncResult(
        success: false,
        message: 'Error actualizando Garmin: $e',
      );
    }
  }

  Future<void> disconnect() async {
    final athlete = context.read<AthleteProgramService>().activeAthlete;

    if (athlete == null) return;

    await WearableProviderService.clearConnection(athleteId: athlete.id);

    if (!mounted) return;

    setState(() {
      connectedProvider = null;
      statusMessage = 'Dispositivo desconectado.';
    });
  }

  String _providerTitle(AppLanguage lang, WearableProviderType provider) {
    switch (provider) {
      case WearableProviderType.demo:
        return AppText.t(
          lang,
          'Prueba sin dispositivo',
          'Test without device',
          'Test ohne Gerät',
        );
      case WearableProviderType.manual:
        return AppText.t(
          lang,
          'Ingresar datos manualmente',
          'Enter data manually',
          'Daten manuell eingeben',
        );
      case WearableProviderType.garmin:
        return AppText.t(
          lang,
          'Garmin recomendado',
          'Garmin recommended',
          'Garmin empfohlen',
        );
      case WearableProviderType.polar:
        return AppText.t(lang, 'Polar', 'Polar', 'Polar');
      case WearableProviderType.appleHealth:
        return AppText.t(lang, 'Apple Watch', 'Apple Watch', 'Apple Watch');
      default:
        return WearableProviderService.providerName(provider);
    }
  }

  String _providerDescription(AppLanguage lang, WearableProviderType provider) {
    switch (provider) {
      case WearableProviderType.demo:
        return AppText.t(
          lang,
          'Usa datos de prueba para revisar la experiencia del entrenador.',
          'Use test data to review the coach experience.',
          'Verwendet Testdaten, um die Traineransicht zu prüfen.',
        );
      case WearableProviderType.manual:
        return AppText.t(
          lang,
          'Registra información básica cuando el atleta no tiene dispositivo conectado.',
          'Log basic information when the athlete has no connected device.',
          'Erfasst Basisdaten, wenn kein Gerät verbunden ist.',
        );
      case WearableProviderType.garmin:
        return AppText.t(
          lang,
          'Actualiza recuperación, sueño, esfuerzo e intensidad desde Garmin.',
          'Updates recovery, sleep, effort and intensity from Garmin.',
          'Aktualisiert Erholung, Schlaf, Belastung und Intensität von Garmin.',
        );
      case WearableProviderType.polar:
        return AppText.t(
          lang,
          'Conecta datos del dispositivo Polar cuando esté disponible.',
          'Connects Polar device data when available.',
          'Verbindet Polar-Gerätedaten, sobald verfügbar.',
        );
      case WearableProviderType.appleHealth:
        return AppText.t(
          lang,
          'Conecta datos del Apple Watch cuando esté disponible.',
          'Connects Apple Watch data when available.',
          'Verbindet Apple-Watch-Daten, sobald verfügbar.',
        );
      default:
        return WearableProviderService.providerDescription(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final athlete = context.watch<AthleteProgramService>().activeAthlete;

    if (athlete == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppText.t(
              lang,
              'No hay atleta activo.',
              'No active athlete.',
              'Kein aktiver Athlet.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppText.t(
            lang,
            'Conectar dispositivo',
            'Connect device',
            'Gerät verbinden',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF111827),
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.watch, size: 44, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    athlete.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppText.t(
              lang,
              'Vincular dispositivo del deportista',
              'Link athlete device',
              'Gerät des Sportlers verbinden',
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _providerCard(
            context,
            lang,
            provider: WearableProviderType.demo,
            icon: Icons.science,
            color: Colors.purple,
          ),
          _providerCard(
            context,
            lang,
            provider: WearableProviderType.manual,
            icon: Icons.edit_note,
            color: Colors.orange,
          ),
          _providerCard(
            context,
            lang,
            provider: WearableProviderType.garmin,
            icon: Icons.watch,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _providerCard(
    BuildContext context,
    AppLanguage lang, {
    required WearableProviderType provider,
    required IconData icon,
    required Color color,
  }) {
    final selected = connectedProvider == provider;

    return Card(
      color: const Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _providerTitle(lang, provider),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _providerDescription(lang, provider),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading
                    ? null
                    : selected && provider == WearableProviderType.garmin
                    ? syncNow
                    : () => connectProvider(provider),
                icon: selected
                    ? const Icon(Icons.check)
                    : const Icon(Icons.link),
                label: Text(
                  selected && provider == WearableProviderType.garmin
                      ? AppText.t(
                          lang,
                          'Sincronizar Garmin',
                          'Sync Garmin',
                          'Garmin synchronisieren',
                        )
                      : selected
                      ? AppText.t(lang, 'Conectado', 'Connected', 'Verbunden')
                      : AppText.t(lang, 'Vincular', 'Link', 'Verbinden'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
