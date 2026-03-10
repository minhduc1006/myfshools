import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/badge.dart';

class DashboardScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final String userName;
  final void Function(String screen, [dynamic data]) onNavigate;

  const DashboardScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.userName,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardFuture;
  late Future<UserProfile> _profileFuture;
  late Future<List<AlertDto>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.apiClient.getDashboard(widget.token);
    _profileFuture = widget.apiClient.getProfile(widget.token);
    _alertsFuture = widget.apiClient.getAlerts(widget.token);
  }

  Future<void> _reload() async {
    setState(() {
      _dashboardFuture = widget.apiClient.getDashboard(widget.token);
      _profileFuture = widget.apiClient.getProfile(widget.token);
      _alertsFuture = widget.apiClient.getAlerts(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, dashboardSnapshot) {
          if (dashboardSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tải dữ liệu thất bại: ${dashboardSnapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final dashboard = dashboardSnapshot.data!;
          return FutureBuilder<UserProfile>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Tải hồ sơ thất bại: ${profileSnapshot.error}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final profile = profileSnapshot.data!;
              final displayName = widget.userName.trim().isNotEmpty
                  ? widget.userName
                  : dashboard.studentName;
              final quickActions = _buildQuickActions(profile);
              final isStudent = profile.role == 'STUDENT';
              final isTeacher = profile.role == 'HOMEROOM_TEACHER' ||
                  profile.role == 'SUBJECT_TEACHER';
              final isExamOfficer = profile.role == 'EXAM_OFFICER';

              return RefreshIndicator(
                onRefresh: _reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 92),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7A00),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào $displayName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Card(
                                color: Colors.white.withValues(alpha: 0.95),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _InfoCol(
                                        label: 'Lớp',
                                        value: profile.role == 'STUDENT'
                                            ? dashboard.className
                                            : (profile.managedClass
                                                    .trim()
                                                    .isNotEmpty
                                                ? profile.managedClass
                                                : dashboard.className),
                                        valueColor: AppColors.foreground,
                                      ),
                                      _InfoCol(
                                        label: 'Năm học',
                                        value: dashboard.term,
                                        valueColor: AppColors.foreground,
                                      ),
                                      _InfoCol(
                                        label: profile.role == 'STUDENT'
                                            ? 'Điểm TB'
                                            : 'Vai trò',
                                        value: profile.role == 'STUDENT'
                                            ? dashboard.gpa
                                            : _roleLabel(profile.role),
                                        valueColor: AppColors.accent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Truy cập nhanh',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 0.85,
                              children: quickActions,
                            ),
                          ],
                        ),
                      ),
                      if (!isStudent)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tổng quan',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              if (isExamOfficer)
                                FutureBuilder<List<TuitionClassSummaryDto>>(
                                  future: widget.apiClient.getExamTuitionOverview(
                                    widget.token,
                                  ),
                                  builder: (context, snapshot) {
                                    final items = snapshot.data ?? const [];
                                    final top = items.take(3).toList();
                                    return AppCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Học phí theo lớp',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (top.isEmpty)
                                            const Text(
                                              'Chưa có dữ liệu.',
                                              style: TextStyle(
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                            )
                                          else
                                            for (final it in top)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Lớp ${it.className}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    AppBadge(
                                                      'Chưa nộp ${it.unpaidStudents}',
                                                      textColor:
                                                          AppColors.destructive,
                                                      background: AppColors
                                                          .destructive
                                                          .withValues(
                                                              alpha: 0.10),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  widget.onNavigate('tuition_admin'),
                                              child: const Text(
                                                'Mở quản lý học phí',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              if (isExamOfficer) const SizedBox(height: 12),
                              if (isExamOfficer)
                                FutureBuilder<List<ServiceRequestDto>>(
                                  future: widget.apiClient.getServiceRequests(
                                    widget.token,
                                    category: 'EXAM',
                                  ),
                                  builder: (context, snapshot) {
                                    final items = snapshot.data ?? const [];
                                    final pending = items
                                        .where((e) => e.status != 'RESOLVED')
                                        .take(3)
                                        .toList();
                                    return AppCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Đơn khảo thí cần xử lý',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (pending.isEmpty)
                                            const Text(
                                              'Không có đơn chờ xử lý.',
                                              style: TextStyle(
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                            )
                                          else
                                            for (final it in pending)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        it.title,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    AppBadge(it.status),
                                                  ],
                                                ),
                                              ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  widget.onNavigate('exam'),
                                              child: const Text(
                                                'Mở danh sách đơn',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              if (isTeacher)
                                FutureBuilder<List<TeacherAssignmentDto>>(
                                  future: widget.apiClient.getTeacherAssignments(
                                    widget.token,
                                  ),
                                  builder: (context, snapshot) {
                                    final items = snapshot.data ?? const [];
                                    final top = items.take(3).toList();
                                    return AppCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Bài tập gần đây',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (top.isEmpty)
                                            const Text(
                                              'Chưa có bài tập nào.',
                                              style: TextStyle(
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                            )
                                          else
                                            for (final it in top)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            it.title,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            '${it.targetClass} • ${it.dueDate}',
                                                            style:
                                                                const TextStyle(
                                                              color: AppColors
                                                                  .mutedForeground,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    AppBadge(it.subject),
                                                  ],
                                                ),
                                              ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () => widget.onNavigate(
                                                'teacher-workbench',
                                              ),
                                              child: const Text(
                                                'Mở giao bài',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              if (isTeacher) const SizedBox(height: 12),
                              if (isTeacher)
                                FutureBuilder<List<ScheduleItemDto>>(
                                  future: widget.apiClient.getTimetable(
                                    widget.token,
                                  ),
                                  builder: (context, snapshot) {
                                    final items = (snapshot.data ?? const [])
                                        .where((e) =>
                                            DateTime.tryParse(e.scheduleDate) !=
                                            null)
                                        .toList()
                                      ..sort((a, b) => (a.scheduleDate +
                                              a.startTime)
                                          .compareTo(
                                              b.scheduleDate + b.startTime));
                                    final todayKey = DateUtils.dateOnly(
                                      DateTime.now(),
                                    ).toString();
                                    final todayItems = items
                                        .where(
                                            (e) => e.scheduleDate == todayKey)
                                        .take(3)
                                        .toList();
                                    return AppCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Lịch hôm nay',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (todayItems.isEmpty)
                                            const Text(
                                              'Không có lịch dạy hôm nay.',
                                              style: TextStyle(
                                                color:
                                                    AppColors.mutedForeground,
                                              ),
                                            )
                                          else
                                            for (final it in todayItems)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        it.subject,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    AppBadge(it.startTime),
                                                  ],
                                                ),
                                              ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  widget.onNavigate(
                                                'timetable',
                                              ),
                                              child: const Text('Mở lịch dạy'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 12),
                              FutureBuilder<List<AlertDto>>(
                                future: _alertsFuture,
                                builder: (context, snapshot) {
                                  final items = snapshot.data ?? const [];
                                  final top = items.take(3).toList();
                                  return AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Thông báo gần đây',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (top.isEmpty)
                                          const Text(
                                            'Chưa có thông báo.',
                                            style: TextStyle(
                                              color: AppColors.mutedForeground,
                                            ),
                                          )
                                        else
                                          for (final it in top)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    it.title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    it.message,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .mutedForeground,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                widget.onNavigate('alerts'),
                                            child: const Text('Xem tất cả'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (profile.role == 'STUDENT') ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tiết sắp tới',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 16),
                              ...dashboard.upcomingClasses.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                item.dayLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.dayNumber}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.subject,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          item.room,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            color: AppColors
                                                                .mutedForeground,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  AppBadge(item.startTime),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'GV: ${item.teacher}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.mutedForeground,
                                                ),
                                              ),
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
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildQuickActions(UserProfile profile) {
    final isStudent = profile.role == 'STUDENT';
    final isHomeroom = profile.role == 'HOMEROOM_TEACHER';
    final isSubjectTeacher = profile.role == 'SUBJECT_TEACHER';
    final isExamOfficer = profile.role == 'EXAM_OFFICER';
    final isTeacher = isHomeroom || isSubjectTeacher;

    final actions = <Widget>[
      _QuickAction(
        icon: LucideIcons.bell,
        label: 'Thông báo',
        color: const Color(0xFFF59E0B),
        onTap: () => widget.onNavigate('alerts'),
      ),
    ];

    if (isTeacher) {
      actions.add(
        _QuickAction(
          icon: LucideIcons.clipboardSignature,
          label: 'Giao bài',
          color: const Color(0xFF0F766E),
          onTap: () => widget.onNavigate('teacher-workbench'),
        ),
      );
    }

    if (isExamOfficer) {
      actions.add(
        _QuickAction(
          icon: LucideIcons.wallet,
          label: 'Học phí',
          color: const Color(0xFF10B981),
          onTap: () => widget.onNavigate('tuition_admin'),
        ),
      );
      actions.add(
        _QuickAction(
          icon: LucideIcons.shieldCheck,
          label: 'Khảo thí',
          color: const Color(0xFF334155),
          onTap: () => widget.onNavigate('exam'),
        ),
      );
    }

    if (isStudent) {
      actions.addAll([
        _QuickAction(
          icon: LucideIcons.calendar,
          label: 'Lịch học',
          color: AppColors.secondary,
          onTap: () => widget.onNavigate('timetable'),
        ),
        _QuickAction(
          icon: LucideIcons.clipboardCheck,
          label: 'Bài tập',
          color: AppColors.primary,
          onTap: () => widget.onNavigate('homework'),
        ),
        _QuickAction(
          icon: LucideIcons.trendingUp,
          label: 'Điểm số',
          color: AppColors.accent,
          onTap: () => widget.onNavigate('grades'),
        ),
        _QuickAction(
          icon: LucideIcons.bookOpen,
          label: 'Ghi chú',
          color: const Color(0xFFF97316),
          onTap: () => widget.onNavigate('notes'),
        ),
        _QuickAction(
          icon: LucideIcons.wallet,
          label: 'Học phí',
          color: const Color(0xFF10B981),
          onTap: () => widget.onNavigate('tuition_receipts'),
        ),
        _QuickAction(
          icon: LucideIcons.fileText,
          label: 'Viết đơn',
          color: const Color(0xFF6366F1),
          onTap: () => widget.onNavigate('applications'),
        ),
        _QuickAction(
          icon: LucideIcons.shieldCheck,
          label: 'Khảo thí',
          color: const Color(0xFF334155),
          onTap: () => widget.onNavigate('exam'),
        ),
      ]);
    } else if (isTeacher) {
      actions.addAll([
        _QuickAction(
          icon: LucideIcons.trendingUp,
          label: 'Nhập điểm',
          color: AppColors.accent,
          onTap: () => widget.onNavigate('grades'),
        ),
        _QuickAction(
          icon: LucideIcons.calendar,
          label: 'Lịch dạy',
          color: AppColors.secondary,
          onTap: () => widget.onNavigate('timetable'),
        ),
      ]);
    }

    return actions;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'HOMEROOM_TEACHER':
        return 'Chủ nhiệm';
      case 'SUBJECT_TEACHER':
        return 'Bộ môn';
      case 'EXAM_OFFICER':
        return 'Khảo thí';
      default:
        return 'Học sinh';
    }
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoCol({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              offset: Offset(0, 2),
              color: Color(0x0A000000),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, height: 1.1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
