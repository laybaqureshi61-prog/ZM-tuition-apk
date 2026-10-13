const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '..', 'data');
const dbFile = path.join(dataDir, 'store.json');

// Ensure data folder exists
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Initial seed data
const initialData = {
  users: [
    {
      id: 'admin_zoya',
      full_name: 'Zoya',
      name: 'Zoya',
      email: 'zoya@zmtuition.com',
      phone: '+919876543201',
      password_hash: '$2b$12$Nq7z8pEw5pI2k5p6a2m2tOhjK9aZ8q1E2g3h4j5k6l7m8n9o0p1q',
      is_phone_verified: true,
      is_email_verified: true,
      is_active: true,
      role: 'admin',
      adminType: 'zoya',
      department: 'Commerce',
      batch: 'Class 11 & 12 (Commerce)',
      isVerified: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      id: 'admin_muskan',
      full_name: 'Muskan',
      name: 'Muskan',
      email: 'muskan@zmtuition.com',
      phone: '+919876543202',
      password_hash: '$2b$12$Nq7z8pEw5pI2k5p6a2m2tOhjK9aZ8q1E2g3h4j5k6l7m8n9o0p1q',
      is_phone_verified: true,
      is_email_verified: true,
      is_active: true,
      role: 'admin',
      adminType: 'muskan',
      department: 'Maths and Science',
      batch: 'Class 9 & 10',
      isVerified: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ],
  user_sessions: [],
  otps: [],
  batches: [
    {
      id: 'b1',
      name: 'Class 11 & 12 (Commerce)',
      subject: 'Commerce & Accounts',
      time: '3:00 PM - 4:00 PM',
      teacher: 'Zoya',
      fee: 1000,
    },
    {
      id: 'b2',
      name: 'Class 9 (Maths & Science)',
      subject: 'Maths & Science',
      time: '4:00 PM - 5:00 PM',
      teacher: 'Muskan',
      fee: 600,
    },
    {
      id: 'b3',
      name: 'Class 10 (Maths & Science)',
      subject: 'Maths & Science',
      time: '4:00 PM - 5:00 PM',
      teacher: 'Muskan',
      fee: 600,
    },
    {
      id: 'b4',
      name: 'Class 11 & 12 (Maths & Science)',
      subject: 'Physics, Chemistry & Maths',
      time: '5:00 PM - 6:00 PM',
      teacher: 'Muskan',
      fee: 1000,
    },
  ],
  attendance: {
    // date -> { studentId: 'P' | 'A' | 'L' }
  },
  notes: [
    {
      id: 'n1',
      title: 'Chapter 1: Real Numbers & Polynomials',
      subject: 'Mathematics',
      batch: 'Class 10 (Maths & Science)',
      description: 'Comprehensive formula sheet and exercise solutions.',
      link: 'https://example.com/maths-ch1-notes.pdf',
      addedBy: 'Muskan',
      date: '2026-10-08',
    },
    {
      id: 'n2',
      title: 'Accounts: Partnership Fundamentals & Goodwill',
      subject: 'Accounts',
      batch: 'Class 11 & 12 (Commerce)',
      description: 'Important journal entries and ledger balance formats.',
      link: 'https://example.com/commerce-ch1-notes.pdf',
      addedBy: 'Zoya',
      date: '2026-10-09',
    },
    {
      id: 'n3',
      title: 'Science: Chemical Reactions and Equations',
      subject: 'Science',
      batch: 'Class 10 (Maths & Science)',
      description: 'Handwritten key summary and NCERT question bank.',
      link: 'https://example.com/science-ch1-notes.pdf',
      addedBy: 'Muskan',
      date: '2026-10-10',
    },
  ],
  fees: [
    {
      id: 'f1',
      studentId: 'sample1',
      studentName: 'Aman Kumar',
      phone: '9876543210',
      batch: 'Class 10 (Maths & Science)',
      month: 'October 2026',
      amount: 600,
      due: 0,
      status: 'Paid',
      date: '2026-10-05',
    },
  ],
  tests: [
    {
      id: 't1',
      title: 'Mathematics Unit Test 1 (Algebra)',
      subject: 'Mathematics',
      batch: 'Class 10 (Maths & Science)',
      totalMarks: 50,
      date: '2026-10-14',
      scores: [
        { studentName: 'Aman Kumar', roll: '101', marks: 44 },
      ],
    },
    {
      id: 't2',
      title: 'Accounts Balance Sheet Test',
      subject: 'Accounts',
      batch: 'Class 11 & 12 (Commerce)',
      totalMarks: 40,
      date: '2026-10-16',
      scores: [],
    },
  ],
  notices: [
    {
      id: 'nt1',
      title: 'Upcoming Saturday Maths Test',
      content: 'Chapter 3 & 4 test will be conducted this Saturday sharp at 4:00 PM. Bring formula sheets.',
      date: '2026-10-10',
      teacher: 'Muskan',
      department: 'Maths and Science',
    },
    {
      id: 'nt2',
      title: 'Commerce Accounts Project Submission',
      content: 'Class 12 Commerce students must submit their partnership practical files by Monday.',
      date: '2026-10-09',
      teacher: 'Zoya',
      department: 'Commerce',
    },
  ],
};

function readDb() {
  try {
    if (!fs.existsSync(dbFile)) {
      fs.writeFileSync(dbFile, JSON.stringify(initialData, null, 2), 'utf-8');
      return initialData;
    }
    const content = fs.readFileSync(dbFile, 'utf-8');
    return JSON.parse(content);
  } catch (err) {
    console.error('Error reading db.json:', err);
    return initialData;
  }
}

function writeDb(data) {
  try {
    const tempFile = `${dbFile}.tmp`;
    const jsonStr = JSON.stringify(data, null, 2);
    fs.writeFileSync(tempFile, jsonStr, 'utf-8');
    fs.renameSync(tempFile, dbFile);
    return true;
  } catch (err) {
    try {
      fs.writeFileSync(dbFile, JSON.stringify(data, null, 2), 'utf-8');
      return true;
    } catch (writeErr) {
      console.error('Fatal Error writing store.json:', writeErr);
      return false;
    }
  }
}

module.exports = {
  readDb,
  writeDb,
};
