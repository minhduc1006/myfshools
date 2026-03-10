import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_client.dart';
import '../services/api_models.dart';
import '../widgets/bottom_nav.dart';
import 'chat_detail_screen.dart';
import 'chat_list_screen.dart';
import 'campus_hub_screen.dart';
import 'dashboard_screen.dart';
import 'grades_entry_screen.dart';
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
  int _chatRefreshTick = 0;
  late Future<UserProfile> _profileFuture;

  Future<void> _push(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openChatDetail(Map<String, dynamic> thread) async {
    await _push(
      context,
      ChatDetailScreen(
        apiClient: widget.apiClient,
        token: widget.token,
        thread: thread,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _chatRefreshTick++);
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.apiClient.getProfile(widget.token);
  }

  List<(String, IconData, String)> _tabsForRole(String role) {
    if (role == 'EXAM_OFFICER') {
      return const [
        ('dashboard', LucideIcons.home, 'Trang chủ'),
        ('campus', LucideIcons.shieldCheck, 'Khảo thí'),
        ('chat', LucideIcons.messageSquare, 'Chat'),
        ('profile', LucideIcons.user, 'Cá nhân'),
      ];
    }

    return const [
      ('dashboard', LucideIcons.home, 'Trang chủ'),
      ('timetable', LucideIcons.calendar, 'Thời khóa biểu'),
      ('homework', LucideIcons.clipboardList, 'Bài tập'),
      ('chat', LucideIcons.messageSquare, 'Chat'),
      ('profile', LucideIcons.user, 'Cá nhân'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _profileFuture = widget.apiClient.getProfile(widget.token);
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final role = (snapshot.data?.role ?? 'STUDENT').toString();
        final tabs = _tabsForRole(role);
        final allowedIds = tabs.map((t) => t.$1).toSet();
        final effectiveTab = allowedIds.contains(tab) ? tab : tabs.first.$1;
        if (effectiveTab != tab) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => tab = effectiveTab);
          });
        }

        Widget content;
        switch (effectiveTab) {
          case 'campus':
            content = CampusHubScreen(
              apiClient: widget.apiClient,
              token: widget.token,
              initialSection: role == 'EXAM_OFFICER' ? 'tuition_admin' : 'alerts',
            );
            break;
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
              key: ValueKey('chat_$_chatRefreshTick'),
              apiClient: widget.apiClient,
              token: widget.token,
              onNavigate: (s, [d]) {
                if (s == 'chat-detail' && d != null) {
                  _openChatDetail((d as Map).cast<String, dynamic>());
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
                if (s == 'grades') {
                  _push(
                    context,
                    GradesEntryScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                    ),
                  );
                }
                if (s == 'notes') {
                  _push(
                    context,
                    NotesScreen(apiClient: widget.apiClient, token: widget.token),
                  );
                }
              },
            );
            break;
          default:
            content = DashboardScreen(
              apiClient: widget.apiClient,
              token: widget.token,
              userName: widget.userName,
              onNavigate: (s, [d]) {
                if (s == 'timetable') {
                  setState(() => tab = 'timetable');
                }
                if (s == 'homework') {
                  setState(() => tab = 'homework');
                }
                if (s == 'chat') {
                  setState(() => tab = 'chat');
                }
                if (s == 'profile') {
                  setState(() => tab = 'profile');
                }
                if (s == 'campus') {
                  setState(() => tab = 'campus');
                }
                if (s == 'grades') {
                  _push(
                    context,
                    GradesEntryScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                    ),
                  );
                }
                if (s == 'notes') {
                  _push(
                    context,
                    NotesScreen(apiClient: widget.apiClient, token: widget.token),
                  );
                }
                if (s == 'alerts') {
                  _push(
                    context,
                    CampusHubScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                      initialSection: 'alerts',
                    ),
                  );
                }
                if (s == 'teacher-workbench') {
                  _push(
                    context,
                    CampusHubScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                      initialSection: 'teacher',
                    ),
                  );
                }
                if (s == 'applications') {
                  _push(
                    context,
                    CampusHubScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                      initialSection: 'applications',
                    ),
                  );
                }
                if (s == 'support' || s == 'exam') {
                  _push(
                    context,
                    CampusHubScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                      initialSection: 'exam',
                    ),
                  );
                }
                if (s == 'tuition_admin') {
                  _push(
                    context,
                    CampusHubScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                      initialSection: 'tuition_admin',
                    ),
                  );
                }
                if (s == 'tuition_receipts' || s == 'tuition_payment') {
                  _push(
                    context,
                    CampusHubScreen(
                      apiClient: widget.apiClient,
                      token: widget.token,
                      initialSection: 'tuition',
                    ),
                  );
                }
              },
            );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: BottomNav(
            activeTab: effectiveTab,
            tabs: tabs,
            onTabChange: (t) => setState(() => tab = t),
          ),
        );
      },
    );
  }
}
