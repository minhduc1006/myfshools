class UserProfile {
  final int id;
  final String phone;
  final String fullName;
  final String className;
  final String term;
  final String gpa;
  final String avatarInitial;

  const UserProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.className,
    required this.term,
    required this.gpa,
    required this.avatarInitial,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      gpa: (json['gpa'] ?? '').toString(),
      avatarInitial: (json['avatarInitial'] ?? '').toString(),
    );
  }
}

class LoginResponse {
  final String accessToken;
  final UserProfile user;

  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: (json['accessToken'] ?? '').toString(),
      user: UserProfile.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }
}

class UpcomingClassItem {
  final int id;
  final String dayLabel;
  final int dayNumber;
  final String subject;
  final String room;
  final String startTime;
  final String teacher;

  const UpcomingClassItem({
    required this.id,
    required this.dayLabel,
    required this.dayNumber,
    required this.subject,
    required this.room,
    required this.startTime,
    required this.teacher,
  });

  factory UpcomingClassItem.fromJson(Map<String, dynamic> json) {
    return UpcomingClassItem(
      id: (json['id'] as num).toInt(),
      dayLabel: (json['dayLabel'] ?? '').toString(),
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
      subject: (json['subject'] ?? '').toString(),
      room: (json['room'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      teacher: (json['teacher'] ?? '').toString(),
    );
  }
}

class DashboardData {
  final String studentName;
  final String className;
  final String term;
  final String gpa;
  final List<UpcomingClassItem> upcomingClasses;

  const DashboardData({
    required this.studentName,
    required this.className,
    required this.term,
    required this.gpa,
    required this.upcomingClasses,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      studentName: (json['studentName'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      gpa: (json['gpa'] ?? '').toString(),
      upcomingClasses: ((json['upcomingClasses'] as List?) ?? const [])
          .map((e) => UpcomingClassItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HomeworkItemDto {
  final int id;
  final String title;
  final String subject;
  final String due;
  final String status;
  final String progress;

  const HomeworkItemDto({
    required this.id,
    required this.title,
    required this.subject,
    required this.due,
    required this.status,
    required this.progress,
  });

  factory HomeworkItemDto.fromJson(Map<String, dynamic> json) {
    return HomeworkItemDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      due: (json['due'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      progress: (json['progress'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subject': subject,
        'due': due,
        'status': status,
        'progress': progress,
      };
}

class GradeDto {
  final int id;
  final String subject;
  final String letter;
  final String oralScores;
  final String quizScores;
  final String examScores;
  final String semesterScore;
  final String score;
  final String note;

  const GradeDto({
    required this.id,
    required this.subject,
    required this.letter,
    required this.oralScores,
    required this.quizScores,
    required this.examScores,
    required this.semesterScore,
    required this.score,
    required this.note,
  });

  factory GradeDto.fromJson(Map<String, dynamic> json) {
    return GradeDto(
      id: (json['id'] as num).toInt(),
      subject: (json['subject'] ?? '').toString(),
      letter: (json['letter'] ?? '').toString(),
      oralScores: (json['oralScores'] ?? '').toString(),
      quizScores: (json['quizScores'] ?? '').toString(),
      examScores: (json['examScores'] ?? '').toString(),
      semesterScore: (json['semesterScore'] ?? '').toString(),
      score: (json['score'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class NoteDto {
  final int id;
  final String title;
  final String preview;
  final String content;
  final String date;

  const NoteDto({
    required this.id,
    required this.title,
    required this.preview,
    required this.content,
    required this.date,
  });

  factory NoteDto.fromJson(Map<String, dynamic> json) {
    return NoteDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      preview: (json['preview'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
    );
  }
}

class ScheduleItemDto {
  final int id;
  final int dayOfWeekIndex;
  final String dayShort;
  final String dayFull;
  final int dayOfMonth;
  final String scheduleDate;
  final int weekOfSemester;
  final String subject;
  final String room;
  final String startTime;
  final String endTime;
  final String teacher;
  final String colorHex;

  const ScheduleItemDto({
    required this.id,
    required this.dayOfWeekIndex,
    required this.dayShort,
    required this.dayFull,
    required this.dayOfMonth,
    required this.scheduleDate,
    required this.weekOfSemester,
    required this.subject,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.teacher,
    required this.colorHex,
  });

  factory ScheduleItemDto.fromJson(Map<String, dynamic> json) {
    return ScheduleItemDto(
      id: (json['id'] as num).toInt(),
      dayOfWeekIndex: (json['dayOfWeekIndex'] as num).toInt(),
      dayShort: (json['dayShort'] ?? '').toString(),
      dayFull: (json['dayFull'] ?? '').toString(),
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      scheduleDate: (json['scheduleDate'] ?? '').toString(),
      weekOfSemester: (json['weekOfSemester'] as num?)?.toInt() ?? 1,
      subject: (json['subject'] ?? '').toString(),
      room: (json['room'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      teacher: (json['teacher'] ?? '').toString(),
      colorHex: (json['colorHex'] ?? '#2563EB').toString(),
    );
  }
}

class ChatThreadDto {
  final int id;
  final String name;
  final String participantInitial;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool isGroup;

  const ChatThreadDto({
    required this.id,
    required this.name,
    required this.participantInitial,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.isGroup,
  });

  factory ChatThreadDto.fromJson(Map<String, dynamic> json) {
    return ChatThreadDto(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      participantInitial: (json['participantInitial'] ?? '').toString(),
      lastMessage: (json['lastMessage'] ?? '').toString(),
      lastTime: (json['lastTime'] ?? '').toString(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isGroup: json['group'] == true,
    );
  }
}

class ChatUserDto {
  final int id;
  final String phone;
  final String fullName;
  final String className;
  final String term;
  final String gpa;
  final String avatarInitial;

  const ChatUserDto({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.className,
    required this.term,
    required this.gpa,
    required this.avatarInitial,
  });

  factory ChatUserDto.fromJson(Map<String, dynamic> json) {
    return ChatUserDto(
      id: (json['id'] as num).toInt(),
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      gpa: (json['gpa'] ?? '').toString(),
      avatarInitial: (json['avatarInitial'] ?? '').toString(),
    );
  }
}

class ChatMessageDto {
  final int id;
  final bool fromMe;
  final String text;
  final String time;

  const ChatMessageDto({
    required this.id,
    required this.fromMe,
    required this.text,
    required this.time,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: (json['id'] as num).toInt(),
      fromMe: json['fromMe'] == true,
      text: (json['text'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
    );
  }
}
