import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _neonCyan = Color(0xFF00F5FF);
const Color _neonPink = Color(0xFFFF2FB1);
const Color _neonPurple = Color(0xFF8D4DFF);
const Color _neonGreen = Color(0xFF5CFF87);
const Color _deepBlack = Color(0xFF0A0B10);
const Color _panelBlack = Color(0xFF14151A);
const Color _panelBlackAlt = Color(0xFF10121A);

enum WeightUnit { kg, lb }

enum HeightUnit { cm, ft }

enum AppThemePreset { neon, classic, highContrast }

WeightUnit _globalWeightUnit = WeightUnit.kg;
HeightUnit _globalHeightUnit = HeightUnit.cm;
AppThemePreset _globalThemePreset = AppThemePreset.neon;
final ValueNotifier<int> _appThemeVersion = ValueNotifier<int>(0);

double _displayWeight(double weightKg) {
  if (_globalWeightUnit == WeightUnit.lb) {
    return weightKg * 2.20462;
  }
  return weightKg;
}

String _weightUnitLabel() {
  return _globalWeightUnit == WeightUnit.lb ? 'lb' : 'kg';
}

String formatWeight(double weightKg, {int decimals = 1}) {
  return '${_displayWeight(weightKg).toStringAsFixed(decimals)} ${_weightUnitLabel()}';
}

String formatHeight(double heightCm) {
  if (_globalHeightUnit == HeightUnit.ft) {
    final totalInches = heightCm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches - (feet * 12)).round();
    return '$feet\'$inches"';
  }
  return '${heightCm.toStringAsFixed(1)} cm';
}

Color _themeAccentColor() {
  switch (_globalThemePreset) {
    case AppThemePreset.classic:
      return const Color(0xFF4A90E2);
    case AppThemePreset.highContrast:
      return const Color(0xFFFFFF00);
    case AppThemePreset.neon:
      return _neonCyan;
  }
}

Color _themeSecondaryColor() {
  switch (_globalThemePreset) {
    case AppThemePreset.classic:
      return const Color(0xFF8FA3BF);
    case AppThemePreset.highContrast:
      return const Color(0xFF00FFFF);
    case AppThemePreset.neon:
      return _neonPurple;
  }
}

Color _themeSuccessColor() {
  switch (_globalThemePreset) {
    case AppThemePreset.classic:
      return const Color(0xFF66BB6A);
    case AppThemePreset.highContrast:
      return const Color(0xFF00FF66);
    case AppThemePreset.neon:
      return _neonGreen;
  }
}

Color _themeDangerColor() {
  switch (_globalThemePreset) {
    case AppThemePreset.classic:
      return const Color(0xFFEF5350);
    case AppThemePreset.highContrast:
      return const Color(0xFFFF3300);
    case AppThemePreset.neon:
      return _neonPink;
  }
}

Color _themePanelColor() {
  switch (_globalThemePreset) {
    case AppThemePreset.classic:
      return const Color(0xFF222833);
    case AppThemePreset.highContrast:
      return const Color(0xFF0A0A0A);
    case AppThemePreset.neon:
      return _panelBlackAlt;
  }
}

BoxDecoration _appBackgroundDecoration() {
  switch (_globalThemePreset) {
    case AppThemePreset.classic:
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1720), Color(0xFF1A2433), Color(0xFF0E141D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    case AppThemePreset.highContrast:
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF121212), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    case AppThemePreset.neon:
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [_deepBlack, _panelBlackAlt, _deepBlack],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
  }
}

BoxDecoration _appForegroundDecoration() {
  if (_globalThemePreset != AppThemePreset.neon) {
    return const BoxDecoration();
  }

  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        _neonCyan.withValues(alpha: 0.03),
        _neonPurple.withValues(alpha: 0.02),
        _neonPink.withValues(alpha: 0.03),
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
  );
}

void main() {
  runApp(const MyApp());
}

class ExerciseWeight {
  ExerciseWeight({
    required this.date,
    required this.weightKg,
    required this.reps,
    required this.series,
    this.notes = '',
  });

  DateTime date;
  double weightKg;
  int reps;
  int series;
  String notes;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'reps': reps,
      'series': series,
      'notes': notes,
    };
  }

  factory ExerciseWeight.fromJson(Map<String, dynamic> json) {
    return ExerciseWeight(
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: json['reps'] as int,
      series: json['series'] as int,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class Friend {
  Friend({required this.name, this.photo});

  String name;
  File? photo;

  Map<String, dynamic> toJson() {
    return {'name': name, 'photo': photo?.path};
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      name: json['name'] as String,
      photo: json['photo'] != null ? File(json['photo'] as String) : null,
    );
  }
}

class Exercise {
  Exercise({
    required this.name,
    this.photo,
    this.series = 0,
    this.reps = 0,
    this.weightKg = 0,
    this.friendWeightKg = 0,
    List<ExerciseWeight>? weightHistory,
    String? muscleGroup,
  })  : weightHistory = weightHistory ?? [],
        muscleGroup = muscleGroup ?? _getMuscleGroupFromName(name);

  String name;
  File? photo;
  int series;
  int reps;
  double weightKg;
  double friendWeightKg;
  final List<ExerciseWeight> weightHistory;
  String muscleGroup;

  double? get lastWeightKg {
    if (weightHistory.isEmpty) return null;
    return weightHistory.last.weightKg;
  }

  static String _getMuscleGroupFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('press de banca') ||
        lower.contains('apertura') ||
        lower.contains('fondos') ||
        lower.contains('pecho')) {
      return 'Pecho';
    } else if (lower.contains('dominada') ||
        lower.contains('remo') ||
        lower.contains('jalones') ||
        lower.contains('espalda')) {
      return 'Espalda';
    } else if (lower.contains('sentadilla') ||
        lower.contains('prensa') ||
        lower.contains('extensión') ||
        lower.contains('pierna')) {
      return 'Piernas';
    } else if (lower.contains('press militar') ||
        lower.contains('elevación') ||
        lower.contains('pájaro') ||
        lower.contains('hombro')) {
      return 'Hombro';
    } else if (lower.contains('curl') ||
        lower.contains('tríceps') ||
        lower.contains('martillo') ||
        lower.contains('brazo')) {
      return 'Brazos';
    }
    return 'Otros';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photo': photo?.path,
      'series': series,
      'reps': reps,
      'weightKg': weightKg,
      'friendWeightKg': friendWeightKg,
      'muscleGroup': muscleGroup,
      'weightHistory': weightHistory.map((w) => w.toJson()).toList(),
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      photo: json['photo'] != null ? File(json['photo'] as String) : null,
      series: json['series'] as int,
      reps: json['reps'] as int,
      weightKg: (json['weightKg'] as num).toDouble(),
      friendWeightKg: (json['friendWeightKg'] as num).toDouble(),
      muscleGroup: json['muscleGroup'] as String?,
      weightHistory: (json['weightHistory'] as List<dynamic>?)
          ?.map((e) => ExerciseWeight.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Section {
  Section({required this.name, List<Exercise>? exercises})
    : exercises = exercises ?? [];

  String name;
  final List<Exercise> exercises;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DayPlan {
  DayPlan({required this.label, List<Section>? sections})
    : sections = sections ?? [];

  final String label;
  final List<Section> sections;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      label: json['label'] as String,
      sections: (json['sections'] as List<dynamic>?)
          ?.map((s) => Section.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BodyPhoto {
  BodyPhoto({required this.date, required this.photo, this.weightKg = 0});

  DateTime date;
  File photo;
  double weightKg;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'photo': photo.path,
      'weightKg': weightKg,
    };
  }

  factory BodyPhoto.fromJson(Map<String, dynamic> json) {
    return BodyPhoto(
      date: DateTime.parse(json['date'] as String),
      photo: File(json['photo'] as String),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _appThemeVersion,
      builder: (context, _, themeTick) {
        ColorScheme colorScheme;
        Color scaffoldBg;
        Color cardBg;
        Color panelBg;
        Color accent;
        Color fabColor;

        switch (_globalThemePreset) {
          case AppThemePreset.classic:
            colorScheme = const ColorScheme.dark(
              primary: Color(0xFF4A90E2),
              secondary: Color(0xFF66BB6A),
              surface: Color(0xFF1E1E1E),
              onSurface: Color(0xFFF2F2F2),
              onPrimary: Colors.white,
              onSecondary: Colors.black,
            );
            scaffoldBg = const Color(0xFF121212);
            cardBg = const Color(0xFF1E1E1E);
            panelBg = const Color(0xFF2A2A2A);
            accent = const Color(0xFF4A90E2);
            fabColor = const Color(0xFF66BB6A);
            break;
          case AppThemePreset.highContrast:
            colorScheme = const ColorScheme.dark(
              primary: Color(0xFFFFFF00),
              secondary: Color(0xFF00FFFF),
              surface: Color(0xFF000000),
              onSurface: Color(0xFFFFFFFF),
              onPrimary: Colors.black,
              onSecondary: Colors.black,
            );
            scaffoldBg = const Color(0xFF000000);
            cardBg = const Color(0xFF0D0D0D);
            panelBg = const Color(0xFF121212);
            accent = const Color(0xFFFFFF00);
            fabColor = const Color(0xFF00FF66);
            break;
          case AppThemePreset.neon:
            colorScheme = const ColorScheme.dark(
              primary: _neonCyan,
              secondary: _neonPink,
              surface: _panelBlack,
              onSurface: Color(0xFFEAF6FF),
              onPrimary: Colors.black,
              onSecondary: Colors.black,
            );
            scaffoldBg = _deepBlack;
            cardBg = _panelBlack;
            panelBg = _panelBlackAlt;
            accent = _neonCyan;
            fabColor = _neonPink;
            break;
        }

        final baseTextTheme = GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

        return MaterialApp(
          key: ValueKey(themeTick),
          debugShowCheckedModeBanner: false,
          title: 'Gimnasio',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: scaffoldBg,
            cardColor: cardBg,
            textTheme: baseTextTheme,
            dialogTheme: DialogThemeData(backgroundColor: panelBg),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: panelBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent, width: 1.6),
              ),
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.black,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.6)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: accent),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: fabColor,
              foregroundColor: Colors.black,
            ),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Friend> _friends = [];
  int _primaryFriendIndex = -1;
  late int _selectedDayIndex;
  late int _todayIndex;
  bool _showAddSectionForm = false;
  late TextEditingController _sectionNameController;

  final List<DayPlan> _week = [
    DayPlan(label: 'Lunes'),
    DayPlan(label: 'Martes'),
    DayPlan(label: 'Miercoles'),
    DayPlan(label: 'Jueves'),
    DayPlan(label: 'Viernes'),
    DayPlan(label: 'Sabado'),
    DayPlan(label: 'Domingo'),
  ];
  final List<String> _dayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  double _userWeightKg = 0;
  double _userHeightCm = 0;
  final List<BodyPhoto> _bodyPhotos = [];

  String? get _primaryFriendName {
    if (_primaryFriendIndex < 0 || _primaryFriendIndex >= _friends.length) {
      return null;
    }
    return _friends[_primaryFriendIndex].name;
  }

  @override
  void initState() {
    super.initState();
    final weekdayIndex = DateTime.now().weekday - 1;
    _todayIndex = weekdayIndex.clamp(0, _week.length - 1);
    _selectedDayIndex = _todayIndex;
    _sectionNameController = TextEditingController();
    _loadData().then((_) {
      // Si la semana está vacía, crear datos de ejemplo
      if (_week.every((day) => day.sections.isEmpty)) {
        _initializeSampleData();
      }
    });
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar semana
      final weekJson = _week.map((day) => day.toJson()).toList();
      await prefs.setString('week', jsonEncode(weekJson));

      // Guardar amigos
      final friendsJson = _friends.map((f) => f.toJson()).toList();
      await prefs.setString('friends', jsonEncode(friendsJson));

      // Guardar fotos de progreso
      final bodyPhotosJson = _bodyPhotos.map((p) => p.toJson()).toList();
      await prefs.setString('bodyPhotos', jsonEncode(bodyPhotosJson));

      // Guardar datos personales
      await prefs.setDouble('userWeight', _userWeightKg);
      await prefs.setDouble('userHeight', _userHeightCm);
      await prefs.setInt('primaryFriend', _primaryFriendIndex);
      await prefs.setString('weightUnit', _globalWeightUnit.name);
      await prefs.setString('heightUnit', _globalHeightUnit.name);
      await prefs.setString('themePreset', _globalThemePreset.name);
    } catch (e) {
      debugPrint('Error al guardar: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar semana
      final weekJson = prefs.getString('week');
      if (weekJson != null) {
        final decoded = jsonDecode(weekJson) as List<dynamic>;
        _week.clear();
        for (final item in decoded) {
          _week.add(DayPlan.fromJson(item as Map<String, dynamic>));
        }
      }

      // Cargar amigos
      final friendsJson = prefs.getString('friends');
      if (friendsJson != null) {
        final decoded = jsonDecode(friendsJson) as List<dynamic>;
        _friends.clear();
        for (final item in decoded) {
          _friends.add(Friend.fromJson(item as Map<String, dynamic>));
        }
      }

      // Cargar fotos de progreso
      final bodyPhotosJson = prefs.getString('bodyPhotos');
      if (bodyPhotosJson != null) {
        final decoded = jsonDecode(bodyPhotosJson) as List<dynamic>;
        _bodyPhotos.clear();
        for (final item in decoded) {
          try {
            _bodyPhotos.add(BodyPhoto.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            // Skip photos with missing files
          }
        }
      }

      // Cargar datos personales
      _userWeightKg = prefs.getDouble('userWeight') ?? 0;
      _userHeightCm = prefs.getDouble('userHeight') ?? 0;
      _primaryFriendIndex = prefs.getInt('primaryFriend') ?? -1;

      final savedWeightUnit = prefs.getString('weightUnit');
      final savedHeightUnit = prefs.getString('heightUnit');
      final savedThemePreset = prefs.getString('themePreset');

      _globalWeightUnit = WeightUnit.values.firstWhere(
        (u) => u.name == savedWeightUnit,
        orElse: () => WeightUnit.kg,
      );
      _globalHeightUnit = HeightUnit.values.firstWhere(
        (u) => u.name == savedHeightUnit,
        orElse: () => HeightUnit.cm,
      );
      _globalThemePreset = AppThemePreset.values.firstWhere(
        (t) => t.name == savedThemePreset,
        orElse: () => AppThemePreset.neon,
      );
      _appThemeVersion.value++;

      setState(() {});
    } catch (e) {
      debugPrint('Error al cargar: $e');
    }
  }

  void _updateUnits(WeightUnit weightUnit, HeightUnit heightUnit) {
    setState(() {
      _globalWeightUnit = weightUnit;
      _globalHeightUnit = heightUnit;
    });
    _saveData();
  }

  void _updateTheme(AppThemePreset preset) {
    setState(() {
      _globalThemePreset = preset;
    });
    _appThemeVersion.value++;
    _saveData();
  }

  void _initializeSampleData() {
    final now = DateTime.now();

    // Limpiar datos anteriores
    for (final day in _week) {
      day.sections.clear();
    }

    // Ejercicios de ejemplo con historial
    final sampleExercises = {
      'Pecho': {
        'exercises': ['Press de banca', 'Aperturas con mancuernas', 'Fondos'],
        'weights': [80.0, 85.0, 90.0],
      },
      'Espalda': {
        'exercises': ['Dominadas', 'Remo con barra', 'Jalones al cuello'],
        'weights': [70.0, 75.0, 80.0],
      },
      'Piernas': {
        'exercises': ['Sentadillas', 'Prensa de piernas', 'Extensiones'],
        'weights': [100.0, 110.0, 120.0],
      },
      'Hombro': {
        'exercises': ['Press militar', 'Elevaciones laterales', 'Pájaros'],
        'weights': [50.0, 52.5, 55.0],
      },
      'Brazos': {
        'exercises': ['Curl de bíceps', 'Extensiones de tríceps', 'Martillos'],
        'weights': [30.0, 32.5, 35.0],
      },
    };

    final scheduleMap = {
      0: ['Pecho', 'Brazos'], // Lunes
      1: ['Espalda'], // Martes
      2: ['Piernas'], // Miércoles
      3: ['Hombro'], // Jueves
      4: ['Pecho', 'Brazos'], // Viernes
      5: ['Espalda', 'Piernas'], // Sábado
      6: [], // Domingo (descanso)
    };

    for (int day = 0; day < 7; day++) {
      final sectionNames = scheduleMap[day] ?? [];

      for (final sectionName in sectionNames) {
        final section = Section(name: sectionName);
        final exerciseList =
            sampleExercises[sectionName]?['exercises'] as List<String>?;
        final weights =
            sampleExercises[sectionName]?['weights'] as List<double>?;

        if (exerciseList != null && weights != null) {
          for (int i = 0; i < exerciseList.length; i++) {
            final exercise = Exercise(
              name: exerciseList[i],
              series: 3,
              reps: 10 + (i % 3) * 2,
              weightKg: weights[i % weights.length] - (5 - i),
            );

            // Agregar historial de pesos (últimos 3 registros)
            for (int j = 0; j < 3; j++) {
              final recordDate = now.subtract(Duration(days: (3 - j) * 3));
              exercise.weightHistory.add(
                ExerciseWeight(
                  date: recordDate,
                  weightKg: weights[i % weights.length] - (10 - j * 3),
                  reps: 10 + (i % 3) * 2,
                  series: 3,
                ),
              );
            }

            section.exercises.add(exercise);
          }
        }

        _week[day].sections.add(section);
      }
    }

    // Agregar datos personales de ejemplo
    _userWeightKg = 75.0;
    _userHeightCm = 180.0;

    setState(() {});
    _saveData();
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    super.dispose();
  }

  void _addSection() {
    final name = _sectionNameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    setState(() {
      _week[_selectedDayIndex].sections.add(Section(name: name));
      _sectionNameController.clear();
      _showAddSectionForm = false;
    });
    _saveData();
  }

  void _toggleAddSectionForm() {
    setState(() {
      _showAddSectionForm = !_showAddSectionForm;
      if (!_showAddSectionForm) {
        _sectionNameController.clear();
      }
    });
  }

  Future<void> _renameSection(Section section) async {
    final nameController = TextEditingController(text: section.name);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar sección'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la sección',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      return;
    }

    setState(() {
      section.name = newName;
    });
    _saveData();
  }

  Future<void> _deleteSection(Section section) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar sección'),
          content: Text('¿Seguro que deseas eliminar "${section.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _week[_selectedDayIndex].sections.remove(section);
    });
    _saveData();
  }

  Future<void> _openAddExercise(Section section) async {
    final nameController = TextEditingController();
    final seriesController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final friendWeightController = TextEditingController();
    final notesController = TextEditingController();
    File? selectedImage;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Nuevo ejercicio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.black12,
                          backgroundImage: selectedImage == null
                              ? null
                              : FileImage(selectedImage!),
                          child: selectedImage == null
                              ? const Icon(Icons.image, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final image = await pickImage(context);
                              if (image != null) {
                                setModalState(() {
                                  selectedImage = image;
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Foto de maquina'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Series',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repeticiones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_primaryFriendName != null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: friendWeightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Peso $_primaryFriendName (kg)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (ej: "Muy fácil", "Nuevo PR")',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final series = int.tryParse(seriesController.text.trim()) ?? 0;
    final reps = int.tryParse(repsController.text.trim()) ?? 0;
    final weight = double.tryParse(weightController.text.trim()) ?? 0;
    final friendWeight =
        double.tryParse(friendWeightController.text.trim()) ?? 0;
    final notes = notesController.text.trim();

    setState(() {
      final newExercise = Exercise(
        name: name,
        photo: selectedImage,
        series: series,
        reps: reps,
        weightKg: weight,
        friendWeightKg: friendWeight,
      );
      // Registrar en historial de pesos
      newExercise.weightHistory.add(
        ExerciseWeight(
          date: DateTime.now(),
          weightKg: weight,
          reps: reps,
          series: series,
          notes: notes,
        ),
      );
      section.exercises.add(newExercise);
    });
    _saveData();
  }

  Future<void> _openEditExercise(Exercise exercise) async {
    final seriesController = TextEditingController(text: '${exercise.series}');
    final repsController = TextEditingController(text: '${exercise.reps}');
    final weightController = TextEditingController(
      text: '${exercise.weightKg}',
    );
    final friendWeightController = TextEditingController(
      text: '${exercise.friendWeightKg}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar ${exercise.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: seriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Series',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeticiones',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_primaryFriendName != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: friendWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Peso $_primaryFriendName (kg)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                          _openQuickWeightLog(exercise);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Reg. Peso Hoy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == 'delete') {
      _deleteExercise(exercise);
      return;
    }

    if (result != 'save') {
      return;
    }

    setState(() {
      exercise.series = int.tryParse(seriesController.text.trim()) ?? 0;
      exercise.reps = int.tryParse(repsController.text.trim()) ?? 0;
      exercise.weightKg = double.tryParse(weightController.text.trim()) ?? 0;
      exercise.friendWeightKg =
          double.tryParse(friendWeightController.text.trim()) ?? 0;
    });
    _saveData();
  }

  Future<void> _openQuickWeightLog(Exercise exercise) async {
    final weightController = TextEditingController(
      text: exercise.lastWeightKg?.toStringAsFixed(1) ?? '',
    );
    final repsController =
        TextEditingController(text: '${exercise.weightHistory.lastOrNull?.reps ?? exercise.reps}');
    final friendWeightController = TextEditingController(
      text: exercise.friendWeightKg > 0 ? exercise.friendWeightKg.toStringAsFixed(1) : '',
    );
    final notesController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registrar: ${exercise.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hoy ${DateTime.now().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso levantado (kg)',
                    border: OutlineInputBorder(),
                    hintText: 'ej: 80.5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeticiones',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_primaryFriendName != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: friendWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Peso $_primaryFriendName (kg)',
                      border: const OutlineInputBorder(),
                      hintText: 'Opcional',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (ej: "Muy fácil", "Nuevo PR!")',
                    border: OutlineInputBorder(),
                    hintText: 'Opcional',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    if (result != 'save') {
      return;
    }

    final weight = double.tryParse(weightController.text.trim()) ?? 0.0;
    final reps = int.tryParse(repsController.text.trim()) ?? exercise.reps;
    final friendWeight = double.tryParse(friendWeightController.text.trim()) ?? 0.0;

    setState(() {
      exercise.weightHistory.add(
        ExerciseWeight(
          date: DateTime.now(),
          weightKg: weight,
          reps: reps,
          series: exercise.series,
          notes: notesController.text.trim(),
        ),
      );
      if (friendWeight > 0) {
        exercise.friendWeightKg = friendWeight;
      }
    });
    _saveData();
  }

  void _deleteExercise(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar ${exercise.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (final day in _week) {
                  for (final section in day.sections) {
                    section.exercises.removeWhere(
                      (e) => e.name == exercise.name,
                    );
                  }
                }
              });
              _saveData();
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _appBackgroundDecoration(),
        foregroundDecoration: _appForegroundDecoration(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(
                delay: const Duration(milliseconds: 80),
                child: _Header(
                  title: 'Gimnasio',
                  subtitle: 'Elige un dia para entrenar',
                  countLabel: '${_week.length} dias',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProgressPage(
                                week: _week,
                                userWeightKg: _userWeightKg,
                                userHeightCm: _userHeightCm,
                                onWeightsUpdated: (weight, height) {
                                  setState(() {
                                    _userWeightKg = weight;
                                    _userHeightCm = height;
                                  });
                                  _saveData();
                                },
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.trending_up, color: _themeSuccessColor()),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => BodyProgressPage(
                                    bodyPhotos: _bodyPhotos,
                                    onPhotosChanged: _saveData,
                                  ),
                                ),
                              )
                              .then((_) {
                                setState(() {});
                              });
                        },
                        icon: Icon(
                          Icons.photo_camera,
                          color: _themeSecondaryColor(),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final selectedIndex = await Navigator.of(context)
                              .push<int>(
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(
                                    friends: _friends,
                                    selectedIndex: _primaryFriendIndex,
                                    currentWeightUnit: _globalWeightUnit,
                                    currentHeightUnit: _globalHeightUnit,
                                    currentThemePreset: _globalThemePreset,
                                    onUnitsChanged: _updateUnits,
                                    onThemeChanged: _updateTheme,
                                  ),
                                ),
                              );
                          if (!mounted) {
                            return;
                          }
                          if (selectedIndex != null) {
                            setState(() {
                              _primaryFriendIndex = selectedIndex;
                            });
                            _saveData();
                          } else {
                            setState(() {});
                            _saveData();
                          }
                        },
                        icon: Icon(Icons.settings, color: _themeAccentColor()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Reveal(
                delay: const Duration(milliseconds: 160),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_week.length, (index) {
                        final day = _week[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == _week.length - 1 ? 0 : 12,
                          ),
                          child: _Reveal(
                            delay: Duration(milliseconds: 60 * index),
                            offset: const Offset(0, 0.08),
                            child: _DayDot(
                              initial: _dayInitials[index],
                              label: day.label,
                              selected: _selectedDayIndex == index,
                              isToday: _todayIndex == index,
                              onTap: () {
                                setState(() {
                                  _selectedDayIndex = index;
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_showAddSectionForm)
                _Reveal(
                  delay: const Duration(milliseconds: 280),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton.icon(
                      onPressed: _toggleAddSectionForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear sección'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                )
              else
                _Reveal(
                  delay: const Duration(milliseconds: 280),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      elevation: 4,
                      shadowColor: _themeAccentColor().withValues(alpha: 0.25),
                      color: _panelBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _themeAccentColor().withValues(alpha: 0.32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nueva sección',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _sectionNameController,
                              decoration: InputDecoration(
                                labelText:
                                    'Nombre (ej: Pecho, Espalda, Piernas)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addSection(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _toggleAddSectionForm,
                                    icon: const Icon(Icons.close),
                                    label: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _addSection,
                                    icon: const Icon(Icons.check),
                                    label: const Text('Guardar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _week[_selectedDayIndex].sections.isEmpty
                    ? _EmptyState(
                        title: 'Sin secciones',
                        subtitle: 'Crea una sección para ordenar ejercicios.',
                        icon: Icons.view_list,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemBuilder: (context, index) {
                          final section = _week[_selectedDayIndex].sections[index];
                          return _Reveal(
                            delay: Duration(milliseconds: 60 * index),
                            child: _ExpandableSectionCard(
                              section: section,
                              friendName: _primaryFriendName,
                              onAddExercise: () => _openAddExercise(section),
                              onEditExercise: _openEditExercise,
                              onRenameSection: () => _renameSection(section),
                              onDeleteSection: () => _deleteSection(section),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemCount: _week[_selectedDayIndex].sections.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    required this.week,
    required this.userWeightKg,
    required this.userHeightCm,
    required this.onWeightsUpdated,
  });

  final List<DayPlan> week;
  final double userWeightKg;
  final double userHeightCm;
  final Function(double, double) onWeightsUpdated;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String? _expandedExercise;

  Map<String, List<ExerciseWeight>> _getAllExercises() {
    final Map<String, List<ExerciseWeight>> exerciseMap = {};

    for (final day in widget.week) {
      for (final section in day.sections) {
        for (final exercise in section.exercises) {
          if (exerciseMap[exercise.name] == null) {
            exerciseMap[exercise.name] = [];
          }
          exerciseMap[exercise.name]!.addAll(exercise.weightHistory);
        }
      }
    }

    // Ordenar cada lista por fecha
    exerciseMap.forEach((_, weights) {
      weights.sort((a, b) => a.date.compareTo(b.date));
    });

    return exerciseMap;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDaysAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Hace $difference días';
    return _formatDate(date);
  }

  List<FlSpot> _createChartData(List<ExerciseWeight> weights) {
    final spots = <FlSpot>[];
    for (int i = 0; i < weights.length; i++) {
      spots.add(FlSpot(i.toDouble(), weights[i].weightKg));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _getAllExercises();

    return Scaffold(
      body: Container(
        decoration: _appBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(
                delay: const Duration(milliseconds: 80),
                child: _Header(
                  title: 'Progresión',
                  subtitle: 'Tu evolución por ejercicio',
                  countLabel: '${exercises.length} ejercicios',
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: exercises.isEmpty
                    ? _EmptyState(
                        title: 'Sin historial',
                        subtitle: 'Comienza a entrenar para ver tu progresión.',
                        icon: Icons.trending_up,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemBuilder: (context, index) {
                          final exerciseName = exercises.keys.toList()[index];
                          final weights = exercises[exerciseName]!;
                          final lastWeight = weights.last;
                          final firstWeight = weights.first;
                          final difference =
                              lastWeight.weightKg - firstWeight.weightKg;
                          final isPositive = difference >= 0;
                          final isExpanded = _expandedExercise == exerciseName;

                          return _Reveal(
                            delay: Duration(milliseconds: 60 * index),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _expandedExercise = isExpanded
                                      ? null
                                      : exerciseName;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: Card(
                                  elevation: isExpanded ? 8 : 4,
                                  shadowColor: isPositive
                                      ? _themeSuccessColor().withValues(alpha: 0.25)
                                      : _themeDangerColor().withValues(alpha: 0.25),
                                  color: _panelBlack,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: BorderSide(
                                      color: isPositive
                                          ? _themeSuccessColor().withValues(
                                              alpha: isExpanded ? 0.6 : 0.32,
                                            )
                                          : _themeDangerColor().withValues(
                                              alpha: isExpanded ? 0.6 : 0.32,
                                            ),
                                      width: isExpanded ? 2 : 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    exerciseName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${weights.length} registros',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  formatWeight(lastWeight.weightKg),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: _themeAccentColor(),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isPositive
                                                          ? Icons.trending_up
                                                          : Icons.trending_down,
                                                      color: isPositive
                                                          ? _themeSuccessColor()
                                                          : _themeDangerColor(),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${isPositive ? '+' : ''}${_displayWeight(difference).toStringAsFixed(1)} ${_weightUnitLabel()}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isPositive
                                                            ? _themeSuccessColor()
                                                            : _themeDangerColor(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              isExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: _themeAccentColor(),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _panelBlackAlt,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Último registro',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _getDaysAgo(
                                                      lastWeight.date,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _themeAccentColor(),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${lastWeight.series} × ${lastWeight.reps} @ ${formatWeight(lastWeight.weightKg)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (lastWeight.notes.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: _themeSecondaryColor()
                                                        .withValues(
                                                          alpha: 0.1,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: _themeSecondaryColor()
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.note,
                                                        color: _themeSecondaryColor(),
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          lastWeight.notes,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: _themeSecondaryColor(),
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (isExpanded) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            'Evolución del peso',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 200,
                                            child: LineChart(
                                              LineChartData(
                                                gridData: FlGridData(
                                                  show: true,
                                                  drawVerticalLine: false,
                                                  horizontalInterval:
                                                      weights.isEmpty
                                                      ? 1
                                                      : null,
                                                  getDrawingHorizontalLine:
                                                      (value) {
                                                        return FlLine(
                                                          color: _themeAccentColor()
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                          strokeWidth: 1,
                                                        );
                                                      },
                                                ),
                                                borderData: FlBorderData(
                                                  show: true,
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: _themeAccentColor()
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                    left: BorderSide(
                                                      color: _themeAccentColor()
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                titlesData: FlTitlesData(
                                                  show: true,
                                                  bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      getTitlesWidget:
                                                          (
                                                            double value,
                                                            TitleMeta meta,
                                                          ) {
                                                            if (value.toInt() %
                                                                    2 !=
                                                                0) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            final index = value
                                                                .toInt();
                                                            if (index < 0 ||
                                                                index >=
                                                                    weights
                                                                        .length) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8,
                                                                  ),
                                                              child: Text(
                                                                _formatDate(
                                                                  weights[index]
                                                                      .date,
                                                                ).substring(
                                                                  0,
                                                                  5,
                                                                ),
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color:
                                                                      Theme.of(
                                                                        context,
                                                                      ).colorScheme.onSurface.withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                  leftTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      getTitlesWidget:
                                                          (
                                                            double value,
                                                            TitleMeta meta,
                                                          ) {
                                                            return Text(
                                                              '${_displayWeight(value).toStringAsFixed(0)} ${_weightUnitLabel()}',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withValues(
                                                                          alpha:
                                                                              0.5,
                                                                        ),
                                                              ),
                                                            );
                                                          },
                                                      reservedSize: 40,
                                                    ),
                                                  ),
                                                ),
                                                lineBarsData: [
                                                  LineChartBarData(
                                                    spots: _createChartData(
                                                      weights,
                                                    ),
                                                    isCurved: true,
                                                    color: isPositive
                                                      ? _themeSuccessColor()
                                                      : _themeDangerColor(),
                                                    barWidth: 3,
                                                    isStrokeCapRound: true,
                                                    dotData: FlDotData(
                                                      show: true,
                                                      getDotPainter:
                                                          (
                                                            spot,
                                                            percent,
                                                            barData,
                                                            index,
                                                          ) {
                                                            return FlDotCirclePainter(
                                                              radius: 4,
                                                              color: isPositive
                                                                  ? _themeSuccessColor()
                                                                  : _themeDangerColor(),
                                                              strokeWidth: 2,
                                                              strokeColor:
                                                                  _panelBlack,
                                                            );
                                                          },
                                                    ),
                                                    belowBarData: BarAreaData(
                                                      show: true,
                                                      color:
                                                          (isPositive
                                                                  ? _themeSuccessColor()
                                                                  : _themeDangerColor())
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemCount: exercises.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BodyProgressPage extends StatefulWidget {
  const BodyProgressPage({
    super.key,
    required this.bodyPhotos,
    required this.onPhotosChanged,
  });

  final List<BodyPhoto> bodyPhotos;
  final VoidCallback onPhotosChanged;

  @override
  State<BodyProgressPage> createState() => _BodyProgressPageState();
}

class _BodyProgressPageState extends State<BodyProgressPage> {
  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Cámara'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Galería'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final weightController = TextEditingController();

      if (!mounted) return;
      final weight = await showDialog<double?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Agregar foto de progreso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Peso actual (kg)',
                  hintText: 'Opcional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final w = double.tryParse(weightController.text.trim()) ?? 0;
                Navigator.pop(context, w);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (weight == null) return;

      final photo = BodyPhoto(
        date: DateTime.now(),
        photo: File(pickedFile.path),
        weightKg: weight,
      );

      setState(() {
        widget.bodyPhotos.add(photo);
        widget.bodyPhotos.sort((a, b) => b.date.compareTo(a.date));
      });
      widget.onPhotosChanged();
    } catch (e) {
      debugPrint('Error al seleccionar foto: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDaysAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Ayer';
    if (difference < 7) return 'Hace $difference días';
    return _formatDate(date);
  }

  List<FlSpot> _createWeightChartData() {
    final photosWithWeight = widget.bodyPhotos
        .where((p) => p.weightKg > 0)
        .toList();
    if (photosWithWeight.isEmpty) return [];

    final spots = <FlSpot>[];
    for (int i = 0; i < photosWithWeight.length; i++) {
      spots.add(FlSpot(i.toDouble(), photosWithWeight[i].weightKg));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final photosWithWeight = widget.bodyPhotos
        .where((p) => p.weightKg > 0)
        .toList();
    final hasWeightData = photosWithWeight.isNotEmpty;
    final chartData = _createWeightChartData();

    return Scaffold(
      body: Container(
        decoration: _appBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(
                delay: const Duration(milliseconds: 80),
                child: _Header(
                  title: 'Progreso Corporal',
                  subtitle: 'Tu transformación visual',
                  countLabel: '${widget.bodyPhotos.length} fotos',
                  onBack: () => Navigator.of(context).pop(),
                  trailing: IconButton(
                    onPressed: _addPhoto,
                    icon: Icon(Icons.add_a_photo, color: _themeAccentColor()),
                  ),
                ),
              ),
              if (hasWeightData) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _Reveal(
                    delay: const Duration(milliseconds: 160),
                    child: Card(
                      elevation: 4,
                      shadowColor: _themeSuccessColor().withValues(alpha: 0.25),
                      color: _panelBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _themeSuccessColor().withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progresión de peso',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 160,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: _themeSuccessColor().withValues(
                                          alpha: 0.15,
                                        ),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _themeSuccessColor().withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      left: BorderSide(
                                        color: _themeSuccessColor().withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() % 2 != 0 ||
                                              value.toInt() >=
                                                  photosWithWeight.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final idx = value.toInt();
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              _formatDate(
                                                photosWithWeight[idx].date,
                                              ).substring(0, 5),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()} kg',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                          );
                                        },
                                        reservedSize: 40,
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: chartData,
                                      isCurved: true,
                                      color: _themeSuccessColor(),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 4,
                                                color: _themeSuccessColor(),
                                                strokeWidth: 2,
                                                strokeColor: _panelBlack,
                                              );
                                            },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: _themeSuccessColor().withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: widget.bodyPhotos.isEmpty
                    ? _EmptyState(
                        title: 'Sin fotos',
                        subtitle:
                            'Sube una foto para comenzar a rastrear tu progreso.',
                        icon: Icons.image,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: widget.bodyPhotos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final photo = widget.bodyPhotos[index];
                          final daysAgo = _getDaysAgo(photo.date);

                          return _Reveal(
                            delay: Duration(milliseconds: 60 * index),
                            child: GestureDetector(
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Gestionar foto'),
                                    content: Text(
                                      photo.weightKg > 0
                                      ? 'Peso: ${formatWeight(photo.weightKg)}\n\n¿Qué deseas hacer?'
                                          : 'Sin peso registrado\n\n¿Qué deseas hacer?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      if (photo.weightKg > 0)
                                        TextButton(
                                          onPressed: () {
                                            final weightController =
                                                TextEditingController(
                                                  text: photo.weightKg
                                                      .toString(),
                                                );
                                            Navigator.pop(context);
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Editar peso',
                                                ),
                                                content: TextField(
                                                  controller: weightController,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Nuevo peso (kg)',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final w =
                                                          double.tryParse(
                                                            weightController
                                                                .text
                                                                .trim(),
                                                          ) ??
                                                          0;
                                                      setState(() {
                                                        photo.weightKg = w;
                                                      });
                                                      widget.onPhotosChanged();
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'Guardar',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('Editar peso'),
                                        ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            widget.bodyPhotos.removeAt(index);
                                          });
                                          widget.onPhotosChanged();
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shadowColor: _themeAccentColor().withValues(alpha: 0.25),
                                color: _panelBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: _themeAccentColor().withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Image.file(
                                        photo.photo,
                                        width: double.infinity,
                                        height: 280,
                                        fit: BoxFit.cover,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      daysAgo,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _themeAccentColor(),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatDate(photo.date),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Icon(
                                                  Icons.touch_app,
                                                  color: _themeDangerColor().withValues(
                                                    alpha: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (photo.weightKg > 0) ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _panelBlackAlt,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _themeSuccessColor()
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.monitor_weight,
                                                      color: _themeSuccessColor(),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      formatWeight(photo.weightKg),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: _themeSuccessColor(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.friends,
    required this.selectedIndex,
    required this.currentWeightUnit,
    required this.currentHeightUnit,
    required this.currentThemePreset,
    required this.onUnitsChanged,
    required this.onThemeChanged,
  });

  final List<Friend> friends;
  final int selectedIndex;
  final WeightUnit currentWeightUnit;
  final HeightUnit currentHeightUnit;
  final AppThemePreset currentThemePreset;
  final void Function(WeightUnit, HeightUnit) onUnitsChanged;
  final void Function(AppThemePreset) onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _selectedIndex;
  late WeightUnit _weightUnit;
  late HeightUnit _heightUnit;
  late AppThemePreset _themePreset;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _weightUnit = widget.currentWeightUnit;
    _heightUnit = widget.currentHeightUnit;
    _themePreset = widget.currentThemePreset;
  }

  Future<void> _openAddFriend() async {
    final nameController = TextEditingController();
    File? selectedImage;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Agregar amigo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black12,
                          backgroundImage: selectedImage == null
                              ? null
                              : FileImage(selectedImage!),
                          child: selectedImage == null
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final image = await pickImage(context);
                              if (image != null) {
                                setModalState(() {
                                  selectedImage = image;
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Agregar foto'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    setState(() {
      widget.friends.add(Friend(name: name, photo: selectedImage));
      if (_selectedIndex < 0) {
        _selectedIndex = widget.friends.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_selectedIndex);
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddFriend,
          icon: const Icon(Icons.person_add),
          label: const Text('Agregar amigo'),
        ),
        body: Container(
        decoration: _appBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(
                delay: const Duration(milliseconds: 80),
                child: _Header(
                  title: 'Configuración',
                  subtitle: 'Amigos y preferencias',
                  countLabel: '${widget.friends.length} amigos',
                  onBack: () => Navigator.of(context).pop(_selectedIndex),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                  children: [
                    _Reveal(
                      delay: const Duration(milliseconds: 60),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _themePanelColor(),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _themeAccentColor().withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preferencias de la app',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<WeightUnit>(
                              initialValue: _weightUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidad de peso',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: WeightUnit.kg,
                                  child: Text('Kilogramos (kg)'),
                                ),
                                DropdownMenuItem(
                                  value: WeightUnit.lb,
                                  child: Text('Libras (lb)'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _weightUnit = value;
                                });
                                widget.onUnitsChanged(_weightUnit, _heightUnit);
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<HeightUnit>(
                              initialValue: _heightUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidad de altura',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: HeightUnit.cm,
                                  child: Text('Centímetros (cm)'),
                                ),
                                DropdownMenuItem(
                                  value: HeightUnit.ft,
                                  child: Text('Pies (ft)'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _heightUnit = value;
                                });
                                widget.onUnitsChanged(_weightUnit, _heightUnit);
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<AppThemePreset>(
                              initialValue: _themePreset,
                              decoration: const InputDecoration(
                                labelText: 'Tema de color',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: AppThemePreset.neon,
                                  child: Text('Neón'),
                                ),
                                DropdownMenuItem(
                                  value: AppThemePreset.classic,
                                  child: Text('Clásico'),
                                ),
                                DropdownMenuItem(
                                  value: AppThemePreset.highContrast,
                                  child: Text('Alto contraste'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _themePreset = value;
                                });
                                widget.onThemeChanged(_themePreset);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sección de amigos
                    Text(
                      'Mis amigos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.friends.isEmpty)
                      _Reveal(
                        child: Center(
                          child: Text(
                            'Sin amigos aún',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        widget.friends.length,
                        (index) {
                          final friend = widget.friends[index];
                          return _Reveal(
                            delay: Duration(milliseconds: 60 * (index + 1)),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SelectableFriendCard(
                                friend: friend,
                                selected: _selectedIndex == index,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    // Sección de información personal
                    _Reveal(
                      delay: const Duration(milliseconds: 80),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _themePanelColor(),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _themeAccentColor().withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: _themeAccentColor().withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: _themeAccentColor(),
                                  child: Icon(Icons.person, size: 28, color: Colors.black),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Felipe Paimilla',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ingeniero Civil Informático',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sobre mi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _themeAccentColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Estudiante de Ingeniería Civil Informática en la Universidad de Playa Ancha. Especializado en automatización de procesos, desarrollo web y soporte técnico. He trabajado en proyectos como sistemas de inventario digital, migrations de plataformas CMS y optimización de flujos de trabajo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: const Text('Flutter', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeAccentColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeAccentColor().withValues(alpha: 0.3)),
                                ),
                                Chip(
                                  label: const Text('Dart', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeSecondaryColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeSecondaryColor().withValues(alpha: 0.3)),
                                ),
                                Chip(
                                  label: const Text('Automatización', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeSuccessColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeSuccessColor().withValues(alpha: 0.3)),
                                ),
                                Chip(
                                  label: const Text('Backend', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeDangerColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeDangerColor().withValues(alpha: 0.3)),
                                ),
                                Chip(
                                  label: const Text('Cloud & AI Enthusiast', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeAccentColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeAccentColor().withValues(alpha: 0.3)),
                                ),
                                Chip(
                                  label: const Text('Python Developer', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeSecondaryColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeSecondaryColor().withValues(alpha: 0.3)),
                                ),
                                Chip(
                                  label: const Text('Scrum Certified Agile', style: TextStyle(fontSize: 11)),
                                  backgroundColor: _themeSuccessColor().withValues(alpha: 0.15),
                                  side: BorderSide(color: _themeSuccessColor().withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.parse('https://github.com/Paimilla');
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    icon: const Icon(Icons.code, size: 16),
                                    label: const Text('GitHub', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Email'),
                                            content: const SelectableText('fpaimilla@gmail.com'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('Cerrar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.email, size: 16),
                                    label: const Text('Email', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://www.linkedin.com/in/felipe-paimilla-4000a2206/',
                                  );
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.work_outline, size: 16),
                                label: const Text(
                                  'LinkedIn',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class DayDetailPage extends StatefulWidget {
  const DayDetailPage({super.key, required this.dayPlan, this.friendName, this.onSave});

  final DayPlan dayPlan;
  final String? friendName;
  final Future<void> Function()? onSave;

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  bool _showAddSectionForm = false;
  late TextEditingController _sectionNameController;

  @override
  void initState() {
    super.initState();
    _sectionNameController = TextEditingController();
  }

  @override
  void dispose() {
    _sectionNameController.dispose();
    widget.onSave?.call();
    super.dispose();
  }

  void _addSection() {
    final name = _sectionNameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    setState(() {
      widget.dayPlan.sections.add(Section(name: name));
      _sectionNameController.clear();
      _showAddSectionForm = false;
    });
  }

  void _toggleAddSectionForm() {
    setState(() {
      _showAddSectionForm = !_showAddSectionForm;
      if (!_showAddSectionForm) {
        _sectionNameController.clear();
      }
    });
  }

  Future<void> _renameSection(Section section) async {
    final nameController = TextEditingController(text: section.name);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar sección'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la sección',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      return;
    }

    setState(() {
      section.name = newName;
    });
    await widget.onSave?.call();
  }

  Future<void> _deleteSection(Section section) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar sección'),
          content: Text('¿Seguro que deseas eliminar "${section.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      widget.dayPlan.sections.remove(section);
    });
    await widget.onSave?.call();
  }

  Future<void> _openAddExercise(Section section) async {
    final nameController = TextEditingController();
    final seriesController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final friendWeightController = TextEditingController();
    final notesController = TextEditingController();
    File? selectedImage;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Nuevo ejercicio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.black12,
                          backgroundImage: selectedImage == null
                              ? null
                              : FileImage(selectedImage!),
                          child: selectedImage == null
                              ? const Icon(Icons.image, size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final image = await pickImage(context);
                              if (image != null) {
                                setModalState(() {
                                  selectedImage = image;
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Foto de maquina'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Series',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repeticiones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (widget.friendName != null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: friendWeightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Peso ${widget.friendName} (kg)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (ej: "Muy fácil", "Nuevo PR")',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final series = int.tryParse(seriesController.text.trim()) ?? 0;
    final reps = int.tryParse(repsController.text.trim()) ?? 0;
    final weight = double.tryParse(weightController.text.trim()) ?? 0;
    final friendWeight =
        double.tryParse(friendWeightController.text.trim()) ?? 0;
    final notes = notesController.text.trim();

    setState(() {
      final newExercise = Exercise(
        name: name,
        photo: selectedImage,
        series: series,
        reps: reps,
        weightKg: weight,
        friendWeightKg: friendWeight,
      );
      newExercise.weightHistory.add(
        ExerciseWeight(
          date: DateTime.now(),
          weightKg: weight,
          reps: reps,
          series: series,
          notes: notes,
        ),
      );
      section.exercises.add(newExercise);
    });
  }

  Future<void> _openEditExercise(Exercise exercise) async {
    final seriesController = TextEditingController(text: '${exercise.series}');
    final repsController = TextEditingController(text: '${exercise.reps}');
    final weightController = TextEditingController(
      text: '${exercise.weightKg}',
    );
    final friendWeightController = TextEditingController(
      text: '${exercise.friendWeightKg}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar ${exercise.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: seriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Series',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeticiones',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.friendName != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: friendWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Peso ${widget.friendName} (kg)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                          _openQuickWeightLog(exercise);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Reg. Peso Hoy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == 'delete') {
      _deleteExerciseFromSection(exercise);
      return;
    }

    if (result != 'save') {
      return;
    }

    setState(() {
      exercise.series = int.tryParse(seriesController.text.trim()) ?? 0;
      exercise.reps = int.tryParse(repsController.text.trim()) ?? 0;
      exercise.weightKg = double.tryParse(weightController.text.trim()) ?? 0;
      exercise.friendWeightKg =
          double.tryParse(friendWeightController.text.trim()) ?? 0;
    });
  }

  Future<void> _openQuickWeightLog(Exercise exercise) async {
    final weightController = TextEditingController(
      text: exercise.lastWeightKg?.toStringAsFixed(1) ?? '',
    );
    final repsController =
        TextEditingController(text: '${exercise.weightHistory.lastOrNull?.reps ?? exercise.reps}');
    final friendWeightController = TextEditingController(
      text: exercise.friendWeightKg > 0 ? exercise.friendWeightKg.toStringAsFixed(1) : '',
    );
    final notesController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registrar: ${exercise.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hoy ${DateTime.now().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso levantado (kg)',
                    border: OutlineInputBorder(),
                    hintText: 'ej: 80.5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeticiones',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.friendName != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: friendWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Peso ${widget.friendName} (kg)',
                      border: const OutlineInputBorder(),
                      hintText: 'Opcional',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (ej: "Muy fácil", "Nuevo PR!")',
                    border: OutlineInputBorder(),
                    hintText: 'Opcional',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    if (result != 'save') {
      return;
    }

    final weight = double.tryParse(weightController.text.trim()) ?? 0.0;
    final reps = int.tryParse(repsController.text.trim()) ?? exercise.reps;
    final friendWeight = double.tryParse(friendWeightController.text.trim()) ?? 0.0;

    setState(() {
      exercise.weightHistory.add(
        ExerciseWeight(
          date: DateTime.now(),
          weightKg: weight,
          reps: reps,
          series: exercise.series,
          notes: notesController.text.trim(),
        ),
      );
      if (friendWeight > 0) {
        exercise.friendWeightKg = friendWeight;
      }
    });
  }

  void _deleteExerciseFromSection(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar ${exercise.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Buscar el ejercicio en todas las secciones y eliminarlo
                for (final section in widget.dayPlan.sections) {
                  section.exercises.removeWhere((e) => e.name == exercise.name);
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _appBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Reveal(
                delay: const Duration(milliseconds: 80),
                child: _Header(
                  title: widget.dayPlan.label,
                  subtitle: 'Secciones del entrenamiento',
                  countLabel: '${widget.dayPlan.sections.length} secciones',
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 12),
              if (!_showAddSectionForm)
                _Reveal(
                  delay: const Duration(milliseconds: 160),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FilledButton.icon(
                      onPressed: _toggleAddSectionForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear seccion'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                )
              else
                _Reveal(
                  delay: const Duration(milliseconds: 160),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      elevation: 4,
                      shadowColor: _themeAccentColor().withValues(alpha: 0.25),
                      color: _panelBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: _themeAccentColor().withValues(alpha: 0.32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nueva sección',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _sectionNameController,
                              decoration: InputDecoration(
                                labelText:
                                    'Nombre (ej: Pecho, Espalda, Piernas)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addSection(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _toggleAddSectionForm,
                                    icon: const Icon(Icons.close),
                                    label: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _addSection,
                                    icon: const Icon(Icons.check),
                                    label: const Text('Guardar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: widget.dayPlan.sections.isEmpty
                    ? _EmptyState(
                        title: 'Sin secciones',
                        subtitle: 'Crea una seccion para ordenar ejercicios.',
                        icon: Icons.view_list,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemBuilder: (context, index) {
                          final section = widget.dayPlan.sections[index];
                          return _Reveal(
                            delay: Duration(milliseconds: 60 * index),
                            child: _ExpandableSectionCard(
                              section: section,
                              friendName: widget.friendName,
                              onAddExercise: () => _openAddExercise(section),
                              onEditExercise: _openEditExercise,
                              onRenameSection: () => _renameSection(section),
                              onDeleteSection: () => _deleteSection(section),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemCount: widget.dayPlan.sections.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _shown = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      opacity: _shown ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: _shown ? Offset.zero : widget.offset,
        child: widget.child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              CircleAvatar(
                radius: 22,
                backgroundColor: _themeAccentColor(),
                child: Icon(Icons.local_fire_department, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _panelBlackAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _themeAccentColor().withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: _themeAccentColor().withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  countLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _themeAccentColor(),
                  ),
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [trailing!],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: _panelBlackAlt,
              child: Icon(icon, size: 32, color: _themeAccentColor()),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: _themeAccentColor().withValues(alpha: 0.25),
      color: _panelBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _themeAccentColor().withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _panelBlackAlt,
              backgroundImage: friend.photo == null
                  ? null
                  : FileImage(friend.photo!),
              child: friend.photo == null
                  ? Icon(Icons.person, size: 26, color: _themeAccentColor())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableFriendCard extends StatelessWidget {
  const _SelectableFriendCard({
    required this.friend,
    required this.selected,
    required this.onTap,
  });

  final Friend friend;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Stack(
        children: [
          _FriendCard(friend: friend),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: selected ? _themeSuccessColor() : _panelBlackAlt,
              child: Icon(
                selected ? Icons.check : Icons.circle_outlined,
                size: 14,
                color: selected ? Colors.black : _themeAccentColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.initial,
    required this.label,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String initial;
  final String label;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isToday)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _themeAccentColor().withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _themeAccentColor().withValues(alpha: 0.25),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _themeSecondaryColor() : _panelBlack,
                  border: Border.all(
                    color: selected
                        ? _themeSecondaryColor()
                        : _themeSecondaryColor().withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? _themeSecondaryColor().withValues(alpha: 0.45)
                          : const Color(0x22000000),
                      blurRadius: selected ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.black : _themeSecondaryColor(),
                  ),
                ),
              ),
              if (isToday)
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _themeAccentColor(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'HOY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? _themeSecondaryColor()
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSectionCard extends StatefulWidget {
  const _ExpandableSectionCard({
    required this.section,
    required this.friendName,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onRenameSection,
    required this.onDeleteSection,
  });

  final Section section;
  final String? friendName;
  final VoidCallback onAddExercise;
  final Function(Exercise) onEditExercise;
  final VoidCallback onRenameSection;
  final VoidCallback onDeleteSection;

  @override
  State<_ExpandableSectionCard> createState() => _ExpandableSectionCardState();
}

class _ExpandableSectionCardState extends State<_ExpandableSectionCard> {
  bool _expanded = false;

  // Colores para diferentes secciones
  List<Color> get _sectionColors => [
    _themeAccentColor(),
    _themeSuccessColor(),
    _themeSecondaryColor(),
    _themeDangerColor(),
  ];

  Color get _sectionColor {
    final allSections =
        (widget.section.name.hashCode.abs()) % _sectionColors.length;
    return _sectionColors[allSections];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: _sectionColor.withValues(alpha: 0.25),
      color: _panelBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _sectionColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _sectionColor,
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.section.exercises.length} ejercicios',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar sección',
                        onPressed: widget.onRenameSection,
                        icon: Icon(Icons.edit_outlined, color: _themeAccentColor()),
                      ),
                      IconButton(
                        tooltip: 'Eliminar sección',
                        onPressed: widget.onDeleteSection,
                        icon: Icon(Icons.delete_outline, color: _themeDangerColor()),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: _sectionColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              color: _sectionColor.withValues(alpha: 0.2),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.section.exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Sin ejercicios aún',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final exercise = widget.section.exercises[index];
                        return _ExerciseCard(
                          exercise: exercise,
                          onEdit: () => widget.onEditExercise(exercise),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemCount: widget.section.exercises.length,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onAddExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ejercicio'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _sectionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onEdit});

  final Exercise exercise;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasHistory = exercise.weightHistory.isNotEmpty;
    final firstWeight = hasHistory
        ? exercise.weightHistory.first.weightKg
        : 0.0;
    final lastWeight = hasHistory ? exercise.weightHistory.last.weightKg : 0.0;
    final weightDiff = hasHistory ? lastWeight - firstWeight : 0.0;

    return Card(
      elevation: 4,
      shadowColor: _themeAccentColor().withValues(alpha: 0.25),
      color: _panelBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _themeAccentColor().withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _panelBlackAlt,
                  backgroundImage: exercise.photo == null
                      ? null
                      : FileImage(exercise.photo!),
                  child: exercise.photo == null
                      ? Icon(Icons.image, size: 24, color: _themeAccentColor())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricChip(
                            label: 'Series',
                            value: '${exercise.series}',
                          ),
                          _MetricChip(label: 'Reps', value: '${exercise.reps}'),
                          _MetricChip(
                            label: 'Peso',
                            value: exercise.weightKg > 0
                                ? formatWeight(exercise.weightKg)
                                : formatWeight(0),
                          ),
                          if (exercise.lastWeightKg != null)
                            _MetricChip(
                              label: 'Último',
                              value: formatWeight(exercise.lastWeightKg!),
                              color: _themeSuccessColor(),
                            ),
                          _MetricChip(
                            label: 'Amigo',
                            value: exercise.friendWeightKg > 0
                                ? formatWeight(exercise.friendWeightKg)
                                : formatWeight(0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, color: _themeAccentColor()),
                ),
              ],
            ),
            if (hasHistory) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: _panelBlackAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _themeSecondaryColor().withValues(alpha: 0.3)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;
                    final spacing = 12.0;
                    final itemWidth = isCompact
                        ? (constraints.maxWidth - spacing) / 2
                        : (constraints.maxWidth - (spacing * 3)) / 4;

                    Widget statItem({required String label, required Widget value}) {
                      return SizedBox(
                        width: itemWidth,
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: value,
                            ),
                          ],
                        ),
                      );
                    }

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 10,
                      children: [
                        statItem(
                          label: 'Historial',
                          value: Text(
                            '${exercise.weightHistory.length} registros',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _themeSecondaryColor(),
                            ),
                          ),
                        ),
                        statItem(
                          label: 'Desde',
                          value: Text(
                            formatWeight(firstWeight),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _themeAccentColor(),
                            ),
                          ),
                        ),
                        statItem(
                          label: 'Actual',
                          value: Text(
                            formatWeight(lastWeight),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _themeSuccessColor(),
                            ),
                          ),
                        ),
                        statItem(
                          label: 'Progreso',
                          value: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                weightDiff >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 14,
                                color: weightDiff >= 0 ? _themeSuccessColor() : _themeDangerColor(),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${weightDiff >= 0 ? '+' : ''}${_displayWeight(weightDiff).toStringAsFixed(1)} ${_weightUnitLabel()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: weightDiff >= 0 ? _themeSuccessColor() : _themeDangerColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (exercise.weightHistory.last.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _themeSecondaryColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _themeSecondaryColor().withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: _themeSecondaryColor(),
                      ),
                      Expanded(
                        child: Text(
                          exercise.weightHistory.last.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: _themeSecondaryColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? _themeAccentColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _panelBlackAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: color != null ? chipColor : const Color(0xFFEAF6FF),
        ),
      ),
    );
  }
}

Future<File?> pickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galeria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (source == null) {
    return null;
  }

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 85,
  );

  if (picked == null) {
    return null;
  }

  return File(picked.path);
}
