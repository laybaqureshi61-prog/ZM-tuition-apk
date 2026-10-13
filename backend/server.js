require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRoutesV2 = require('./routes/authRoutesV2');
const authRoutesLegacy = require('./routes/authRoutes');
const tuitionRoutes = require('./routes/tuitionRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Request Logger
app.use((req, res, next) => {
  console.log(`[HTTP REQ] ${req.method} ${req.url}`, req.body);
  next();
});

// PRD Version 2.0 Auth Routes
app.use('/api/v1/auth', authRoutesV2);

// Backward Compatibility Routes
app.use('/api/auth', authRoutesV2);
app.use('/api/legacy/auth', authRoutesLegacy);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'ZM Tuition Backend (PRD v2.0 Auth Active)',
    time: new Date(),
  });
});

// Tuition Management Routes
app.use('/api', tuitionRoutes);

// Serve Flutter Web release build
const path = require('path');
const buildDir = path.join(__dirname, '../zm_app/build/web');
app.use(express.static(buildDir));

app.use((req, res, next) => {
  if (req.url.startsWith('/api')) return next();
  res.sendFile(path.join(buildDir, 'index.html'));
});

// MongoDB connection
if (process.env.MONGO_URI) {
  mongoose.connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 2000,
  })
  .then(() => {
    console.log('MongoDB connected successfully');
  })
  .catch((err) => {
    console.log('MongoDB not reachable. Running with persistent JSON database engine (data/store.json).');
  });
}

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`ZM Tuition Backend Server running on port ${PORT} (0.0.0.0)`);
});
