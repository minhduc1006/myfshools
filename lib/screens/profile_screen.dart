import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final VoidCallback onLogout;
  final void Function(String screen, [dynamic data]) onNavigate;

  const ProfileScreen({
    super.key,
    required this.apiClient,
    required this.token,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getProfile(widget.token);
  }

  Future<void> _reload() async {
    setState(() => _future = widget.apiClient.getProfile(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: FutureBuilder<UserProfile>(
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
                  ElevatedButton(
                      onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }

          final user = snapshot.data!;
          final isStudent = user.role == 'STUDENT';
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 92),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(user.avatarInitial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${user.className} - ${user.term}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      if (isStudent) ...[
                        InkWell(
                          onTap: () => widget.onNavigate('grades'),
                          borderRadius: BorderRadius.circular(12),
                          child: const AppCard(
                            child: _ProfileRow(LucideIcons.trendingUp,
                                'Điểm số', AppColors.accent),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => widget.onNavigate('notes'),
                          borderRadius: BorderRadius.circular(12),
                          child: const AppCard(
                            child: _ProfileRow(LucideIcons.bookOpen, 'Ghi chú',
                                AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const AppCard(
                        child: _ProfileRow(LucideIcons.settings, 'Cài đặt',
                            AppColors.secondary),
                      ),
                      const SizedBox(height: 12),
                      const AppCard(
                        child: _ProfileRow(LucideIcons.helpCircle, 'Trợ giúp',
                            AppColors.secondary),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onLogout,
                          icon: const Icon(LucideIcons.logOut, size: 18),
                          label: const Text('Đăng xuất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.destructive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800))),
        const Icon(LucideIcons.chevronRight,
            size: 16, color: AppColors.mutedForeground),
      ],
    );
  }
}
