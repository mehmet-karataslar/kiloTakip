import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_theme.dart';
import 'data/weight_repository.dart';
import 'domain/measurements.dart';
import 'presentation/calculators.dart';
import 'presentation/charts.dart';
import 'presentation/common.dart';
import 'presentation/editor.dart';
import 'presentation/records.dart';
import 'presentation/reports.dart';
import 'presentation/settings.dart';
import 'services/reminders.dart';
import 'services/workbook.dart';
import 'state/weight_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    runApp(const MobileOnly());
    return;
  }
  runApp(
    KiloTakip(
      store: WeightStore(SqliteWeights()),
      settings: AppSettings(),
      reminders: Reminders(),
    ),
  );
}

class MobileOnly extends StatelessWidget {
  const MobileOnly({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kilo Takip',
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_android, size: 42),
              const SizedBox(height: 16),
              Text(
                'Kilo Takip',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ölçümlerini kaydetmek için Kilo Takip’i Android veya iOS cihazında aç.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class KiloTakip extends StatelessWidget {
  const KiloTakip({
    required this.store,
    required this.settings,
    required this.reminders,
    this.useNotifications = true,
    super.key,
  });
  final WeightStore store;
  final AppSettings settings;
  final Reminders reminders;
  final bool useNotifications;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) {
      AppI18n.current = settings.language;
      return MaterialApp(
        title: trText('Kilo Takip'),
        debugShowCheckedModeBanner: false,
        locale: settings.language.materialLocale,
        supportedLocales: {
          for (final lang in AppLanguage.values) lang.materialLocale,
        }.toList(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.build(Brightness.light, settings.palette),
        darkTheme: AppTheme.build(Brightness.dark, settings.palette),
        themeMode: settings.theme,
        builder: (context, child) => Directionality(
          textDirection: settings.language.isRtl
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
        home: _Shell(store, settings, reminders, useNotifications),
      );
    },
  );
}

class _Shell extends StatefulWidget {
  const _Shell(
    this.store,
    this.settings,
    this.reminders,
    this.useNotifications,
  );
  final WeightStore store;
  final AppSettings settings;
  final Reminders reminders;
  final bool useNotifications;
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
  int tab = 0;
  bool editing = false;
  bool exporting = false;
  bool initialized = false;
  Slot? pending;
  DateTime today = dayOf(DateTime.now());
  Timer? rollover;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleRollover();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(start()));
  }

  void scheduleRollover() {
    rollover?.cancel();
    final now = DateTime.now();
    rollover = Timer(shiftDay(now, 1).difference(now), refreshDate);
  }

  void refreshDate() {
    final date = dayOf(DateTime.now());
    if (date != today && mounted) setState(() => today = date);
    scheduleRollover();
  }

  Future<void> start() async {
    final load = widget.store.load();
    if (widget.useNotifications) {
      try {
        await widget.settings.load();
      } catch (_) {
        if (mounted) {
          message('Ayarlar okunamadı. Varsayılan ayarlar kullanılıyor.');
        }
      }
      await widget.reminders.initialize(
        (slot) {
          pending = slot;
          openPending();
        },
        onQuickLogLastWeight: quickSaveLastWeight,
      );
    }
    await load;
    if (!mounted) return;
    openPending();
    if (!widget.useNotifications) return;
    try {
      final ask = await widget.settings.claimInitialPermissionPrompt();
      await widget.reminders.sync(widget.settings, ask: ask);
    } catch (_) {
      widget.reminders.value = ReminderStatus.error;
    }
    initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    refreshDate();
    if (initialized) unawaited(widget.reminders.sync(widget.settings));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    rollover?.cancel();
    super.dispose();
  }

  void message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void openPending() {
    final slot = pending;
    if (!mounted ||
        slot == null ||
        editing ||
        widget.store.loading ||
        widget.store.failed) {
      return;
    }
    pending = null;
    setState(() => tab = 0);
    unawaited(open(dayOf(DateTime.now()), slot));
  }

  Future<void> open(DateTime day, Slot slot) async {
    if (editing || widget.store.loading || widget.store.failed) return;
    editing = true;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeightEditor(
        widget.store,
        day,
        slot,
        original: widget.store.stats.days[day]?.values[slot],
      ),
    );
    editing = false;
    if (!mounted) return;
    if (saved == true) message('Kilo kaydı başarıyla kaydedildi.');
    openPending();
  }

  Future<void> deleteEntries(List<Measurement> entries) async {
    if (entries.isEmpty) return;
    final description = entries.length == 1
        ? '${formatTurkishDate(entries.single.day)} • ${entries.single.slot.label} • ${kg(entries.single.kg)}'
        : '${formatTurkishDate(entries.first.day)} tarihine ait sabah ve akşam kayıtları (${entries.map((e) => '${e.slot.label}: ${kg(e.kg)}').join(', ')}) birlikte silinecek.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu kilo kaydını silmek istediğine emin misin?'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.store.deleteMany(entries);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Kilo kaydı silindi.'),
              action: SnackBarAction(
                label: trText('Geri Al'),
                onPressed: () {
                  unawaited(() async {
                    for (final entry in entries) {
                      final existing = widget
                          .store
                          .stats
                          .days[entry.day]
                          ?.values[entry.slot];
                      await widget.store.save(entry, original: existing);
                    }
                    if (mounted) message('Silinen kayıt geri yüklendi.');
                  }());
                },
              ),
            ),
          );
      }
    } catch (_) {
      if (mounted) message('Kayıt silinemedi. Tekrar dene.');
    }
  }

  Future<void> quickSaveLastWeight(Slot slot) async {
    final last = widget.store.stats.latestMeasurement;
    if (last == null) {
      unawaited(open(today, slot));
      return;
    }
    final now = TimeOfDay.now();
    final existing = widget.store.stats.days[today]?.values[slot];
    try {
      await widget.store.save(
        Measurement(
          today,
          slot,
          last.kg,
          minutes: now.hour * 60 + now.minute,
        ),
        original: existing,
      );
      if (mounted) {
        message('${slot.label} kilosu (${kg(last.kg)}) hızlıca kaydedildi.');
      }
    } catch (_) {
      if (mounted) message('Hızlı kayıt yapılamadı.');
    }
  }

  Future<void> snoozeReminder(Slot slot) async {
    await widget.reminders.snoozeOneHour(slot);
    if (mounted) {
      message('${slot.label} hatırlatması 1 saat sonrasına ertelendi.');
    }
  }

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (settingsCtx) => SettingsPage(
          widget.settings,
          widget.reminders,
          () => export(settingsCtx),
        ),
      ),
    );
  }

  Future<void> export([BuildContext? callerContext]) async {
    final activeContext = callerContext ?? context;
    if (exporting) return;
    final entries = widget.store.stats.all;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(activeContext).showSnackBar(
        const SnackBar(
          content: Text('Dışa aktarmak için önce bir kilo kaydı eklemelisin.'),
        ),
      );
      return;
    }
    final fileName = workbookFileName();
    final messenger = ScaffoldMessenger.of(activeContext);
    final renderObj =
        activeContext.findRenderObject() ?? context.findRenderObject();
    final box = renderObj! as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    final share = await showModalBottomSheet<bool>(
      context: activeContext,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  children: [
                    const Text(
                      'Excel Dışa Aktar (.xlsx)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$fileName • ${entries.length} kayıt',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: sheetCtx.colors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.save_alt_rounded),
                title: const Text('Cihaza Kaydet (.xlsx)'),
                subtitle: const Text(
                  'Telefon hafızasına veya İndirilenler klasörüne kaydet',
                ),
                onTap: () => Navigator.pop(sheetCtx, false),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Paylaş / Excel ile Aç (.xlsx)'),
                subtitle: const Text(
                  'Excel, WhatsApp, Drive veya E-posta ile aç/gönder',
                ),
                onTap: () => Navigator.pop(sheetCtx, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || share == null) return;
    exporting = true;
    messenger.showSnackBar(
      const SnackBar(content: Text('Excel dosyası hazırlanıyor…')),
    );
    try {
      final result = await WorkbookExport().export(
        entries,
        share: share,
        origin: origin,
      );
      if (mounted) {
        messenger.hideCurrentSnackBar();
        if (result && !share) {
          messenger.showSnackBar(
            SnackBar(content: Text('Excel dosyası ($fileName) kaydedildi.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Excel dosyası oluşturulamadı. Tekrar deneyebilirsin.',
            ),
          ),
        );
      }
    } finally {
      exporting = false;
    }
  }

  String get _appBarTitle => switch (tab) {
    1 => 'Grafikler',
    2 => 'Geçmiş',
    3 => 'Raporlar',
    4 => 'Hesap & Analiz',
    _ => 'Kilo Takip',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.store, widget.settings]),
    builder: (context, _) {
      final stats = widget.store.stats;
      return Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle),
          actions: [
            IconButton(
              tooltip: trText('Görünüm & Tema'),
              icon: const Icon(Icons.palette_outlined),
              onPressed: () => showThemeSelectorSheet(
                context,
                widget.settings,
              ),
            ),
            IconButton(
              tooltip: trText('Uygulama Dili'),
              onPressed: () => showLanguageSelectorSheet(
                context,
                widget.settings,
                widget.reminders,
              ),
              icon: Text(
                widget.settings.language.flag,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            IconButton(
              tooltip: trText('Ayarlar'),
              icon: const Icon(Icons.settings_outlined),
              onPressed: openSettings,
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: widget.store.loading
              ? const Center(child: CircularProgressIndicator())
              : widget.store.failed
              ? PageBody([
                  const Note('Kayıtlar okunamadı. Tekrar deneyebilirsin.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await widget.store.load();
                      openPending();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ])
              : switch (tab) {
                  1 => ChartsPage(
                    stats,
                    today,
                    targetWeight: widget.settings.targetWeight,
                    maintenanceBandTolerance: widget.settings.maintenanceMode
                        ? widget.settings.maintenanceToleranceKg
                        : null,
                  ),
                  2 => HistoryPage(stats, today, open, deleteEntries),
                  3 => ReportsPage(
                    stats,
                    today,
                    export,
                    settings: widget.settings,
                    onOpenSettings: openSettings,
                  ),
                  4 => CalculatorsPage(stats, widget.settings),
                  _ => Dashboard(
                    stats,
                    today,
                    {
                      for (final entry in widget.settings.reminders.entries)
                        entry.key: entry.value.time,
                    },
                    open,
                    onNavigateToCharts: () => setState(() => tab = 1),
                    settings: widget.settings,
                    onQuickSaveLastWeight: quickSaveLastWeight,
                    onSnoozeReminder: snoozeReminder,
                  ),
                },
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: tab,
          onTap: (i) => setState(() => tab = i),
        ),
      );
    },
  );
}
