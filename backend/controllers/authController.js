const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { readDb, writeDb } = require('../utils/db');
const sendOtp = require('../utils/sendOtp');

const JWT_SECRET = process.env.JWT_SECRET || 'zm_tuition_super_secret_jwt_key_2026';

// Helper to generate 6-digit OTP
const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

// 1. Send OTP
exports.sendOtp = async (req, res) => {
  try {
    const { email, phone } = req.body;
    if (!email && !phone) {
      return res.status(400).json({ message: 'Phone Number or Email is required.' });
    }

    const cleanEmail = email ? email.toLowerCase().trim() : '';
    const cleanPhone = phone ? phone.trim() : '';
    const otpCode = generateOtp();

    const db = readDb();
    // Filter out existing OTPs for this email or phone
    db.otps = (db.otps || []).filter(o => {
      const matchEmail = cleanEmail && o.email === cleanEmail;
      const matchPhone = cleanPhone && o.phone === cleanPhone;
      return !matchEmail && !matchPhone;
    });

    db.otps.push({
      email: cleanEmail,
      phone: cleanPhone,
      otp: otpCode,
      expiresAt: Date.now() + 5 * 60 * 1000, // 5 minutes
    });
    writeDb(db);

    // Send via SMS and Email
    await sendOtp(cleanPhone, cleanEmail, otpCode);

    res.status(200).json({
      message: `OTP sent successfully to ${cleanEmail || cleanPhone}. Please check your inbox / spam folder.`,
    });
  } catch (err) {
    console.error('Error in sendOtp:', err);
    res.status(500).json({ message: 'Server error while sending OTP.' });
  }
};

// 2. Verify OTP
exports.verifyOtp = async (req, res) => {
  try {
    const { email, phone, otp } = req.body;
    if ((!email && !phone) || !otp) {
      return res.status(400).json({ message: 'Phone or Email and OTP code are required.' });
    }

    const cleanEmail = email ? email.toLowerCase().trim() : '';
    const cleanPhone = phone ? phone.trim() : '';
    const cleanOtp = otp.toString().trim();

    const db = readDb();
    const recordIndex = (db.otps || []).findIndex(
      o => (
        (cleanEmail && o.email === cleanEmail) ||
        (cleanPhone && o.phone === cleanPhone)
      ) && o.otp === cleanOtp && o.expiresAt > Date.now()
    );

    if (recordIndex === -1) {
      return res.status(400).json({ message: 'Invalid or expired OTP code.' });
    }

    const matchedRecord = db.otps[recordIndex];
    // Remove used OTP
    db.otps.splice(recordIndex, 1);
    writeDb(db);

    const verificationToken = jwt.sign(
      { email: cleanEmail || matchedRecord.email, phone: cleanPhone || matchedRecord.phone },
      JWT_SECRET,
      { expiresIn: '15m' }
    );

    res.status(200).json({
      message: 'OTP verified successfully.',
      verificationToken,
    });
  } catch (err) {
    console.error('Error in verifyOtp:', err);
    res.status(500).json({ message: 'Server error while verifying OTP.' });
  }
};

// 3. Register Account
exports.register = async (req, res) => {
  try {
    const { name, email, phone, password, role, adminType, batch, verificationToken } = req.body;

    if (!verificationToken) {
      return res.status(401).json({ message: 'Verification token missing. Please verify OTP first.' });
    }

    const cleanEmail = email ? email.toLowerCase().trim() : '';
    const cleanPhone = phone ? phone.trim() : '';

    // Verify token
    try {
      const decoded = jwt.verify(verificationToken, JWT_SECRET);
      if (cleanEmail && decoded.email && decoded.email !== cleanEmail) {
        return res.status(400).json({ message: 'Email does not match verification token.' });
      }
      if (cleanPhone && decoded.phone && decoded.phone !== cleanPhone) {
        return res.status(400).json({ message: 'Phone does not match verification token.' });
      }
    } catch (_) {
      return res.status(401).json({ message: 'Invalid or expired verification token.' });
    }

    const db = readDb();
    const existing = (db.users || []).find(u => 
      (cleanEmail && u.email === cleanEmail) || 
      (cleanPhone && u.phone === cleanPhone)
    );
    if (existing) {
      return res.status(400).json({ message: 'Account already registered with this phone or email.' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    let department = '';
    let selectedAdminType = null;
    if (role === 'admin') {
      selectedAdminType = adminType === 'muskan' ? 'muskan' : 'zoya';
      department = selectedAdminType === 'zoya' ? 'Commerce' : 'Maths and Science';
    }

    const newUser = {
      id: 'u_' + Date.now(),
      name: name.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      password: hashedPassword,
      role: role || 'student',
      adminType: selectedAdminType,
      department,
      batch: batch || 'Class 10 (Maths & Science)',
      isVerified: true,
      createdAt: new Date().toISOString(),
    };

    db.users.push(newUser);

    // If student, initialize initial fee and attendance entry
    if (newUser.role === 'student') {
      db.fees = db.fees || [];
      db.fees.push({
        id: 'f_' + Date.now(),
        studentId: newUser.id,
        studentName: newUser.name,
        phone: newUser.phone,
        batch: newUser.batch,
        month: 'October 2026',
        amount: newUser.batch.includes('Commerce') || newUser.batch.includes('11 & 12') ? 1000 : 500,
        due: newUser.batch.includes('Commerce') || newUser.batch.includes('11 & 12') ? 1000 : 500,
        status: 'Due',
        date: new Date().toISOString().slice(0, 10),
      });
    }

    writeDb(db);

    res.status(201).json({
      message: 'Account registered successfully with phone ' + cleanPhone,
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone,
        role: newUser.role,
        adminType: newUser.adminType,
        department: newUser.department,
        batch: newUser.batch,
      },
    });
  } catch (err) {
    console.error('Error in register:', err);
    res.status(500).json({ message: 'Server error during registration.' });
  }
};

// 4. Login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Please enter Email/Phone and Password.' });
    }

    const cleanInput = email.toLowerCase().trim();
    const db = readDb();

    // Support logging in via either email OR phone number
    const user = (db.users || []).find(
      u => u.email.toLowerCase() === cleanInput || u.phone === cleanInput
    );

    if (!user) {
      return res.status(404).json({ message: 'No registered user found with this email/phone.' });
    }

    // Default master password check for seeded admins if password not set yet
    let isMatch = false;
    if (!user.password && (user.adminType === 'zoya' || user.adminType === 'muskan')) {
      isMatch = true; // allow initial login for seeded admins
    } else {
      isMatch = await bcrypt.compare(password, user.password);
    }

    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect password. Please try again.' });
    }

    const token = jwt.sign(
      {
        id: user.id,
        role: user.role,
        phone: user.phone,
        email: user.email,
        adminType: user.adminType,
        department: user.department,
        batch: user.batch,
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(200).json({
      message: 'Login successful.',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        adminType: user.adminType,
        department: user.department,
        batch: user.batch,
      },
    });
  } catch (err) {
    console.error('Error in login:', err);
    res.status(500).json({ message: 'Server error during login.' });
  }
};

// 5. Auth Middleware
exports.requireAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authentication required. Please log in.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (_) {
    return res.status(401).json({ message: 'Session expired. Please log in again.' });
  }
};

// 6. Reset Password
exports.resetPassword = async (req, res) => {
  try {
    const { email, phone, newPassword, verificationToken } = req.body;
    if (!verificationToken) {
      return res.status(401).json({ message: 'Verification token required. Please verify OTP first.' });
    }
    const cleanEmail = email ? email.toLowerCase().trim() : '';
    const cleanPhone = phone ? phone.trim() : '';
    try {
      const decoded = jwt.verify(verificationToken, JWT_SECRET);
      if (cleanEmail && decoded.email && decoded.email !== cleanEmail) {
        return res.status(400).json({ message: 'Email does not match verification token.' });
      }
      if (cleanPhone && decoded.phone && decoded.phone !== cleanPhone) {
        return res.status(400).json({ message: 'Phone does not match verification token.' });
      }
    } catch (_) {
      return res.status(401).json({ message: 'Invalid or expired verification token.' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    const db = readDb();
    const user = (db.users || []).find(u => 
      (cleanEmail && u.email === cleanEmail) ||
      (cleanPhone && u.phone === cleanPhone)
    );
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }
    user.password = hashedPassword;
    writeDb(db);

    res.status(200).json({ message: 'Password reset successfully.' });
  } catch (err) {
    console.error('Error in resetPassword:', err);
    res.status(500).json({ message: 'Server error while resetting password.' });
  }
};
