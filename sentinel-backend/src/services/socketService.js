const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

class SocketService {
  constructor(server) {
    this.io = new Server(server, {
      cors: {
        origin: process.env.NODE_ENV === 'production' 
          ? ['https://your-frontend-domain.com'] 
          : ['http://localhost:3000', 'http://127.0.0.1:3000'],
        methods: ['GET', 'POST'],
      },
    });

    this.connectedUsers = new Map(); // userId -> socketId mapping
    this.setupSocketHandlers();
    console.log('✅ WebSocket service initialized');
  }

  setupSocketHandlers() {
    // Authentication middleware for sockets
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token;
        if (!token) {
          return next(new Error('Authentication error: No token provided'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId);
        
        if (!user) {
          return next(new Error('Authentication error: User not found'));
        }

        socket.userId = user.id;
        socket.user = user;
        next();
      } catch (error) {
        next(new Error('Authentication error: Invalid token'));
      }
    });

    this.io.on('connection', (socket) => {
      console.log(`👤 User connected: ${socket.user.full_name} (${socket.userId})`);
      
      // Store user connection
      this.connectedUsers.set(socket.userId, socket.id);
      
      // Join user to their personal room
      socket.join(`user-${socket.userId}`);
      
      // Handle emergency alert broadcasting
      socket.on('emergency-alert', (alertData) => {
        this.handleEmergencyAlert(socket, alertData);
      });

      // Handle location updates during emergencies
      socket.on('location-update', (locationData) => {
        this.handleLocationUpdate(socket, locationData);
      });

      // Handle alert acknowledgment
      socket.on('acknowledge-alert', (alertId) => {
        this.handleAlertAcknowledgment(socket, alertId);
      });

      // Handle user status updates
      socket.on('status-update', (status) => {
        this.handleStatusUpdate(socket, status);
      });

      // Handle disconnection
      socket.on('disconnect', () => {
        console.log(`👤 User disconnected: ${socket.user.full_name} (${socket.userId})`);
        this.connectedUsers.delete(socket.userId);
      });

      // Send welcome message
      socket.emit('connected', {
        message: 'Connected to Sentinel Safety Network',
        userId: socket.userId,
        timestamp: new Date().toISOString(),
      });
    });
  }

  // Handle emergency alert broadcasting
  handleEmergencyAlert(socket, alertData) {
    console.log(`🚨 Emergency alert from ${socket.user.full_name}:`, alertData);

    // Broadcast to emergency contacts if they're online
    if (alertData.contactIds && alertData.contactIds.length > 0) {
      alertData.contactIds.forEach(contactUserId => {
        this.io.to(`user-${contactUserId}`).emit('emergency-notification', {
          type: 'emergency_alert',
          alert: {
            id: alertData.id,
            type: alertData.alertType,
            message: alertData.message,
            location: alertData.location,
            user: {
              id: socket.userId,
              name: socket.user.full_name,
              phone: socket.user.phone_number,
            },
          },
          timestamp: new Date().toISOString(),
        });
      });
    }

    // Acknowledge receipt
    socket.emit('alert-sent', {
      alertId: alertData.id,
      status: 'broadcasted',
      timestamp: new Date().toISOString(),
    });
  }

  // Handle location updates during emergencies
  handleLocationUpdate(socket, locationData) {
    console.log(`📍 Location update from ${socket.user.full_name}:`, locationData);

    // Broadcast location updates to authorized contacts
    if (locationData.alertId) {
      this.io.to(`alert-${locationData.alertId}`).emit('location-update', {
        alertId: locationData.alertId,
        location: {
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          accuracy: locationData.accuracy,
          address: locationData.address,
        },
        user: {
          id: socket.userId,
          name: socket.user.full_name,
        },
        timestamp: new Date().toISOString(),
      });
    }
  }

  // Handle alert acknowledgment
  handleAlertAcknowledgment(socket, alertId) {
    console.log(`✅ Alert acknowledged by ${socket.user.full_name}: ${alertId}`);

    // Notify the alert sender that someone acknowledged
    this.io.to(`alert-${alertId}`).emit('alert-acknowledged', {
      alertId: alertId,
      acknowledgedBy: {
        id: socket.userId,
        name: socket.user.full_name,
      },
      timestamp: new Date().toISOString(),
    });
  }

  // Handle user status updates
  handleStatusUpdate(socket, status) {
    console.log(`📊 Status update from ${socket.user.full_name}:`, status);

    // Broadcast status to relevant contacts
    socket.broadcast.emit('user-status-update', {
      userId: socket.userId,
      userName: socket.user.full_name,
      status: status,
      timestamp: new Date().toISOString(),
    });
  }

  // Send notification to specific user
  sendNotificationToUser(userId, notification) {
    const socketId = this.connectedUsers.get(userId);
    if (socketId) {
      this.io.to(socketId).emit('notification', notification);
      return true;
    }
    return false; // User not connected
  }

  // Broadcast emergency alert to multiple users
  broadcastEmergencyAlert(userIds, alertData) {
    userIds.forEach(userId => {
      this.io.to(`user-${userId}`).emit('emergency-notification', alertData);
    });
  }

  // Get connected users count
  getConnectedUsersCount() {
    return this.connectedUsers.size;
  }

  // Get connected users list
  getConnectedUsers() {
    return Array.from(this.connectedUsers.keys());
  }
}

module.exports = SocketService;