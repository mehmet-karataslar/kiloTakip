import 'dart:io';

import 'package:flutter/material.dart' hide Text;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import '../services/reminders.dart';
import 'common.dart';

const appVersionString = '1.0.0';

Future<void> showLanguageSelectorSheet(
  BuildContext context,
  AppSettings settings,
  Reminders reminders,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      final c = sheetCtx.colors;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: c.primaryBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Uygulama Dili & Bölge',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tüm ekranları, grafikleri, raporları ve hesaplamaları seçtiğin dilde görüntüle.',
                    style: TextStyle(fontSize: 12.5, color: c.subtitle),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: AppLanguage.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final lang = AppLanguage.values[index];
                  final selected = settings.language == lang;
                  return Material(
                    color: selected ? c.primarySoft : c.background,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await settings.setLanguage(lang);
                        await reminders.sync(settings);
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? c.primaryBlue : c.cardBorder,
                            width: selected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.nativeName,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: c.heading,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${lang.trName} • ${lang.languageCode.toUpperCase()}-${lang.countryCode}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: c.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: c.primaryBlue,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showThemeSelectorSheet(
  BuildContext context,
  AppSettings settings,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final c = ctx.colors;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.94,
            builder: (ctx, scrollCtrl) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: c.primaryBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Görünüm & Tema',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: c.heading,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Açık, koyu veya sistem teması ile 8 uyumlu renk paletinden birini seç.',
                        style: TextStyle(fontSize: 12.5, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.cardBorder),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _ThemeOptionButton(
                          label: 'Açık',
                          icon: Icons.wb_sunny_outlined,
                          active: settings.theme == ThemeMode.light,
                          onTap: () async {
                            await settings.setTheme(ThemeMode.light);
                            setSheetState(() {});
                          },
                        ),
                        _ThemeOptionButton(
                          label: 'Koyu',
                          icon: Icons.dark_mode_outlined,
                          active: settings.theme == ThemeMode.dark,
                          onTap: () async {
                            await settings.setTheme(ThemeMode.dark);
                            setSheetState(() {});
                          },
                        ),
                        _ThemeOptionButton(
                          label: 'Sistem',
                          icon: Icons.desktop_windows_outlined,
                          active: settings.theme == ThemeMode.system,
                          onTap: () async {
                            await settings.setTheme(ThemeMode.system);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Renk Paleti (${AppColorPalette.values.length} Uyumlu Seçenek)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.heading,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: AppColorPalette.values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final palette = AppColorPalette.values[index];
                      final selected = settings.palette == palette;
                      return Material(
                        color: selected ? c.primarySoft : c.background,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await settings.setPalette(palette);
                            setSheetState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? c.primaryBlue : c.cardBorder,
                                width: selected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: palette.lightPrimary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: const Offset(-6, 0),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: palette.lightSecondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        palette.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: c.heading,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        palette.description,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: c.subtitle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: c.primaryBlue,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage(
    this.settings,
    this.reminders,
    this.export, {
    super.key,
  });

  final AppSettings settings;
  final Reminders reminders;
  final VoidCallback export;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool busy = false;
  bool _paletteExpanded = false;

  Future<void> change(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayar kaydedilemedi. Tekrar dene.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openGoalDialog() async {
    final startCtrl = TextEditingController(
      text: widget.settings.startWeight == null
          ? ''
          : formatWeightValue(widget.settings.startWeight!),
    );
    final targetCtrl = TextEditingController(
      text: widget.settings.targetWeight == null
          ? ''
          : formatWeightValue(widget.settings.targetWeight!),
    );
    final heightCtrl = TextEditingController(
      text: widget.settings.heightCm == null
          ? ''
          : widget.settings.heightCm!.round().toString(),
    );
    var maintenance = widget.settings.maintenanceMode;
    String? validationError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Hedef Kilo & Boy Ayarları'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Başlangıç kilosu, hedef kilo ve boy (cm) bilgini girerek VKİ, ideal kilo aralığı ve hedef tarihini takip edebilirsin.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: startCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: trText('Başlangıç Kilosu (opsiyonel)'),
                    hintText: trText('Örn. 85.0'),
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: trText('Hedef Kilo (opsiyonel)'),
                    hintText: trText('Örn. 78.0'),
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: trText('Boy (cm - VKİ hesabı için)'),
                    hintText: trText('Örn. 175'),
                    suffixText: 'cm',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Kilo Koruma Modu (±1.0 kg)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Hedef kiloya ulaştığında güvenli koruma bandını grafikte göster',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  value: maintenance,
                  onChanged: (v) => setDialogState(() => maintenance = v),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    validationError!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (widget.settings.startWeight != null ||
                widget.settings.targetWeight != null ||
                widget.settings.heightCm != null)
              TextButton(
                onPressed: () {
                  startCtrl.clear();
                  targetCtrl.clear();
                  heightCtrl.clear();
                  maintenance = false;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Temizle'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final sText = startCtrl.text.trim();
                final tText = targetCtrl.text.trim();
                final hText = heightCtrl.text.trim();
                final sVal = sText.isEmpty ? null : parseWeight(sText);
                final tVal = tText.isEmpty ? null : parseWeight(tText);
                final hVal = hText.isEmpty
                    ? null
                    : double.tryParse(hText.replaceAll(',', '.'));

                if (sText.isNotEmpty && sVal == null) {
                  setDialogState(() {
                    validationError =
                        'Başlangıç kilosu 2 ile 500 kg arasında olmalıdır.';
                  });
                  return;
                }
                if (tText.isNotEmpty && tVal == null) {
                  setDialogState(() {
                    validationError =
                        'Hedef kilo 2 ile 500 kg arasında olmalıdır.';
                  });
                  return;
                }
                if (hText.isNotEmpty &&
                    (hVal == null || hVal < 80 || hVal > 250)) {
                  setDialogState(() {
                    validationError = 'Boy 80 ile 250 cm arasında olmalıdır.';
                  });
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      final sText = startCtrl.text.trim();
      final tText = targetCtrl.text.trim();
      final hText = heightCtrl.text.trim();
      await change(
        () => widget.settings.setGoals(
          start: sText.isEmpty ? null : parseWeight(sText),
          target: tText.isEmpty ? null : parseWeight(tText),
          height: hText.isEmpty
              ? null
              : double.tryParse(hText.replaceAll(',', '.')),
          maintenance: maintenance,
        ),
      );
    }
    startCtrl.dispose();
    targetCtrl.dispose();
    heightCtrl.dispose();
  }

  Future<void> _openCircumferencesDialog() async {
    final waistCtrl = TextEditingController(
      text: widget.settings.waistCm == null
          ? ''
          : widget.settings.waistCm!.toStringAsFixed(1),
    );
    final hipCtrl = TextEditingController(
      text: widget.settings.hipCm == null
          ? ''
          : widget.settings.hipCm!.toStringAsFixed(1),
    );
    final neckCtrl = TextEditingController(
      text: widget.settings.neckCm == null
          ? ''
          : widget.settings.neckCm!.toStringAsFixed(1),
    );
    String? validationError;

    double? parseCm(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t.replaceAll(',', '.'));
      return (v != null && v >= 15 && v <= 250) ? rounded(v) : -1;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Vücut Çevre Ölçüleri (cm)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tartıdaki kilo sabit kalsa bile incelmeyi takip etmek için mezura ölçülerini kaydedebilirsin.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: waistCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: trText('Bel Çevresi (opsiyonel)'),
                    hintText: trText('Örn. 88.0'),
                    suffixText: 'cm',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hipCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: trText('Kalça Çevresi (opsiyonel)'),
                    hintText: trText('Örn. 102.0'),
                    suffixText: 'cm',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: neckCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: trText('Boyun Çevresi (opsiyonel)'),
                    hintText: trText('Örn. 38.0'),
                    suffixText: 'cm',
                  ),
                ),
                if (validationError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    validationError!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final w = parseCm(waistCtrl.text);
                final h = parseCm(hipCtrl.text);
                final n = parseCm(neckCtrl.text);
                if (w == -1 || h == -1 || n == -1) {
                  setDialogState(() {
                    validationError =
                        'Lütfen 15 ile 250 cm arasında geçerli değerler girin.';
                  });
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      await change(
        () => widget.settings.setCircumferences(
          waist: parseCm(waistCtrl.text),
          hip: parseCm(hipCtrl.text),
          neck: parseCm(neckCtrl.text),
        ),
      );
    }
    waistCtrl.dispose();
    hipCtrl.dispose();
    neckCtrl.dispose();
  }

  String _activeScheduleSummary(AppSettings settings) {
    final parts = [
      for (final slot in Slot.values)
        if (settings.reminders[slot]!.enabled)
          '${slot.label} ${settings.reminders[slot]!.timeLabel}',
    ];
    return parts.isEmpty ? 'Kapalı' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: trText('Geri'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ayarlar'),
        actions: [
          IconButton(
            tooltip: trText('Hakkında'),
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: trText('Kilo Takip'),
                applicationVersion: trText('Sürüm $appVersionString'),
                children: const [
                  Text(
                    'Sabah ve akşam kilo ölçümlerini tamamen çevrimdışı olarak cihazında saklayan kişisel kilo takip uygulaması.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.settings, widget.reminders]),
          builder: (context, _) {
            final status = widget.reminders.value;
            return PageBody([
              // BÖLÜM 1 – BİLDİRİMLER
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.notifications_none_rounded,
                      iconBg: c.primarySoft,
                      iconColor: c.primaryBlue,
                      title: 'Bildirimler',
                      subtitle:
                          'Kilo takibini hatırlatacak bildirimleri ayarla.',
                    ),
                    const SizedBox(height: 16),

                    for (final (idx, slot) in Slot.values.indexed) ...[
                      if (idx > 0) const SizedBox(height: 14),
                      _ReminderSlotBlock(
                        slot: slot,
                        reminder: widget.settings.reminders[slot]!,
                        busy: busy,
                        onToggle: (enabled) => change(() async {
                          final current = widget.settings.reminders[slot]!;
                          final updated = Reminder(enabled, current.time);
                          await widget.settings.setReminder(slot, updated);
                          await widget.reminders.sync(
                            widget.settings,
                            ask: enabled,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    enabled
                                        ? '${slot.label} bildirimi her gün saat ${updated.timeLabel} için aktif edildi.'
                                        : '${slot.label} bildirimi kapatıldı.',
                                  ),
                                ),
                              );
                          }
                        }),
                        onPickTime: () async {
                          final current = widget.settings.reminders[slot]!;
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: current.time,
                            builder: (ctx, child) => MediaQuery(
                              data: MediaQuery.of(
                                ctx,
                              ).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            ),
                          );
                          if (mounted && picked != null) {
                            await change(() async {
                              final updated = Reminder(true, picked);
                              await widget.settings.setReminder(slot, updated);
                              await widget.reminders.sync(
                                widget.settings,
                                ask: true,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${slot.label} bildirimi her gün saat ${updated.timeLabel} için planlandı.',
                                      ),
                                    ),
                                  );
                              }
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: c.subtitle,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            switch (status) {
                              ReminderStatus.blocked =>
                                'Hatırlatmaları alabilmek için bildirim izni vermen gerekiyor.',
                              ReminderStatus.approximate =>
                                'Aktif: ${_activeScheduleSummary(widget.settings)} (Yaklaşık zamanlama).',
                              ReminderStatus.error =>
                                'Bildirim planlanamadı. Tekrar deneyebilirsin.',
                              ReminderStatus.off =>
                                'Sabah ve akşam bildirimleri şu anda kapalı.',
                              ReminderStatus.active =>
                                'Aktif: ${_activeScheduleSummary(widget.settings)} (Yerel telefon bildirimleri kullanılır).',
                            },
                            style: TextStyle(
                              fontSize: 12.5,
                              color: status == ReminderStatus.blocked
                                  ? c.orangeText
                                  : c.subtitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (status == ReminderStatus.blocked ||
                        status == ReminderStatus.error) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => change(
                                  () => widget.reminders.sync(
                                    widget.settings,
                                    ask: true,
                                  ),
                                ),
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Bildirim İznini Kontrol Et'),
                        ),
                      ),
                    ],
                    if (Platform.isAndroid &&
                        status == ReminderStatus.approximate) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => change(
                                  () => widget.reminders.sync(
                                    widget.settings,
                                    askExact: true,
                                  ),
                                ),
                          icon: const Icon(Icons.alarm_on_rounded),
                          label: const Text('Kesin Alarm İznini Aç'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // BÖLÜM 2 – DİL SEÇİMİ (16 DİL & BÖLGE)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.language_rounded,
                      iconBg: c.primarySoft,
                      iconColor: c.primaryBlue,
                      title: 'Uygulama Dili & Bölge',
                      subtitle:
                          'Tüm ekranları, grafikleri, raporları ve hesaplamaları seçtiğin dilde görüntüle.',
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: busy
                          ? null
                          : () => showLanguageSelectorSheet(
                              context,
                              widget.settings,
                              widget.reminders,
                            ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Text(
                              widget.settings.language.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.settings.language.nativeName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: c.heading,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Dil (${AppLanguage.values.length} Ülke / Bölge) • ${widget.settings.language.trName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.unfold_more_rounded,
                              color: c.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // BÖLÜM 3 – GÖRÜNÜM
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.palette_outlined,
                      iconBg: c.primarySoft,
                      iconColor: c.primaryBlue,
                      title: 'Görünüm',
                      subtitle:
                          'Uygulamanın tema modunu ve vurgu renk paletini seç.',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.cardBorder),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _ThemeOptionButton(
                            label: 'Açık',
                            icon: Icons.wb_sunny_outlined,
                            active: widget.settings.theme == ThemeMode.light,
                            onTap: busy
                                ? null
                                : () => change(
                                    () => widget.settings.setTheme(
                                      ThemeMode.light,
                                    ),
                                  ),
                          ),
                          _ThemeOptionButton(
                            label: 'Koyu',
                            icon: Icons.dark_mode_outlined,
                            active: widget.settings.theme == ThemeMode.dark,
                            onTap: busy
                                ? null
                                : () => change(
                                    () => widget.settings.setTheme(
                                      ThemeMode.dark,
                                    ),
                                  ),
                          ),
                          _ThemeOptionButton(
                            label: 'Sistem',
                            icon: Icons.desktop_windows_outlined,
                            active: widget.settings.theme == ThemeMode.system,
                            onTap: busy
                                ? null
                                : () => change(
                                    () => widget.settings.setTheme(
                                      ThemeMode.system,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // --------------------------------------------------------
                    // Açılır / Kapanır Renk Paleti Listesi
                    // --------------------------------------------------------
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Renk Paleti (${AppColorPalette.values.length} Seçenek)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.heading,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(
                            () => _paletteExpanded = !_paletteExpanded,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _paletteExpanded
                                      ? trText('Kapat')
                                      : trText('Değiştir'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _paletteExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: c.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Başlık Özeti (Seçili Palet Kartı - Tıklayınca Açılır/Kapanır)
                    Material(
                      color: c.background,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(
                          () => _paletteExpanded = !_paletteExpanded,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _paletteExpanded
                                  ? widget.settings.palette.lightPrimary
                                  : c.cardBorder,
                              width: _paletteExpanded ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              _PaletteDualSwatch(
                                primary: widget.settings.palette.lightPrimary,
                                secondary:
                                    widget.settings.palette.lightSecondary,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.settings.palette.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: c.heading,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.settings.palette
                                                .lightPrimary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            trText('Aktif'),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: widget.settings.palette
                                                  .lightPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.settings.palette.description,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: c.subtitle,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedRotation(
                                turns: _paletteExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: c.subtitle,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Açılır Liste (Tüm Seçenekler)
                    if (_paletteExpanded) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final (
                              index,
                              p,
                            ) in AppColorPalette.values.indexed) ...[
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: c.cardBorder.withValues(alpha: 0.6),
                                ),
                              Builder(
                                builder: (context) {
                                  final selected =
                                      widget.settings.palette == p;
                                  return Material(
                                    color: selected
                                        ? p.lightPrimary.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    child: InkWell(
                                      onTap: busy
                                          ? null
                                          : () => change(
                                              () =>
                                                  widget.settings.setPalette(p),
                                            ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            _PaletteDualSwatch(
                                              primary: p.lightPrimary,
                                              secondary: p.lightSecondary,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.label,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: selected
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      color: selected
                                                          ? p.lightPrimary
                                                          : c.heading,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1.5),
                                                  Text(
                                                    p.description,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: c.subtitle,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (selected)
                                              Icon(
                                                Icons.check_circle_rounded,
                                                size: 20,
                                                color: p.lightPrimary,
                                              )
                                            else
                                              Icon(
                                                Icons.circle_outlined,
                                                size: 19,
                                                color: c.cardBorder,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // BÖLÜM 3 – HEDEF KİLO & VÜCUT ÖLÇÜLERİ
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.track_changes_rounded,
                      iconBg: c.primarySoft,
                      iconColor: c.primaryBlue,
                      title: 'Hedef Kilo & Vücut Ölçüleri',
                      subtitle:
                          'Hedef kilo, boy (VKİ) ve mezura çevre ölçülerini tanımla.',
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: busy ? null : _openGoalDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.settings.targetWeight == null
                                        ? 'Henüz hedef kilo belirlenmedi.'
                                        : 'Hedef: ${kg(widget.settings.targetWeight)}${widget.settings.maintenanceMode ? " (Koruma Modu)" : ""}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.heading,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      widget.settings.startWeight == null
                                          ? 'Başlangıç: İlk kayıt'
                                          : 'Başlangıç: ${kg(widget.settings.startWeight)}',
                                      if (widget.settings.heightCm != null)
                                        'Boy: ${widget.settings.heightCm!.round()} cm',
                                    ].join(' • '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: c.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: busy ? null : _openCircumferencesDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bel, Kalça & Boyun Çevresi (cm)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.heading,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (widget.settings.waistCm == null &&
                                            widget.settings.hipCm == null &&
                                            widget.settings.neckCm == null)
                                        ? 'Mezura ölçüsü girilmedi (Opsiyonel)'
                                        : [
                                            if (widget.settings.waistCm != null)
                                              'Bel: ${widget.settings.waistCm!.toStringAsFixed(1)} cm',
                                            if (widget.settings.hipCm != null)
                                              'Kalça: ${widget.settings.hipCm!.toStringAsFixed(1)} cm',
                                            if (widget.settings.neckCm != null)
                                              'Boyun: ${widget.settings.neckCm!.toStringAsFixed(1)} cm',
                                          ].join(' • '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.straighten_rounded,
                              size: 19,
                              color: c.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // BÖLÜM 4 – VERİ YÖNETİMİ
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.storage_rounded,
                      iconBg: c.primarySoft,
                      iconColor: c.primaryBlue,
                      title: 'Veri Yönetimi',
                      subtitle:
                          'Kilo verilerini dışa aktar, yerel veri bilgisini görüntüle.',
                    ),
                    const SizedBox(height: 14),

                    // Excel Dışa Aktar (.xlsx)
                    Material(
                      color: c.background,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: widget.export,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: c.greenSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.table_view_rounded,
                                  color: c.greenText,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Excel Dışa Aktar (.xlsx)',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: c.heading,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tüm kilo kayıtlarını Excel dosyası olarak indir.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: c.subtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: c.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Yerel Veri Bilgisi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.dns_outlined,
                              color: c.primaryBlue,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yerel Veri Bilgisi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: c.heading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Verileriniz bu cihazda saklanır. İnternet bağlantısı gerekmez.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: c.greenSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: c.greenText,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'SQLite',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.greenText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // BÖLÜM 5 – HAKKINDA
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: c.primaryBlue,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Hakkında',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_weight_outlined,
                          size: 19,
                          color: c.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Uygulama Adı',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.heading,
                            ),
                          ),
                        ),
                        Text(
                          'Kilo Takip',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: c.heading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 19,
                          color: c.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sürüm',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.heading,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'v$appVersionString',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 19,
                          color: c.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tamamen Çevrimdışı Çalışır',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.heading,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12.5, color: c.subtitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReminderSlotBlock extends StatelessWidget {
  const _ReminderSlotBlock({
    required this.slot,
    required this.reminder,
    required this.busy,
    required this.onToggle,
    required this.onPickTime,
  });

  final Slot slot;
  final Reminder reminder;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final formattedTime = clockLabel(
      reminder.time.hour * 60 + reminder.time.minute,
    );

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.slotSurface(slot),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: SlotIcon(slot, size: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.label} Bildirimi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.heading,
                    ),
                  ),
                  Text(
                    reminder.enabled
                        ? 'Her gün $formattedTime saatinde hatırlatır'
                        : 'Bildirim kapalı',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: reminder.enabled ? c.primaryBlue : c.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: reminder.enabled,
              activeTrackColor: c.primaryBlue,
              onChanged: busy ? null : onToggle,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: c.background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: busy ? null : onPickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: c.subtitle,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: reminder.enabled ? c.heading : c.subtitle,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: c.subtitle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeOptionButton extends StatelessWidget {
  const _ThemeOptionButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Material(
        color: active ? c.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? c.primaryBlue : c.subtitle,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? c.primaryBlue : c.heading,
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

class _PaletteDualSwatch extends StatelessWidget {
  const _PaletteDualSwatch({
    required this.primary,
    required this.secondary,
    this.size = 24,
  });

  final Color primary;
  final Color secondary;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                color: secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: secondary.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
