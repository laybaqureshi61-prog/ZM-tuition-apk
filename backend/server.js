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
const fs = require('fs');
const buildDir = fs.existsSync(path.join(__dirname, 'public'))
  ? path.join(__dirname, 'public')
  : path.join(__dirname, '../zm_app/build/web');

if (fs.existsSync(buildDir)) {
  console.log(`[STATIC] Serving Flutter Web frontend from: ${buildDir}`);
  app.use(express.static(buildDir));

  // Dedicated handler for missing asset manifests to prevent Flutter JSON parse errors
  app.get(['/assets/AssetManifest.json', '/AssetManifest.json'], (req, res) => {
    res.json({});
  });

  // Catch-all 404 for API endpoints (always JSON, never HTML)
  app.use('/api', (req, res) => {
    res.status(404).json({ error: 'API route not found', path: req.originalUrl });
  });

  // SPA fallback for HTML page navigations only
  app.use((req, res, next) => {
    if (req.path.includes('.') || req.path.startsWith('/assets/')) {
      return res.status(404).send('Not Found');
    }
    res.sendFile(path.join(buildDir, 'index.html'));
  });
} else {
  console.log(`[STATIC] Warning: Web build directory not found at ${buildDir}`);
}

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
