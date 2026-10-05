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
  bool isArchived;
  String studentPin;

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
    this.isArchived = false,
    this.studentPin = '1234',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'status': status,
        'assignedClass': assignedClass,
        'rollNo': rollNo,
        'phone': phone,
        'parentPhone': parentPhone,
        'address': address,
        'isArchived': isArchived,
        'studentPin': studentPin,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        role: json['role'] ?? 'student',
        status: json['status'] ?? 'approved',
        assignedClass: json['assignedClass'] ?? '',
        rollNo: json['rollNo'] ?? '',
        phone: json['phone'] ?? '',
        parentPhone: json['parentPhone'] ?? '',
        address: json['address'] ?? '',
        isArchived: json['isArchived'] ?? false,
        studentPin: json['studentPin'] ?? '1234',
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'className': className,
        'date': date,
        'fileUrl': fileUrl,
        'uploadedBy': uploadedBy,
        'fileName': fileName,
        'fileSize': fileSize,
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        className: json['className'] ?? '',
        date: json['date'] ?? '',
        fileUrl: json['fileUrl'] ?? '',
        uploadedBy: json['uploadedBy'] ?? '',
        fileName: json['fileName'] ?? 'Document.pdf',
        fileSize: json['fileSize'] ?? '2.4 MB',
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'description': description,
        'category': category,
      };

  factory NoticeModel.fromJson(Map<String, dynamic> json) => NoticeModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        date: json['date'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? 'General',
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'description': description,
        'type': type,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        time: json['time'] ?? '',
        description: json['description'] ?? '',
        type: json['type'] ?? 'general',
      );
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final String status; // 'Present', 'Absent', 'Leave', 'Late', 'Holiday'
  final String markedBy;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.status,
    required this.markedBy,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'date': date.toIso8601String(),
        'status': status,
        'markedBy': markedBy,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        studentId: json['studentId'] ?? '',
        studentName: json['studentName'] ?? '',
        className: json['className'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        status: json['status'] ?? 'Present',
        markedBy: json['markedBy'] ?? 'Admin',
      );
}

class FeeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String month;
  final double amount;
  double paidAmount;
  bool isPaid;
  bool isPartial;
  String date;
  String receiptNo;
  String paymentMode; // 'Cash', 'UPI'
  String note;

  FeeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.className = 'Class 12th',
    required this.month,
    required this.amount,
    this.paidAmount = 0.0,
    required this.isPaid,
    this.isPartial = false,
    required this.date,
    this.receiptNo = '',
    this.paymentMode = 'Cash',
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'month': month,
        'amount': amount,
        'paidAmount': paidAmount,
        'isPaid': isPaid,
        'isPartial': isPartial,
        'date': date,
        'receiptNo': receiptNo,
        'paymentMode': paymentMode,
        'note': note,
      };

  factory FeeModel.fromJson(Map<String, dynamic> json) => FeeModel(
        id: json['id'] ?? '',
        studentId: json['studentId'] ?? '',
        studentName: json['studentName'] ?? '',
        className: json['className'] ?? '',
        month: json['month'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
        isPaid: json['isPaid'] ?? false,
        isPartial: json['isPartial'] ?? false,
        date: json['date'] ?? '',
        receiptNo: json['receiptNo'] ?? '',
        paymentMode: json['paymentMode'] ?? 'Cash',
        note: json['note'] ?? '',
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'className': className,
        'dueDate': dueDate,
        'description': description,
      };

  factory HomeworkModel.fromJson(Map<String, dynamic> json) => HomeworkModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        className: json['className'] ?? '',
        dueDate: json['dueDate'] ?? '',
        description: json['description'] ?? '',
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionText': questionText,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
      };

  factory TestQuestion.fromJson(Map<String, dynamic> json) => TestQuestion(
        id: json['id'] ?? '',
        questionText: json['questionText'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctOptionIndex: json['correctOptionIndex'] ?? 0,
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'className': className,
        'totalMarks': totalMarks,
        'durationMinutes': durationMinutes,
        'date': date,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory TestSeriesModel.fromJson(Map<String, dynamic> json) => TestSeriesModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        className: json['className'] ?? '',
        totalMarks: json['totalMarks'] ?? 25,
        durationMinutes: json['durationMinutes'] ?? 15,
        date: json['date'] ?? '',
        questions: (json['questions'] as List?)?.map((q) => TestQuestion.fromJson(q)).toList() ?? [],
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'testTitle': testTitle,
        'score': score,
        'totalMarks': totalMarks,
        'status': status,
        'date': date,
      };

  factory TestResultModel.fromJson(Map<String, dynamic> json) => TestResultModel(
        id: json['id'] ?? '',
        studentId: json['studentId'] ?? '',
        studentName: json['studentName'] ?? '',
        testTitle: json['testTitle'] ?? '',
        score: json['score'] ?? 0,
        totalMarks: json['totalMarks'] ?? 0,
        status: json['status'] ?? '',
        date: json['date'] ?? '',
      );
}
