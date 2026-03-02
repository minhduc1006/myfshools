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
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getDashboard(widget.token);
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.apiClient.getDashboard(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: FutureBuilder<DashboardData>(
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
                  Text('Load failed: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final displayName = widget.userName.trim().isNotEmpty ? widget.userName : data.studentName;
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
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            color: Colors.white.withValues(alpha: 0.95),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _InfoCol(label: 'Lớp', value: data.className, valueColor: AppColors.foreground),
                                  _InfoCol(label: 'Năm học', value: data.term, valueColor: AppColors.foreground),
                                  _InfoCol(label: 'Điểm TB', value: data.gpa, valueColor: AppColors.accent),
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
                        const Text('Truy cập nhanh', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 0.85,
                          children: [
                            _QuickAction(icon: LucideIcons.calendar, label: 'Lịch học', color: AppColors.secondary, onTap: () => widget.onNavigate('timetable')),
                            _QuickAction(icon: LucideIcons.clipboardCheck, label: 'Bài tập', color: AppColors.primary, onTap: () => widget.onNavigate('homework')),
                            _QuickAction(icon: LucideIcons.trendingUp, label: 'Điểm số', color: AppColors.accent, onTap: () => widget.onNavigate('grades')),
                            _QuickAction(icon: LucideIcons.bookOpen, label: 'Ghi chú', color: const Color(0xFFF97316), onTap: () => widget.onNavigate('notes')),
                            _QuickAction(icon: LucideIcons.wallet, label: 'Học phí', color: const Color(0xFF10B981), onTap: () => widget.onNavigate('tuition_receipts')),
                            _QuickAction(icon: LucideIcons.fileText, label: 'Viết đơn', color: const Color(0xFF6366F1), onTap: () => widget.onNavigate('applications')),
                            _QuickAction(icon: LucideIcons.receipt, label: 'Biên lai', color: const Color(0xFF0EA5E9), onTap: () => widget.onNavigate('tuition_payment')),
                            _QuickAction(icon: LucideIcons.helpCircle, label: 'Hỗ trợ', color: const Color(0xFFEF4444), onTap: () => widget.onNavigate('support')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiết sắp tới', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        ...data.upcomingClasses.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      children: [
                                        Text(c.dayLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        const SizedBox(height: 2),
                                        Text('${c.dayNumber}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(c.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                  const SizedBox(height: 2),
                                                  Text(c.room, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                                                ],
                                              ),
                                            ),
                                            AppBadge(c.startTime),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('GV: ${c.teacher}', style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
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
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoCol({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

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
          boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Color(0x0A000000))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
