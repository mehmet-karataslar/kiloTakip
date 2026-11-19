import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/widgets.dart' as fw show Text;
import 'package:intl/intl.dart' hide TextDirection;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

class Text extends StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  static InlineSpan _localizeSpan(InlineSpan span) {
    if (span is TextSpan) {
      return TextSpan(
        text: span.text == null ? null : trText(span.text!),
        children: span.children?.map(_localizeSpan).toList(),
        style: span.style,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel:
            span.semanticsLabel == null ? null : trText(span.semanticsLabel!),
        locale: span.locale,
        spellOut: span.spellOut,
      );
    }
    return span;
  }

  @override
  Widget build(BuildContext context) {
    if (textSpan != null) {
      return fw.Text.rich(
        _localizeSpan(textSpan!),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel == null ? null : trText(semanticsLabel!),
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return fw.Text(
      trText(data ?? ''),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null ? null : trText(semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

List<String> get turkishMonths => AppI18n.months;

List<String> get turkishShortMonths => AppI18n.shortMonths;

List<String> get turkishWeekdays => AppI18n.weekdays;

List<String> get turkishShortWeekdays => AppI18n.shortWeekdays;

final shortDate = DateFormat('dd.MM.yyyy', 'tr_TR');
final longDate = DateFormat('d MMMM y', 'tr_TR');
final monthLabel = DateFormat('MMMM y', 'tr_TR');
final decimal = NumberFormat('0.0#', 'tr_TR');

String formatTurkishDate(DateTime date) =>
    '${date.day} ${turkishMonths[date.month - 1]} ${date.year}';

String formatTurkishDateWithWeekday(DateTime date) =>
    '${formatTurkishDate(date)}, ${turkishWeekdays[date.weekday - 1]}';

String formatShortDayMonth(DateTime date) =>
    '${date.day} ${turkishShortMonths[date.month - 1]}';

String formatMonthYear(DateTime date) =>
    '${turkishMonths[date.month - 1]} ${date.year}';

String formatWeightValue(double value) {
  final r = rounded(value);
  final hundredths = (r * 100).round().abs() % 10;
  return hundredths == 0 ? r.toStringAsFixed(1) : r.toStringAsFixed(2);
}

String kg(double? n) => n == null ? '—' : '${formatWeightValue(n)} kg';

String delta(double? n, {String empty = 'Veri yetersiz'}) {
  if (n == null) return trText(empty);
  final r = rounded(n);
  if (r == 0) return '0.0 kg';
  final sign = r > 0 ? '+' : '-';
  return '$sign${formatWeightValue(r.abs())} kg';
}

String measurementLabel(Measurement measurement) {
  final time = measurement.minutes;
  return time == null
      ? kg(measurement.kg)
      : '${kg(measurement.kg)} • ${clockLabel(time)}';
}

class PageBody extends StatelessWidget {
  const PageBody(
    this.children, {
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 28),
    super.key,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(
        padding: padding,
        children: children,
      ),
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.borderRadius = 20,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      decoration: BoxDecoration(
        color: color ?? c.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? c.cardBorder),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
    return box;
  }
}

class Section extends StatelessWidget {
  const Section(this.title, {this.subtitle, super.key});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.heading,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13.5,
                color: c.subtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Note extends StatelessWidget {
  const Note(this.text, {this.icon, super.key});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.info_outline_rounded,
            size: 20,
            color: c.primaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                color: c.subtitle,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<(T value, String label)> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _PillButton(
              label: item.$2,
              active: item.$1 == selected,
              onTap: () => onSelected(item.$1),
              colors: c,
            ),
          ),
        ],
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? colors.primaryBlue : colors.chipUnselected,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : colors.heading,
            ),
          ),
        ),
      ),
    ),
  );
}

class SlotIcon extends StatelessWidget {
  const SlotIcon(this.slot, {this.size = 20, this.color, super.key});
  final Slot slot;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.slotAccent(slot);
    return Icon(
      slot == Slot.morning
          ? Icons.wb_twilight_rounded
          : Icons.dark_mode_outlined,
      size: size,
      color: c,
    );
  }
}

/// Referans görseldeki sade mavi tartı illüstrasyonu.
class ScaleIllustration extends StatelessWidget {
  const ScaleIllustration({this.size = 72, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.15,
    height: size,
    child: CustomPaint(
      painter: _ScalePainter(
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    ),
  );
}

class _ScalePainter extends CustomPainter {
  const _ScalePainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bgBlobPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1A3154).withValues(alpha: 0.7)
          : const Color(0xFFE3EFFD);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.18,
        size.width * 0.92,
        size.height * 0.76,
      ),
      bgBlobPaint,
    );

    canvas.save();
    canvas.translate(size.width * 0.54, size.height * 0.54);
    canvas.rotate(0.06);

    final w = size.width * 0.62;
    final h = size.height * 0.66;
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(2, 3), width: w, height: h),
      const Radius.circular(11),
    );
    final topRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      const Radius.circular(11),
    );

    // Tartı gövde gölgesi
    canvas.drawRRect(
      baseRect,
      Paint()..color = const Color(0xFF3E82E8),
    );

    // Tartı ön yüzey
    canvas.drawRRect(
      topRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8CC0FF), Color(0xFF5A9DF8)],
        ).createShader(topRect.outerRect),
    );

    // Kadran alanı (yarım daire / pencere)
    final dialRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(0, -h * 0.16),
        width: w * 0.64,
        height: h * 0.36,
      ),
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    canvas.drawRRect(dialRect, Paint()..color = Colors.white);

    // Kadran ibresi ve çizgileri
    final tickPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final dialCenter = Offset(0, -h * 0.03);
    for (final angle in [-2.4, -1.9, -1.2, -0.7]) {
      final p1 = Offset(
        dialCenter.dx + math.cos(angle) * (w * 0.20),
        dialCenter.dy + math.sin(angle) * (w * 0.20),
      );
      final p2 = Offset(
        dialCenter.dx + math.cos(angle) * (w * 0.26),
        dialCenter.dy + math.sin(angle) * (w * 0.26),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }
    // İbre
    canvas.drawLine(
      dialCenter,
      Offset(dialCenter.dx + 2, dialCenter.dy - h * 0.22),
      Paint()
        ..color = const Color(0xFF166FE5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // Sol üst küçük vurgu çizgileri
    final rayPaint = Paint()
      ..color = const Color(0xFF287DF0)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.22),
      Offset(size.width * 0.10, size.height * 0.17),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.15),
      Offset(size.width * 0.21, size.height * 0.07),
      rayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.13, size.height * 0.30),
      Offset(size.width * 0.06, size.height * 0.30),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScalePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa'),
    (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Grafikler'),
    (Icons.history_rounded, Icons.history_rounded, 'Geçmiş'),
    (Icons.analytics_outlined, Icons.analytics_outlined, 'Raporlar'),
    (Icons.calculate_rounded, Icons.calculate_outlined, 'Hesap'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardSurface,
        border: Border(top: BorderSide(color: c.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              for (final (i, item) in _items.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: currentIndex == i
                          ? c.primarySoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onTap(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 2,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentIndex == i ? item.$1 : item.$2,
                                size: 21,
                                color: currentIndex == i
                                    ? c.primaryBlue
                                    : c.subtitle,
                              ),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.$3,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: currentIndex == i
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: currentIndex == i
                                        ? c.primaryBlue
                                        : c.subtitle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
