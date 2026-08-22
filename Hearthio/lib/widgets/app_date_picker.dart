import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Opens Hearthio's shared single-date picker.
///
/// Business callers keep ownership of [firstDate] and [lastDate]. The picker
/// only normalizes the values to local calendar dates and returns the selected
/// date after the user confirms the staged value.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  String? title,
}) {
  final normalizedFirst = _dateOnly(firstDate);
  final normalizedLast = _dateOnly(lastDate);
  assert(!normalizedLast.isBefore(normalizedFirst));

  final normalizedInitial = _clampDate(
    _dateOnly(initialDate),
    normalizedFirst,
    normalizedLast,
  );

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.paper,
    barrierColor: context.palette.scrim,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _AppDatePickerSheet(
      initialDate: normalizedInitial,
      firstDate: normalizedFirst,
      lastDate: normalizedLast,
      currentDate: _dateOnly(currentDate ?? DateTime.now()),
      title: title ?? context.l10n.selectDate,
    ),
  );
}

class _AppDatePickerSheet extends StatefulWidget {
  const _AppDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.currentDate,
    required this.title,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime currentDate;
  final String title;

  @override
  State<_AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<_AppDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  DateTime get _firstMonth => _monthOnly(widget.firstDate);
  DateTime get _lastMonth => _monthOnly(widget.lastDate);

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
    _displayedMonth = _monthOnly(_selectedDate);
  }

  bool get _canGoToPreviousMonth => _displayedMonth.isAfter(_firstMonth);
  bool get _canGoToNextMonth => _displayedMonth.isBefore(_lastMonth);
  bool get _canSelectToday => _isInRange(widget.currentDate);

  void _showPreviousMonth() {
    if (!_canGoToPreviousMonth) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _showNextMonth() {
    if (!_canGoToNextMonth) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  void _selectToday() {
    if (!_canSelectToday) return;
    setState(() {
      _selectedDate = widget.currentDate;
      _displayedMonth = _monthOnly(widget.currentDate);
    });
  }

  bool _isInRange(DateTime date) =>
      !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.vertical;
    final sheetHeight = math.min(620.0, availableHeight * 0.655);
    final confirmButtonWidth = math.min(220.0, mediaQuery.size.width * 0.47);
    final contentHeight = math.max(500.0, sheetHeight);
    final viewportHeight = math.min(contentHeight, availableHeight);
    final l10n = context.l10n;
    final weekdays = [
      l10n.weekdaySunday,
      l10n.weekdayMonday,
      l10n.weekdayTuesday,
      l10n.weekdayWednesday,
      l10n.weekdayThursday,
      l10n.weekdayFriday,
      l10n.weekdaySaturday,
    ];

    return SizedBox(
      key: const Key('app-date-picker-sheet'),
      height: viewportHeight,
      child: SingleChildScrollView(
        physics: contentHeight > viewportHeight
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: contentHeight,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: context.palette.handle,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 13, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: context.palette.ink,
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('app-date-picker-today'),
                      onPressed: _canSelectToday ? _selectToday : null,
                      style: TextButton.styleFrom(
                        foregroundColor: context.palette.primary,
                        disabledForegroundColor: context.palette.disabled,
                        minimumSize: const Size(56, 44),
                      ),
                      child: Text(
                        l10n.today,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _MonthHeader(
                month: _displayedMonth,
                canGoPrevious: _canGoToPreviousMonth,
                canGoNext: _canGoToNextMonth,
                onPrevious: _showPreviousMonth,
                onNext: _showNextMonth,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (final weekday in weekdays)
                      Expanded(
                        child: Center(
                          child: Text(
                            weekday,
                            style: TextStyle(
                              color: context.palette.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Expanded(child: _buildCalendarGrid()),
              Divider(height: 1, color: context.palette.divider),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      height: 50,
                      child: TextButton(
                        key: const Key('app-date-picker-cancel'),
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: context.palette.primary,
                        ),
                        child: Text(
                          l10n.commonCancel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: confirmButtonWidth,
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          key: const Key('app-date-picker-confirm'),
                          onPressed: () =>
                              Navigator.pop(context, _selectedDate),
                          style: FilledButton.styleFrom(
                            backgroundColor: context.palette.primary,
                            foregroundColor: context.palette.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            l10n.commonDone,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = _displayedMonth;
    final leadingEmptyCells = firstDayOfMonth.weekday % DateTime.daysPerWeek;
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: DateTime.daysPerWeek,
          mainAxisExtent: 44,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          final day = index - leadingEmptyCells + 1;
          if (day < 1 || day > daysInMonth) {
            return const SizedBox.shrink();
          }
          final date = DateTime(
            _displayedMonth.year,
            _displayedMonth.month,
            day,
          );
          final isEnabled = _isInRange(date);
          return _CalendarDay(
            date: date,
            isEnabled: isEnabled,
            isSelected: _isSameDate(date, _selectedDate),
            isToday: _isSameDate(date, widget.currentDate),
            onTap: isEnabled
                ? () => setState(() => _selectedDate = date)
                : null,
          );
        },
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
    child: Row(
      children: [
        _MonthButton(
          key: const Key('app-date-picker-previous-month'),
          semanticLabel: context.l10n.previousMonth,
          icon: Icons.chevron_left_rounded,
          onPressed: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Center(
            child: Text(
              context.l10n.calendarMonthYear(month.year, month.month),
              key: const Key('app-date-picker-month-label'),
              style: TextStyle(
                color: context.palette.ink,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        _MonthButton(
          key: const Key('app-date-picker-next-month'),
          semanticLabel: context.l10n.nextMonth,
          icon: Icons.chevron_right_rounded,
          onPressed: canGoNext ? onNext : null,
        ),
      ],
    ),
  );
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    enabled: onPressed != null,
    child: IconButton(
      onPressed: onPressed,
      color: context.palette.ink,
      disabledColor: context.palette.disabled,
      iconSize: 30,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(icon),
    ),
  );
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.isEnabled,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool isEnabled;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? context.palette.onPrimary
        : isEnabled
        ? context.palette.ink
        : context.palette.disabled;
    final dayKey = '${date.year}-${date.month}-${date.day}';

    final dateLabel = context.l10n.dateYmd(date.year, date.month, date.day);
    return Semantics(
      key: Key('app-date-picker-day-$dayKey'),
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label: isToday ? context.l10n.dateTodaySemantic(dateLabel) : dateLabel,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          key: Key('app-date-picker-day-hit-$dayKey'),
          onTap: onTap,
          radius: 22,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.palette.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: context.palette.primary, width: 1.3)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _monthOnly(DateTime value) => DateTime(value.year, value.month);

DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
  if (value.isBefore(first)) return first;
  if (value.isAfter(last)) return last;
  return value;
}

bool _isSameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
