const express = require('express');
const app = express();
const PORT = 3000;

console.log('🚀 Starting simple test server...');

app.get('/health', (req, res) => {
  console.log('📊 Health endpoint called');
  res.json({ 
    status: 'OK', 
    message: 'Test server is working!',
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

app.get('/', (req, res) => {
  res.json({ 
    message: 'Sentinel Backend Test Server',
    endpoints: ['/health']
  });
});

const server = app.listen(PORT, () => {
  console.log(`✅ Test server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🏠 Root: http://localhost:${PORT}/`);
});

server.on('error', (err) => {
  console.error('❌ Server error:', err);
  if (err.code === 'EADDRINUSE') {
    console.log(`Port ${PORT} is already in use. Trying port ${PORT + 1}...`);
    server.listen(PORT + 1);
  }
});