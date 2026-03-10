import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../theme/app_theme.dart';
import 'grades_screen.dart';
import 'teacher_gradebook_screen.dart';

class GradesEntryScreen extends StatelessWidget {
  final ApiClient apiClient;
  final String token;

  const GradesEntryScreen({
    super.key,
    required this.apiClient,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: apiClient.getProfile(token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.muted,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.muted,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        if (profile.role == 'STUDENT') {
          return GradesScreen(apiClient: apiClient, token: token);
        }
        if (profile.role == 'HOMEROOM_TEACHER' ||
            profile.role == 'EXAM_OFFICER') {
          return TeacherGradebookScreen(apiClient: apiClient, token: token);
        }
        return const Scaffold(
          backgroundColor: AppColors.muted,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Màn nhập điểm hiện đang mở cho giáo viên chủ nhiệm và khảo thí.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
