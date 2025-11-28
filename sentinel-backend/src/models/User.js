const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const { runQuery, getQuery, allQuery } = require('../config/database');

class User {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.email = data.email;
    this.password_hash = data.password_hash;
    this.full_name = data.full_name;
    this.phone_number = data.phone_number;
    this.date_of_birth = data.date_of_birth;
    this.emergency_medical_info = data.emergency_medical_info;
    this.profile_picture_url = data.profile_picture_url;
    this.is_active = data.is_active !== undefined ? data.is_active : 1;
    this.email_verified = data.email_verified !== undefined ? data.email_verified : 0;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create new user
  async save() {
    const sql = `
      INSERT INTO users (
        id, email, password_hash, full_name, phone_number, 
        date_of_birth, emergency_medical_info, profile_picture_url,
        is_active, email_verified
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const params = [
      this.id,
      this.email,
      this.password_hash,
      this.full_name,
      this.phone_number,
      this.date_of_birth,
      this.emergency_medical_info,
      this.profile_picture_url,
      this.is_active,
      this.email_verified
    ];

    await runQuery(sql, params);
    return this;
  }

  // Find user by email
  static async findByEmail(email) {
    const sql = 'SELECT * FROM users WHERE email = ? AND is_active = 1';
    const row = await getQuery(sql, [email]);
    return row ? new User(row) : null;
  }

  // Find user by ID
  static async findById(id) {
    const sql = 'SELECT * FROM users WHERE id = ? AND is_active = 1';
    const row = await getQuery(sql, [id]);
    return row ? new User(row) : null;
  }

  // Update user
  async update(updateData) {
    const fields = [];
    const values = [];

    Object.keys(updateData).forEach(key => {
      if (updateData[key] !== undefined && key !== 'id') {
        fields.push(`${key} = ?`);
        values.push(updateData[key]);
      }
    });

    if (fields.length === 0) return this;

    fields.push('updated_at = CURRENT_TIMESTAMP');
    values.push(this.id);

    const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
    await runQuery(sql, values);

    // Refresh user data
    const updated = await User.findById(this.id);
    Object.assign(this, updated);
    return this;
  }

  // Hash password
  static async hashPassword(password) {
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    return await bcrypt.hash(password, saltRounds);
  }

  // Verify password
  async verifyPassword(password) {
    return await bcrypt.compare(password, this.password_hash);
  }

  // Get user with settings
  async getWithSettings() {
    const sql = `
      SELECT 
        u.*,
        s.enable_location_sharing,
        s.auto_contact_police,
        s.enable_vibration,
        s.enable_sound_alerts,
        s.enable_push_notifications,
        s.alert_delay_seconds,
        s.share_location_with_contacts,
        s.enable_quick_dial,
        s.require_pin_on_startup,
        s.enable_biometric_auth,
        s.enable_stealth_mode,
        s.auto_lock_minutes
      FROM users u
      LEFT JOIN user_settings s ON u.id = s.user_id
      WHERE u.id = ? AND u.is_active = 1
    `;
    
    return await getQuery(sql, [this.id]);
  }

  // Convert to JSON (exclude sensitive data)
  toJSON() {
    const { password_hash, ...userWithoutPassword } = this;
    return userWithoutPassword;
  }
}

module.exports = User;