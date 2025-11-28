const { v4: uuidv4 } = require('uuid');
const { runQuery, getQuery, allQuery } = require('../config/database');

class EmergencyContact {
  constructor(data) {
    this.id = data.id || uuidv4();
    this.user_id = data.user_id;
    this.name = data.name;
    this.phone_number = data.phone_number;
    this.email = data.email;
    this.relationship = data.relationship;
    this.is_active = data.is_active !== undefined ? data.is_active : 1;
    this.priority_order = data.priority_order || 1;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Save new contact
  async save() {
    const sql = `
      INSERT INTO emergency_contacts (
        id, user_id, name, phone_number, email, 
        relationship, is_active, priority_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const params = [
      this.id,
      this.user_id,
      this.name,
      this.phone_number,
      this.email,
      this.relationship,
      this.is_active,
      this.priority_order
    ];

    await runQuery(sql, params);
    return this;
  }

  // Find contacts by user ID
  static async findByUserId(userId) {
    const sql = `
      SELECT * FROM emergency_contacts 
      WHERE user_id = ? 
      ORDER BY priority_order ASC, created_at DESC
    `;
    const rows = await allQuery(sql, [userId]);
    return rows.map(row => new EmergencyContact(row));
  }

  // Find active contacts by user ID
  static async findActiveByUserId(userId) {
    const sql = `
      SELECT * FROM emergency_contacts 
      WHERE user_id = ? AND is_active = 1 
      ORDER BY priority_order ASC, created_at DESC
    `;
    const rows = await allQuery(sql, [userId]);
    return rows.map(row => new EmergencyContact(row));
  }

  // Find contact by ID
  static async findById(id) {
    const sql = 'SELECT * FROM emergency_contacts WHERE id = ?';
    const row = await getQuery(sql, [id]);
    return row ? new EmergencyContact(row) : null;
  }

  // Update contact
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

    const sql = `UPDATE emergency_contacts SET ${fields.join(', ')} WHERE id = ?`;
    await runQuery(sql, values);

    // Refresh contact data
    const updated = await EmergencyContact.findById(this.id);
    Object.assign(this, updated);
    return this;
  }

  // Delete contact
  async delete() {
    const sql = 'DELETE FROM emergency_contacts WHERE id = ?';
    await runQuery(sql, [this.id]);
    return true;
  }

  // Get contact count for user
  static async getCountByUserId(userId) {
    const sql = 'SELECT COUNT(*) as count FROM emergency_contacts WHERE user_id = ? AND is_active = 1';
    const result = await getQuery(sql, [userId]);
    return result.count;
  }
}

module.exports = EmergencyContact;