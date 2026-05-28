import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_language.dart';
import 'app_text.dart';
import 'athletes_screen.dart';
import 'competition_calendar_screen.dart';
import 'global_state.dart';
import 'training_history_service.dart';
import 'history_screen.dart';
import 'wearable_integration_service.dart';
import 'athlete_context_service.dart';
import 'athlete_program_service.dart';
import 'daily_ai_training_screen.dart';
import 'weekly_planner_screen.dart';
import 'athlete_today_plan_screen.dart';
import 'athlete_wearable_screen.dart';
import 'daily_training_assignment_service.dart';
import 'physiology_profile_storage_service.dart';
import 'daily_auto_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await PhysiologyProfileStorageService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLanguageNotifier()),
        ChangeNotifierProvider<AthleteProgramService>.value(
          value: AthleteProgramService.instance,
        ),
        ChangeNotifierProvider(create: (_) => GlobalTrainingState()),
        ChangeNotifierProvider(create: (_) => TrainingHistoryService()),
        ChangeNotifierProvider(create: (_) => WearableIntegrationService()),
        ChangeNotifierProvider(create: (_) => AthleteContextService()),
        ChangeNotifierProvider(create: (_) => DailyTrainingAssignmentService()),
        ChangeNotifierProvider(create: (_) => DailyAutoSyncService()),
      ],
      child: const SpeedSkateApp(),
    ),
  );
}

class SpeedSkateApp extends StatelessWidget {
  const SpeedSkateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedSkate AI Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF07111F),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF111827),
          error: Color(0xFFEF4444),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07111F),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),

        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF0F172A)),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white70,
          selectedColor: Colors.white,
        ),

        dividerColor: Colors.white12,

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111827),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.4),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(color: Colors.white),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF111827),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1E293B),
          selectedColor: const Color(0xFF2563EB),
          disabledColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),

        canvasColor: const Color(0xFF111827),
        dialogBackgroundColor: const Color(0xFF111827),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF3B82F6),
          selectionColor: Color(0x663B82F6),
          selectionHandleColor: Color(0xFF3B82F6),
        ),

        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

enum UserRole { coach, athlete, admin }

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _login(BuildContext context, UserRole role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainShell(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, size: 76, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'SpeedSkate AI Coach',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppText.t(
                      lang,
                      'Planificación inteligente para patinaje de velocidad',
                      'Intelligent planning for speed skating',
                      'Intelligente Planung für Speedskating',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _LanguageSelector(lang: lang),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => _login(context, UserRole.coach),
                    icon: const Icon(Icons.sports),
                    label: Text(
                      AppText.t(
                        lang,
                        'Entrar como entrenador',
                        'Login as coach',
                        'Als Trainer anmelden',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _login(context, UserRole.athlete),
                    icon: const Icon(Icons.person),
                    label: Text(
                      AppText.t(
                        lang,
                        'Entrar como atleta',
                        'Login as athlete',
                        'Als Athlet anmelden',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _login(context, UserRole.admin),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: Text(
                      AppText.t(
                        lang,
                        'Entrar como administrador',
                        'Login as admin',
                        'Als Administrator anmelden',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppLanguage lang;

  const _LanguageSelector({required this.lang});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppLanguage>(
      segments: const [
        ButtonSegment(value: AppLanguage.es, label: Text('ES')),
        ButtonSegment(value: AppLanguage.en, label: Text('EN')),
        ButtonSegment(value: AppLanguage.de, label: Text('DE')),
      ],
      selected: {lang},
      onSelectionChanged: (value) {
        context.read<AppLanguageNotifier>().changeLanguage(value.first);
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final UserRole role;

  const MainShell({super.key, required this.role});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;
  bool autoSyncStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (autoSyncStarted) return;
    autoSyncStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runAutoSync(force: false);
    });
  }

  Future<void> _runAutoSync({required bool force}) async {
    final athleteProgramService = context.read<AthleteProgramService>();
    final athleteContextService = context.read<AthleteContextService>();
    final wearableIntegrationService = context
        .read<WearableIntegrationService>();
    final assignmentService = context.read<DailyTrainingAssignmentService>();
    final autoSyncService = context.read<DailyAutoSyncService>();

    await autoSyncService.runAutoSync(
      athleteService: athleteProgramService,
      athleteContext: athleteContextService,
      wearableService: wearableIntegrationService,
      assignmentService: assignmentService,
      force: force,
    );
  }

  String roleText(AppLanguage lang) {
    switch (widget.role) {
      case UserRole.coach:
        return AppText.t(lang, 'Entrenador', 'Coach', 'Trainer');
      case UserRole.athlete:
        return AppText.t(lang, 'Atleta', 'Athlete', 'Athlet');
      case UserRole.admin:
        return AppText.t(lang, 'Administrador', 'Admin', 'Administrator');
    }
  }

  List<_MenuItem> menuItems(AppLanguage lang) {
    if (widget.role == UserRole.coach) {
      return [
        _MenuItem(
          AppText.t(lang, 'Atletas', 'Athletes', 'Athleten'),
          Icons.groups,
          'athletes',
        ),
        _MenuItem(
          AppText.t(lang, 'Wearables', 'Wearables', 'Wearables'),
          Icons.watch,
          'wearables',
        ),
        _MenuItem(
          AppText.t(
            lang,
            'AI Coach Diario',
            'Daily AI Coach',
            'Täglicher KI Coach',
          ),
          Icons.auto_awesome,
          'aiCoach',
        ),
        _MenuItem(
          AppText.t(
            lang,
            'Plan semanal IA',
            'AI Weekly Planner',
            'KI Wochenplan',
          ),
          Icons.calendar_view_week,
          'weeklyPlanner',
        ),
        _MenuItem(
          AppText.t(lang, 'Calendario', 'Calendar', 'Kalender'),
          Icons.calendar_month,
          'calendar',
        ),
        _MenuItem(
          AppText.t(lang, 'Historial', 'History', 'Verlauf'),
          Icons.history,
          'history',
        ),
        _MenuItem(
          AppText.t(lang, 'Configuración', 'Settings', 'Einstellungen'),
          Icons.settings,
          'settings',
        ),
      ];
    }

    if (widget.role == UserRole.athlete) {
      return [
        _MenuItem(
          AppText.t(
            lang,
            'Entrenamiento de hoy',
            'Today training',
            'Heutiges Training',
          ),
          Icons.today,
          'athleteToday',
        ),
        _MenuItem(
          AppText.t(lang, 'Historial', 'History', 'Verlauf'),
          Icons.history,
          'history',
        ),
        _MenuItem(
          AppText.t(lang, 'Configuración', 'Settings', 'Einstellungen'),
          Icons.settings,
          'settings',
        ),
      ];
    }

    return [
      _MenuItem(
        AppText.t(lang, 'Atletas', 'Athletes', 'Athleten'),
        Icons.groups,
        'athletes',
      ),
      _MenuItem(
        AppText.t(lang, 'Calendario', 'Calendar', 'Kalender'),
        Icons.calendar_month,
        'calendar',
      ),
      _MenuItem(
        AppText.t(lang, 'Configuración', 'Settings', 'Einstellungen'),
        Icons.settings,
        'settings',
      ),
    ];
  }

  Widget currentPage(AppLanguage lang) {
    final items = menuItems(lang);

    if (selectedIndex >= items.length) {
      selectedIndex = 0;
    }

    final item = items[selectedIndex];

    if (item.keyName == 'athletes') return const AthletesScreen();
    if (item.keyName == 'wearables') return const AthleteWearableScreen();

    if (item.keyName == 'aiCoach') {
      return widget.role == UserRole.athlete
          ? const AthleteTodayPlanScreen()
          : const DailyAITrainingScreen();
    }

    if (item.keyName == 'athleteToday') return const AthleteTodayPlanScreen();
    if (item.keyName == 'weeklyPlanner') return const WeeklyPlannerScreen();
    if (item.keyName == 'calendar') return const CompetitionCalendarScreen();
    if (item.keyName == 'history') return const HistoryScreen();
    if (item.keyName == 'settings') return const SettingsPage();

    return PlaceholderPage(title: item.title);
  }

  void selectPage(int index) {
    setState(() {
      selectedIndex = index;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;
    final items = menuItems(lang);

    if (selectedIndex >= items.length) {
      selectedIndex = 0;
    }

    final currentTitle = items[selectedIndex].title;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
        actions: [
          Consumer<DailyAutoSyncService>(
            builder: (context, sync, _) {
              if (!sync.syncing) return const SizedBox.shrink();

              return const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: AppText.t(lang, 'Cerrar sesión', 'Logout', 'Abmelden'),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF07111F)),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SpeedSkate AI Coach\n${roleText(lang)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return ListTile(
                    selected: selectedIndex == index,
                    selectedTileColor: Colors.blue.withOpacity(0.10),
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () => selectPage(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: currentPage(lang),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String keyName;

  const _MenuItem(this.title, this.icon, this.keyName);
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppText.t(lang, 'Configuración', 'Settings', 'Einstellungen'),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppText.t(lang, 'Idioma', 'Language', 'Sprache')),
            subtitle: Text(
              AppText.t(
                lang,
                'Selecciona español, inglés o alemán',
                'Select Spanish, English or German',
                'Wähle Spanisch, Englisch oder Deutsch',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LanguageSelector(lang: lang),
      ],
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().current;

    return Center(
      child: Text(
        '$title\n${AppText.t(lang, 'Próximamente', 'Coming soon', 'Demnächst')}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
