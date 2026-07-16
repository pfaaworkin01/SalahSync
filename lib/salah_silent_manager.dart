import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalahConfiguration {
  final String name;
  TimeOfDay startTime;
  int preMuteMinutes; // 0 to 15 mins before
  int silentDurationMinutes; // 5 to 60 mins duration
  bool isEnabled;
  String targetMode; // 'silent' or 'vibrate'

  SalahConfiguration({
    required this.name,
    required this.startTime,
    this.preMuteMinutes = 5,
    this.silentDurationMinutes = 20,
    this.isEnabled = true,
    this.targetMode = 'silent',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'hour': startTime.hour,
        'minute': startTime.minute,
        'preMuteMinutes': preMuteMinutes,
        'silentDurationMinutes': silentDurationMinutes,
        'isEnabled': isEnabled,
        'targetMode': targetMode,
      };

  factory SalahConfiguration.fromJson(Map<String, dynamic> json) {
    return SalahConfiguration(
      name: json['name'],
      startTime: TimeOfDay(hour: json['hour'], minute: json['minute']),
      preMuteMinutes: json['preMuteMinutes'] ?? 5,
      silentDurationMinutes: json['silentDurationMinutes'] ?? 20,
      isEnabled: json['isEnabled'] ?? true,
      targetMode: json['targetMode'] ?? 'silent',
    );
  }

  SalahConfiguration copyWith({
    TimeOfDay? startTime,
    int? preMuteMinutes,
    int? silentDurationMinutes,
    bool? isEnabled,
    String? targetMode,
  }) {
    return SalahConfiguration(
      name: name,
      startTime: startTime ?? this.startTime,
      preMuteMinutes: preMuteMinutes ?? this.preMuteMinutes,
      silentDurationMinutes: silentDurationMinutes ?? this.silentDurationMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      targetMode: targetMode ?? this.targetMode,
    );
  }

  String get formattedTime {
    final hour = startTime.hour == 0 ? 12 : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  final bool isSilentChange;

  LogEntry({
    required this.timestamp,
    required this.message,
    this.isSilentChange = false,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'isSilentChange': isSilentChange,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      message: json['message'],
      isSilentChange: json['isSilentChange'] ?? false,
    );
  }
}

class SalahSilentManager extends ChangeNotifier {
  static const _platform = MethodChannel('com.pfaacodin01.salahsync/sound_mode');

  List<SalahConfiguration> _configs = [];
  List<LogEntry> _logs = [];
  bool _isAutoSilentEnabled = true;
  ThemeMode _themeMode = ThemeMode.dark;
  
  // Platform status
  bool _hasAndroidDndAccess = false;
  String _systemSoundMode = 'normal'; // normal, vibrate, silent
  
  // Active silent override state
  String? _activeOverrideReason;
  DateTime? _activeOverrideEndTime;
  String? _originalSoundModeBeforeOverride;

  // Simulator controls
  bool _isTimeAccelerated = false;
  DateTime _simulatedTime = DateTime.now();
  final int _timeSpeedMultiplier = 60; // 1s real time = 1m simulated time
  Timer? _schedulerTimer;
  Timer? _androidStatusTimer;

  SalahSilentManager() {
    _initDefaults();
    _loadFromPrefs().then((_) {
      _checkAndroidPermission();
      _startTimers();
      _addLog('SalahSync initialized successfully.');
    });
  }

  List<SalahConfiguration> get configs => _configs;
  List<LogEntry> get logs => _logs;
  bool get isAutoSilentEnabled => _isAutoSilentEnabled;
  ThemeMode get themeMode => _themeMode;
  bool get hasAndroidDndAccess => _hasAndroidDndAccess;
  String get systemSoundMode => _systemSoundMode;
  String? get activeOverrideReason => _activeOverrideReason;
  DateTime? get activeOverrideEndTime => _activeOverrideEndTime;
  bool get isTimeAccelerated => _isTimeAccelerated;
  DateTime get currentTime => _isTimeAccelerated ? _simulatedTime : DateTime.now();

  bool get isCurrentlySilenced => _activeOverrideReason != null;

  void _initDefaults() {
    _configs = [
      SalahConfiguration(name: 'Fajr', startTime: const TimeOfDay(hour: 5, minute: 0)),
      SalahConfiguration(name: 'Dhuhr', startTime: const TimeOfDay(hour: 13, minute: 0)),
      SalahConfiguration(name: 'Asr', startTime: const TimeOfDay(hour: 16, minute: 30)),
      SalahConfiguration(name: 'Maghrib', startTime: const TimeOfDay(hour: 18, minute: 45)),
      SalahConfiguration(name: 'Isha', startTime: const TimeOfDay(hour: 20, minute: 15)),
      SalahConfiguration(name: "Jumu'ah", startTime: const TimeOfDay(hour: 13, minute: 0), silentDurationMinutes: 30),
    ];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAutoSilentEnabled = prefs.getBool('isAutoSilentEnabled') ?? true;
      _originalSoundModeBeforeOverride = prefs.getString('originalSoundModeBeforeOverride');
      _activeOverrideReason = prefs.getString('activeOverrideReason');
      
      final endTimeMs = prefs.getInt('activeOverrideEndTime');
      if (endTimeMs != null) {
        _activeOverrideEndTime = DateTime.fromMillisecondsSinceEpoch(endTimeMs);
      }

      final themeStr = prefs.getString('themeMode');
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }

      final configsJson = prefs.getString('salah_configs');
      if (configsJson != null) {
        final List<dynamic> decoded = jsonDecode(configsJson);
        _configs = decoded.map((e) => SalahConfiguration.fromJson(e)).toList();
      }

      final logsJson = prefs.getString('salah_logs');
      if (logsJson != null) {
        final List<dynamic> decoded = jsonDecode(logsJson);
        _logs = decoded.map((e) => LogEntry.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
    notifyListeners();
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _addLog('Theme switched to ${_themeMode == ThemeMode.light ? "Light" : "Dark"} Mode.');
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('themeMode', _themeMode == ThemeMode.light ? 'light' : 'dark');
    });
    notifyListeners();
  }

  Future<void> _saveConfigsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = jsonEncode(_configs.map((e) => e.toJson()).toList());
    await prefs.setString('salah_configs', configsJson);
  }

  Future<void> _saveStateToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoSilentEnabled', _isAutoSilentEnabled);
    await prefs.setStringOrNull('activeOverrideReason', _activeOverrideReason);
    await prefs.setStringOrNull('originalSoundModeBeforeOverride', _originalSoundModeBeforeOverride);
    if (_activeOverrideEndTime != null) {
      await prefs.setInt('activeOverrideEndTime', _activeOverrideEndTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('activeOverrideEndTime');
    }
  }

  Future<void> _saveLogsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Restrict logs length to avoid slow load
    if (_logs.length > 50) {
      _logs = _logs.sublist(_logs.length - 50);
    }
    final logsJson = jsonEncode(_logs.map((e) => e.toJson()).toList());
    await prefs.setString('salah_logs', logsJson);
  }

  void toggleAutoSilent(bool value) {
    _isAutoSilentEnabled = value;
    _addLog('Automatic Silent Mode ${value ? "ENABLED" : "DISABLED"}.');
    _saveStateToPrefs();
    
    // If disabled, immediately release any active overrides
    if (!value && isCurrentlySilenced) {
      _restoreOriginalSound();
    }
    notifyListeners();
  }

  void updateSalahConfig(SalahConfiguration updated) {
    final index = _configs.indexWhere((element) => element.name == updated.name);
    if (index != -1) {
      _configs[index] = updated;
      _addLog('Updated ${updated.name} settings.');
      _saveConfigsToPrefs();
      notifyListeners();
    }
  }

  void quickMute(int minutes) {
    if (!_isAutoSilentEnabled) {
      _addLog('Cannot Quick Mute: Auto Silent is disabled.', isSilentChange: false);
      return;
    }
    final now = currentTime;
    _activeOverrideEndTime = now.add(Duration(minutes: minutes));
    _activeOverrideReason = 'Quick Mute ($minutes mins)';
    
    _addLog('Quick Mute activated for $minutes minutes.');
    _applySilentMode('silent');
    _saveStateToPrefs();
    notifyListeners();
  }

  void cancelQuickMute() {
    if (_activeOverrideReason != null && _activeOverrideReason!.startsWith('Quick Mute')) {
      _addLog('Quick Mute cancelled.');
      _restoreOriginalSound();
    }
  }

  // Developer Simulator functions
  void toggleTimeAcceleration(bool value) {
    _isTimeAccelerated = value;
    if (value) {
      _simulatedTime = DateTime.now();
      _addLog('Time acceleration started (1s real = 1m simulated).');
    } else {
      _addLog('Time acceleration stopped. Restoring real-time.');
      if (isCurrentlySilenced) {
        _restoreOriginalSound();
      }
    }
    notifyListeners();
  }

  void mockSalahNow(String name, int durationMinutes) {
    if (!_isAutoSilentEnabled) {
      _addLog('Cannot mock Salah: Auto Silent is disabled.');
      return;
    }
    final now = currentTime;
    _activeOverrideEndTime = now.add(Duration(minutes: durationMinutes));
    _activeOverrideReason = 'Mock $name Salah';
    _addLog('Developer Mock: Initiated silent period for $name Salah ($durationMinutes mins).');
    _applySilentMode('silent');
    _saveStateToPrefs();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _saveLogsToPrefs();
    notifyListeners();
  }

  // Timers
  void _startTimers() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _runSchedulerTick();
    });

    _androidStatusTimer?.cancel();
    _androidStatusTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _checkAndroidPermission();
    });
  }

  void _runSchedulerTick() {
    final prevTime = _simulatedTime;
    if (_isTimeAccelerated) {
      _simulatedTime = _simulatedTime.add(Duration(seconds: _timeSpeedMultiplier));
    } else {
      _simulatedTime = DateTime.now();
    }

    // Trigger state checks only when minute changes or state is active
    if (_isTimeAccelerated || prevTime.minute != _simulatedTime.minute || isCurrentlySilenced) {
      _checkScheduling();
    }
  }

  void _checkScheduling() {
    if (!_isAutoSilentEnabled) return;

    final now = currentTime;

    // 1. Check if we are currently in an active override
    if (isCurrentlySilenced) {
      if (_activeOverrideEndTime != null && now.isAfter(_activeOverrideEndTime!)) {
        _addLog('Silent period ended for: $_activeOverrideReason');
        _restoreOriginalSound();
      }
      return;
    }

    // 2. Check if we should enter a Salah silent period
    // Iterate through daily config. We must match the day/hour/minute.
    final currentDay = now.weekday; // 5 is Friday
    final currentHour = now.hour;
    final currentMin = now.minute;

    for (var config in _configs) {
      if (!config.isEnabled) continue;

      // Handle Jumu'ah: only on Fridays
      if (config.name == "Jumu'ah" && currentDay != DateTime.friday) {
        continue;
      }
      // Handle normal daily Salahs: skip Jumu'ah if not Friday, skip Dhuhr on Friday
      if (config.name != "Jumu'ah" && currentDay == DateTime.friday && config.name == 'Dhuhr') {
        continue;
      }

      // Calculate start time in minutes from midnight
      final targetMinutes = config.startTime.hour * 60 + config.startTime.minute;
      final currentMinutes = currentHour * 60 + currentMin;

      final startMuteMinutes = targetMinutes - config.preMuteMinutes;
      final endMuteMinutes = targetMinutes + config.silentDurationMinutes;

      // Check if current time falls in this window
      if (currentMinutes >= startMuteMinutes && currentMinutes < endMuteMinutes) {
        // We found an active Salah silent window!
        final remainingMinutes = endMuteMinutes - currentMinutes;
        _activeOverrideEndTime = now.add(Duration(minutes: remainingMinutes));
        _activeOverrideReason = '${config.name} Salah';
        
        _addLog('Auto-Silent triggered: ${config.name} Salah start in ${config.preMuteMinutes} mins.');
        _applySilentMode(config.targetMode);
        _saveStateToPrefs();
        notifyListeners();
        return;
      }
    }
  }

  // Sound Mode Switching Engine
  Future<void> _applySilentMode(String targetMode) async {
    _addLog('Applying sound profile: $targetMode', isSilentChange: true);
    
    // Save original mode before applying
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final currentMode = await _platform.invokeMethod<String>('getSoundMode');
        if (currentMode != null && currentMode != 'unknown') {
          _originalSoundModeBeforeOverride = currentMode;
        }
      } catch (e) {
        debugPrint('Error getting current sound mode: $e');
      }
    }

    _originalSoundModeBeforeOverride ??= 'normal';
    _systemSoundMode = targetMode;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final success = await _platform.invokeMethod<bool>('setSoundMode', {'mode': targetMode});
        if (success == true) {
          _addLog('System sound profile changed to: $targetMode');
        }
      } on PlatformException catch (e) {
        _addLog('Failed to change Android ringer: ${e.message}');
        if (e.code == 'PERMISSION_DENIED') {
          _hasAndroidDndAccess = false;
        }
      }
    } else {
      // iOS / Simulator simulation
      _addLog('iOS Simulation: Audio volume adjusted to 0.0.');
    }
    notifyListeners();
  }

  Future<void> _restoreOriginalSound() async {
    final modeToRestore = _originalSoundModeBeforeOverride ?? 'normal';
    _addLog('Restoring sound profile: $modeToRestore', isSilentChange: true);

    _systemSoundMode = modeToRestore;
    _activeOverrideReason = null;
    _activeOverrideEndTime = null;
    _originalSoundModeBeforeOverride = null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final success = await _platform.invokeMethod<bool>('setSoundMode', {'mode': modeToRestore});
        if (success == true) {
          _addLog('System sound profile restored to: $modeToRestore');
        }
      } on PlatformException catch (e) {
        _addLog('Failed to restore Android ringer: ${e.message}');
      }
    } else {
      // iOS / Simulator simulation
      _addLog('iOS Simulation: Audio volume restored.');
    }

    _saveStateToPrefs();
    notifyListeners();
  }

  // Android DND Permissions
  Future<void> _checkAndroidPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final hasAccess = await _platform.invokeMethod<bool>('hasNotificationPolicyAccess');
        final mode = await _platform.invokeMethod<String>('getSoundMode');
        
        bool changed = false;
        if (hasAccess != null && hasAccess != _hasAndroidDndAccess) {
          _hasAndroidDndAccess = hasAccess;
          changed = true;
        }
        if (mode != null && mode != _systemSoundMode && !isCurrentlySilenced) {
          _systemSoundMode = mode;
          changed = true;
        }

        if (changed) {
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error checking Android status: $e');
      }
    }
  }

  Future<void> requestAndroidDndPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _platform.invokeMethod('openNotificationPolicySettings');
        _addLog('Opened Android Do Not Disturb settings page.');
      } catch (e) {
        _addLog('Error opening settings: $e');
      }
    }
  }

  void _addLog(String message, {bool isSilentChange = false}) {
    final now = DateTime.now();
    _logs.add(LogEntry(timestamp: now, message: message, isSilentChange: isSilentChange));
    _saveLogsToPrefs();
    notifyListeners();
  }

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    _androidStatusTimer?.cancel();
    super.dispose();
  }
}

extension SharedPreferencesExtension on SharedPreferences {
  Future<bool> setStringOrNull(String key, String? value) {
    if (value == null) {
      return remove(key);
    }
    return setString(key, value);
  }
}
