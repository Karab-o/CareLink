/**
 * Sentinel Backend Server
 * Clean, secure, and production-ready
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose'); 
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
require('dotenv').config();


// Database (UPDATED ✔)
const connectDB = require('./config/db'); 

// 1️⃣ Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
.then(() => console.log('MongoDB connected'))
.catch(err => console.error('MongoDB connection error:', err));

// WebSocket
const SocketService = require('./services/socketService');

// Routes
const authRoutes = require('./routes/auth');
const contactRoutes = require('./routes/contacts');
const alertRoutes = require('./routes/alerts');

const app = express();
const server = createServer(app);

// WebSocket instance
const socketService = new SocketService(server);

/* ==========================================================
   SECURITY MIDDLEWARE
========================================================== */

connectDB();

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  })
);

// CORS configuration

   app.use(cors({
  origin: '*', // Allow all origins (for development)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

/* ==========================================================
   RATE LIMITING
========================================================== */

// Global rate limiter
app.use(
  rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: {
      error: 'Too Many Requests',
      message: 'Too many requests, try again later.',
    },
  })
);

// Auth-specific limiter
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: {
    error: 'Too Many Authentication Attempts',
    message: 'Too many login attempts, try again later.',
  },
});

/* ==========================================================
   PARSERS & LOGGING
========================================================== */

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('combined'));

// Attach Request ID
app.use((req, res, next) => {
  req.id = Math.random().toString(36).substr(2, 9);
  res.setHeader('X-Request-ID', req.id);
  next();
});

/* ==========================================================
   SYSTEM ENDPOINTS
========================================================== */

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Sentinel Backend API running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0',
    services: {
      database: 'connected',
      websocket: 'active',
      connectedUsers: socketService.getConnectedUsersCount(),
    },
  });
});

app.get('/api', (req, res) => {
  res.json({
    name: 'Sentinel Personal Safety API',
    version: '1.0.0',
    description: 'Backend API for Sentinel App',
    documentation: 'https://docs.sentinel-app.com',
  });
});

/* ==========================================================
   API ROUTES
========================================================== */

app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/alerts', alertRoutes);

app.get('/api/socket/status', (req, res) => {
  res.json({
    connected: socketService.getConnectedUsersCount(),
    users: socketService.getConnectedUsers(),
  });
});

/* ==========================================================
   ERROR HANDLING
========================================================== */

app.use((err, req, res, next) => {
  console.error(`❌ Error [${req.id}]:`, err.stack);

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      error: 'Invalid JSON',
      message: 'Check your request body format',
      requestId: req.id,
    });
  }

  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: err.message,
      requestId: req.id,
    });
  }

  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message:
      process.env.NODE_ENV === 'development'
        ? err.message
        : 'Something went wrong',
    requestId: req.id,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// 404 handler
app.use( (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
    requestId: req.id,
  });
});

/* ==========================================================
   SERVER STARTUP
========================================================== */

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    console.log('🚀 Starting Sentinel Backend...');

    // Connect to MongoDB (UPDATED ✔)
    await connectDB();

    // Start Server
    server.listen(PORT, () => {
      console.log('====================================');
      console.log('🚀 Sentinel Backend Server Started!');
      console.log('====================================');
      console.log(`📍 Server: http://localhost:${PORT}`);
      console.log(`📊 Health: http://localhost:${PORT}/health`);
      console.log(`🔗 API: http://localhost:${PORT}/api`);
      console.log(`🌐 WebSocket: ws://localhost:${PORT}`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log('====================================');
    });
  } catch (err) {
    console.error('❌ Server failed to start:', err);
    process.exit(1);
  }
};

/* ==========================================================
   SHUTDOWN HANDLERS
========================================================== */

const gracefulShutdown = (signal) => {
  console.log(`\n📴 ${signal} received, shutting down...`);

  server.close(() => {
    console.log('✅ Server closed');
    console.log('🔌 Shutdown complete');
    process.exit(0);
  });

  setTimeout(() => {
    console.error('❌ Force shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled Promise Rejection:', reason);
});

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

startServer();

module.exports = { app, server, socketService };
