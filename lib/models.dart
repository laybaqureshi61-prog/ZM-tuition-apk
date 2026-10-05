class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'admin' or 'student'
  String status; // 'pending', 'approved', 'rejected'
  String assignedClass;
  final String rollNo;
  final String phone;
  final String parentPhone;
  final String address;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.status = 'approved',
    this.assignedClass = 'Class 12th (Science & Math)',
    this.rollNo = '',
    this.phone = '',
    this.parentPhone = '',
    this.address = '',
  });
}

class NoteModel {
  final String id;
  final String title;
  final String subject;
  final String className;
  final String date;
  final String fileUrl;
  final String uploadedBy;
  final String fileName;
  final String fileSize;

  NoteModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.date,
    required this.fileUrl,
    required this.uploadedBy,
    this.fileName = 'Document.pdf',
    this.fileSize = '2.4 MB',
  });
}

class NoticeModel {
  final String id;
  final String title;
  final String date;
  final String description;
  final String category;

  NoticeModel({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.category,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String time;
  final String description;
  final String type; // 'note', 'fee', 'test', 'attendance'

  NotificationModel({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.type,
  });
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final String status; // 'Present', 'Absent', 'Late', 'Leave'
  final String markedBy;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.status,
    required this.markedBy,
  });
}

class FeeModel {
  final String studentId;
  final String studentName;
  final String className;
  final String month;
  final double amount;
  bool isPaid;
  String date;

  FeeModel({
    required this.studentId,
    required this.studentName,
    this.className = 'Class 12th',
    required this.month,
    required this.amount,
    required this.isPaid,
    required this.date,
  });
}

class HomeworkModel {
  final String id;
  final String title;
  final String subject;
  final String className;
  final String dueDate;
  final String description;

  HomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.dueDate,
    required this.description,
  });
}

class TestQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  TestQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class TestSeriesModel {
  final String id;
  final String title;
  final String subject;
  final String className;
  final int totalMarks;
  final int durationMinutes;
  final String date;
  final List<TestQuestion> questions;

  TestSeriesModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.totalMarks,
    required this.durationMinutes,
    required this.date,
    required this.questions,
  });
}

class TestResultModel {
  final String id;
  final String studentId;
  final String studentName;
  final String testTitle;
  final int score;
  final int totalMarks;
  final String status; // 'Completed', 'Cancelled (Cheating Attempt)'
  final String date;

  TestResultModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.testTitle,
    required this.score,
    required this.totalMarks,
    required this.status,
    required this.date,
  });
}
