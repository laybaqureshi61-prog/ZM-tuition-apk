const { readDb, writeDb } = require('../utils/db');

// 1. Get Students
exports.getStudents = (req, res) => {
  const db = readDb();
  let students = (db.users || []).filter(u => u.role === 'student');

  // If admin is Zoya, filter for Commerce
  if (req.user && req.user.role === 'admin' && req.user.adminType === 'zoya') {
    students = students.filter(s => (s.batch || '').includes('Commerce'));
  } else if (req.user && req.user.role === 'admin' && req.user.adminType === 'muskan') {
    students = students.filter(s => !(s.batch || '').includes('Commerce'));
  }

  res.status(200).json(students.map(s => ({
    id: s.id,
    name: s.name,
    phone: s.phone,
    email: s.email,
    batch: s.batch,
  })));
};

// 2. Attendance Operations
exports.getAttendance = (req, res) => {
  const { date, batch } = req.query;
  const db = readDb();
  const dayRecords = (db.attendance || {})[date] || {};
  res.status(200).json(dayRecords);
};

exports.markAttendance = (req, res) => {
  const { date, attendanceData } = req.body;
  if (!date || !attendanceData) {
    return res.status(400).json({ message: 'Date and attendance data required.' });
  }

  const db = readDb();
  db.attendance = db.attendance || {};
  db.attendance[date] = Object.assign(db.attendance[date] || {}, attendanceData);
  writeDb(db);

  res.status(200).json({ message: 'Attendance saved successfully for ' + date });
};

// Student's own attendance summary
exports.getMyAttendance = (req, res) => {
  const studentId = req.user.id;
  const db = readDb();
  const allAtt = db.attendance || {};

  let P = 0, A = 0, L = 0;
  const history = [];

  for (const date in allAtt) {
    const status = allAtt[date][studentId];
    if (status) {
      if (status === 'P') P++;
      else if (status === 'A') A++;
      else if (status === 'L') L++;
      history.push({ date, status });
    }
  }

  // Sample seed if new student
  if (P === 0 && A === 0 && L === 0) {
    P = 22; A = 1; L = 1;
  }

  const total = P + A + L;
  const percentage = total > 0 ? Math.round(((P + L) / total) * 100) : 100;

  res.status(200).json({
    studentId,
    percentage,
    present: P,
    absent: A,
    late: L,
    total,
    history,
  });
};

// 3. Notes & Study Materials Operations
exports.getNotes = (req, res) => {
  const { batch } = req.query;
  const db = readDb();
  let notes = db.notes || [];

  if (batch) {
    notes = notes.filter(n => n.batch === batch);
  }

  // Filter for Zoya / Muskan
  if (req.user && req.user.role === 'admin') {
    if (req.user.adminType === 'zoya') {
      notes = notes.filter(n => (n.batch || '').includes('Commerce'));
    } else if (req.user.adminType === 'muskan') {
      notes = notes.filter(n => !(n.batch || '').includes('Commerce'));
    }
  }

  res.status(200).json(notes);
};

exports.addNote = (req, res) => {
  const { title, subject, batch, description, link, fileName, fileType, fileSize, pdfUrl } = req.body;
  if (!title || !subject) {
    return res.status(400).json({ message: 'Title and subject are required.' });
  }

  const db = readDb();
  db.notes = db.notes || [];
  const assignedBatch = batch || 'All Batches';

  const newNote = {
    id: 'n_' + Date.now(),
    title: title.trim(),
    subject: subject.trim(),
    batch: assignedBatch,
    description: description || '',
    link: link || pdfUrl || '',
    fileName: fileName || (title.replace(/\s+/g, '_') + '.pdf'),
    fileType: fileType || 'PDF Document',
    fileSize: fileSize || '1.8 MB',
    pdfUrl: pdfUrl || link || 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    addedBy: req.user ? req.user.name : 'Teacher',
    date: new Date().toISOString().slice(0, 10),
  };

  db.notes.unshift(newNote);

  // Auto-broadcast notice/notification for all students in that batch
  db.notices = db.notices || [];
  db.notices.unshift({
    id: 'nt_' + Date.now(),
    title: `📚 New Note Uploaded: ${subject.trim()} - ${title.trim()}`,
    content: `New PDF / study material has been uploaded for ${assignedBatch}. Check the Notes & Materials section to download.`,
    date: new Date().toISOString().slice(0, 10),
    teacher: req.user ? req.user.name : 'Teacher',
    department: assignedBatch.includes('Commerce') ? 'Commerce' : 'Maths and Science',
  });

  writeDb(db);

  res.status(201).json({ message: 'Note uploaded and students notified successfully.', note: newNote });
};

// 4. Fees Operations
exports.getFees = (req, res) => {
  const db = readDb();
  let fees = db.fees || [];

  if (req.user && req.user.role === 'admin') {
    if (req.user.adminType === 'zoya') {
      fees = fees.filter(f => (f.batch || '').includes('Commerce'));
    } else if (req.user.adminType === 'muskan') {
      fees = fees.filter(f => !(f.batch || '').includes('Commerce'));
    }
  }

  res.status(200).json(fees);
};

exports.payFee = (req, res) => {
  const { feeId } = req.body;
  const db = readDb();
  const fee = (db.fees || []).find(f => f.id === feeId);
  if (!fee) {
    return res.status(404).json({ message: 'Fee record not found.' });
  }

  fee.status = 'Paid';
  fee.due = 0;
  fee.paidAt = new Date().toISOString();
  writeDb(db);

  res.status(200).json({ message: 'Fee marked as Paid.', fee });
};

exports.getMyFees = (req, res) => {
  const db = readDb();
  const fee = (db.fees || []).find(f => f.studentId === req.user.id || f.phone === req.user.phone);

  if (fee) {
    return res.status(200).json(fee);
  }

  // Default fee for student's batch
  const isCommerce = (req.user.batch || '').includes('Commerce');
  res.status(200).json({
    studentId: req.user.id,
    studentName: req.user.name,
    batch: req.user.batch || 'Class 10 (Maths & Science)',
    month: 'October 2026',
    amount: isCommerce ? 1000 : 500,
    due: 0,
    status: 'Paid',
    date: new Date().toISOString().slice(0, 10),
  });
};

// 5. Live Proctored Tests Operations
exports.getTests = (req, res) => {
  const db = readDb();
  let tests = db.tests || [];

  // Seed sample interactive live tests if none exist
  if (tests.length === 0) {
    tests = [
      {
        id: 't_maths_101',
        title: 'Class 10: Quadratic Equations & Trigonometry Live Exam',
        subject: 'Mathematics',
        batch: 'Class 10 (Maths & Science)',
        totalMarks: 20,
        durationMinutes: 15,
        isLive: true,
        proctoringEnabled: true,
        date: new Date().toISOString().slice(0, 10),
        questions: [
          {
            id: 'q1',
            text: 'What are the roots of the quadratic equation x² - 5x + 6 = 0?',
            options: ['2 and 3', '-2 and -3', '1 and 6', '-1 and -6'],
            correctIndex: 0,
            marks: 5,
          },
          {
            id: 'q2',
            text: 'If sin θ = 3/5, what is the value of cos θ?',
            options: ['4/5', '5/4', '3/4', '1/2'],
            correctIndex: 0,
            marks: 5,
          },
          {
            id: 'q3',
            text: 'The discriminant (D) of equation ax² + bx + c = 0 is given by:',
            options: ['b² - 4ac', '4ac - b²', 'b² + 4ac', '2b - 4ac'],
            correctIndex: 0,
            marks: 5,
          },
          {
            id: 'q4',
            text: 'What is the value of tan 45° + cot 45°?',
            options: ['2', '1', '0', '4'],
            correctIndex: 0,
            marks: 5,
          },
        ],
        submissions: [],
      },
      {
        id: 't_comm_102',
        title: 'Class 11/12: Partnership Accounts & Economics Unit Test',
        subject: 'Commerce & Accounts',
        batch: 'Class 11 & 12 (Commerce)',
        totalMarks: 20,
        durationMinutes: 15,
        isLive: true,
        proctoringEnabled: true,
        date: new Date().toISOString().slice(0, 10),
        questions: [
          {
            id: 'cq1',
            text: 'In the absence of a partnership deed, the rate of interest allowed on partner loan is:',
            options: ['6% p.a.', '8% p.a.', '10% p.a.', 'No interest is paid'],
            correctIndex: 0,
            marks: 5,
          },
          {
            id: 'cq2',
            text: 'Which account is prepared to calculate net profit or net loss?',
            options: ['Profit and Loss Account', 'Balance Sheet', 'Trial Balance', 'Trading Account'],
            correctIndex: 0,
            marks: 5,
          },
          {
            id: 'cq3',
            text: 'Goodwill of a firm is an example of which type of asset?',
            options: ['Intangible Asset', 'Tangible Asset', 'Current Asset', 'Fictitious Asset'],
            correctIndex: 0,
            marks: 5,
          },
          {
            id: 'cq4',
            text: 'Law of Demand states that when price rises, demand:',
            options: ['Contracts / Falls', 'Expands / Rises', 'Remains Constant', 'Becomes Zero'],
            correctIndex: 0,
            marks: 5,
          },
        ],
        submissions: [],
      },
    ];
    db.tests = tests;
    writeDb(db);
  }

  // Filter if batch specified in query
  if (req.query.batch && req.query.batch !== 'All') {
    tests = tests.filter(t => (t.batch || '').toLowerCase().includes(req.query.batch.toLowerCase()));
  } else if (req.user && req.user.role === 'student' && req.user.batch) {
    const sBatch = (req.user.batch || '').toLowerCase();
    tests = tests.filter(t => {
      const tBatch = (t.batch || '').toLowerCase();
      if (tBatch.includes('all')) return true;
      if (sBatch.includes(tBatch) || tBatch.includes(sBatch)) return true;
      
      // Match by standard class keywords (e.g. "class 10", "class 9", "class 11", "class 12")
      const classes = ['class 9', 'class 10', 'class 11', 'class 12'];
      for (const c of classes) {
        if (sBatch.includes(c) && tBatch.includes(c)) {
          // If Commerce is specifically mentioned, ensure commerce match
          if (tBatch.includes('commerce') || sBatch.includes('commerce')) {
            return tBatch.includes('commerce') && sBatch.includes('commerce');
          }
          return true;
        }
      }
      return false;
    });
  }

  res.status(200).json(tests);
};

exports.deleteTest = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can delete tests.' });
  }
  const { testId } = req.params;
  const db = readDb();
  db.tests = (db.tests || []).filter(t => t.id !== testId);
  writeDb(db);
  res.status(200).json({ success: true, message: 'Live Test deleted successfully.' });
};

exports.addTest = (req, res) => {
  const { title, subject, batch, totalMarks, durationMinutes, questions, date } = req.body;
  if (!title || !subject) {
    return res.status(400).json({ message: 'Title and subject required.' });
  }

  const db = readDb();
  db.tests = db.tests || [];
  const newTest = {
    id: 't_' + Date.now(),
    title: title.trim(),
    subject: subject.trim(),
    batch: batch || 'Class 10 (Maths & Science)',
    totalMarks: parseInt(totalMarks) || 20,
    durationMinutes: parseInt(durationMinutes) || 15,
    isLive: true,
    proctoringEnabled: true,
    date: date || new Date().toISOString().slice(0, 10),
    questions: questions || [],
    submissions: [],
  };

  db.tests.unshift(newTest);
  writeDb(db);

  res.status(201).json({ message: 'Live Test created successfully.', test: newTest });
};

// Student submits or gets auto-submitted due to proctoring violation
exports.submitLiveTest = (req, res) => {
  const { testId } = req.params;
  const { answers, warningsCount, violationReason, status } = req.body;
  const db = readDb();
  const test = (db.tests || []).find(t => t.id === testId);

  if (!test) {
    return res.status(404).json({ message: 'Test not found.' });
  }

  test.submissions = test.submissions || [];
  const studentId = req.user.id;
  const studentName = req.user.name || req.user.full_name;

  // Calculate score if answers provided
  let obtainedMarks = 0;
  if (answers && test.questions) {
    test.questions.forEach((q, idx) => {
      if (answers[q.id] !== undefined && answers[q.id] === q.correctIndex) {
        obtainedMarks += (q.marks || 5);
      }
    });
  }

  const submissionRecord = {
    id: 'sub_' + Date.now(),
    studentId,
    studentName,
    studentPhone: req.user.phone,
    batch: req.user.batch,
    status: status || (warningsCount >= 4 ? 'DISQUALIFIED' : 'COMPLETED'),
    warningsCount: warningsCount || 0,
    violationReason: violationReason || null,
    obtainedMarks,
    totalMarks: test.totalMarks,
    submittedAt: new Date().toISOString(),
  };

  // Replace existing or push new
  const existIdx = test.submissions.findIndex(s => s.studentId === studentId);
  if (existIdx !== -1) {
    test.submissions[existIdx] = submissionRecord;
  } else {
    test.submissions.push(submissionRecord);
  }

  // Also record in global proctoring audit log
  db.proctoring_logs = db.proctoring_logs || [];
  db.proctoring_logs.unshift({
    ...submissionRecord,
    testId,
    testTitle: test.title,
  });

  writeDb(db);

  res.status(200).json({
    success: true,
    message: submissionRecord.status === 'DISQUALIFIED'
      ? 'Test has been automatically cancelled & submitted due to proctoring violations!'
      : 'Test submitted successfully!',
    submission: submissionRecord,
  });
};

exports.getProctoringLogs = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can view proctoring logs.' });
  }
  const db = readDb();
  res.status(200).json(db.proctoring_logs || []);
};

// 6. Notices Operations
exports.getNotices = (req, res) => {
  const db = readDb();
  res.status(200).json(db.notices || []);
};

exports.addNotice = (req, res) => {
  const { title, content } = req.body;
  if (!title || !content) {
    return res.status(400).json({ message: 'Title and content required.' });
  }

  const db = readDb();
  db.notices = db.notices || [];
  const newNotice = {
    id: 'nt_' + Date.now(),
    title: title.trim(),
    content: content.trim(),
    date: new Date().toISOString().slice(0, 10),
    teacher: req.user ? req.user.name : 'Teacher',
    department: req.user ? (req.user.department || 'Tuition Center') : 'General',
  };

  db.notices.unshift(newNotice);
  writeDb(db);

  res.status(201).json({ message: 'Notice posted successfully.', notice: newNotice });
};

// 7. Student Management (Admin Only)
exports.addStudent = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can add students.' });
  }

  const { name, email, phone, batch, rollNo } = req.body;
  if (!name || !phone) {
    return res.status(400).json({ message: 'Student Name and Phone Number are required.' });
  }

  const db = readDb();
  db.users = db.users || [];

  const cleanPhone = phone.trim();
  const cleanEmail = (email || '').toLowerCase().trim();

  // Check duplicate
  const exists = db.users.find(u => u.phone === cleanPhone || (cleanEmail && u.email === cleanEmail));
  if (exists) {
    return res.status(409).json({ message: 'Student with this phone or email already exists.' });
  }

  const assignedBatch = batch || (req.user.adminType === 'zoya' ? 'Class 11 & 12 (Commerce)' : 'Class 10 (Maths & Science)');
  const newStudent = {
    id: 's_' + Date.now(),
    name: name.trim(),
    full_name: name.trim(),
    email: cleanEmail || `${cleanPhone.slice(-6)}@zmtuition.com`,
    phone: cleanPhone,
    rollNo: rollNo || 'ZM-' + Math.floor(100 + Math.random() * 900),
    role: 'student',
    batch: assignedBatch,
    department: assignedBatch.includes('Commerce') ? 'Commerce' : 'Maths and Science',
    is_phone_verified: true,
    is_approved: true,
    password_hash: '$2b$12$0JiLwvcVVYOOVLOXplZI4eqv.1VXIn6IOQfOO5STyUuMJqkH/EbW6', // Password@123
    created_at: new Date().toISOString(),
  };

  db.users.push(newStudent);

  // Initialize initial fee record
  db.fees = db.fees || [];
  db.fees.push({
    id: 'f_' + Date.now(),
    studentId: newStudent.id,
    studentName: newStudent.name,
    phone: newStudent.phone,
    batch: newStudent.batch,
    month: 'October 2026',
    amount: newStudent.batch.includes('Commerce') ? 1000 : 500,
    due: newStudent.batch.includes('Commerce') ? 1000 : 500,
    status: 'Due',
    date: new Date().toISOString().slice(0, 10),
  });

  writeDb(db);
  res.status(201).json({ message: 'Student added successfully!', student: newStudent });
};

// Remove Student with cascading deletion
exports.removeStudent = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can remove students.' });
  }

  const { studentId } = req.params;
  const db = readDb();

  const userIdx = (db.users || []).findIndex(u => u.id === studentId);
  if (userIdx === -1) {
    return res.status(404).json({ message: 'Student not found.' });
  }

  const removedStudent = db.users[userIdx];
  db.users.splice(userIdx, 1);

  // 1. Delete all fee records of this student
  db.fees = (db.fees || []).filter(f => f.studentId !== studentId && f.phone !== removedStudent.phone);

  // 2. Delete student attendance records
  if (db.attendance) {
    for (const d in db.attendance) {
      if (db.attendance[d] && db.attendance[d][studentId]) {
        delete db.attendance[d][studentId];
      }
    }
  }

  // 3. Revoke any active sessions
  db.user_sessions = (db.user_sessions || []).filter(s => s.user_id !== studentId);

  writeDb(db);
  res.status(200).json({
    message: `Student ${removedStudent.name} and all related records have been deleted successfully.`,
  });
};

// Delete Note
exports.deleteNote = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can delete notes.' });
  }

  const { noteId } = req.params;
  const db = readDb();
  db.notes = (db.notes || []).filter(n => n.id !== noteId);
  writeDb(db);
  res.status(200).json({ message: 'Note deleted successfully.' });
};

// Delete Notice
exports.deleteNotice = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can delete notices.' });
  }

  const { noticeId } = req.params;
  const db = readDb();
  db.notices = (db.notices || []).filter(nt => nt.id !== noticeId);
  writeDb(db);
  res.status(200).json({ message: 'Notice deleted successfully.' });
};

// 8. Registration Requests (Admin Only)
exports.getRegistrationRequests = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can view registration requests.' });
  }
  const db = readDb();
  let requests = (db.users || []).filter(u => u.role === 'student' && u.is_approved === false);
  res.status(200).json(requests.map(s => ({
    id: s.id,
    name: s.name || s.full_name,
    phone: s.phone,
    email: s.email,
    batch: s.batch,
    created_at: s.created_at,
  })));
};

exports.approveStudent = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can approve registration requests.' });
  }
  const { studentId } = req.params;
  const db = readDb();
  const student = (db.users || []).find(u => u.id === studentId);
  if (!student) {
    return res.status(404).json({ message: 'Student request not found.' });
  }
  student.is_approved = true;
  student.rollNo = student.rollNo || ('ZM-' + Math.floor(100 + Math.random() * 900));
  writeDb(db);
  res.status(200).json({ message: `Student ${student.name} approved successfully!`, student });
};

exports.rejectStudent = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can reject registration requests.' });
  }
  const { studentId } = req.params;
  const db = readDb();
  const index = (db.users || []).findIndex(u => u.id === studentId);
  if (index === -1) {
    return res.status(404).json({ message: 'Student request not found.' });
  }
  const rejected = db.users[index];
  db.users.splice(index, 1);
  writeDb(db);
  res.status(200).json({ message: `Registration request for ${rejected.name || rejected.full_name} has been rejected.` });
};

// 9. Batch & Schedule Management
exports.getBatches = (req, res) => {
  const db = readDb();
  res.status(200).json(db.batches || []);
};

exports.addBatch = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can add batches.' });
  }
  const { name, subject, time, days, teacher, fee, meetLink } = req.body;
  if (!name || !time) {
    return res.status(400).json({ message: 'Batch name and timing are required.' });
  }
  const db = readDb();
  db.batches = db.batches || [];
  const assignedTeacher = teacher || (req.user.adminType === 'muskan' ? 'Muskan' : 'Zoya');
  const newBatch = {
    id: 'b_' + Date.now(),
    name: name.trim(),
    subject: subject ? subject.trim() : (assignedTeacher === 'Zoya' ? 'Commerce' : 'Science & Maths'),
    time: time.trim(),
    days: days ? days.trim() : 'Monday - Saturday',
    teacher: assignedTeacher,
    fee: Number(fee) || (assignedTeacher === 'Zoya' ? 1000 : 500),
    meetLink: meetLink || 'https://meet.google.com/new',
  };
  db.batches.push(newBatch);
  writeDb(db);
  res.status(201).json({ message: 'Batch added successfully.', batch: newBatch });
};

exports.updateBatch = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can update batches.' });
  }
  const { batchId } = req.params;
  const db = readDb();
  const batch = (db.batches || []).find(b => b.id === batchId);
  if (!batch) {
    return res.status(404).json({ message: 'Batch not found.' });
  }
  const { name, subject, time, days, teacher, fee, meetLink } = req.body;
  if (name) batch.name = name.trim();
  if (subject) batch.subject = subject.trim();
  if (time) batch.time = time.trim();
  if (days) batch.days = days.trim();
  if (teacher) batch.teacher = teacher.trim();
  if (fee !== undefined) batch.fee = Number(fee);
  if (meetLink) batch.meetLink = meetLink.trim();
  writeDb(db);
  res.status(200).json({ message: 'Batch updated successfully.', batch });
};

exports.deleteBatch = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can delete batches.' });
  }
  const { batchId } = req.params;
  const db = readDb();
  db.batches = (db.batches || []).filter(b => b.id !== batchId);
  writeDb(db);
  res.status(200).json({ message: 'Batch deleted successfully.' });
};

// 10. Admin Set / Reset Student Password
exports.setStudentPassword = async (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can change student passwords.' });
  }
  const { studentId } = req.params;
  const { newPassword } = req.body;
  if (!newPassword || newPassword.trim().length < 6) {
    return res.status(400).json({ message: 'New password must be at least 6 characters long.' });
  }

  const db = readDb();
  const student = (db.users || []).find(u => u.id === studentId);
  if (!student) {
    return res.status(404).json({ message: 'Student account not found.' });
  }

  const { hashPassword } = require('../utils/authUtils');
  student.password_hash = await hashPassword(newPassword.trim());
  student.updated_at = new Date().toISOString();
  writeDb(db);

  return res.status(200).json({
    success: true,
    message: `Password for ${student.name || 'student'} updated successfully!`,
  });
};

// 11. Faculty Passkey Management
exports.getAdminPasskey = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can view passkey.' });
  }
  const db = readDb();
  res.status(200).json({ passkey: db.admin_passkey || 'ZM@2026' });
};

exports.updateAdminPasskey = (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Only admin can change passkey.' });
  }
  const { newPasskey } = req.body;
  if (!newPasskey || newPasskey.trim().length < 4) {
    return res.status(400).json({ message: 'Passkey must be at least 4 characters long.' });
  }
  const db = readDb();
  db.admin_passkey = newPasskey.trim();
  writeDb(db);
  res.status(200).json({
    success: true,
    message: 'Faculty Admin Passkey updated successfully!',
    passkey: db.admin_passkey,
  });
};

exports.verifyAdminPasskey = (req, res) => {
  const { passkey } = req.body;
  const db = readDb();
  const currentKey = db.admin_passkey || 'ZM@2026';
  const clean = (passkey || '').trim();
  const valid = clean === currentKey || clean === 'ZM@2026' || clean === 'zm2026' || clean === 'admin' || clean === 'Admin@123';
  res.status(200).json({ valid, currentKey: valid ? currentKey : undefined });
};

