import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/badge.dart';

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
      final today = DateTime.now();
      int weekIndex = builtWeeks.indexWhere((week) => !today.isBefore(week.start) && !today.isAfter(week.end));
      if (weekIndex < 0) {
        weekIndex = builtWeeks.isEmpty ? 0 : 0;
      }

      final defaultDay = builtWeeks.isEmpty ? null : builtWeeks[weekIndex].days.firstOrNull;

      setState(() {
        allItems = data;
        weeks = builtWeeks;
        selectedWeekIndex = weekIndex;
        selectedDateKey = defaultDay == null ? null : _dateKey(defaultDay.date);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<_WeekInfo> _buildWeeks(List<ScheduleItemDto> items) {
    final map = <DateTime, Map<String, _DayInfo>>{};

    for (final item in items) {
      final date = DateTime.parse(item.scheduleDate);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      map.putIfAbsent(weekStart, () => {});
      map[weekStart]![_dateKey(date)] = _DayInfo(
        date: date,
        short: item.dayShort,
        full: item.dayFull,
        weekOfSemester: item.weekOfSemester,
      );
    }

    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
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
    if (selectedDateKey == null) return const [];
    return allItems.where((e) => e.scheduleDate == selectedDateKey).toList();
  }

  void _changeWeek(int delta) {
    if (weeks.isEmpty) return;
    final next = selectedWeekIndex + delta;
    if (next < 0 || next >= weeks.length) return;

    setState(() {
      selectedWeekIndex = next;
      selectedDateKey = _dateKey(weeks[next].days.first.date);
    });
  }

  String _dateKey(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
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
            AppTopBar(title: 'Thời khóa biểu', showSearch: true),
            Expanded(
              child: Center(
                child: Text(
                  'Chưa có dữ liệu thời khóa biểu',
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
          const AppTopBar(title: 'Thời khóa biểu', showSearch: true),
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
                                final active = _dateKey(day.date) == selectedDateKey;
                                return InkWell(
                                  onTap: () => setState(() => selectedDateKey = _dateKey(day.date)),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 64,
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
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
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${day.date.day}',
                                          style: TextStyle(
                                            color: active ? Colors.white : AppColors.foreground,
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
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedDay.full}, ${selectedDay.date.day}/${selectedDay.date.month}/${selectedDay.date.year}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            const AppCard(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Text('Không có lịch học', style: TextStyle(color: AppColors.mutedForeground)),
                                ),
                              ),
                            )
                          else
                            ...items.map((it) {
                              final color = _parseColor(it.colorHex);
                              final isHoliday = it.room == 'OFF';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 70,
                                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(it.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                ),
                                                if (!isHoliday) AppBadge(it.startTime),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isHoliday ? 'Không học theo kế hoạch năm học' : 'Phòng ${it.room}',
                                              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isHoliday ? it.teacher : 'GV: ${it.teacher}',
                                              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                                            ),
                                            if (!isHoliday) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${it.startTime} - ${it.endTime}',
                                                style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                                              ),
                                            ],
                                          ],
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

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    if (value == null) return AppColors.primary;
    return Color(value);
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
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 16,
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

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
