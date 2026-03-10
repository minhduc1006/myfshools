class UserProfile {
  final int id;
  final String phone;
  final String fullName;
  final String className;
  final String role;
  final String managedClass;
  final String subjectSpecialty;
  final String term;
  final String gpa;
  final String avatarInitial;

  const UserProfile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.className,
    required this.role,
    required this.managedClass,
    required this.subjectSpecialty,
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
      role: (json['role'] ?? 'STUDENT').toString(),
      managedClass: (json['managedClass'] ?? '').toString(),
      subjectSpecialty: (json['subjectSpecialty'] ?? '').toString(),
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
          .map((e) =>
              UpcomingClassItem.fromJson((e as Map).cast<String, dynamic>()))
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
  final String semester;
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
    required this.semester,
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
      semester: (json['semester'] ?? '1').toString(),
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

class AlertDto {
  final int id;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final bool read;

  const AlertDto({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.read,
  });

  factory AlertDto.fromJson(Map<String, dynamic> json) {
    return AlertDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      read: json['read'] == true,
    );
  }
}

class TeacherAssignmentDto {
  final int id;
  final String title;
  final String subject;
  final String targetClass;
  final String dueDate;
  final String note;
  final String attachmentName;
  final String createdAt;
  final String createdBy;

  const TeacherAssignmentDto({
    required this.id,
    required this.title,
    required this.subject,
    required this.targetClass,
    required this.dueDate,
    required this.note,
    required this.attachmentName,
    required this.createdAt,
    required this.createdBy,
  });

  factory TeacherAssignmentDto.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      targetClass: (json['targetClass'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      attachmentName: (json['attachmentName'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
    );
  }
}

class ServiceRequestDto {
  final int id;
  final String title;
  final String type;
  final String category;
  final String description;
  final String status;
  final String handlerNote;
  final String requester;
  final String createdAt;
  final String updatedAt;

  const ServiceRequestDto({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.description,
    required this.status,
    required this.handlerNote,
    required this.requester,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequestDto.fromJson(Map<String, dynamic> json) {
    return ServiceRequestDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      handlerNote: (json['handlerNote'] ?? '').toString(),
      requester: (json['requester'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}

class TuitionInvoiceDto {
  final int id;
  final String title;
  final int amount;
  final String dueDate;
  final String status;
  final int? payOsOrderCode;
  final String checkoutUrl;
  final String qrCode;
  final String paidAt;

  const TuitionInvoiceDto({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.payOsOrderCode,
    required this.checkoutUrl,
    required this.qrCode,
    required this.paidAt,
  });

  factory TuitionInvoiceDto.fromJson(Map<String, dynamic> json) {
    return TuitionInvoiceDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      dueDate: (json['dueDate'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      payOsOrderCode: (json['payOsOrderCode'] as num?)?.toInt(),
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      paidAt: (json['paidAt'] ?? '').toString(),
    );
  }
}

class PayOsCheckoutDto {
  final int invoiceId;
  final int orderCode;
  final String checkoutUrl;
  final String qrCode;
  final String status;

  const PayOsCheckoutDto({
    required this.invoiceId,
    required this.orderCode,
    required this.checkoutUrl,
    required this.qrCode,
    required this.status,
  });

  factory PayOsCheckoutDto.fromJson(Map<String, dynamic> json) {
    return PayOsCheckoutDto(
      invoiceId: (json['invoiceId'] as num).toInt(),
      orderCode: (json['orderCode'] as num).toInt(),
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class TeacherGradeRowDto {
  final int studentId;
  final String studentPhone;
  final String studentName;
  final String className;
  final String subject;
  final String semester;
  final String oralScores;
  final String quizScores;
  final String examScores;
  final String semesterScore;
  final String averageScore;
  final String note;

  const TeacherGradeRowDto({
    required this.studentId,
    required this.studentPhone,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.semester,
    required this.oralScores,
    required this.quizScores,
    required this.examScores,
    required this.semesterScore,
    required this.averageScore,
    required this.note,
  });

  factory TeacherGradeRowDto.fromJson(Map<String, dynamic> json) {
    return TeacherGradeRowDto(
      studentId: (json['studentId'] as num).toInt(),
      studentPhone: (json['studentPhone'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      semester: (json['semester'] ?? '').toString(),
      oralScores: (json['oralScores'] ?? '').toString(),
      quizScores: (json['quizScores'] ?? '').toString(),
      examScores: (json['examScores'] ?? '').toString(),
      semesterScore: (json['semesterScore'] ?? '').toString(),
      averageScore: (json['averageScore'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class HomeworkClassReportDto {
  final String className;
  final int totalStudents;
  final int submittedCount;
  final int pendingCount;
  final int overdueCount;

  const HomeworkClassReportDto({
    required this.className,
    required this.totalStudents,
    required this.submittedCount,
    required this.pendingCount,
    required this.overdueCount,
  });

  factory HomeworkClassReportDto.fromJson(Map<String, dynamic> json) {
    return HomeworkClassReportDto(
      className: (json['className'] ?? '').toString(),
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeworkStudentStatusDto {
  final String studentPhone;
  final String studentName;
  final String className;
  final String title;
  final String subject;
  final String dueDate;
  final String status;

  const HomeworkStudentStatusDto({
    required this.studentPhone,
    required this.studentName,
    required this.className,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
  });

  factory HomeworkStudentStatusDto.fromJson(Map<String, dynamic> json) {
    return HomeworkStudentStatusDto(
      studentPhone: (json['studentPhone'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class TuitionClassSummaryDto {
  final String className;
  final int totalStudents;
  final int paidStudents;
  final int pendingStudents;
  final int unpaidStudents;
  final int totalAmount;
  final int paidAmount;

  const TuitionClassSummaryDto({
    required this.className,
    required this.totalStudents,
    required this.paidStudents,
    required this.pendingStudents,
    required this.unpaidStudents,
    required this.totalAmount,
    required this.paidAmount,
  });

  factory TuitionClassSummaryDto.fromJson(Map<String, dynamic> json) {
    return TuitionClassSummaryDto(
      className: (json['className'] ?? '').toString(),
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      paidStudents: (json['paidStudents'] as num?)?.toInt() ?? 0,
      pendingStudents: (json['pendingStudents'] as num?)?.toInt() ?? 0,
      unpaidStudents: (json['unpaidStudents'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TuitionStudentStatusDto {
  final int studentId;
  final String studentPhone;
  final String studentName;
  final String className;
  final String status;
  final int totalAmount;
  final int paidAmount;

  const TuitionStudentStatusDto({
    required this.studentId,
    required this.studentPhone,
    required this.studentName,
    required this.className,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
  });

  factory TuitionStudentStatusDto.fromJson(Map<String, dynamic> json) {
    return TuitionStudentStatusDto(
      studentId: (json['studentId'] as num).toInt(),
      studentPhone: (json['studentPhone'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      className: (json['className'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class NoticeDeliveryResultDto {
  final int deliveredCount;

  const NoticeDeliveryResultDto({required this.deliveredCount});

  factory NoticeDeliveryResultDto.fromJson(Map<String, dynamic> json) {
    return NoticeDeliveryResultDto(
      deliveredCount: (json['deliveredCount'] as num?)?.toInt() ?? 0,
    );
  }
}
