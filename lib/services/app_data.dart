import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models.dart';

class AppData extends ChangeNotifier {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  UserModel? currentUser;
  bool isDarkMode = false;
  bool isHindi = false;

  static const String instituteName = 'ZM Tuition – Old Bus Stand, Nakur';
  static const String appVersion = 'ZM Tuition v2.0.0 (build 20000)';

  void toggleDarkMode([bool? val]) {
    isDarkMode = val ?? !isDarkMode;
    notifyListeners();
  }

  void toggleLanguage([bool? val]) {
    isHindi = val ?? !isHindi;
    notifyListeners();
  }

  // Local YYYY-MM-DD date formatter avoiding UTC offset bugs
  static String formatLocalDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseLocalDate(String str) {
    try {
      final parts = str.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return DateTime.now();
  }

  // Simple Translation Dictionary
  String tr(String key) {
    if (!isHindi) return key;
    final map = {
      'Home': 'होम',
      'Attendance': 'उपस्थिति',
      'Students': 'छात्र',
      'Fees': 'शुल्क',
      'More': 'अन्य',
      'Mark All Present': 'सभी उपस्थित दर्ज करें',
      'Present': 'उपस्थित',
      'Absent': 'अनुपस्थित',
      'Leave': 'अवकाश',
      'Late': 'विलंब',
      'Holiday': 'छुट्टी',
      'Search Student': 'छात्र खोजें',
      'Add Student': 'छात्र जोड़ें',
      'Paid': 'भुगतान हुआ',
      'Pending': 'बकाया',
      'Partially Paid': 'आंशिक भुगतान',
      'Record Payment': 'भुगतान दर्ज करें',
      'Backup & Restore': 'बैकअप और पुनर्प्राप्ति',
      'Language': 'भाषा (Language)',
      'Dark Mode': 'डार्क मोड',
      'About': 'ऐप के बारे में',
      'Study Notes': 'अध्ययन नोट्स',
      'Homework': 'गृहकार्य',
      'Tests & Marks': 'परीक्षण और अंक',
      'Archived Students': 'संग्रहीत छात्र',
    };
    return map[key] ?? key;
  }

  // Classes across 9th to 12th
  static const List<String> zoyaCommerceClasses = [
    'Class 12th (Commerce)',
    'Class 11th (Commerce)',
  ];

  static const List<String> muskanScienceClasses = [
    'Class 9th (Science & Math)',
    'Class 10th (Science & Math)',
    'Class 11th (Science & Math)',
    'Class 12th (Science & Math)',
  ];

  static const List<String> allClasses = [
    'Class 9th (Science & Math)',
    'Class 10th (Science & Math)',
    'Class 11th (Science & Math)',
    'Class 11th (Commerce)',
    'Class 12th (Science & Math)',
    'Class 12th (Commerce)',
  ];

  List<String> archivedBatches = [];

  List<String> get classesForCurrentAdmin {
    final available = (currentUser?.name.toLowerCase().contains('zoya') == true || currentUser?.email == 'zm@124')
        ? zoyaCommerceClasses
        : (currentUser?.name.toLowerCase().contains('muskan') == true || currentUser?.email == 'muskan@zm.com')
            ? muskanScienceClasses
            : allClasses;
    return available.where((c) => !archivedBatches.contains(c)).toList();
  }

  int _receiptCounter = 1001;

  String generateReceiptNo() {
    final rec = 'ZM-REC-$_receiptCounter';
    _receiptCounter++;
    return rec;
  }

  // Security Audit Logs
  final List<AuditLogModel> auditLogs = [
    AuditLogModel(
      id: 'log_1',
      timestamp: 'Today, 10:24 AM',
      event: 'Password Reset Triggered',
      userIdentifier: 'zm@124 (Zoya)',
      ipAddress: '192.168.1.102',
      details: '6-digit OTP verified successfully. Password updated in AppData.',
    ),
    AuditLogModel(
      id: 'log_2',
      timestamp: 'Today, 09:15 AM',
      event: 'Failed Login Attempt',
      userIdentifier: 'zm@124',
      ipAddress: '10.0.0.12',
      details: 'Invalid password credential attempt logged.',
    ),
    AuditLogModel(
      id: 'log_3',
      timestamp: 'Yesterday, 04:45 PM',
      event: 'Password Reset Triggered',
      userIdentifier: 'student@123 (Ayesha Khan)',
      ipAddress: '192.168.1.105',
      details: 'OTP verified via SMS/Email recovery engine.',
    ),
    AuditLogModel(
      id: 'log_4',
      timestamp: 'Yesterday, 02:30 PM',
      event: 'Account Status Toggle',
      userIdentifier: 'student_6 (Priya Verma)',
      ipAddress: '192.168.1.1',
      details: 'Status changed to Approved by Admin.',
    ),
  ];

  void addAuditLog({
    required String event,
    required String userIdentifier,
    required String ipAddress,
    required String details,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    auditLogs.insert(
      0,
      AuditLogModel(
        id: 'log_${now.millisecondsSinceEpoch}',
        timestamp: 'Today, $timeStr',
        event: event,
        userIdentifier: userIdentifier,
        ipAddress: ipAddress,
        details: details,
      ),
    );
    notifyListeners();
  }

  // Admins List
  final List<UserModel> admins = [
    UserModel(
      id: 'admin_1',
      name: 'Zoya (Admin 1)',
      email: 'zm@124',
      password: '12345678',
      role: 'admin',
      status: 'approved',
      assignedClass: '12th & 11th Commerce Stream',
    ),
    UserModel(
      id: 'admin_2',
      name: 'Muskan (Admin 2)',
      email: 'muskan@zm.com',
      password: '12345678',
      role: 'admin',
      status: 'approved',
      assignedClass: '9th to 12th Science & Math Stream',
    ),
  ];

  final List<UserModel> users = [
    UserModel(
      id: 'admin_1',
      name: 'Zoya (Admin 1)',
      email: 'zm@124',
      password: '12345678',
      role: 'admin',
      status: 'approved',
      assignedClass: '12th & 11th Commerce Stream',
    ),
    UserModel(
      id: 'admin_2',
      name: 'Muskan (Admin 2)',
      email: 'muskan@zm.com',
      password: '12345678',
      role: 'admin',
      status: 'approved',
      assignedClass: '9th to 12th Science & Math Stream',
    ),
    UserModel(
      id: 'student_1',
      name: 'Ayesha Khan',
      email: 'student@123',
      password: '123456789',
      role: 'student',
      status: 'approved',
      assignedClass: 'Class 10th (Science & Math)',
      rollNo: 'SU/01',
      phone: '9876543210',
      parentPhone: '9876500000',
      address: 'Old Bus Stand, Nakur',
      studentPin: '1234',
    ),
    UserModel(
      id: 'student_2',
      name: 'Riya Sharma',
      email: 'riya@123.com',
      password: '123456789',
      role: 'student',
      status: 'approved',
      assignedClass: 'Class 10th (Science & Math)',
      rollNo: 'SU/02',
      phone: '9876543211',
      parentPhone: '9876500001',
      address: 'Main Market, Nakur',
      studentPin: '1234',
    ),
    UserModel(
      id: 'student_3',
      name: 'Simran Singh',
      email: 'simran@commerce.com',
      password: '123456789',
      role: 'student',
      status: 'approved',
      assignedClass: 'Class 12th (Commerce)',
      rollNo: 'CM/03',
      phone: '9876543212',
      parentPhone: '9876500002',
      address: 'Station Road, Nakur',
      studentPin: '1234',
    ),
    UserModel(
      id: 'student_4',
      name: 'Neha Gupta',
      email: 'neha@123.com',
      password: '123456789',
      role: 'student',
      status: 'approved',
      assignedClass: 'Class 10th (Science & Math)',
      rollNo: 'SU/04',
      phone: '9876543213',
      parentPhone: '9876500003',
      address: 'Gandhi Nagar, Nakur',
      studentPin: '1234',
    ),
    UserModel(
      id: 'student_5',
      name: 'Zainab Ali',
      email: 'zainab@commerce.com',
      password: '123456789',
      role: 'student',
      status: 'approved',
      assignedClass: 'Class 11th (Commerce)',
      rollNo: 'CM/05',
      phone: '9876543214',
      parentPhone: '9876500004',
      address: 'Civil Lines, Nakur',
      studentPin: '1234',
    ),
    UserModel(
      id: 'student_6',
      name: 'Priya Verma',
      email: 'pending@student.com',
      password: 'password123',
      role: 'student',
      status: 'pending',
      assignedClass: 'Class 12th (Commerce)',
      rollNo: 'CM/06',
      studentPin: '1234',
    ),
  ];

  final List<NoteModel> notes = [
    NoteModel(
      id: 'note_1',
      title: 'Mathematics Algebra & Formula Sheet',
      subject: 'Mathematics',
      className: 'Class 10th (Science & Math)',
      date: '25 Sep 2026',
      fileUrl: 'https://example.com/math.pdf',
      uploadedBy: 'Muskan',
      fileName: 'Math_Formulas_Ch1.pdf',
      fileSize: '2.4 MB',
    ),
    NoteModel(
      id: 'note_2',
      title: 'Science Magnetism & Electricity Notes',
      subject: 'Science',
      className: 'Class 10th (Science & Math)',
      date: '24 Sep 2026',
      fileUrl: 'https://example.com/science.pdf',
      uploadedBy: 'Muskan',
      fileName: 'Science_Physics_Ch4.pdf',
      fileSize: '1.8 MB',
    ),
    NoteModel(
      id: 'note_3',
      title: 'Accountancy Balance Sheet & Trial Balance',
      subject: 'Accountancy',
      className: 'Class 12th (Commerce)',
      date: '22 Sep 2026',
      fileUrl: 'https://example.com/accountancy.pdf',
      uploadedBy: 'Zoya',
      fileName: 'Accountancy_Ch2.pdf',
      fileSize: '2.0 MB',
    ),
  ];

  final List<HomeworkModel> homeworkList = [
    HomeworkModel(
      id: 'hw_1',
      title: 'Math Quadratic Equations Ex 4.2',
      subject: 'Mathematics',
      className: 'Class 10th (Science & Math)',
      dueDate: '2026-09-30',
      description: 'Solve Q1 to Q10 in fair copy with step-by-step solutions.',
    ),
    HomeworkModel(
      id: 'hw_2',
      title: 'Accountancy Ledger Posting Assignment',
      subject: 'Accountancy',
      className: 'Class 12th (Commerce)',
      dueDate: '2026-10-02',
      description: 'Prepare Journal entries and Ledger accounts for Problem 5.',
    ),
  ];

  final List<NoticeModel> notices = [
    NoticeModel(
      id: 'notice_1',
      title: 'Holiday Notice',
      date: '25 Sep 2026',
      description: 'Tuition coaching will remain closed on Friday for Gandhi Jayanti.',
      category: 'Holiday',
    ),
    NoticeModel(
      id: 'notice_2',
      title: 'Exam Schedule Released',
      date: '22 Sep 2026',
      description: 'Proctored test series for Class 10th & 12th starts this Sunday at 10:00 AM.',
      category: 'Exam',
    ),
  ];

  final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'notif_1',
      title: 'New note uploaded in Mathematics',
      time: '2 hours ago',
      description: 'Muskan uploaded Algebra Formula Sheet.pdf for Class 10th.',
      type: 'note',
    ),
    NotificationModel(
      id: 'notif_2',
      title: 'Fee payment receipt received',
      time: '5 hours ago',
      description: 'Tuition fee payment of ₹2,500 recorded for September.',
      type: 'fee',
    ),
  ];

  final List<AttendanceRecord> attendanceRecords = [
    AttendanceRecord(
      studentId: 'student_1',
      studentName: 'Ayesha Khan',
      className: 'Class 10th (Science & Math)',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Present',
      markedBy: 'Muskan',
    ),
    AttendanceRecord(
      studentId: 'student_2',
      studentName: 'Riya Sharma',
      className: 'Class 10th (Science & Math)',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Present',
      markedBy: 'Muskan',
    ),
    AttendanceRecord(
      studentId: 'student_3',
      studentName: 'Simran Singh',
      className: 'Class 12th (Commerce)',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Present',
      markedBy: 'Zoya',
    ),
  ];

  final List<FeeModel> fees = [
    FeeModel(
      id: 'fee_1',
      studentId: 'student_1',
      studentName: 'Ayesha Khan',
      className: 'Class 10th (Science & Math)',
      month: 'September 2026',
      amount: 2500,
      paidAmount: 2500,
      isPaid: true,
      isPartial: false,
      date: '2026-09-25',
      receiptNo: 'ZM-REC-1001',
      paymentMode: 'UPI',
      note: 'Paid via GooglePay',
    ),
    FeeModel(
      id: 'fee_2',
      studentId: 'student_2',
      studentName: 'Riya Sharma',
      className: 'Class 10th (Science & Math)',
      month: 'September 2026',
      amount: 2500,
      paidAmount: 2500,
      isPaid: true,
      isPartial: false,
      date: '2026-09-24',
      receiptNo: 'ZM-REC-1002',
      paymentMode: 'Cash',
      note: 'Cash in hand',
    ),
    FeeModel(
      id: 'fee_3',
      studentId: 'student_3',
      studentName: 'Simran Singh',
      className: 'Class 12th (Commerce)',
      month: 'September 2026',
      amount: 2500,
      paidAmount: 1000,
      isPaid: false,
      isPartial: true,
      date: '2026-09-20',
      receiptNo: 'ZM-REC-1003',
      paymentMode: 'Cash',
      note: 'Partial payment ₹1000 received',
    ),
    FeeModel(
      id: 'fee_4',
      studentId: 'student_4',
      studentName: 'Neha Gupta',
      className: 'Class 10th (Science & Math)',
      month: 'September 2026',
      amount: 2500,
      paidAmount: 2500,
      isPaid: true,
      isPartial: false,
      date: '2026-09-18',
      receiptNo: 'ZM-REC-1004',
      paymentMode: 'UPI',
      note: 'UPI Payment',
    ),
    FeeModel(
      id: 'fee_5',
      studentId: 'student_5',
      studentName: 'Zainab Ali',
      className: 'Class 11th (Commerce)',
      month: 'September 2026',
      amount: 2500,
      paidAmount: 0,
      isPaid: false,
      isPartial: false,
      date: 'Pending',
      receiptNo: '',
      paymentMode: 'Cash',
      note: '',
    ),
  ];

  final List<TestSeriesModel> testSeriesList = [
    TestSeriesModel(
      id: 'ts_1',
      title: 'Class 10th Math Unit Test',
      subject: 'Mathematics',
      className: 'Class 10th (Science & Math)',
      totalMarks: 25,
      durationMinutes: 15,
      date: 'Date: 25 Sep 2026 | 10:00 AM',
      questions: [
        TestQuestion(
          id: 'q1',
          questionText: 'What is the quadratic formula for ax² + bx + c = 0?',
          options: ['x = (-b ± √(b² - 4ac)) / 2a', 'x = (-b ± √(b² + 4ac)) / 2a', 'x = b / 2a', 'x = -b / a'],
          correctOptionIndex: 0,
        ),
      ],
    ),
  ];

  final List<TestResultModel> testResults = [
    TestResultModel(
      id: 'tr_1',
      studentId: 'student_1',
      studentName: 'Ayesha Khan',
      testTitle: 'Class 10th Math Unit Test',
      score: 23,
      totalMarks: 25,
      status: 'Completed',
      date: '2026-09-25',
    ),
  ];

  // Auth methods
  bool login(String identifier, String password, String role) {
    try {
      final query = identifier.trim().toLowerCase();
      final user = users.firstWhere((u) {
        if (u.role != role) return false;
        if (u.status == 'suspended') return false;
        final matchEmail = u.email.toLowerCase() == query;
        final matchPhone = u.phone == query || u.parentPhone == query;
        final matchRoll = u.rollNo.toLowerCase() == query;

        bool matchSecret = false;
        if (role == 'student') {
          matchSecret = (u.password == password || u.studentPin == password);
        } else {
          matchSecret = (u.password == password);
        }

        return (matchEmail || matchPhone || matchRoll) && matchSecret;
      });

      currentUser = user;
      addAuditLog(
        event: 'User Login',
        userIdentifier: '${user.name} (${user.email})',
        ipAddress: '192.168.1.100',
        details: 'Successful login as $role',
      );
      notifyListeners();
      return true;
    } catch (_) {
      addAuditLog(
        event: 'Failed Login Attempt',
        userIdentifier: identifier,
        ipAddress: '192.168.1.120',
        details: 'Invalid credentials or suspended account attempt for role $role',
      );
      return false;
    }
  }

  UserModel? findUserByIdentifier(String identifier) {
    final query = identifier.trim().toLowerCase();
    try {
      return users.firstWhere((u) {
        return u.email.toLowerCase() == query ||
            u.phone == query ||
            u.parentPhone == query ||
            u.rollNo.toLowerCase() == query ||
            u.name.toLowerCase() == query;
      });
    } catch (_) {
      return null;
    }
  }

  bool resetPasswordByIdentifier(String identifier, String newPassword) {
    final query = identifier.trim().toLowerCase();
    int foundIndex = users.indexWhere((u) {
      return u.email.toLowerCase() == query ||
          u.phone == query ||
          u.parentPhone == query ||
          u.rollNo.toLowerCase() == query ||
          u.name.toLowerCase() == query;
    });

    if (foundIndex != -1) {
      final oldUser = users[foundIndex];
      final updatedUser = UserModel(
        id: oldUser.id,
        name: oldUser.name,
        email: oldUser.email,
        password: newPassword,
        role: oldUser.role,
        status: oldUser.status,
        assignedClass: oldUser.assignedClass,
        rollNo: oldUser.rollNo,
        phone: oldUser.phone,
        parentPhone: oldUser.parentPhone,
        address: oldUser.address,
        isArchived: oldUser.isArchived,
        studentPin: newPassword.length >= 4 ? newPassword.substring(0, 4) : newPassword,
      );
      users[foundIndex] = updatedUser;

      final adminIndex = admins.indexWhere((a) => a.id == oldUser.id || a.email.toLowerCase() == oldUser.email.toLowerCase());
      if (adminIndex != -1) {
        admins[adminIndex] = updatedUser;
      }

      addAuditLog(
        event: 'Password Reset Triggered',
        userIdentifier: '${oldUser.name} (${oldUser.email})',
        ipAddress: '192.168.1.105',
        details: 'Password successfully reset via 3-step OTP engine. Immediate login active.',
      );

      notifyListeners();
      return true;
    }
    return false;
  }

  void toggleUserAccountStatus(String userId, String newStatus) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = users[index];
      user.status = newStatus;
      addAuditLog(
        event: 'Account Status Toggle',
        userIdentifier: '${user.name} (${user.role})',
        ipAddress: '192.168.1.1',
        details: 'Account status updated to "$newStatus"',
      );
      notifyListeners();
    }
  }

  bool changeCurrentUserPassword(String oldPassword, String newPassword) {
    if (currentUser == null) return false;
    if (currentUser!.password != oldPassword && currentUser!.studentPin != oldPassword) {
      return false;
    }
    final index = users.indexWhere((u) => u.id == currentUser!.id);
    if (index != -1) {
      final updated = UserModel(
        id: currentUser!.id,
        name: currentUser!.name,
        email: currentUser!.email,
        password: newPassword,
        role: currentUser!.role,
        status: currentUser!.status,
        assignedClass: currentUser!.assignedClass,
        rollNo: currentUser!.rollNo,
        phone: currentUser!.phone,
        parentPhone: currentUser!.parentPhone,
        address: currentUser!.address,
        studentPin: newPassword.length >= 4 ? newPassword.substring(0, 4) : newPassword,
        isArchived: currentUser!.isArchived,
      );
      users[index] = updated;
      currentUser = updated;

      final adminIndex = admins.indexWhere((a) => a.id == currentUser!.id || a.email.toLowerCase() == currentUser!.email.toLowerCase());
      if (adminIndex != -1) {
        admins[adminIndex] = updated;
      }

      addAuditLog(
        event: 'User Password Change',
        userIdentifier: '${currentUser!.name} (${currentUser!.email})',
        ipAddress: '192.168.1.100',
        details: 'Self password update completed',
      );

      notifyListeners();
      return true;
    }
    return false;
  }

  bool signupStudent({
    required String name,
    required String email,
    required String password,
    String rollNo = '',
    String phone = '',
    String parentPhone = '',
    String address = '',
    String studentPin = '1234',
  }) {
    if (users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return false;
    }
    final newUser = UserModel(
      id: 'student_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      password: password,
      role: 'student',
      status: 'pending',
      assignedClass: 'Unassigned',
      rollNo: rollNo,
      phone: phone,
      parentPhone: parentPhone,
      address: address,
      studentPin: studentPin.isNotEmpty ? studentPin : '1234',
    );
    users.add(newUser);
    currentUser = newUser;
    addAuditLog(
      event: 'Student Registration',
      userIdentifier: '$name ($email)',
      ipAddress: '192.168.1.110',
      details: 'New student self-registered, status set to pending',
    );
    notifyListeners();
    return true;
  }

  void addStudentDirectly({
    required String name,
    required String email,
    required String assignedClass,
    String rollNo = '',
    String phone = '',
    String parentPhone = '',
    String address = '',
    String studentPin = '1234',
  }) {
    final studentId = 'student_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = UserModel(
      id: studentId,
      name: name,
      email: email,
      password: '123456789',
      role: 'student',
      status: 'approved',
      assignedClass: assignedClass,
      rollNo: rollNo,
      phone: phone,
      parentPhone: parentPhone,
      address: address,
      studentPin: studentPin,
    );
    users.add(newUser);
    fees.add(FeeModel(
      id: 'fee_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      studentName: newUser.name,
      className: assignedClass,
      month: 'September 2026',
      amount: 2500,
      paidAmount: 0,
      isPaid: false,
      date: 'Pending',
    ));
    addAuditLog(
      event: 'Direct Student Creation',
      userIdentifier: '$name ($assignedClass)',
      ipAddress: '192.168.1.1',
      details: 'Directly added student by admin',
    );
    notifyListeners();
  }

  void updateStudent(UserModel student) {
    final index = users.indexWhere((u) => u.id == student.id);
    if (index != -1) {
      users[index] = student;
      notifyListeners();
    }
  }

  void archiveStudent(String studentId) {
    final user = users.firstWhere((u) => u.id == studentId, orElse: () => users.first);
    user.isArchived = true;
    notifyListeners();
  }

  void unarchiveStudent(String studentId) {
    final user = users.firstWhere((u) => u.id == studentId, orElse: () => users.first);
    user.isArchived = false;
    notifyListeners();
  }

  void resetStudentPin(String studentId, String newPin) {
    final user = users.firstWhere((u) => u.id == studentId, orElse: () => users.first);
    user.studentPin = newPin;
    addAuditLog(
      event: 'Admin PIN Reset',
      userIdentifier: '${user.name} (${user.id})',
      ipAddress: '192.168.1.1',
      details: 'Student PIN updated by Admin',
    );
    notifyListeners();
  }

  void archiveBatch(String className) {
    if (!archivedBatches.contains(className)) {
      archivedBatches.add(className);
      notifyListeners();
    }
  }

  void unarchiveBatch(String className) {
    archivedBatches.remove(className);
    notifyListeners();
  }

  void addNote(NoteModel note) {
    notes.insert(0, note);
    notices.insert(
      0,
      NoticeModel(
        id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Note: ${note.title}',
        date: formatLocalDate(DateTime.now()),
        description: 'New study material published for ${note.className} in ${note.subject}.',
        category: 'Academics',
      ),
    );
    notifyListeners();
  }

  void addHomework(HomeworkModel hw) {
    homeworkList.insert(0, hw);
    notices.insert(
      0,
      NoticeModel(
        id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Homework: ${hw.title}',
        date: formatLocalDate(DateTime.now()),
        description: 'Due Date: ${hw.dueDate} for ${hw.className}. ${hw.description}',
        category: 'Homework',
      ),
    );
    notifyListeners();
  }

  void addTestSeries(TestSeriesModel test) {
    testSeriesList.insert(0, test);
    notices.insert(
      0,
      NoticeModel(
        id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Test: ${test.title}',
        date: formatLocalDate(DateTime.now()),
        description: 'Duration: ${test.durationMinutes} mins | Total Marks: ${test.totalMarks}. Proctored mode.',
        category: 'Exam',
      ),
    );
    notifyListeners();
  }

  void recordTestResult(TestResultModel result) {
    testResults.insert(0, result);
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  void approveStudent(String studentId, String assignedClass) {
    final user = users.firstWhere((u) => u.id == studentId);
    user.status = 'approved';
    user.assignedClass = assignedClass;
    fees.add(FeeModel(
      id: 'fee_${DateTime.now().millisecondsSinceEpoch}',
      studentId: user.id,
      studentName: user.name,
      className: assignedClass,
      month: 'September 2026',
      amount: 2500,
      paidAmount: 0,
      isPaid: false,
      date: 'Pending',
    ));
    addAuditLog(
      event: 'Student Approval',
      userIdentifier: '${user.name} (${user.email})',
      ipAddress: '192.168.1.1',
      details: 'Approved and assigned to $assignedClass',
    );
    notifyListeners();
  }

  void rejectStudent(String studentId) {
    final user = users.firstWhere((u) => u.id == studentId);
    user.status = 'rejected';
    addAuditLog(
      event: 'Student Rejection',
      userIdentifier: '${user.name} (${user.email})',
      ipAddress: '192.168.1.1',
      details: 'Registration request rejected',
    );
    notifyListeners();
  }

  void recordFeePayment({
    required String feeId,
    required double paidAmount,
    required double totalAmount,
    required String paymentMode,
    required String note,
  }) {
    final fee = fees.firstWhere((f) => f.id == feeId, orElse: () => fees.first);
    fee.paidAmount = paidAmount;
    fee.paymentMode = paymentMode;
    fee.note = note;
    fee.date = formatLocalDate(DateTime.now());
    if (fee.receiptNo.isEmpty) {
      fee.receiptNo = generateReceiptNo();
    }

    if (paidAmount >= totalAmount) {
      fee.isPaid = true;
      fee.isPartial = false;
    } else if (paidAmount > 0) {
      fee.isPaid = false;
      fee.isPartial = true;
    } else {
      fee.isPaid = false;
      fee.isPartial = false;
    }

    addAuditLog(
      event: 'Fee Payment Recorded',
      userIdentifier: '${fee.studentName} (${fee.month})',
      ipAddress: '192.168.1.1',
      details: 'Paid ₹$paidAmount via $paymentMode. Receipt: ${fee.receiptNo}',
    );

    notifyListeners();
  }

  void markAttendance({
    required String studentId,
    required String studentName,
    required String className,
    required DateTime date,
    required String status,
    required String markedBy,
  }) {
    final localFormatted = formatLocalDate(date);
    attendanceRecords.removeWhere((r) => r.studentId == studentId && formatLocalDate(r.date) == localFormatted);
    attendanceRecords.add(
      AttendanceRecord(
        studentId: studentId,
        studentName: studentName,
        className: className,
        date: date,
        status: status,
        markedBy: markedBy,
      ),
    );
    notifyListeners();
  }

  // Backup JSON Export
  String exportToJson() {
    final Map<String, dynamic> data = {
      'users': users.map((u) => u.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'notices': notices.map((n) => n.toJson()).toList(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'attendanceRecords': attendanceRecords.map((a) => a.toJson()).toList(),
      'fees': fees.map((f) => f.toJson()).toList(),
      'homeworkList': homeworkList.map((h) => h.toJson()).toList(),
      'testSeriesList': testSeriesList.map((t) => t.toJson()).toList(),
      'testResults': testResults.map((r) => r.toJson()).toList(),
      'auditLogs': auditLogs.map((l) => l.toJson()).toList(),
      'archivedBatches': archivedBatches,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Restore JSON Import
  bool importFromJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      if (data.containsKey('users')) {
        users.clear();
        for (var u in data['users']) {
          users.add(UserModel.fromJson(u));
        }
      }
      if (data.containsKey('notes')) {
        notes.clear();
        for (var n in data['notes']) {
          notes.add(NoteModel.fromJson(n));
        }
      }
      if (data.containsKey('notices')) {
        notices.clear();
        for (var n in data['notices']) {
          notices.add(NoticeModel.fromJson(n));
        }
      }
      if (data.containsKey('notifications')) {
        notifications.clear();
        for (var n in data['notifications']) {
          notifications.add(NotificationModel.fromJson(n));
        }
      }
      if (data.containsKey('attendanceRecords')) {
        attendanceRecords.clear();
        for (var a in data['attendanceRecords']) {
          attendanceRecords.add(AttendanceRecord.fromJson(a));
        }
      }
      if (data.containsKey('fees')) {
        fees.clear();
        for (var f in data['fees']) {
          fees.add(FeeModel.fromJson(f));
        }
      }
      if (data.containsKey('homeworkList')) {
        homeworkList.clear();
        for (var h in data['homeworkList']) {
          homeworkList.add(HomeworkModel.fromJson(h));
        }
      }
      if (data.containsKey('testSeriesList')) {
        testSeriesList.clear();
        for (var t in data['testSeriesList']) {
          testSeriesList.add(TestSeriesModel.fromJson(t));
        }
      }
      if (data.containsKey('testResults')) {
        testResults.clear();
        for (var r in data['testResults']) {
          testResults.add(TestResultModel.fromJson(r));
        }
      }
      if (data.containsKey('auditLogs')) {
        auditLogs.clear();
        for (var l in data['auditLogs']) {
          auditLogs.add(AuditLogModel.fromJson(l));
        }
      }
      if (data.containsKey('archivedBatches')) {
        archivedBatches = List<String>.from(data['archivedBatches']);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
