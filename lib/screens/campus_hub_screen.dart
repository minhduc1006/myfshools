import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/badge.dart';

class CampusHubScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final String initialSection;

  const CampusHubScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.initialSection,
  });

  @override
  State<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends State<CampusHubScreen> {
  late String _section;
  bool _loading = true;
  String? _error;
  UserProfile? _profile;

  List<AlertDto> _alerts = const [];
  List<TeacherAssignmentDto> _assignments = const [];
  List<ServiceRequestDto> _myRequests = const [];
  List<ServiceRequestDto> _examRequests = const [];
  List<TuitionInvoiceDto> _invoices = const [];
  List<TuitionClassSummaryDto> _tuitionOverview = const [];

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _loadSection();
  }

  Future<void> _loadSection() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile =
          _profile ?? await widget.apiClient.getProfile(widget.token);
      final allowedSections = _availableSectionsFor(profile);
      final nextSection =
          allowedSections.contains(_section) ? _section : allowedSections.first;
      _profile = profile;
      _section = nextSection;

      switch (nextSection) {
        case 'teacher':
          _assignments =
              await widget.apiClient.getTeacherAssignments(widget.token);
          break;
        case 'applications':
          _myRequests = await widget.apiClient.getServiceRequests(widget.token);
          break;
        case 'exam':
          _examRequests = await widget.apiClient.getServiceRequests(
            widget.token,
            category: 'EXAM',
          );
          break;
        case 'tuition':
          _invoices = await widget.apiClient.getTuitionInvoices(widget.token);
          break;
        case 'tuition_admin':
          _tuitionOverview =
              await widget.apiClient.getExamTuitionOverview(widget.token);
          break;
        default:
          _alerts = await widget.apiClient.getAlerts(widget.token);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeSection(String next) async {
    setState(() => _section = next);
    await _loadSection();
  }

  bool get _isStudent => _profile?.role == 'STUDENT';
  bool get _isExamOfficer => _profile?.role == 'EXAM_OFFICER';
  List<String> get _visibleSections =>
      _profile == null ? const ['alerts'] : _availableSectionsFor(_profile!);

  List<String> _availableSectionsFor(UserProfile profile) {
    if (profile.role == 'STUDENT') {
      return const ['alerts', 'applications', 'exam', 'tuition'];
    }
    if (profile.role == 'EXAM_OFFICER') {
      return const ['alerts', 'tuition_admin', 'exam'];
    }
    if (profile.role == 'HOMEROOM_TEACHER' ||
        profile.role == 'SUBJECT_TEACHER') {
      return const ['alerts', 'teacher'];
    }
    return const ['alerts'];
  }

  String _sectionLabel(String section) {
    switch (section) {
      case 'teacher':
        return 'Giáo viên';
      case 'applications':
        return 'Đơn từ';
      case 'exam':
        return 'Khảo thí';
      case 'tuition_admin':
        return 'Học phí';
      case 'tuition':
        return 'Học phí';
      default:
        return 'Thông báo';
    }
  }

  Future<void> _createAssignment() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final classController = TextEditingController(text: '6A');
    final dueController = TextEditingController(text: '08/03/2026');
    final noteController = TextEditingController();
    final fileController = TextEditingController(text: 'assignment.pdf');

    final created = await _showFormSheet(
      title: 'Tạo bài tập mới',
      children: [
        _SheetField(label: 'Tiêu đề', controller: titleController),
        _SheetField(label: 'Môn học', controller: subjectController),
        _SheetField(label: 'Lớp áp dụng', controller: classController),
        _SheetField(label: 'Hạn nộp', controller: dueController),
        _SheetField(
          label: 'Hướng dẫn',
          controller: noteController,
          maxLines: 3,
        ),
        _SheetField(label: 'Tệp đính kèm', controller: fileController),
      ],
      onSubmit: () async {
        await widget.apiClient.createTeacherAssignment(
          widget.token,
          title: titleController.text,
          subject: subjectController.text,
          targetClass: classController.text,
          dueDate: dueController.text,
          note: noteController.text,
          attachmentName: fileController.text,
        );
      },
    );

    _disposeControllers([
      titleController,
      subjectController,
      classController,
      dueController,
      noteController,
      fileController,
    ]);

    if (created) {
      await _loadSection();
      _showToast('Đã tạo bài tập.');
    }
  }

  Future<void> _createApplication() async {
    final titleController = TextEditingController();
    final typeController = TextEditingController(text: 'Giấy xác nhận');
    final detailController = TextEditingController();

    final created = await _showFormSheet(
      title: 'Gửi đơn',
      children: [
        _SheetField(label: 'Tiêu đề', controller: titleController),
        _SheetField(label: 'Loại đơn', controller: typeController),
        _SheetField(
          label: 'Nội dung',
          controller: detailController,
          maxLines: 4,
        ),
      ],
      onSubmit: () async {
        await widget.apiClient.createServiceRequest(
          widget.token,
          title: titleController.text,
          type: typeController.text,
          category: 'APPLICATION',
          description: detailController.text,
        );
      },
    );

    _disposeControllers([titleController, typeController, detailController]);

    if (created) {
      await _loadSection();
      _showToast('Đã gửi đơn.');
    }
  }

  Future<void> _createExamRequest() async {
    final titleController = TextEditingController();
    final typeController = TextEditingController(text: 'Phúc khảo');
    final detailController = TextEditingController();

    final created = await _showFormSheet(
      title: 'Tạo yêu cầu khảo thí',
      children: [
        _SheetField(label: 'Tiêu đề', controller: titleController),
        _SheetField(label: 'Loại yêu cầu', controller: typeController),
        _SheetField(
          label: 'Chi tiết',
          controller: detailController,
          maxLines: 4,
        ),
      ],
      onSubmit: () async {
        await widget.apiClient.createServiceRequest(
          widget.token,
          title: titleController.text,
          type: typeController.text,
          category: 'EXAM',
          description: detailController.text,
        );
      },
    );

    _disposeControllers([titleController, typeController, detailController]);

    if (created) {
      await _loadSection();
      _showToast('Đã gửi yêu cầu khảo thí.');
    }
  }

  Future<void> _createNotice() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final classController = TextEditingController(text: '6A');
    String target = 'ALL';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo thông báo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Nội dung'),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setInner) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'ALL',
                      groupValue: target,
                      title: const Text('Gửi toàn trường'),
                      onChanged: (value) => setInner(() => target = value!),
                    ),
                    RadioListTile<String>(
                      value: 'CLASS',
                      groupValue: target,
                      title: const Text('Gửi theo lớp'),
                      onChanged: (value) => setInner(() => target = value!),
                    ),
                    if (target == 'CLASS')
                      TextField(
                        controller: classController,
                        decoration: const InputDecoration(
                          labelText: 'Lớp (vd: 6A)',
                        ),
                      ),
                  ],
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
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    final title = titleController.text.trim();
    final message = messageController.text.trim();
    final className = classController.text.trim();

    titleController.dispose();
    messageController.dispose();
    classController.dispose();

    if (created != true) {
      return;
    }

    try {
      final result = await widget.apiClient.createExamNotice(
        widget.token,
        title: title,
        message: message,
        target: target,
        className: target == 'CLASS' ? className : null,
      );
      await _loadSection();
      _showToast('Đã gửi ${result.deliveredCount} thông báo.');
    } catch (e) {
      _showToast('$e');
    }
  }

  Future<void> _resolveRequest(ServiceRequestDto item) async {
    final noteController = TextEditingController(
      text: 'Đã kiểm tra và cập nhật kết quả.',
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xử lý #${item.id}'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Ghi chú xử lý'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );

    final note = noteController.text;
    noteController.dispose();

    if (accepted == true) {
      try {
        await widget.apiClient.resolveServiceRequest(
          widget.token,
          item.id,
          note: note,
        );
        await _loadSection();
        _showToast('Đã cập nhật yêu cầu.');
      } catch (e) {
        _showToast('$e');
      }
    }
  }

  Future<void> _markAllAlertsRead() async {
    try {
      await widget.apiClient.markAllAlertsRead(widget.token);
      await _loadSection();
      _showToast('Đã đánh dấu tất cả là đã đọc.');
    } catch (e) {
      _showToast('$e');
    }
  }

  Future<void> _openPayOs(TuitionInvoiceDto invoice) async {
    var fallbackCheckoutUrl = invoice.checkoutUrl;
    try {
      final checkout =
          await widget.apiClient.createPayOsLink(widget.token, invoice.id);
      fallbackCheckoutUrl = checkout.checkoutUrl;
      final checkoutUri = Uri.tryParse(checkout.checkoutUrl);
      if (checkoutUri == null) {
        throw Exception('Liên kết thanh toán PayOS không hợp lệ.');
      }

      final opened = await launchUrl(
        checkoutUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw Exception('Không thể mở trang thanh toán PayOS.');
      }

      if (mounted) {
        _showToast('Đã mở trang thanh toán. Kéo xuống để làm mới trạng thái.');
      }
      await _loadSection();
    } on MissingPluginException {
      await _showPayOsFallback(fallbackCheckoutUrl);
    } catch (e) {
      _showToast('$e');
    }
  }

  Future<void> _showPayOsFallback(String checkoutUrl) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liên kết thanh toán'),
        content: SelectableText(
          checkoutUrl.trim().isEmpty
              ? 'Chưa lấy được liên kết thanh toán.'
              : checkoutUrl,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (checkoutUrl.trim().isNotEmpty) {
                await Clipboard.setData(
                  ClipboardData(text: checkoutUrl),
                );
              }
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop();
              _showToast('Đã sao chép liên kết thanh toán.');
            },
            child: const Text('Sao chép'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showFormSheet({
    required String title,
    required List<Widget> children,
    required Future<void> Function() onSubmit,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormSheet(
        title: title,
        onSubmit: onSubmit,
        children: children,
      ),
    );
    return result == true;
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  void _showToast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: Column(
        children: [
          AppTopBar(
            title: 'Dịch vụ học đường',
            showBack: true,
            onBack: () => Navigator.of(context).pop(),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final section in _visibleSections)
                    _SectionChip(
                      label: _sectionLabel(section),
                      active: _section == section,
                      onTap: () => _changeSection(section),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadSection,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSection,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [_buildSection()],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case 'teacher':
        return _buildTeacherSection();
      case 'applications':
        return _buildApplicationsSection();
      case 'exam':
        return _buildExamSection();
      case 'tuition_admin':
        return _buildTuitionAdminSection();
      case 'tuition':
        return _buildTuitionSection();
      default:
        return _buildAlertsSection();
    }
  }

  Widget _buildAlertsSection() {
    final unread = _alerts.where((item) => !item.read).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Trung tâm thông báo',
          subtitle: '$unread thông báo chưa đọc',
          actionLabel: _isExamOfficer ? 'Tạo thông báo' : 'Đánh dấu đã đọc',
          onAction: _isExamOfficer ? _createNotice : _markAllAlertsRead,
        ),
        const SizedBox(height: 12),
        for (final alert in _alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _alertColor(alert.type),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: alert.read
                                ? AppColors.mutedForeground
                                : AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(alert.message),
                        const SizedBox(height: 6),
                        Text(
                          alert.createdAt,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
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
    );
  }

  Widget _buildTeacherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Không gian giáo viên',
          subtitle: 'Tạo bài tập và phát thông báo cho lớp',
          actionLabel: 'Giao bài',
          onAction: _createAssignment,
        ),
        const SizedBox(height: 12),
        for (final item in _assignments)
          Padding(
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
                      _StatusPill(
                        label: item.targetClass,
                        background: AppColors.secondary.withValues(alpha: 0.1),
                        textColor: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${item.subject} • Hạn nộp ${item.dueDate}'),
                  const SizedBox(height: 8),
                  Text(item.note),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo bởi: ${item.createdBy}',
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.paperclip,
                        size: 16,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.attachmentName)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApplicationsSection() {
    final applications =
        _myRequests.where((item) => item.category == 'Đơn từ').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Đơn từ',
          subtitle: 'Tạo và theo dõi các loại đơn',
          actionLabel: _isStudent ? 'Tạo đơn' : null,
          onAction: _isStudent ? _createApplication : null,
        ),
        const SizedBox(height: 12),
        for (final item in applications)
          Padding(
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
                      _StatusPill(
                        label: item.status,
                        background: AppColors.primary.withValues(alpha: 0.1),
                        textColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.type,
                    style: const TextStyle(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Text(item.description),
                  const SizedBox(height: 8),
                  Text(
                    item.updatedAt,
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Khảo thí',
          subtitle: _isExamOfficer
              ? 'Tiếp nhận và xử lý yêu cầu học sinh'
              : 'Theo dõi và gửi yêu cầu khảo thí',
          actionLabel: _isExamOfficer ? 'Làm mới' : 'Tạo yêu cầu',
          onAction: _isExamOfficer ? _loadSection : _createExamRequest,
        ),
        const SizedBox(height: 12),
        for (final item in _examRequests)
          Padding(
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
                      _StatusPill(
                        label: item.status,
                        background: item.status == 'Đã xử lý'
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : const Color(0xFFFEF3C7),
                        textColor: item.status == 'Đã xử lý'
                            ? AppColors.accent
                            : const Color(0xFFB45309),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.type} • ${item.requester}',
                    style: const TextStyle(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Text(item.description),
                  if (item.handlerNote.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Xử lý: ${item.handlerNote}'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.updatedAt,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (_isExamOfficer && item.status != 'Đã xử lý')
                        TextButton(
                          onPressed: () => _resolveRequest(item),
                          child: const Text('Xử lý'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTuitionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Học phí',
          subtitle: 'Nhấn thanh toán để mở trang web PayOS trực tiếp',
          actionLabel: 'Làm mới',
          onAction: _loadSection,
        ),
        const SizedBox(height: 12),
        for (final item in _invoices)
          Padding(
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
                      _StatusPill(
                        label: item.status,
                        background: item.status == 'Đã thanh toán'
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        textColor: item.status == 'Đã thanh toán'
                            ? AppColors.accent
                            : AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hạn: ${item.dueDate}',
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency(item.amount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (item.payOsOrderCode != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'PayOS order: ${item.payOsOrderCode}',
                      style: const TextStyle(color: AppColors.secondary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: item.status == 'Đã thanh toán'
                          ? null
                          : () => _openPayOs(item),
                      icon: const Icon(LucideIcons.wallet, size: 18),
                      label: Text(
                        item.status == 'Đã thanh toán'
                            ? 'Đã thanh toán'
                            : 'Thanh toán qua PayOS',
                      ),
                    ),
                  ),
                  if (item.paidAt.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Đã ghi nhận lúc ${item.paidAt}',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTuitionAdminSection() {
    final items = _tuitionOverview;
    if (items.isEmpty) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Chưa có dữ liệu học phí theo lớp.',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Học phí theo lớp',
          subtitle: 'Xem danh sách đã nộp và chưa nộp',
          actionLabel: 'Làm mới',
          onAction: _loadSection,
        ),
        const SizedBox(height: 12),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _openTuitionClassDetails(item.className),
              borderRadius: BorderRadius.circular(12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lớp ${item.className}',
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
                          value: '${item.totalStudents}',
                        ),
                        _SummaryChip(
                          label: 'Đã nộp',
                          value: '${item.paidStudents}',
                        ),
                        _SummaryChip(
                          label: 'Chờ',
                          value: '${item.pendingStudents}',
                        ),
                        _SummaryChip(
                          label: 'Chưa nộp',
                          value: '${item.unpaidStudents}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openTuitionClassDetails(String className) async {
    try {
      final details = await widget.apiClient.getExamTuitionClassDetails(
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
                          'Học phí lớp $className',
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
                                  _TuitionStatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.studentPhone} • ${_currency(item.paidAmount)}/${_currency(item.totalAmount)}',
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
      _showToast('$e');
    }
  }

  Color _alertColor(String type) {
    switch (type) {
      case 'success':
        return AppColors.accent;
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.secondary;
    }
  }

  String _currency(int amount) {
    final digits = amount.toString();
    final chars = <String>[];
    for (int i = 0; i < digits.length; i++) {
      chars.add(digits[i]);
      final reverseIndex = digits.length - i;
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        chars.add(',');
      }
    }
    return '${chars.join()} VND';
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SectionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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

class _TuitionStatusBadge extends StatelessWidget {
  final String status;

  const _TuitionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status.contains('Đã')) {
      color = AppColors.accent;
    } else if (status.contains('Chờ')) {
      color = const Color(0xFFF59E0B);
    } else if (status.contains('Chưa')) {
      color = AppColors.destructive;
    } else {
      color = AppColors.mutedForeground;
    }
    return AppBadge(
      status,
      textColor: color,
      background: color.withValues(alpha: 0.10),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _SheetField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _FormSheet extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final Future<void> Function() onSubmit;

  const _FormSheet({
    required this.title,
    required this.children,
    required this.onSubmit,
  });

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      return;
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.children,
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.destructive),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Đang lưu...' : 'Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
