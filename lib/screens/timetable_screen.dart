import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';

class TimetableScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final void Function(String screen, [dynamic data]) onNavigate;

  const TimetableScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onNavigate,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool loading = true;
  String? error;
  List<ScheduleItemDto> allItems = const [];
  List<_WeekInfo> weeks = const [];
  int selectedWeekIndex = 0;
  String? selectedDateKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await widget.apiClient.getTimetable(widget.token);
      if (!mounted) return;

      final builtWeeks = _buildWeeks(data);
      final today = DateUtils.dateOnly(DateTime.now());
      final currentIndex = builtWeeks.indexWhere(
        (week) => !today.isBefore(week.start) && !today.isAfter(week.end),
      );
      final initialWeekIndex = currentIndex >= 0 ? currentIndex : 0;
      final initialDateKey = builtWeeks.isEmpty ? null : _dateKey(builtWeeks[initialWeekIndex].days.first.date);

      setState(() {
        allItems = data;
        weeks = builtWeeks;
        selectedWeekIndex = initialWeekIndex;
        selectedDateKey = initialDateKey;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<_WeekInfo> _buildWeeks(List<ScheduleItemDto> items) {
    final grouped = <DateTime, Map<String, _DayInfo>>{};

    for (final item in items) {
      final parsed = DateTime.tryParse(item.scheduleDate);
      if (parsed == null) continue;

      final date = DateUtils.dateOnly(parsed);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final dateKey = _dateKey(date);

      final weekDays = grouped.putIfAbsent(weekStart, () => <String, _DayInfo>{});
      weekDays.putIfAbsent(
        dateKey,
        () => _DayInfo(
          date: date,
          short: item.dayShort,
          full: item.dayFull,
          weekOfSemester: item.weekOfSemester,
        ),
      );
    }

    final entries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) {
      final days = entry.value.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      return _WeekInfo(
        start: entry.key,
        end: entry.key.add(const Duration(days: 6)),
        weekOfSemester: days.isEmpty ? 1 : days.first.weekOfSemester,
        days: days,
      );
    }).toList();
  }

  _WeekInfo? get currentWeek {
    if (weeks.isEmpty) return null;
    if (selectedWeekIndex < 0 || selectedWeekIndex >= weeks.length) return weeks.first;
    return weeks[selectedWeekIndex];
  }

  List<ScheduleItemDto> get selectedItems {
    final key = selectedDateKey;
    if (key == null) return const [];
    return allItems.where((item) => item.scheduleDate == key).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _changeWeek(int delta) {
    if (weeks.isEmpty) return;

    final nextIndex = selectedWeekIndex + delta;
    if (nextIndex < 0 || nextIndex >= weeks.length) return;

    setState(() {
      selectedWeekIndex = nextIndex;
      selectedDateKey = _dateKey(weeks[nextIndex].days.first.date);
    });
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return AppColors.primary;
    return Color(int.parse('FF$clean', radix: 16));
  }

  bool _isOffDay(ScheduleItemDto item) {
    final subject = item.subject.toLowerCase();
    return subject.contains('nghỉ') || subject.contains('không học') || item.room.trim().toUpperCase() == 'OFF';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(error!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final week = currentWeek;
    if (week == null) {
      return const Scaffold(
        body: Column(
          children: [
            AppTopBar(title: 'Thời khóa biểu'),
            Expanded(
              child: Center(
                child: Text(
                  'Chưa có dữ liệu thời khóa biểu.',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedDay = week.days.firstWhere(
      (day) => _dateKey(day.date) == selectedDateKey,
      orElse: () => week.days.first,
    );
    final items = selectedItems;

    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Thời khóa biểu'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 92),
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _NavPill(
                                icon: LucideIcons.chevronLeft,
                                enabled: selectedWeekIndex > 0,
                                onTap: () => _changeWeek(-1),
                              ),
                              Expanded(
                                child: Text(
                                  'Tuần ${week.weekOfSemester} - Tháng ${week.start.month}, ${week.start.year}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              _NavPill(
                                icon: LucideIcons.chevronRight,
                                enabled: selectedWeekIndex < weeks.length - 1,
                                onTap: () => _changeWeek(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: week.days.map((day) {
                                final active = _dateKey(day.date) == _dateKey(selectedDay.date);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => setState(() => selectedDateKey = _dateKey(day.date)),
                                  child: Container(
                                    width: 58,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: active ? AppColors.primary : AppColors.muted,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          day.short,
                                          style: TextStyle(
                                            color: active ? Colors.white : AppColors.mutedForeground,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${day.date.day}',
                                          style: TextStyle(
                                            color: active ? Colors.white : AppColors.foreground,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedDay.full}, ngày ${selectedDay.date.day}/${selectedDay.date.month}/${selectedDay.date.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            const AppCard(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Text(
                                    'Không có lịch học trong ngày này.',
                                    style: TextStyle(color: AppColors.mutedForeground),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...items.map((item) {
                              final offDay = _isOffDay(item);
                              final stripeColor = offDay ? AppColors.mutedForeground : _parseColor(item.colorHex);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppCard(
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: offDay ? 96 : 112,
                                        decoration: BoxDecoration(
                                          color: stripeColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: offDay
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.subject,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    const Text(
                                                      'Không học theo kế hoạch năm học.',
                                                      style: TextStyle(
                                                        color: AppColors.mutedForeground,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            item.subject,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w800,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${item.startTime} - ${item.endTime}',
                                                          style: const TextStyle(
                                                            color: AppColors.mutedForeground,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          LucideIcons.mapPin,
                                                          size: 16,
                                                          color: AppColors.mutedForeground,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            item.room,
                                                            style: const TextStyle(
                                                              color: AppColors.mutedForeground,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          LucideIcons.user,
                                                          size: 16,
                                                          color: AppColors.mutedForeground,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            item.teacher,
                                                            style: const TextStyle(
                                                              color: AppColors.mutedForeground,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavPill({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppColors.muted : AppColors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.foreground : AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class _WeekInfo {
  final DateTime start;
  final DateTime end;
  final int weekOfSemester;
  final List<_DayInfo> days;

  const _WeekInfo({
    required this.start,
    required this.end,
    required this.weekOfSemester,
    required this.days,
  });
}

class _DayInfo {
  final DateTime date;
  final String short;
  final String full;
  final int weekOfSemester;

  const _DayInfo({
    required this.date,
    required this.short,
    required this.full,
    required this.weekOfSemester,
  });
}
