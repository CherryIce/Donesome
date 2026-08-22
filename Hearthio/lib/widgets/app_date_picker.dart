import 'dart:math' as math;

import 'package:flutter/material.dart';

const _primary = Color(0xFF31584B);
const _paper = Color(0xFFFFFEFA);
const _ink = Color(0xFF263630);
const _muted = Color(0xFF72817A);
const _disabled = Color(0xFFB7C0BA);
const _divider = Color(0xFFE7ECE5);

/// Opens Hearthio's shared single-date picker.
///
/// Business callers keep ownership of [firstDate] and [lastDate]. The picker
/// only normalizes the values to local calendar dates and returns the selected
/// date after the user taps “完成”.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  String title = '选择日期',
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
    backgroundColor: _paper,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => _AppDatePickerSheet(
      initialDate: normalizedInitial,
      firstDate: normalizedFirst,
      lastDate: normalizedLast,
      currentDate: _dateOnly(currentDate ?? DateTime.now()),
      title: title,
    ),
  );
}

class _AppDatePickerSheet extends StatefulWidget {
  const _AppDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.currentDate,
    this.title = '选择日期',
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
  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

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
                  color: const Color(0xFFC9CEC9),
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
                        style: const TextStyle(
                          color: _ink,
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
                        foregroundColor: _primary,
                        disabledForegroundColor: _disabled,
                        minimumSize: const Size(56, 44),
                      ),
                      child: const Text(
                        '今天',
                        style: TextStyle(
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
                    for (final weekday in _weekdays)
                      Expanded(
                        child: Center(
                          child: Text(
                            weekday,
                            style: const TextStyle(
                              color: _muted,
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
              const Divider(height: 1, color: _divider),
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
                        style: TextButton.styleFrom(foregroundColor: _primary),
                        child: const Text(
                          '取消',
                          style: TextStyle(
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
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            '完成',
                            style: TextStyle(
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
          semanticLabel: '上个月',
          icon: Icons.chevron_left_rounded,
          onPressed: canGoPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Center(
            child: Text(
              '${month.year}年${month.month}月',
              key: const Key('app-date-picker-month-label'),
              style: const TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        _MonthButton(
          key: const Key('app-date-picker-next-month'),
          semanticLabel: '下个月',
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
      color: _ink,
      disabledColor: _disabled,
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
        ? Colors.white
        : isEnabled
        ? _ink
        : _disabled;
    final dayKey = '${date.year}-${date.month}-${date.day}';

    return Semantics(
      key: Key('app-date-picker-day-$dayKey'),
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label:
          '${date.year}年${date.month}月${date.day}日'
          '${isToday ? '，今天' : ''}',
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
                color: isSelected ? _primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: _primary, width: 1.3)
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
