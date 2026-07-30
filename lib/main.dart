import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'salah_silent_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SalahSilentManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = SalahSilentManager();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _manager,
      builder: (context, _) {
        return MaterialApp(
          title: 'SalahSync',
          debugShowCheckedModeBanner: false,
          themeMode: _manager.themeMode,
          // Premium Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E), // Emerald Green
              brightness: Brightness.light,
              primary: const Color(0xFF0D9488),
              secondary: const Color(0xFFD97706), // Warm Amber Gold
              surface: Colors.white,
              background: const Color(0xFFF1F5F9),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              titleLarge: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF475569),
              ),
            ),
          ),
          // Premium Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deep Navy
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E), // Emerald Green
              brightness: Brightness.dark,
              primary: const Color(0xFF0D9488),
              secondary: const Color(0xFFEAB308), // Golden Yellow
              surface: const Color(0xFF1E293B), // Slate Card
              background: const Color(0xFF0B0F19),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titleLarge: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          home: WebPhoneFrame(
            child: MainDashboard(manager: _manager),
          ),
        );
      },
    );
  }
}


class MainDashboard extends StatefulWidget {
  final SalahSilentManager manager;
  const MainDashboard({super.key, required this.manager});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  late final SalahSilentManager _manager;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _manager = widget.manager;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  IconData _getSalahIcon(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'dhuhr':
        return Icons.wb_sunny_rounded;
      case 'asr':
        return Icons.filter_drama_rounded;
      case 'maghrib':
        return Icons.nights_stay_rounded;
      case 'isha':
        return Icons.dark_mode_rounded;
      case "jumu'ah":
        return Icons.mosque_rounded;
      default:
        return Icons.alarm_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _manager,
      builder: (context, _) {
        final nowStr = DateFormat('hh:mm:ss a').format(_manager.currentTime);
        final dateStr = DateFormat(
          'EEEE, MMMM d, y',
        ).format(_manager.currentTime);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SalahSync',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _manager.isTimeAccelerated
                            ? 'Simulated Time Active'
                            : 'Automatic Sound Profiles',
                        style: TextStyle(
                          fontSize: 12,
                          color: _manager.isTimeAccelerated
                              ? Theme.of(context).colorScheme.secondary
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            actions: [
              // Theme Toggle Button
              IconButton(
                icon: Icon(
                  _manager.themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: _manager.themeMode == ThemeMode.dark
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Toggle light/dark theme',
                onPressed: () => _manager.toggleThemeMode(),
              ),
              const SizedBox(width: 4),
              // Global Silent Toggle Switch
              Row(
                children: [
                  Text(
                    _manager.isAutoSilentEnabled ? 'Active' : 'Paused',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _manager.isAutoSilentEnabled
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  CupertinoSwitch(
                    activeColor: const Color(0xFF10B981),
                    value: _manager.isAutoSilentEnabled,
                    onChanged: (val) => _manager.toggleAutoSilent(val),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    // 1. Status Indicator Card
                    _buildStatusCard(nowStr, dateStr, isDark),
                    const SizedBox(height: 16),

                    // 2. Android DND Permissions Reminder
                    if (Theme.of(context).platform == TargetPlatform.android &&
                        !_manager.hasAndroidDndAccess)
                      _buildAndroidPermissionWarning(),

                    // 3. Quick Mute Section
                    _buildQuickMuteSection(isDark),
                    const SizedBox(height: 20),

                    // 4. Salah List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configure Salah Auto-Mute',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        const Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 5. Salah List
                    ..._manager.configs.map(
                      (config) => _buildSalahConfigItem(config, isDark),
                    ),
                    const SizedBox(height: 24),

                    // 6. Log Console Section
                    _buildLogSection(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // 7. Developer Simulator Panel
              _buildSimulatorPanel(isDark),
            ],
          ),
        );
      },
    );
  }

  // --- UI Section Builders ---

  Widget _buildStatusCard(String nowStr, String dateStr, bool isDark) {
    final isSilenced = _manager.isCurrentlySilenced;

    // Choose beautiful background colors based on active theme and silent state
    final bgGradientColors = isSilenced
        ? (isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
              : [const Color(0xFFEEF2F6), const Color(0xFFE2E8F0)])
        : (isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), Colors.white]);

    final borderColor = isSilenced
        ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isSilenced
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nowStr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _manager.isTimeAccelerated
                            ? Theme.of(context).colorScheme.secondary
                            : textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Current State Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSilenced
                      ? Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.15)
                      : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSilenced
                        ? Theme.of(context).colorScheme.secondary
                        : (isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1)),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSilenced)
                      AnimatedBuilder(
                        animation: _pulseController!,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseController!.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 14,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      isSilenced ? 'SILENT MODE ACTIVE' : 'RINGER NORMAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSilenced
                            ? Theme.of(context).colorScheme.secondary
                            : secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 30,
          ),

          if (isSilenced) ...[
            Icon(
              Icons.volume_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              _manager.activeOverrideReason ?? 'Salah Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            if (_manager.activeOverrideEndTime != null)
              Builder(
                builder: (context) {
                  final remaining = _manager.activeOverrideEndTime!.difference(
                    _manager.currentTime,
                  );
                  final minutes = remaining.inMinutes;
                  final seconds = remaining.inSeconds % 60;
                  final timeStr =
                      '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
                  return Text(
                    'Restoring ringer profile in $timeStr',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                      fontSize: 14,
                    ),
                  );
                },
              ),
            if (_manager.activeOverrideReason != null &&
                _manager.activeOverrideReason!.startsWith('Quick Mute')) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _manager.cancelQuickMute(),
                icon: const Icon(Icons.volume_up_rounded, size: 16),
                label: const Text('Cancel Mute Now'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 36,
                        color: Color(0xFF0D9488),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _manager.isAutoSilentEnabled
                            ? 'Active Guard'
                            : 'System Paused',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _manager.isAutoSilentEnabled
                            ? 'Monitoring schedules'
                            : 'Auto silent is off',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.settings_phone_rounded,
                        size: 36,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ringer: ${_manager.systemSoundMode.toUpperCase()}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Default profile state',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAndroidPermissionWarning() {
    return Card(
      color: const Color(0xFF7F1D1D).withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFB91C1C), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Do Not Disturb Access Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Android requires "Do Not Disturb" policy permission so the app can automatically put the phone into Silent or Vibrate mode.',
              style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _manager.requestAndroidDndPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Grant Access in Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMuteSection(bool isDark) {
    final durations = [15, 30, 45, 60];
    final isSilenced = _manager.isCurrentlySilenced;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Quick Manual Override',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: durations.map((minutes) {
            final cardColor = isSilenced
                ? (isDark ? const Color(0xFF0B0F19) : const Color(0xFFE2E8F0))
                : (isDark ? const Color(0xFF1E293B) : Colors.white);

            final borderColor = isSilenced
                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

            return Expanded(
              child: GestureDetector(
                onTap: isSilenced ? null : () => _manager.quickMute(minutes),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.volume_off_rounded,
                        size: 20,
                        color: isSilenced
                            ? (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF94A3B8))
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$minutes Min',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSilenced
                              ? (isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFF94A3B8))
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSalahConfigItem(SalahConfiguration config, bool isDark) {
    final titleColor = config.isEnabled
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    final inactiveIconBg = isDark
        ? const Color(0xFF334155).withOpacity(0.2)
        : const Color(0xFFE2E8F0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditSalahBottomSheet(config),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Salah Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: config.isEnabled
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                      : inactiveIconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: config.isEnabled
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  _getSalahIcon(config.name),
                  color: config.isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Salah Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${config.preMuteMinutes}m buffer • ${config.silentDurationMinutes}m silent (${config.targetMode})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Salah Start Time button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    config.formattedTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.isEnabled ? 'Tap to edit' : 'Disabled',
                    style: TextStyle(
                      fontSize: 10,
                      color: config.isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Enable Switch
              CupertinoSwitch(
                value: config.isEnabled,
                onChanged: (val) {
                  _manager.updateSalahConfig(config.copyWith(isEnabled: val));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogSection(bool isDark) {
    final consoleBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity Log',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (_manager.logs.isNotEmpty)
              TextButton(
                onPressed: () => _manager.clearLogs(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'Clear logs',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: consoleBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.all(12),
          child: _manager.logs.isEmpty
              ? const Center(
                  child: Text(
                    'No activities logged yet.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: _manager.logs.length,
                  itemBuilder: (context, index) {
                    final log = _manager.logs[_manager.logs.length - 1 - index];
                    final timeStr = DateFormat(
                      'hh:mm:ss a',
                    ).format(log.timestamp);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '[$timeStr] ',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              log.message,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: log.isSilentChange
                                    ? Theme.of(context).colorScheme.secondary
                                    : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSimulatorPanel(bool isDark) {
    final panelBg = isDark ? const Color(0xFF111827) : const Color(0xFFE2E8F0);
    final borderColor = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFCBD5E1);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.developer_mode_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Simulation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Fast Time',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        activeColor: Theme.of(context).colorScheme.secondary,
                        value: _manager.isTimeAccelerated,
                        onChanged: (val) => _manager.toggleTimeAcceleration(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manager.mockSalahNow('Dhuhr', 2),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text(
                      'Mock Dhuhr (2m)',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manager.mockSalahNow('Jumu\'ah', 5),
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text(
                      'Mock Jumuah (5m)',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Sheet Configuration Editor ---

  void _showEditSalahBottomSheet(SalahConfiguration config) {
    TimeOfDay selectedTime = config.startTime;
    int preMute = config.preMuteMinutes;
    int duration = config.silentDurationMinutes;
    String mode = config.targetMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final tempConfig = SalahConfiguration(
              name: config.name,
              startTime: selectedTime,
              preMuteMinutes: preMute,
              silentDurationMinutes: duration,
              targetMode: mode,
            );

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetTextColor = isDark
                ? Colors.white
                : const Color(0xFF0F172A);
            final sheetSubtitleColor = isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF475569);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit ${config.name} Auto-Mute',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: sheetTextColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: sheetSubtitleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Time Picker Button
                  Text(
                    'Start Time',
                    style: TextStyle(
                      fontSize: 13,
                      color: sheetSubtitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: isDark
                                  ? ColorScheme.dark(
                                      primary: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      onPrimary: Colors.white,
                                      surface: const Color(0xFF1E293B),
                                      onSurface: Colors.white,
                                    )
                                  : ColorScheme.light(
                                      primary: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: const Color(0xFF0F172A),
                                    ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setSheetState(() => selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0B0F19)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempConfig.formattedTime,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: sheetTextColor,
                            ),
                          ),
                          Icon(
                            Icons.access_time_filled_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Pre-Mute Buffer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pre-Mute Buffer',
                        style: TextStyle(
                          fontSize: 13,
                          color: sheetSubtitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$preMute mins before start',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: preMute.toDouble(),
                    min: 0,
                    max: 15,
                    divisions: 15,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      setSheetState(() => preMute = val.round());
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Silent Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Silent Period Duration',
                        style: TextStyle(
                          fontSize: 13,
                          color: sheetSubtitleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$duration mins total',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      setSheetState(() => duration = val.round());
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Mute Mode
                  Text(
                    'Sound Profile Mode',
                    style: TextStyle(
                      fontSize: 13,
                      color: sheetSubtitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('Silent (Do Not Disturb)'),
                          ),
                          selected: mode == 'silent',
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: mode == 'silent'
                                ? Colors.white
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569)),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF0B0F19)
                              : const Color(0xFFF1F5F9),
                          onSelected: (selected) {
                            if (selected) setSheetState(() => mode = 'silent');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Vibrate Only')),
                          selected: mode == 'vibrate',
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: mode == 'vibrate'
                                ? Colors.white
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569)),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF0B0F19)
                              : const Color(0xFFF1F5F9),
                          onSelected: (selected) {
                            if (selected) setSheetState(() => mode = 'vibrate');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 5. Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: sheetTextColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _manager.updateSalahConfig(
                              config.copyWith(
                                startTime: selectedTime,
                                preMuteMinutes: preMute,
                                silentDurationMinutes: duration,
                                targetMode: mode,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class WebPhoneFrame extends StatefulWidget {
  final Widget child;
  const WebPhoneFrame({super.key, required this.child});

  @override
  State<WebPhoneFrame> createState() => _WebPhoneFrameState();
}

class _WebPhoneFrameState extends State<WebPhoneFrame> {
  bool _showFrame = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600 || !_showFrame) {
          return widget.child;
        }

        const phoneWidth = 412.0;
        final phoneHeight = (constraints.maxHeight * 0.92).clamp(700.0, 890.0);

        return Scaffold(
          backgroundColor: const Color(0xFF070A14),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone_android, color: Color(0xFF0D9488), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SalahSync Mobile Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFrame = !_showFrame;
                        });
                      },
                      icon: Icon(
                        _showFrame ? Icons.fullscreen : Icons.phone_android,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                      label: Text(
                        _showFrame ? 'Full Width View' : 'Phone Frame View',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: phoneWidth,
                    height: phoneHeight,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: const Color(0xFF334155), width: 10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Stack(
                        children: [
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: Size(phoneWidth, phoneHeight),
                              padding: const EdgeInsets.only(top: 28, bottom: 16),
                            ),
                            child: widget.child,
                          ),
                          Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 90,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
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
          ),
        );
      },
    );
  }
}

