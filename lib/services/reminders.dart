import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import '../l10n/app_localizations.dart';

class Reminder {
  const Reminder(this.enabled, this.time);
  final bool enabled;
  final TimeOfDay time;

  String get timeLabel => clockLabel(time.hour * 60 + time.minute);
}

enum ReminderStatus { off, blocked, approximate, active, error }

tz.Location resolveLocalTimezone(String? identifier, Duration systemOffset) {
  if (identifier != null && identifier.isNotEmpty) {
    try {
      return tz.getLocation(identifier);
    } catch (_) {
      // Bilinmeyen/alias kimlik durumunda offset kontrolüne geç
    }
  }
  // Türkiye saat dilimi (UTC+03:00) için doğrudan Europe/Istanbul kullan
  if (systemOffset.inMinutes == 180) {
    return tz.getLocation('Europe/Istanbul');
  }
  for (final loc in tz.timeZoneDatabase.locations.values) {
    if (loc.currentTimeZone.offset == systemOffset) {
      return loc;
    }
  }
  return tz.getLocation('Europe/Istanbul');
}

tz.TZDateTime nextReminder(tz.TZDateTime now, TimeOfDay time) {
  final today = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  return today.isAfter(now)
      ? today
      : tz.TZDateTime(
          now.location,
          now.year,
          now.month,
          now.day + 1,
          time.hour,
          time.minute,
        );
}

class AppSettings extends ChangeNotifier {
  late final _prefs = SharedPreferencesAsync();
  final reminders = {
    for (final slot in Slot.values)
      slot: Reminder(true, TimeOfDay(hour: slot.hour, minute: slot.minute)),
  };
  ThemeMode theme = ThemeMode.light;
  AppColorPalette palette = AppColorPalette.ocean;
  AppLanguage language = AppLanguage.tr;
  double? startWeight;
  double? targetWeight;
  double? heightCm;
  bool maintenanceMode = false;
  double maintenanceToleranceKg = 1.0;
  double? waistCm;
  double? hipCm;
  double? neckCm;
  int age = 30;
  bool isMale = true;
  int activityLevel = 1; // 0: Hareketsiz, 1: Hafif Aktif, 2: Orta Aktif, 3: Çok Aktif
  final Map<String, int> _waterGlasses = {};

  double? get waistToHeightRatio {
    if (waistCm == null || heightCm == null || heightCm! <= 0) return null;
    return rounded(waistCm! / heightCm!);
  }

  int waterGlassesFor(DateTime day) => _waterGlasses[dateKey(day)] ?? 0;

  double waterLitersFor(DateTime day) =>
      rounded(waterGlassesFor(day) * 0.25);

  Future<void> setWaterGlasses(DateTime day, int glasses) async {
    final clamped = glasses.clamp(0, 30);
    final key = dateKey(day);
    _waterGlasses[key] = clamped;
    notifyListeners();
    try {
      await _prefs.setInt('water_$key', clamped);
    } on Object {}
  }

  Future<void> load() async {
    for (final slot in Slot.values) {
      final enabled = await _prefs.getBool('${slot.name}_enabled') ?? true;
      final minutes =
          await _prefs.getInt('${slot.name}_time') ??
          (slot.hour * 60 + slot.minute);
      reminders[slot] = Reminder(
        enabled,
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
    }
    final saved = await _prefs.getString('theme_mode');
    theme =
        ThemeMode.values.where((mode) => mode.name == saved).firstOrNull ??
        ThemeMode.light;
    final savedPalette = await _prefs.getString('color_palette');
    palette =
        AppColorPalette.values
            .where((p) => p.name == savedPalette)
            .firstOrNull ??
        AppColorPalette.ocean;
    final savedLang = await _prefs.getString('app_language');
    language =
        AppLanguage.values.where((l) => l.name == savedLang).firstOrNull ??
        AppLanguage.tr;
    AppI18n.current = language;
    startWeight = await _prefs.getDouble('start_weight');
    targetWeight = await _prefs.getDouble('target_weight');
    heightCm = await _prefs.getDouble('height_cm');
    maintenanceMode = await _prefs.getBool('maintenance_mode') ?? false;
    maintenanceToleranceKg =
        await _prefs.getDouble('maintenance_tolerance_kg') ?? 1.0;
    waistCm = await _prefs.getDouble('waist_cm');
    hipCm = await _prefs.getDouble('hip_cm');
    neckCm = await _prefs.getDouble('neck_cm');
    age = await _prefs.getInt('profile_age') ?? 30;
    isMale = await _prefs.getBool('profile_is_male') ?? true;
    activityLevel = await _prefs.getInt('profile_activity') ?? 1;

    final today = dayOf(DateTime.now());
    for (var i = 0; i < 14; i++) {
      final d = shiftDay(today, -i);
      final k = dateKey(d);
      final w = await _prefs.getInt('water_$k');
      if (w != null) _waterGlasses[k] = w;
    }
    notifyListeners();
  }

  Future<void> setReminder(Slot slot, Reminder value) async {
    reminders[slot] = value;
    notifyListeners();
    try {
      await _prefs.setBool('${slot.name}_enabled', value.enabled);
      await _prefs.setInt(
        '${slot.name}_time',
        value.time.hour * 60 + value.time.minute,
      );
    } on Object {
      // Widget test ortamında platform kanalı yoksa bellek durumu korunur.
    }
  }

  Future<void> setTheme(ThemeMode value) async {
    theme = value;
    notifyListeners();
    try {
      await _prefs.setString('theme_mode', value.name);
    } on Object {
      // Widget test ortamında platform kanalı yoksa bellek durumu korunur.
    }
  }

  Future<void> setPalette(AppColorPalette value) async {
    palette = value;
    notifyListeners();
    try {
      await _prefs.setString('color_palette', value.name);
    } on Object {}
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    AppI18n.current = value;
    notifyListeners();
    try {
      await _prefs.setString('app_language', value.name);
    } on Object {}
  }

  Future<void> setGoals({
    required double? start,
    required double? target,
    double? height,
    bool? maintenance,
    double? tolerance,
  }) async {
    startWeight = start == null ? null : rounded(start);
    targetWeight = target == null ? null : rounded(target);
    if (height != null || heightCm != null) {
      heightCm = height == null ? null : rounded(height);
    }
    if (maintenance != null) maintenanceMode = maintenance;
    if (tolerance != null) maintenanceToleranceKg = rounded(tolerance);
    notifyListeners();
    try {
      if (start == null) {
        await _prefs.remove('start_weight');
      } else {
        await _prefs.setDouble('start_weight', rounded(start));
      }
      if (target == null) {
        await _prefs.remove('target_weight');
      } else {
        await _prefs.setDouble('target_weight', rounded(target));
      }
      if (height == null) {
        await _prefs.remove('height_cm');
      } else {
        await _prefs.setDouble('height_cm', rounded(height));
      }
      if (maintenance != null) {
        await _prefs.setBool('maintenance_mode', maintenance);
      }
      if (tolerance != null) {
        await _prefs.setDouble('maintenance_tolerance_kg', rounded(tolerance));
      }
    } on Object {
      // Widget test ortamında platform kanalı yoksa bellek durumu korunur.
    }
  }

  Future<void> setCircumferences({
    required double? waist,
    required double? hip,
    required double? neck,
  }) async {
    waistCm = waist == null ? null : rounded(waist);
    hipCm = hip == null ? null : rounded(hip);
    neckCm = neck == null ? null : rounded(neck);
    notifyListeners();
    try {
      if (waist == null) {
        await _prefs.remove('waist_cm');
      } else {
        await _prefs.setDouble('waist_cm', rounded(waist));
      }
      if (hip == null) {
        await _prefs.remove('hip_cm');
      } else {
        await _prefs.setDouble('hip_cm', rounded(hip));
      }
      if (neck == null) {
        await _prefs.remove('neck_cm');
      } else {
        await _prefs.setDouble('neck_cm', rounded(neck));
      }
    } on Object {}
  }

  Future<void> setCalculatorProfile({
    double? height,
    double? target,
    int? newAge,
    bool? male,
    int? activity,
    double? waist,
    double? hip,
    double? neck,
  }) async {
    if (height != null) heightCm = rounded(height);
    if (target != null) targetWeight = rounded(target);
    if (newAge != null) age = newAge.clamp(10, 100);
    if (male != null) isMale = male;
    if (activity != null) activityLevel = activity.clamp(0, 3);
    if (waist != null) waistCm = waist <= 0 ? null : rounded(waist);
    if (hip != null) hipCm = hip <= 0 ? null : rounded(hip);
    if (neck != null) neckCm = neck <= 0 ? null : rounded(neck);
    notifyListeners();
    try {
      if (heightCm != null) await _prefs.setDouble('height_cm', heightCm!);
      if (targetWeight != null) {
        await _prefs.setDouble('target_weight', targetWeight!);
      }
      await _prefs.setInt('profile_age', age);
      await _prefs.setBool('profile_is_male', isMale);
      await _prefs.setInt('profile_activity', activityLevel);
      if (waistCm != null) {
        await _prefs.setDouble('waist_cm', waistCm!);
      } else {
        await _prefs.remove('waist_cm');
      }
      if (hipCm != null) {
        await _prefs.setDouble('hip_cm', hipCm!);
      } else {
        await _prefs.remove('hip_cm');
      }
      if (neckCm != null) {
        await _prefs.setDouble('neck_cm', neckCm!);
      } else {
        await _prefs.remove('neck_cm');
      }
    } on Object {}
  }

  Future<bool> claimInitialPermissionPrompt() async {
    if (await _prefs.getBool('asked_notifications') == true) return false;
    await _prefs.setBool('asked_notifications', true);
    return true;
  }
}

class Reminders extends ValueNotifier<ReminderStatus> {
  Reminders() : super(ReminderStatus.off);
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> _queue = Future.value();
  final scheduledTimes = <Slot, tz.TZDateTime>{};

  AndroidFlutterLocalNotificationsPlugin? get _android => Platform.isAndroid
      ? _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
      : null;
  IOSFlutterLocalNotificationsPlugin? get _ios => Platform.isIOS
      ? _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
      : null;

  Future<void> _updateTimezone() async {
    String? tzName;
    try {
      tzName = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {}
    tz.setLocalLocation(
      resolveLocalTimezone(tzName, DateTime.now().timeZoneOffset),
    );
  }

  Future<void> initialize(
    void Function(Slot) open, {
    void Function(Slot)? onQuickLogLastWeight,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    void dispatch(NotificationResponse? response) {
      if (response == null) return;
      final slot =
          Slot.values.where((s) => s.name == response.payload).firstOrNull;
      if (slot == null) return;
      if (response.actionId == 'snooze_1h') {
        snoozeOneHour(slot);
        return;
      }
      if (response.actionId == 'quick_log' && onQuickLogLastWeight != null) {
        onQuickLogLastWeight(slot);
        return;
      }
      open(slot);
    }

    try {
      tzdata.initializeTimeZones();
      await _updateTimezone();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_reminder'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: dispatch,
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        dispatch(launch?.notificationResponse);
      }
    } catch (_) {
      value = ReminderStatus.error;
    }
  }

  /// 8. Bildirimi 1 saat sonrasına erteleme (Snooze)
  Future<void> snoozeOneHour(Slot slot) async {
    if (!_ready) return;
    try {
      await _updateTimezone();
      final snoozeTarget =
          tz.TZDateTime.now(tz.local).add(const Duration(hours: 1));
      final exact = await _android?.canScheduleExactNotifications() ?? true;
      final lang = AppI18n.current;
      await _plugin.zonedSchedule(
        id: 100 + slot.index,
        title: trText('${slot.label} Kilo & Bel Hatırlatması (Ertelendi)', lang),
        body: trText(
          '1 saat önce ertelediğin ${slot.label.toLowerCase()} kilonu ve bel ölçünü şimdi kaydedebilirsin.',
          lang,
        ),
        scheduledDate: snoozeTarget,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'weight_reminders',
            trText('Kilo ve Bel Hatırlatmaları', lang),
            channelDescription: trText(
              'Günlük sabah ve akşam kilo ve bel ölçümü hatırlatmaları',
              lang,
            ),
            importance: Importance.high,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'quick_log',
                trText('Son Kiloyu Kaydet', lang),
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'snooze_1h',
                trText('1 Saat Ertele', lang),
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: slot.name,
      );
    } catch (_) {}
  }

  Future<void> sync(
    AppSettings settings, {
    bool ask = false,
    bool askExact = false,
  }) {
    _queue = _queue.then((_) async {
      if (!_ready) return;
      try {
        final enabled = settings.reminders.values.any((r) => r.enabled);
        if (enabled && ask) {
          await _android?.requestNotificationsPermission();
          await _ios?.requestPermissions(alert: true, sound: true);
        }
        final allowed =
            await _android?.areNotificationsEnabled() ??
            (await _ios?.checkPermissions())?.isEnabled ??
            false;
        if (enabled && allowed && askExact) {
          await _android?.requestExactAlarmsPermission();
        }
        final exact = await _android?.canScheduleExactNotifications() ?? true;
        if (enabled && allowed) {
          await _updateTimezone();
        }
        scheduledTimes.clear();
        for (final slot in Slot.values) {
          final id = slot.index + 1;
          final reminder = settings.reminders[slot]!;
          await _plugin.cancel(id: id);
          if (!allowed || !reminder.enabled) continue;
          final targetDate = nextReminder(
            tz.TZDateTime.now(tz.local),
            reminder.time,
          );
          scheduledTimes[slot] = targetDate;
          final lang = settings.language;
          await _plugin.zonedSchedule(
            id: id,
            title: trText(
              '${slot.label} Kilo & Bel Hatırlatması (${reminder.timeLabel})',
              lang,
            ),
            body: trText(
              slot == Slot.morning
                  ? 'Günaydın! Sabah kilonu ve bel ölçünü kaydetmeyi unutma.'
                  : 'Akşam kilonu ve bel ölçünü kaydederek günlük değişimini takip et.',
              lang,
            ),
            scheduledDate: targetDate,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'weight_reminders',
                trText('Kilo ve Bel Hatırlatmaları', lang),
                channelDescription: trText(
                  'Günlük sabah ve akşam kilo ve bel ölçümü hatırlatmaları',
                  lang,
                ),
                importance: Importance.high,
                priority: Priority.high,
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    'quick_log',
                    trText('Son Kiloyu Kaydet', lang),
                    showsUserInterface: true,
                  ),
                  AndroidNotificationAction(
                    'snooze_1h',
                    trText('1 Saat Ertele', lang),
                    showsUserInterface: true,
                  ),
                ],
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: slot.name,
          );
        }
        value = !enabled
            ? ReminderStatus.off
            : !allowed
            ? ReminderStatus.blocked
            : exact
            ? ReminderStatus.active
            : ReminderStatus.approximate;
      } catch (_) {
        value = ReminderStatus.error;
      }
    });
    return _queue;
  }
}
