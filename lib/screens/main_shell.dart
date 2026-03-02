import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/bottom_nav.dart';
import 'chat_detail_screen.dart';
import 'chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'grades_screen.dart';
import 'homework_detail_screen.dart';
import 'homework_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'timetable_screen.dart';

class MainShell extends StatefulWidget {
  final ApiClient apiClient;
  final String token;
  final String userName;
  final VoidCallback onLogout;

  const MainShell({
    super.key,
    required this.apiClient,
    required this.token,
    required this.userName,
    required this.onLogout,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String tab = 'dashboard';

  Future<void> _push(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (tab) {
      case 'timetable':
        content = TimetableScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          onNavigate: (s, [d]) {},
        );
        break;
      case 'homework':
        content = HomeworkScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          onNavigate: (s, [d]) {
            if (s == 'homework-detail' && d != null) {
              _push(context, HomeworkDetailScreen(item: d));
            }
          },
        );
        break;
      case 'chat':
        content = ChatListScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          onNavigate: (s, [d]) {
            if (s == 'chat-detail' && d != null) {
              _push(
                context,
                ChatDetailScreen(
                  apiClient: widget.apiClient,
                  token: widget.token,
                  thread: d,
                ),
              );
            }
          },
        );
        break;
      case 'profile':
        content = ProfileScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          onLogout: widget.onLogout,
          onNavigate: (s, [d]) {
            if (s == 'grades') _push(context, GradesScreen(apiClient: widget.apiClient, token: widget.token));
            if (s == 'notes') _push(context, NotesScreen(apiClient: widget.apiClient, token: widget.token));
          },
        );
        break;
      default:
        content = DashboardScreen(
          apiClient: widget.apiClient,
          token: widget.token,
          userName: widget.userName,
          onNavigate: (s, [d]) {
            if (s == 'timetable') setState(() => tab = 'timetable');
            if (s == 'homework') setState(() => tab = 'homework');
            if (s == 'chat') setState(() => tab = 'chat');
            if (s == 'profile') setState(() => tab = 'profile');
            if (s == 'grades') _push(context, GradesScreen(apiClient: widget.apiClient, token: widget.token));
            if (s == 'notes') _push(context, NotesScreen(apiClient: widget.apiClient, token: widget.token));
          },
        );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNav(
        activeTab: tab,
        onTabChange: (t) => setState(() => tab = t),
      ),
    );
  }
}
