import 'package:flutter/foundation.dart';
import '../models.dart';

class AppData extends ChangeNotifier {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  UserModel? currentUser;
  bool isDarkMode = false; // System Dark Mode Toggle

  void toggleDarkMode(bool val) {
    isDarkMode = val;
    notifyListeners();
  }

  // Available classes across 9th to 12th
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

  List<String> get classesForCurrentAdmin {
    if (currentUser?.name.toLowerCase().contains('zoya') == true || currentUser?.email == 'zm@124') {
      return zoyaCommerceClasses;
    } else if (currentUser?.name.toLowerCase().contains('muskan') == true || currentUser?.email == 'muskan@zm.com') {
      return muskanScienceClasses;
    }
    return allClasses;
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
      address: 'Block B, Sector 4, City',
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
      address: 'Street 5, Green Park',
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
      address: 'Central Market Road',
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
      address: 'Model Town',
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
      address: 'Civil Lines',
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
      title: 'English Grammar & Comprehension',
      subject: 'English',
      className: 'Class 10th (Science & Math)',
      date: '23 Sep 2026',
      fileUrl: 'https://example.com/english.pdf',
      uploadedBy: 'Muskan',
      fileName: 'English_Grammar_Guide.pdf',
      fileSize: '1.2 MB',
    ),
    NoteModel(
      id: 'note_4',
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
    NoticeModel(
      id: 'notice_3',
      title: 'Fee Reminder Notice',
      date: '20 Sep 2026',
      description: 'Please submit September tuition fees before 28th September.',
      category: 'Fee',
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
    NotificationModel(
      id: 'notif_3',
      title: 'Live test scheduled for tomorrow',
      time: '1 day ago',
      description: 'Class 10th Math test series starts at 10:00 AM in proctored mode.',
      type: 'test',
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
      studentId: 'student_1',
      studentName: 'Ayesha Khan',
      className: 'Class 10th',
      month: 'September 2026',
      amount: 2500,
      isPaid: true,
      date: '25 Sep 2026',
    ),
    FeeModel(
      studentId: 'student_2',
      studentName: 'Riya Sharma',
      className: 'Class 10th',
      month: 'September 2026',
      amount: 2500,
      isPaid: true,
      date: '24 Sep 2026',
    ),
    FeeModel(
      studentId: 'student_3',
      studentName: 'Simran Singh',
      className: 'Class 12th',
      month: 'September 2026',
      amount: 2500,
      isPaid: false,
      date: 'Pending',
    ),
    FeeModel(
      studentId: 'student_4',
      studentName: 'Neha Gupta',
      className: 'Class 10th',
      month: 'September 2026',
      amount: 2500,
      isPaid: true,
      date: '18 Sep 2026',
    ),
    FeeModel(
      studentId: 'student_5',
      studentName: 'Zainab Ali',
      className: 'Class 11th',
      month: 'September 2026',
      amount: 2500,
      isPaid: false,
      date: 'Pending',
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
          questionText: 'What is the quadratic formula?',
          options: ['x = (-b ± √(b² - 4ac)) / 2a', 'x = (-b ± √(b² + 4ac)) / 2a', 'x = b / 2a', 'x = -b / a'],
          correctOptionIndex: 0,
        ),
      ],
    ),
    TestSeriesModel(
      id: 'ts_2',
      title: 'Class 10th Science Magnetism Test',
      subject: 'Science',
      className: 'Class 10th (Science & Math)',
      totalMarks: 20,
      durationMinutes: 10,
      date: 'Date: 26 Sep 2026 | 10:00 AM',
      questions: [
        TestQuestion(
          id: 'q1',
          questionText: 'What is the SI unit of magnetic field strength?',
          options: ['Tesla (T)', 'Gauss', 'Weber (Wb)', 'Henry (H)'],
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
      date: '25 Sep 2026',
    ),
  ];

  bool login(String email, String password, String role) {
    try {
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password && u.role == role,
      );
      currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool signupStudent({
    required String name,
    required String email,
    required String password,
    String rollNo = '',
    String phone = '',
    String parentPhone = '',
    String address = '',
  }) {
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
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
    );
    users.add(newUser);
    currentUser = newUser;
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
    );
    users.add(newUser);
    fees.add(FeeModel(
      studentId: studentId,
      studentName: newUser.name,
      className: assignedClass,
      month: 'September 2026',
      amount: 2500,
      isPaid: false,
      date: 'Pending',
    ));
    notifyListeners();
  }

  void updateStudent(UserModel student) {
    final index = users.indexWhere((u) => u.id == student.id);
    if (index != -1) {
      users[index] = student;
      notifyListeners();
    }
  }

  void addTestSeries(TestSeriesModel test) {
    testSeriesList.insert(0, test);
    notices.insert(
      0,
      NoticeModel(
        id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Live Test: ${test.title}',
        date: 'Today',
        description: 'Duration: ${test.durationMinutes} mins | Total Marks: ${test.totalMarks}. Proctored mode enabled.',
        category: 'Exam',
      ),
    );
    notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Live Test Scheduled',
        time: 'Just now',
        description: '${test.title} for ${test.className}.',
        type: 'test',
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
      studentId: user.id,
      studentName: user.name,
      className: assignedClass,
      month: 'September 2026',
      amount: 2500,
      isPaid: false,
      date: 'Pending',
    ));
    notifyListeners();
  }

  void rejectStudent(String studentId) {
    final user = users.firstWhere((u) => u.id == studentId);
    user.status = 'rejected';
    notifyListeners();
  }

  void addNote(NoteModel note) {
    notes.insert(0, note);
    notices.insert(
      0,
      NoticeModel(
        id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Note: ${note.title}',
        date: 'Today',
        description: 'New study material published for ${note.className} in ${note.subject}.',
        category: 'Academics',
      ),
    );
    notifications.insert(
      0,
      NotificationModel(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Note Uploaded',
        time: 'Just now',
        description: '${note.uploadedBy} uploaded ${note.title}.',
        type: 'note',
      ),
    );
    notifyListeners();
  }

  void updateFeeStatus(String studentId, String month, bool isPaid) {
    final fee = fees.firstWhere((f) => f.studentId == studentId && f.month == month, orElse: () => fees.first);
    fee.isPaid = isPaid;
    fee.date = isPaid ? 'Today' : 'Pending';
    notifyListeners();
  }

  void markAttendance({required String studentId, required String studentName, required String className, required DateTime date, required String status, required String markedBy}) {
    attendanceRecords.removeWhere((r) => r.studentId == studentId && r.date.year == date.year && r.date.month == date.month && r.date.day == date.day);
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
}
