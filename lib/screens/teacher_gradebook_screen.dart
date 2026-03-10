import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';

class TeacherGradebookScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;

  const TeacherGradebookScreen({
    super.key,
    required this.apiClient,
    required this.token,
  });

  @override
  State<TeacherGradebookScreen> createState() => _TeacherGradebookScreenState();
}

class _TeacherGradebookScreenState extends State<TeacherGradebookScreen> {
  String _semester = '1';
  UserProfile? _profile;
  bool _loading = true;
  String? _error;
  List<TeacherGradeRowDto> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile =
          _profile ?? await widget.apiClient.getProfile(widget.token);
      final className = profile.managedClass.trim().isNotEmpty
          ? profile.managedClass
          : profile.className;
      final rows = await widget.apiClient.getClassGrades(
        widget.token,
        className,
        semester: _semester,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _rows = rows;
      });
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

  Future<void> _changeSemester(String semester) async {
    if (_semester == semester) {
      return;
    }
    setState(() => _semester = semester);
    await _load();
  }

  Future<void> _editRow(TeacherGradeRowDto row) async {
    final oralCtrl = TextEditingController(text: row.oralScores);
    final quizCtrl = TextEditingController(text: row.quizScores);
    final examCtrl = TextEditingController(text: row.examScores);
    final semesterCtrl = TextEditingController(text: row.semesterScore);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${row.studentName} - ${row.subject}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oralCtrl,
                decoration: const InputDecoration(labelText: 'Điểm miệng'),
              ),
              TextField(
                controller: quizCtrl,
                decoration: const InputDecoration(labelText: 'Điểm 15 phút'),
              ),
              TextField(
                controller: examCtrl,
                decoration: const InputDecoration(labelText: 'Điểm 1 tiết'),
              ),
              TextField(
                controller: semesterCtrl,
                decoration: const InputDecoration(labelText: 'Điểm học kỳ'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
      oralCtrl.dispose();
      quizCtrl.dispose();
      examCtrl.dispose();
      semesterCtrl.dispose();
      return;
    }

    try {
      await widget.apiClient.updateTeacherGrade(
        widget.token,
        studentId: row.studentId,
        subject: row.subject,
        semester: _semester,
        oralScores: oralCtrl.text,
        quizScores: quizCtrl.text,
        examScores: examCtrl.text,
        semesterScore: semesterCtrl.text,
      );
      oralCtrl.dispose();
      quizCtrl.dispose();
      examCtrl.dispose();
      semesterCtrl.dispose();
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật điểm.')),
      );
    } catch (e) {
      oralCtrl.dispose();
      quizCtrl.dispose();
      examCtrl.dispose();
      semesterCtrl.dispose();
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
    final className = _profile?.managedClass.trim().isNotEmpty == true
        ? _profile!.managedClass
        : (_profile?.className ?? '');

    return Scaffold(
      backgroundColor: AppColors.muted,
      body: Column(
        children: [
          const AppTopBar(title: 'Nhập điểm', showBack: true),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                if (className.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.school2,
                        size: 16,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lớp phụ trách: $className',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                if (className.isNotEmpty) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SemesterButton(
                        label: 'Học kỳ 1',
                        active: _semester == '1',
                        onTap: () => _changeSemester('1'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SemesterButton(
                        label: 'Học kỳ 2',
                        active: _semester == '2',
                        onTap: () => _changeSemester('2'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bảng điểm lớp',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_rows.isEmpty)
                                    const Text(
                                      'Chưa có dữ liệu điểm cho lớp này.',
                                      style: TextStyle(
                                        color: AppColors.mutedForeground,
                                      ),
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Học sinh')),
                                          DataColumn(label: Text('Môn')),
                                          DataColumn(label: Text('TB')),
                                          DataColumn(label: Text('Xếp loại')),
                                          DataColumn(label: Text('Sửa')),
                                        ],
                                        rows: [
                                          for (final row in _rows)
                                            DataRow(
                                              cells: [
                                                DataCell(
                                                  SizedBox(
                                                    width: 170,
                                                    child:
                                                        Text(row.studentName),
                                                  ),
                                                ),
                                                DataCell(
                                                  SizedBox(
                                                    width: 120,
                                                    child: Text(row.subject),
                                                  ),
                                                ),
                                                DataCell(
                                                    Text(row.averageScore)),
                                                DataCell(Text(row.note)),
                                                DataCell(
                                                  IconButton(
                                                    onPressed: () =>
                                                        _editRow(row),
                                                    icon: const Icon(
                                                      LucideIcons.pencil,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
          ),
        ],
      ),
    );
  }
}

class _SemesterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SemesterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
          ),
        ),
      ),
    );
  }
}
