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
  static const _titleText = 'B\u1ea3ng \u0111i\u1ec3m';
  static const _retryText = 'Th\u1eed l\u1ea1i';
  static const _semester1Text = 'H\u1ecdc k\u1ef3 1';
  static const _semester2Text = 'H\u1ecdc k\u1ef3 2';
  static const _sheetTitleText = 'B\u1ea2NG \u0110I\u1ec2M H\u1eccC SINH';
  static const _averageLabelText = '\u0110TBC';
  static const _conductLabelText = 'H\u1ecdc l\u1ef1c';
  static const _progressLabelText = 'Ti\u1ebfn \u0111\u1ed9';
  static const _sttText = 'STT';
  static const _subjectText = 'M\u00f4n h\u1ecdc';
  static const _oralText = 'Mi\u1ec7ng';
  static const _quizText = '15 ph\u00fat';
  static const _examText = '1 ti\u1ebft';
  static const _semesterScoreText = 'H\u1ecdc k\u1ef3';
  static const _avgSemesterText = 'TBHK';
  static const _noteText = 'Ghi ch\u00fa';
  static const _passText = '\u0110\u1ea1t';
  static const _emptyScoreText = 'Ch\u01b0a c\u00f3';
  static const _noDataText = 'Ch\u01b0a c\u00f3 d\u1eef li\u1ec7u';
  static const _temporaryText = 'T\u1ea1m t\u00ednh';
  static const _excellentText = 'Gi\u1ecfi';
  static const _goodText = 'Kh\u00e1';
  static const _averageText = 'Trung b\u00ecnh';
  static const _weakText = 'Y\u1ebfu';
  static const _peSubjectText = 'gi\u00e1o d\u1ee5c th\u1ec3 ch\u1ea5t';
  static const _mathText = 'to\u00e1n';
  static const _literatureText = 'ng\u1eef v\u0103n';

  String _semester = '1';
  late Future<List<GradeDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getGrades(widget.token, semester: _semester);
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.apiClient.getGrades(widget.token, semester: _semester);
    });
  }

  void _changeSemester(String semester) {
    if (_semester == semester) {
      return;
    }
    setState(() {
      _semester = semester;
      _future = widget.apiClient.getGrades(widget.token, semester: _semester);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: Column(
        children: [
          AppTopBar(
            title: _titleText,
            showBack: true,
            onBack: () => Navigator.of(context).pop(),
          ),
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
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text(_retryText),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? const [];
                final overallAverage = _calculateOverallAverage(items);
                final overallClassification =
                    _calculateOverallClassification(items, overallAverage);

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SemesterTab(
                              label: _semester1Text,
                              active: _semester == '1',
                              onTap: () => _changeSemester('1'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SemesterTab(
                              label: _semester2Text,
                              active: _semester == '2',
                              onTap: () => _changeSemester('2'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              _sheetTitleText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'H\u1ecdc k\u1ef3 $_semester - N\u0103m h\u1ecdc 2025 - 2026',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _SummaryChip(
                                  label: _averageLabelText,
                                  value: _formatNumber(overallAverage),
                                ),
                                _SummaryChip(
                                  label:
                                      _semester == '1' ? _conductLabelText : _progressLabelText,
                                  value: overallClassification,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8FAFC),
                                ),
                                dataRowMinHeight: 48,
                                dataRowMaxHeight: 64,
                                columnSpacing: 16,
                                horizontalMargin: 12,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      _sttText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _subjectText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _oralText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _quizText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _examText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _semesterScoreText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _avgSemesterText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      _noteText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: [
                                  for (int i = 0; i < items.length; i++)
                                    DataRow(
                                      cells: [
                                        DataCell(Text('${i + 1}')),
                                        DataCell(
                                          SizedBox(
                                            width: 160,
                                            child: Text(items[i].subject),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 70,
                                            child: Text(
                                              _displayOralScores(items[i]),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 90,
                                            child: Text(
                                              _displayQuizScores(items[i]),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              _displayExamScores(items[i]),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(_displaySemester(items[i])),
                                        ),
                                        DataCell(
                                          Text(_displayAverage(items[i])),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              _displayClassification(items[i]),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _semester == '1'
                                  ? 'H\u1ecdc k\u1ef3 1 l\u00e0 \u0111i\u1ec3m t\u1ed5ng k\u1ebft ho\u00e0n ch\u1ec9nh.'
                                  : 'H\u1ecdc k\u1ef3 2 \u0111ang trong qu\u00e1 tr\u00ecnh h\u1ecdc n\u00ean ch\u01b0a c\u00f3 \u0111i\u1ec3m h\u1ecdc k\u1ef3; m\u1ed9t s\u1ed1 \u0111\u1ea7u \u0111i\u1ec3m c\u00f3 th\u1ec3 c\u00f2n thi\u1ebfu.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
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
    if (_isPhysicalEducation(grade) && _semester == '2') {
      return '';
    }
    if (_isPassNote(grade.note)) {
      return _passText;
    }
    if (grade.semesterScore.trim().isEmpty) {
      return _emptyScoreText;
    }
    return _stripDecimal(grade.semesterScore);
  }

  String _displayAverage(GradeDto grade) {
    if (_isPhysicalEducation(grade) && _semester == '2') {
      return '';
    }
    if (_isPassNote(grade.note)) {
      return _passText;
    }
    return _stripDecimal(grade.score);
  }

  String _displayClassification(GradeDto grade) {
    if (_isPhysicalEducation(grade)) {
      return '';
    }
    if (grade.note.isEmpty) {
      return '';
    }
    return _normalizeGradeValue(grade.note);
  }

  String _displayOralScores(GradeDto grade) {
    return _isPhysicalEducation(grade) ? '' : _normalizeGradeValue(grade.oralScores);
  }

  String _displayQuizScores(GradeDto grade) {
    return _isPhysicalEducation(grade) ? '' : _normalizeGradeValue(grade.quizScores);
  }

  String _displayExamScores(GradeDto grade) {
    return _isPhysicalEducation(grade) ? '' : _normalizeGradeValue(grade.examScores);
  }

  bool _isPhysicalEducation(GradeDto grade) {
    final subject = grade.subject.trim().toLowerCase();
    return subject == _peSubjectText || subject == 'giao duc the chat';
  }

  bool _isPassNote(String note) {
    final value = note.trim().toLowerCase();
    return value == _passText.toLowerCase() || value == 'dat';
  }

  double _calculateOverallAverage(List<GradeDto> grades) {
    final academicGrades = grades
        .where(
          (grade) => !_isPhysicalEducation(grade) && !_isPassNote(grade.note),
        )
        .toList();
    if (academicGrades.isEmpty) {
      return 0;
    }

    double total = 0;
    for (final grade in academicGrades) {
      total += double.tryParse(grade.score) ?? 0;
    }
    final average = total / academicGrades.length;
    return double.parse(average.toStringAsFixed(1));
  }

  String _calculateOverallClassification(
    List<GradeDto> grades,
    double overallAverage,
  ) {
    final academicGrades = grades
        .where(
          (grade) => !_isPhysicalEducation(grade) && !_isPassNote(grade.note),
        )
        .toList();
    if (academicGrades.isEmpty) {
      return _noDataText;
    }
    if (_semester == '2') {
      return _temporaryText;
    }

    double minScore = 10;
    double math = 0;
    double literature = 0;

    for (final grade in academicGrades) {
      final score = double.tryParse(grade.score) ?? 0;
      if (score < minScore) {
        minScore = score;
      }

      final subject = grade.subject.trim().toLowerCase();
      if (subject == _mathText || subject == 'toan') {
        math = score;
      }
      if (subject == _literatureText || subject == 'ngu van') {
        literature = score;
      }
    }

    if (overallAverage >= 8.0 &&
        minScore >= 6.5 &&
        (math >= 8.0 || literature >= 8.0)) {
      return _excellentText;
    }
    if (overallAverage >= 6.5 &&
        minScore >= 5.0 &&
        (math >= 6.5 || literature >= 6.5)) {
      return _goodText;
    }
    if (overallAverage >= 5.0 && minScore >= 3.5) {
      return _averageText;
    }
    return _weakText;
  }

  String _normalizeGradeValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (_isPassNote(trimmed)) {
      return _passText;
    }
    return trimmed;
  }

  String _formatNumber(double value) {
    final rounded = value.toStringAsFixed(1);
    if (rounded.endsWith('.0')) {
      return rounded.substring(0, rounded.length - 2);
    }
    return rounded;
  }

  String _stripDecimal(String value) {
    if (value.isEmpty) {
      return '';
    }
    if (value.endsWith('.00')) {
      return value.substring(0, value.length - 3);
    }
    if (value.endsWith('0') && value.contains('.')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}

class _SemesterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SemesterTab({
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
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
