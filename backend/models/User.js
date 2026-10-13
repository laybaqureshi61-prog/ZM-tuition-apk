const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['student', 'admin'], default: 'student' },
  adminType: { type: String, enum: ['zoya', 'muskan', null], default: null }, // 'zoya' = Commerce, 'muskan' = Maths & Science
  department: { type: String, default: '' }, // 'Commerce' or 'Maths and Science'
  batch: { type: String, default: '' }, // For student
  isVerified: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
