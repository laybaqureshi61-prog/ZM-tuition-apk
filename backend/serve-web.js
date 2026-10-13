const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
app.use(cors());

// Disable caching for development & hot updates so phone always gets fresh code
app.use((req, res, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  console.log(`[PHONE/WEB] ${req.method} ${req.url} - ${req.ip}`);
  next();
});

const buildDir = path.join(__dirname, '../zm_app/build/web');
app.use(express.static(buildDir, {
  etag: false,
  maxAge: 0,
}));

app.use((req, res) => {
  res.sendFile(path.join(buildDir, 'index.html'));
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`ZM Tuition Web Server running on port ${PORT} (0.0.0.0)`);
  console.log(`Open on phone: http://192.168.1.3:${PORT}`);
});
