import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';

class GradesScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;

  const GradesScreen({
    super.key,
    required this.apiClient,
    required this.token,
  });

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  late Future<List<GradeDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getGrades(widget.token);
  }

  Future<void> _reload() async {
    setState(() => _future = widget.apiClient.getGrades(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: Column(
        children: [
          AppTopBar(title: 'Bảng điểm', showBack: true, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: FutureBuilder<List<GradeDto>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(snapshot.error.toString()),
                        const SizedBox(height: 8),
                        ElevatedButton(onPressed: _reload, child: const Text('Thử lại')),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? const [];
                final overallAverage = _calculateOverallAverage(items);
                final overallClassification = _calculateOverallClassification(items, overallAverage);

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'BẢNG ĐIỂM HỌC SINH',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Học kỳ 1 - Năm học 2025 - 2026',
                              style: TextStyle(color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _SummaryChip(label: 'ĐTBC', value: _formatNumber(overallAverage)),
                                _SummaryChip(label: 'Học lực', value: overallClassification),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: const Color(0xFFCBD5E1),
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 64,
                                  columnSpacing: 16,
                                  horizontalMargin: 12,
                                  columns: const [
                                    DataColumn(label: Text('STT', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('Tên môn học', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('Miệng', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('15 phút', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('1 tiết', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('Học kỳ', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('TBHK', style: TextStyle(fontWeight: FontWeight.w700))),
                                    DataColumn(label: Text('Xếp loại', style: TextStyle(fontWeight: FontWeight.w700))),
                                  ],
                                  rows: [
                                    for (int i = 0; i < items.length; i++)
                                      DataRow(
                                        cells: [
                                          DataCell(Text('${i + 1}')),
                                          DataCell(
                                            SizedBox(
                                              width: 140,
                                              child: Text(
                                                items[i].subject,
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                          DataCell(SizedBox(width: 70, child: Text(items[i].oralScores))),
                                          DataCell(SizedBox(width: 90, child: Text(items[i].quizScores))),
                                          DataCell(SizedBox(width: 80, child: Text(items[i].examScores))),
                                          DataCell(Text(_displaySemester(items[i]))),
                                          DataCell(Text(_displayAverage(items[i]))),
                                          DataCell(SizedBox(width: 110, child: Text(_displayClassification(items[i])))),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Cách xếp loại học lực: Giỏi khi ĐTBC >= 8.0, không môn nào dưới 6.5 và Toán hoặc Ngữ văn >= 8.0; Khá khi ĐTBC >= 6.5, không môn nào dưới 5.0 và Toán hoặc Ngữ văn >= 6.5; Trung bình khi ĐTBC >= 5.0 và không môn nào dưới 3.5.',
                                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _displaySemester(GradeDto grade) {
    if (grade.note == 'Đạt') return 'Đ';
    return _stripDecimal(grade.semesterScore);
  }

  String _displayAverage(GradeDto grade) {
    if (grade.note == 'Đạt') return 'Đ';
    return _stripDecimal(grade.score);
  }

  String _displayClassification(GradeDto grade) {
    if (grade.note.isEmpty) return '';
    return grade.note;
  }

  double _calculateOverallAverage(List<GradeDto> grades) {
    final academicGrades = grades.where((grade) => grade.note != 'Đạt').toList();
    if (academicGrades.isEmpty) return 0;

    double total = 0;
    for (final grade in academicGrades) {
      total += double.tryParse(grade.score) ?? 0;
    }
    final average = total / academicGrades.length;
    return double.parse(average.toStringAsFixed(1));
  }

  String _calculateOverallClassification(List<GradeDto> grades, double overallAverage) {
    final academicGrades = grades.where((grade) => grade.note != 'Đạt').toList();
    if (academicGrades.isEmpty) return 'Chưa có dữ liệu';

    double minScore = 10;
    double math = 0;
    double literature = 0;

    for (final grade in academicGrades) {
      final score = double.tryParse(grade.score) ?? 0;
      if (score < minScore) minScore = score;
      if (grade.subject == 'Toán') math = score;
      if (grade.subject == 'Ngữ văn') literature = score;
    }

    if (overallAverage >= 8.0 && minScore >= 6.5 && (math >= 8.0 || literature >= 8.0)) {
      return 'Giỏi';
    }
    if (overallAverage >= 6.5 && minScore >= 5.0 && (math >= 6.5 || literature >= 6.5)) {
      return 'Khá';
    }
    if (overallAverage >= 5.0 && minScore >= 3.5) {
      return 'Trung bình';
    }
    return 'Yếu';
  }

  String _formatNumber(double value) {
    final rounded = value.toStringAsFixed(1);
    if (rounded.endsWith('.0')) {
      return rounded.substring(0, rounded.length - 2);
    }
    return rounded;
  }

  String _stripDecimal(String value) {
    if (value.endsWith('.00')) {
      return value.substring(0, value.length - 3);
    }
    if (value.endsWith('0') && value.contains('.')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
