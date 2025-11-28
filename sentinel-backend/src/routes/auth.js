const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Register new user
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/),
  body('fullName').trim().isLength({ min: 2, max: 100 }),
  body('phoneNumber').optional().isMobilePhone(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        details: errors.array(),
      });
    }

    const { email, password, fullName, phoneNumber, dateOfBirth, emergencyMedicalInfo } = req.body;

    // Check if user already exists
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'User Already Exists',
        message: 'An account with this email already exists',
      });
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const insertQuery = `
      INSERT INTO users (email, password_hash, full_name, phone_number, date_of_birth, emergency_medical_info)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, email, full_name, phone_number, created_at
    `;
    
    const result = await pool.query(insertQuery, [
      email,
      passwordHash,
      fullName,
      phoneNumber || null,
      dateOfBirth || null,
      emergencyMedicalInfo || null,
    ]);

    const user = result.rows[0];

    // Create default user settings
    const settingsQuery = `
      INSERT INTO user_settings (user_id)
      VALUES ($1)
    `;
    await pool.query(settingsQuery, [user.id]);

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        phoneNumber: user.phone_number,
        createdAt: user.created_at,
      },
      token,
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to register user',
    });
  }
});

// Login user
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        details: errors.array(),
      });
    }

    const { email, password } = req.body;

    // Find user
    const userQuery = `
      SELECT id, email, password_hash, full_name, phone_number, is_active, email_verified
      FROM users 
      WHERE email = $1
    `;
    const userResult = await pool.query(userQuery, [email]);

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        error: 'Authentication Failed',
        message: 'Invalid email or password',
      });
    }

    const user = userResult.rows[0];

    if (!user.is_active) {
      return res.status(401).json({
        error: 'Account Disabled',
        message: 'Your account has been disabled. Please contact support.',
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Authentication Failed',
        message: 'Invalid email or password',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Update last login
    await pool.query(
      'UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = $1',
      [user.id]
    );

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        phoneNumber: user.phone_number,
        emailVerified: user.email_verified,
      },
      token,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to login',
    });
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const userQuery = `
      SELECT u.id, u.email, u.full_name, u.phone_number, u.date_of_birth, 
             u.emergency_medical_info, u.profile_picture_url, u.email_verified,
             u.created_at, u.updated_at,
             s.enable_location_sharing, s.auto_contact_police, s.enable_vibration,
             s.enable_sound_alerts, s.enable_push_notifications, s.alert_delay_seconds,
             s.share_location_with_contacts, s.enable_quick_dial, s.require_pin_on_startup,
             s.enable_biometric_auth, s.enable_stealth_mode, s.auto_lock_minutes
      FROM users u
      LEFT JOIN user_settings s ON u.id = s.user_id
      WHERE u.id = $1
    `;
    
    const result = await pool.query(userQuery, [req.user.id]);
    const user = result.rows[0];

    if (!user) {
      return res.status(404).json({
        error: 'User Not Found',
        message: 'User profile not found',
      });
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        phoneNumber: user.phone_number,
        dateOfBirth: user.date_of_birth,
        emergencyMedicalInfo: user.emergency_medical_info,
        profilePictureUrl: user.profile_picture_url,
        emailVerified: user.email_verified,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
        settings: {
          enableLocationSharing: user.enable_location_sharing,
          autoContactPolice: user.auto_contact_police,
          enableVibration: user.enable_vibration,
          enableSoundAlerts: user.enable_sound_alerts,
          enablePushNotifications: user.enable_push_notifications,
          alertDelaySeconds: user.alert_delay_seconds,
          shareLocationWithContacts: user.share_location_with_contacts,
          enableQuickDial: user.enable_quick_dial,
          requirePinOnStartup: user.require_pin_on_startup,
          enableBiometricAuth: user.enable_biometric_auth,
          enableStealthMode: user.enable_stealth_mode,
          autoLockMinutes: user.auto_lock_minutes,
        },
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get user profile',
    });
  }
});

// Logout (invalidate token - in a real app, you'd maintain a blacklist)
router.post('/logout', authenticateToken, (req, res) => {
  // In a production app, you would add the token to a blacklist in Redis
  res.json({
    message: 'Logged out successfully',
  });
});

module.exports = router;