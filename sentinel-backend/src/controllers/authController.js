const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { runQuery } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class AuthController {
  // Register new user
  static async register(req, res) {
    try {
      const { email, password, fullName, phoneNumber, dateOfBirth, emergencyMedicalInfo } = req.body;

      // Check if user already exists
      const existingUser = await User.findByEmail(email);
      if (existingUser) {
        return res.status(409).json({
          error: 'User Already Exists',
          message: 'An account with this email already exists',
        });
      }

      // Hash password
      const passwordHash = await User.hashPassword(password);

      // Create user
      const userData = {
        email,
        password_hash: passwordHash,
        full_name: fullName,
        phone_number: phoneNumber || null,
        date_of_birth: dateOfBirth || null,
        emergency_medical_info: emergencyMedicalInfo || null,
      };

      const user = new User(userData);
      await user.save();

      // Create default user settings
      const settingsId = uuidv4();
      await runQuery(
        'INSERT INTO user_settings (id, user_id) VALUES (?, ?)',
        [settingsId, user.id]
      );

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      res.status(201).json({
        message: 'User registered successfully',
        user: user.toJSON(),
        token,
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to register user',
      });
    }
  }

  // Login user
  static async login(req, res) {
    try {
      const { email, password } = req.body;

      // Find user
      const user = await User.findByEmail(email);
      if (!user) {
        return res.status(401).json({
          error: 'Authentication Failed',
          message: 'Invalid email or password',
        });
      }

      // Verify password
      const isValidPassword = await user.verifyPassword(password);
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
      await user.update({ updated_at: new Date().toISOString() });

      res.json({
        message: 'Login successful',
        user: user.toJSON(),
        token,
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to login',
      });
    }
  }

  // Get current user profile
  static async getProfile(req, res) {
    try {
      const userWithSettings = await req.user.getWithSettings();

      if (!userWithSettings) {
        return res.status(404).json({
          error: 'User Not Found',
          message: 'User profile not found',
        });
      }

      // Structure the response
      const { password_hash, ...userProfile } = userWithSettings;
      
      res.json({
        user: {
          ...userProfile,
          settings: {
            enableLocationSharing: userProfile.enable_location_sharing,
            autoContactPolice: userProfile.auto_contact_police,
            enableVibration: userProfile.enable_vibration,
            enableSoundAlerts: userProfile.enable_sound_alerts,
            enablePushNotifications: userProfile.enable_push_notifications,
            alertDelaySeconds: userProfile.alert_delay_seconds,
            shareLocationWithContacts: userProfile.share_location_with_contacts,
            enableQuickDial: userProfile.enable_quick_dial,
            requirePinOnStartup: userProfile.require_pin_on_startup,
            enableBiometricAuth: userProfile.enable_biometric_auth,
            enableStealthMode: userProfile.enable_stealth_mode,
            autoLockMinutes: userProfile.auto_lock_minutes,
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
  }

  // Update user profile
  static async updateProfile(req, res) {
    try {
      const { fullName, phoneNumber, dateOfBirth, emergencyMedicalInfo } = req.body;

      const updateData = {};
      if (fullName !== undefined) updateData.full_name = fullName;
      if (phoneNumber !== undefined) updateData.phone_number = phoneNumber;
      if (dateOfBirth !== undefined) updateData.date_of_birth = dateOfBirth;
      if (emergencyMedicalInfo !== undefined) updateData.emergency_medical_info = emergencyMedicalInfo;

      await req.user.update(updateData);

      res.json({
        message: 'Profile updated successfully',
        user: req.user.toJSON(),
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to update profile',
      });
    }
  }

  // Update user settings
  static async updateSettings(req, res) {
    try {
      const {
        enableLocationSharing,
        autoContactPolice,
        enableVibration,
        enableSoundAlerts,
        enablePushNotifications,
        alertDelaySeconds,
        shareLocationWithContacts,
        enableQuickDial,
        requirePinOnStartup,
        enableBiometricAuth,
        enableStealthMode,
        autoLockMinutes,
      } = req.body;

      const updateData = {};
      if (enableLocationSharing !== undefined) updateData.enable_location_sharing = enableLocationSharing ? 1 : 0;
      if (autoContactPolice !== undefined) updateData.auto_contact_police = autoContactPolice ? 1 : 0;
      if (enableVibration !== undefined) updateData.enable_vibration = enableVibration ? 1 : 0;
      if (enableSoundAlerts !== undefined) updateData.enable_sound_alerts = enableSoundAlerts ? 1 : 0;
      if (enablePushNotifications !== undefined) updateData.enable_push_notifications = enablePushNotifications ? 1 : 0;
      if (alertDelaySeconds !== undefined) updateData.alert_delay_seconds = alertDelaySeconds;
      if (shareLocationWithContacts !== undefined) updateData.share_location_with_contacts = shareLocationWithContacts ? 1 : 0;
      if (enableQuickDial !== undefined) updateData.enable_quick_dial = enableQuickDial ? 1 : 0;
      if (requirePinOnStartup !== undefined) updateData.require_pin_on_startup = requirePinOnStartup ? 1 : 0;
      if (enableBiometricAuth !== undefined) updateData.enable_biometric_auth = enableBiometricAuth ? 1 : 0;
      if (enableStealthMode !== undefined) updateData.enable_stealth_mode = enableStealthMode ? 1 : 0;
      if (autoLockMinutes !== undefined) updateData.auto_lock_minutes = autoLockMinutes;

      if (Object.keys(updateData).length === 0) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'No settings to update',
        });
      }

      const fields = [];
      const values = [];

      Object.keys(updateData).forEach(key => {
        fields.push(`${key} = ?`);
        values.push(updateData[key]);
      });

      fields.push('updated_at = CURRENT_TIMESTAMP');
      values.push(req.user.id);

      const sql = `UPDATE user_settings SET ${fields.join(', ')} WHERE user_id = ?`;
      await runQuery(sql, values);

      res.json({
        message: 'Settings updated successfully',
      });
    } catch (error) {
      console.error('Update settings error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to update settings',
      });
    }
  }

  // Change password
  static async changePassword(req, res) {
    try {
      const { currentPassword, newPassword } = req.body;

      // Verify current password
      const isValidPassword = await req.user.verifyPassword(currentPassword);
      if (!isValidPassword) {
        return res.status(400).json({
          error: 'Invalid Password',
          message: 'Current password is incorrect',
        });
      }

      // Hash new password
      const newPasswordHash = await User.hashPassword(newPassword);

      // Update password
      await req.user.update({ password_hash: newPasswordHash });

      res.json({
        message: 'Password changed successfully',
      });
    } catch (error) {
      console.error('Change password error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to change password',
      });
    }
  }

  // Logout (invalidate token - in a real app, you'd maintain a blacklist)
  static async logout(req, res) {
    // In a production app, you would add the token to a blacklist in Redis
    res.json({
      message: 'Logged out successfully',
    });
  }
}

module.exports = AuthController;