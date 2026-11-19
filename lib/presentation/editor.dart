import 'package:flutter/material.dart' hide Text;

import '../app/app_theme.dart';
import '../data/weight_repository.dart';
import '../domain/measurements.dart';
import '../state/weight_store.dart';
import 'common.dart';

class _SlotDraft {
  _SlotDraft({
    required this.weightController,
    required this.waistController,
    required this.noteController,
    required this.time,
    required this.dirty,
  });

  final TextEditingController weightController;
  final TextEditingController waistController;
  final TextEditingController noteController;
  TimeOfDay time;
  bool dirty;

  void dispose() {
    weightController.dispose();
    waistController.dispose();
    noteController.dispose();
  }
}

class WeightEditor extends StatefulWidget {
  const WeightEditor(
    this.store,
    this.day,
    this.slot, {
    this.original,
    super.key,
  });
  final WeightStore store;
  final DateTime day;
  final Slot slot;
  final Measurement? original;

  @override
  State<WeightEditor> createState() => _WeightEditorState();
}

class _WeightEditorState extends State<WeightEditor> {
  late DateTime day = dayOf(widget.day);
  late Slot slot = widget.slot;
  late final Map<Slot, _SlotDraft> drafts = {
    for (final s in Slot.values) s: _createDraft(day, s),
  };

  final formKey = GlobalKey<FormState>();
  bool busy = false;
  String? error;

  _SlotDraft _createDraft(DateTime targetDay, Slot s) {
    final existing = widget.store.stats.days[targetDay]?.values[s];
    final TimeOfDay initialTime;
    if (existing?.minutes != null) {
      initialTime = TimeOfDay(
        hour: existing!.minutes! ~/ 60,
        minute: existing.minutes! % 60,
      );
    } else if (existing != null) {
      initialTime = TimeOfDay(hour: s.hour, minute: s.minute);
    } else {
      initialTime = TimeOfDay.now();
    }

    return _SlotDraft(
      weightController: TextEditingController(
        text: existing == null ? '' : formatWeightValue(existing.kg),
      ),
      waistController: TextEditingController(
        text: existing?.waistCm == null
            ? ''
            : existing!.waistCm!.toStringAsFixed(1),
      ),
      noteController: TextEditingController(
        text: existing?.cleanNote ?? '',
      ),
      time: initialTime,
      dirty: false,
    );
  }

  void _syncDraftsForNewDate(DateTime newDay) {
    for (final s in Slot.values) {
      final draft = drafts[s]!;
      final existing = widget.store.stats.days[newDay]?.values[s];
      if (!draft.dirty) {
        draft.weightController.text = existing == null
            ? ''
            : formatWeightValue(existing.kg);
        draft.waistController.text = existing?.waistCm == null
            ? ''
            : existing!.waistCm!.toStringAsFixed(1);
        draft.noteController.text = existing?.cleanNote ?? '';
        if (existing?.minutes != null) {
          draft.time = TimeOfDay(
            hour: existing!.minutes! ~/ 60,
            minute: existing.minutes! % 60,
          );
        }
      }
    }
  }

  _SlotDraft get activeDraft => drafts[slot]!;

  @override
  void dispose() {
    for (final draft in drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  void stepWeight(double deltaKg) {
    final controller = activeDraft.weightController;
    final current = parseWeight(controller.text) ??
        widget.store.stats.days[day]?.values[slot]?.kg ??
        widget.store.stats.latestMeasurement?.kg ??
        85.0;
    final next = (current + deltaKg).clamp(minWeight, maxWeight);
    setState(() {
      controller.text = formatWeightValue(next);
      activeDraft.dirty = true;
    });
    formKey.currentState?.validate();
  }

  void stepWaist(double deltaCm) {
    final controller = activeDraft.waistController;
    final current = double.tryParse(controller.text.replaceAll(',', '.')) ??
        widget.store.stats.days[day]?.values[slot]?.waistCm ??
        widget.store.stats.latestWaistCm ??
        80.0;
    final next = (current + deltaCm).clamp(15.0, 250.0);
    setState(() {
      controller.text = next.toStringAsFixed(1);
      activeDraft.dirty = true;
    });
    formKey.currentState?.validate();
  }

  Future<void> save() async {
    if (busy || !formKey.currentState!.validate()) return;

    // Hangi kayıt türlerinde (Sabah / Akşam) geçerli veri girilmiş kontrol et
    final toSave = <Slot, Measurement>{};
    for (final s in Slot.values) {
      final draft = drafts[s]!;
      final rawText = draft.weightController.text.trim();
      if (rawText.isEmpty) continue;

      final parsedKg = parseWeight(rawText);
      if (parsedKg == null) {
        setState(() {
          slot = s;
          error =
              '${s.label} kilosu için 2 ile 500 kg arasında geçerli bir değer girin.';
        });
        formKey.currentState?.validate();
        return;
      }

      final rawWaist = draft.waistController.text.trim();
      double? parsedWaist;
      if (rawWaist.isNotEmpty) {
        final val = double.tryParse(rawWaist.replaceAll(',', '.'));
        if (val == null || val < 15.0 || val > 250.0) {
          setState(() {
            slot = s;
            error = trText(
              'Bel ölçüsü için 15 ile 250 cm arasında geçerli bir değer girin.',
            );
          });
          formKey.currentState?.validate();
          return;
        }
        parsedWaist = rounded(val);
      }

      // Aktif sekme veya kullanıcı tarafından değiştirilmiş/girilmiş sekmeyi kaydet
      final existing = widget.store.stats.days[day]?.values[s];
      final minutes = draft.time.hour * 60 + draft.time.minute;
      final cleanNote = draft.noteController.text.trim();
      final isChanged =
          existing == null ||
          existing.kg != parsedKg ||
          existing.waistCm != parsedWaist ||
          existing.effectiveMinutes != minutes ||
          (existing.cleanNote ?? '') != cleanNote;

      if (s == slot || draft.dirty || isChanged) {
        toSave[s] = Measurement(
          day,
          s,
          parsedKg,
          minutes: minutes,
          note: draft.noteController.text,
          waistCm: parsedWaist,
        );
      }
    }

    if (toSave.isEmpty) {
      setState(() {
        error = 'Kaydetmek için bir kilo değeri girin.';
      });
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      for (final entry in toSave.entries) {
        final s = entry.key;
        final measurement = entry.value;
        // Her kayıt türü (Sabah / Akşam) yalnızca kendi slotundaki kaydı günceller veya ekler;
        // birbirinin üzerine yazmaz.
        final existingSameSlot = widget.store.stats.days[day]?.values[s];
        await widget.store.save(
          measurement,
          original: existingSameSlot,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e is DuplicateMeasurement
              ? 'Bu tarih ve kayıt türü için zaten bir ölçüm mevcut.'
              : 'Kilo kaydı kaydedilemedi. Lütfen tekrar dene.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final draft = activeDraft;
    final existingForActiveSlot = widget.store.stats.days[day]?.values[slot];

    return PopScope(
      canPop: !busy,
      child: Container(
        decoration: BoxDecoration(
          color: c.cardSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sürükleme tutamacı
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: c.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Başlık ve kapatma ikonu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kilo Kaydet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: c.heading,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sabah ve akşam ölçümlerini birbirinden bağımsız olarak girebilir veya düzenleyebilirsin.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.subtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: trText('Kapat'),
                          onPressed: busy ? null : () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: c.subtitle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Alan 1 (Tarih) ve Alan 2 (Saat) yan yana
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: _FieldBox(
                            label: 'Tarih',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: busy
                                  ? null
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: day,
                                        firstDate: DateTime(1900),
                                        lastDate: dayOf(DateTime.now()),
                                      );
                                      if (mounted && picked != null) {
                                        final newDay = dayOf(picked);
                                        setState(() {
                                          day = newDay;
                                          _syncDraftsForNewDate(newDay);
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: c.cardBorder),
                                  color: c.background,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: c.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        formatTurkishDate(day),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: c.heading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: _FieldBox(
                            label: 'Saat',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: busy
                                  ? null
                                  : () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: draft.time,
                                        builder: (ctx, child) => MediaQuery(
                                          data: MediaQuery.of(ctx).copyWith(
                                            alwaysUse24HourFormat: true,
                                          ),
                                          child: child!,
                                        ),
                                      );
                                      if (mounted && picked != null) {
                                        setState(() {
                                          draft.time = picked;
                                          draft.dirty = true;
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: c.cardBorder),
                                  color: c.background,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 18,
                                      color: c.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        clockLabel(
                                          draft.time.hour * 60 +
                                              draft.time.minute,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: c.heading,
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
                    const SizedBox(height: 14),

                    // Alan 3 – Kayıt Türü (Sabah / Akşam bağımsız sekmeler)
                    _FieldBox(
                      label: 'Kayıt Türü',
                      child: Row(
                        children: [
                          for (final (i, s) in Slot.values.indexed) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final sDraft = drafts[s]!;
                                  final sKg = parseWeight(
                                    sDraft.weightController.text,
                                  );
                                  final isSelected = slot == s;
                                  return Material(
                                    color: isSelected
                                        ? c.primaryBlue
                                        : c.background,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: busy
                                          ? null
                                          : () => setState(() {
                                              slot = s;
                                              error = null;
                                            }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? c.primaryBlue
                                                : c.cardBorder,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SlotIcon(
                                                  s,
                                                  size: 19,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : c.slotAccent(s),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  s.label,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : c.heading,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              sKg != null
                                                  ? kg(sKg)
                                                  : 'Girilmedi',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white.withValues(
                                                        alpha: 0.9,
                                                      )
                                                    : c.subtitle,
                                              ),
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
                        ],
                      ),
                    ),

                    if (existingForActiveSlot != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: c.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${formatTurkishDate(day)} ${slot.label} kaydı (${kg(existingForActiveSlot.kg)}) düzenleniyor.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: c.heading,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Alan 4 – Kilo (kg) + Hızlı Artırma/Azaltma Butonları
                    _FieldBox(
                      label: '${slot.label} Kilosu (kg)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('weight_input_field'),
                            controller: draft.weightController,
                            autofocus: true,
                            enabled: !busy,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() => draft.dirty = true),
                            decoration: InputDecoration(
                              hintText: '85.0',
                              hintStyle: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: c.subtitle.withValues(alpha: 0.45),
                              ),
                              suffixText: 'kg',
                              suffixStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.subtitle,
                              ),
                              prefixIcon: IconButton(
                                tooltip: trText('Azalt (-0.1 kg)'),
                                onPressed: busy ? null : () => stepWeight(-0.1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ),
                            validator: (text) {
                              final trimmed = (text ?? '').trim();
                              final otherSlot = slot == Slot.morning
                                  ? Slot.evening
                                  : Slot.morning;
                              final otherHasValid =
                                  parseWeight(
                                    drafts[otherSlot]!.weightController.text,
                                  ) !=
                                  null;
                              if (trimmed.isEmpty && otherHasValid) return null;
                              return parseWeight(trimmed) == null
                                  ? trText('2 ile 500 kg arasında geçerli bir kilo değeri girin.')
                                  : null;
                            },
                            onFieldSubmitted: (_) => save(),
                          ),
                          const SizedBox(height: 8),
                          // 6. Hızlı Artırma / Azaltma Butonları (-0.5, -0.1, +0.1, +0.5 kg)
                          Row(
                            children: [
                              for (final (idx, step)
                                  in [-0.5, -0.1, 0.1, 0.5].indexed) ...[
                                if (idx > 0) const SizedBox(width: 6),
                                Expanded(
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => stepWeight(step),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(color: c.cardBorder),
                                    backgroundColor: c.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    step > 0
                                        ? '+${step.toStringAsFixed(1)} kg'
                                        : '${step.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Bel Ölçüsü (cm - opsiyonel) + Hızlı Ayar Butonları
                  _FieldBox(
                    label: trText('Bel Ölçüsü (cm - opsiyonel)'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('waist_input_field'),
                          controller: draft.waistController,
                          enabled: !busy,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: c.heading,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() => draft.dirty = true),
                          decoration: InputDecoration(
                            hintText: '80.0',
                            hintStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: c.subtitle.withValues(alpha: 0.45),
                            ),
                            suffixText: 'cm',
                            suffixStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.subtitle,
                            ),
                            prefixIcon: Icon(
                              Icons.straighten_rounded,
                              color: c.primaryBlue,
                            ),
                          ),
                          validator: (text) {
                            final val = (text ?? '').trim();
                            if (val.isEmpty) return null;
                            final cm = double.tryParse(val.replaceAll(',', '.'));
                            if (cm == null || cm < 15.0 || cm > 250.0) {
                              return trText(
                                'Bel ölçüsü için 15 ile 250 cm arasında geçerli bir değer girin.',
                              );
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => save(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final (idx, step)
                                in [-1.0, -0.5, 0.5, 1.0].indexed) ...[
                              if (idx > 0) const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => stepWaist(step),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide(color: c.cardBorder),
                                    backgroundColor: c.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    step > 0
                                        ? '+${step.toStringAsFixed(1)} cm'
                                        : '${step.toStringAsFixed(1)} cm',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: c.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                    // Alan 5 – Hazır Etiketler (Quick Tags) + Not (opsiyonel)
                    _FieldBox(
                      label: 'Hazır Etiketler & Not (opsiyonel)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in quickTags)
                                Builder(
                                  builder: (context) {
                                    final selected = draft.noteController.text
                                        .contains(tag);
                                    return FilterChip(
                                      label: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected
                                              ? c.primaryBlue
                                              : c.heading,
                                        ),
                                      ),
                                      selected: selected,
                                      showCheckmark: false,
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: c.background,
                                      selectedColor: c.primarySoft,
                                      side: BorderSide(
                                        color: selected
                                            ? c.primaryBlue
                                            : c.cardBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      onSelected: busy
                                          ? null
                                          : (_) {
                                              setState(() {
                                                draft.noteController.text =
                                                    toggleTagInNote(
                                                      draft.noteController.text,
                                                      tag,
                                                    );
                                                draft.dirty = true;
                                              });
                                            },
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('note_input_field'),
                            controller: draft.noteController,
                            enabled: !busy,
                            maxLines: 2,
                            minLines: 1,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() => draft.dirty = true),
                            style: TextStyle(fontSize: 14, color: c.heading),
                            decoration: InputDecoration(
                              hintText: trText('Örn. Spor sonrası, diyet 3. gün vb.'),
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: c.subtitle.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Alt Butonlar: İptal ve Kaydet
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: c.cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'İptal',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.heading,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: busy ? null : save,
                            style: FilledButton.styleFrom(
                              backgroundColor: c.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              busy ? 'Kaydediliyor…' : 'Kaydet',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.heading,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
