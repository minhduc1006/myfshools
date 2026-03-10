import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/badge.dart';

class HomeworkScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final void Function(String screen, [dynamic data]) onNavigate;

  const HomeworkScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onNavigate,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  int _studentTab = 0;
  List<HomeworkItemDto> _studentItems = const [];

  int _teacherTab = 0;
  List<TeacherAssignmentDto> _teacherAssignments = const [];
  List<HomeworkClassReportDto> _teacherReports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isStudent => _profile?.role == 'STUDENT';
  bool get _canCreateAssignment =>
      _profile?.role == 'HOMEROOM_TEACHER' ||
      _profile?.role == 'SUBJECT_TEACHER';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          _profile ?? await widget.apiClient.getProfile(widget.token);
      if (profile.role == 'STUDENT') {
        final data = await widget.apiClient.getHomeworks(widget.token);
        if (!mounted) {
          return;
        }
        setState(() {
          _profile = profile;
          _studentItems = data;
        });
      } else {
        final reports = await widget.apiClient.getTeacherHomeworkReports(
          widget.token,
        );
        final assignments = profile.role == 'EXAM_OFFICER'
            ? const <TeacherAssignmentDto>[]
            : await widget.apiClient.getTeacherAssignments(widget.token);
        if (!mounted) {
          return;
        }
        setState(() {
          _profile = profile;
          _teacherAssignments = assignments;
          _teacherReports = reports;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<HomeworkItemDto> get _filteredStudentItems {
    if (_studentTab == 1) {
      return _studentItems
          .where((i) => i.status == 'pending' || i.status == 'overdue')
          .toList();
    }
    if (_studentTab == 2) {
      return _studentItems.where((i) => i.status == 'submitted').toList();
    }
    return _studentItems;
  }

  Future<void> _createAssignment() async {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(
      text: _profile?.subjectSpecialty.trim().isNotEmpty == true
          ? _profile!.subjectSpecialty
          : '',
    );
    final classCtrl = TextEditingController(
      text: _profile?.managedClass ?? '',
    );
    final dueCtrl = TextEditingController(text: '08/03/2026');
    final noteCtrl = TextEditingController();
    final fileCtrl = TextEditingController(text: 'assignment.pdf');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giao bài'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Môn học'),
              ),
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(labelText: 'Lớp'),
              ),
              TextField(
                controller: dueCtrl,
                decoration: const InputDecoration(labelText: 'Hạn nộp'),
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Hướng dẫn'),
                maxLines: 3,
              ),
              TextField(
                controller: fileCtrl,
                decoration: const InputDecoration(labelText: 'Tệp đính kèm'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (saved != true) {
      titleCtrl.dispose();
      subjectCtrl.dispose();
      classCtrl.dispose();
      dueCtrl.dispose();
      noteCtrl.dispose();
      fileCtrl.dispose();
      return;
    }

    try {
      await widget.apiClient.createTeacherAssignment(
        widget.token,
        title: titleCtrl.text,
        subject: subjectCtrl.text,
        targetClass: classCtrl.text,
        dueDate: dueCtrl.text,
        note: noteCtrl.text,
        attachmentName: fileCtrl.text,
      );
      titleCtrl.dispose();
      subjectCtrl.dispose();
      classCtrl.dispose();
      dueCtrl.dispose();
      noteCtrl.dispose();
      fileCtrl.dispose();
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã giao bài.')),
      );
    } on ApiException catch (e) {
      titleCtrl.dispose();
      subjectCtrl.dispose();
      classCtrl.dispose();
      dueCtrl.dispose();
      noteCtrl.dispose();
      fileCtrl.dispose();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _openClassReport(String className) async {
    try {
      final details = await widget.apiClient.getTeacherHomeworkReportDetails(
        widget.token,
        className,
      );
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.85,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Báo cáo lớp $className',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final item = details[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.studentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('${item.subject} • ${item.title}'),
                              const SizedBox(height: 6),
                              Text(
                                'Hạn: ${item.dueDate} • ${item.studentPhone}',
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isStudent ? 'Bài tập' : 'Giảng dạy';

    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: title, showSearch: _isStudent),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(_error!, textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _isStudent
                            ? _StudentHomeworkView(
                                tab: _studentTab,
                                items: _filteredStudentItems,
                                onTabChange: (value) =>
                                    setState(() => _studentTab = value),
                                onOpenItem: (item) => widget.onNavigate(
                                  'homework-detail',
                                  item.toMap(),
                                ),
                              )
                            : _TeacherHomeworkView(
                                tab: _teacherTab,
                                assignments: _teacherAssignments,
                                reports: _teacherReports,
                                canCreateAssignment: _canCreateAssignment,
                                onTabChange: (value) =>
                                    setState(() => _teacherTab = value),
                                onCreateAssignment: _createAssignment,
                                onOpenClassReport: _openClassReport,
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StudentHomeworkView extends StatelessWidget {
  final int tab;
  final List<HomeworkItemDto> items;
  final ValueChanged<int> onTabChange;
  final ValueChanged<HomeworkItemDto> onOpenItem;

  const _StudentHomeworkView({
    required this.tab,
    required this.items,
    required this.onTabChange,
    required this.onOpenItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 92),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _TabPill(
                  label: 'Tất cả',
                  active: tab == 0,
                  onTap: () => onTabChange(0),
                ),
                const SizedBox(width: 10),
                _TabPill(
                  label: 'Đang làm',
                  active: tab == 1,
                  onTap: () => onTabChange(1),
                ),
                const SizedBox(width: 10),
                _TabPill(
                  label: 'Đã nộp',
                  active: tab == 2,
                  onTap: () => onTabChange(2),
                ),
              ],
            ),
          );
        }

        final it = items[index - 1];
        final color = it.status == 'submitted'
            ? AppColors.accent
            : (it.status == 'overdue'
                ? AppColors.destructive
                : AppColors.primary);
        final badgeText = it.status == 'submitted'
            ? 'Đã nộp'
            : (it.status == 'overdue' ? 'Quá hạn' : 'Chưa nộp');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onOpenItem(it),
            borderRadius: BorderRadius.circular(12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              it.subject,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        badgeText,
                        textColor: color,
                        background: color.withValues(alpha: 0.10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hạn: ${it.due}',
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        it.progress,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeacherHomeworkView extends StatelessWidget {
  final int tab;
  final List<TeacherAssignmentDto> assignments;
  final List<HomeworkClassReportDto> reports;
  final bool canCreateAssignment;
  final ValueChanged<int> onTabChange;
  final VoidCallback onCreateAssignment;
  final ValueChanged<String> onOpenClassReport;

  const _TeacherHomeworkView({
    required this.tab,
    required this.assignments,
    required this.reports,
    required this.canCreateAssignment,
    required this.onTabChange,
    required this.onCreateAssignment,
    required this.onOpenClassReport,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = tab == 0 ? assignments.length : reports.length;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _TabPill(
                      label: 'Giao bài',
                      active: tab == 0,
                      onTap: () => onTabChange(0),
                    ),
                    const SizedBox(width: 10),
                    _TabPill(
                      label: 'Báo cáo lớp',
                      active: tab == 1,
                      onTap: () => onTabChange(1),
                    ),
                  ],
                ),
                if (canCreateAssignment) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCreateAssignment,
                      icon: Icon(LucideIcons.plus, size: 16),
                      label: const Text('Tạo bài tập mới'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        if (tab == 0) {
          final item = assignments[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      AppBadge(item.targetClass),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${item.subject} • Hạn nộp ${item.dueDate}'),
                  const SizedBox(height: 8),
                  Text(item.note),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo bởi: ${item.createdBy}',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final report = reports[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onOpenClassReport(report.className),
            borderRadius: BorderRadius.circular(12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lớp ${report.className}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SummaryChip(
                        label: 'Sĩ số',
                        value: '${report.totalStudents}',
                      ),
                      _SummaryChip(
                        label: 'Đã nộp',
                        value: '${report.submittedCount}',
                      ),
                      _SummaryChip(
                        label: 'Chưa nộp',
                        value: '${report.pendingCount}',
                      ),
                      _SummaryChip(
                        label: 'Quá hạn',
                        value: '${report.overdueCount}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.foreground,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Đã nộp':
        color = AppColors.accent;
        break;
      case 'Quá hạn':
        color = AppColors.destructive;
        break;
      default:
        color = AppColors.primary;
    }

    return AppBadge(
      status,
      textColor: color,
      background: color.withValues(alpha: 0.10),
    );
  }
}
